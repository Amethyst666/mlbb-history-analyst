import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_stats.dart';
import '../models/game_stats.dart';
import '../utils/game_data.dart';
import '../utils/database_helper.dart';
import '../utils/ocr_parser.dart';
import '../utils/image_identifier.dart';
import '../utils/app_strings.dart';
import '../utils/data_utils.dart';
import '../widgets/hero_picker.dart';
import '../widgets/item_picker.dart';

class AddGameScreen extends StatefulWidget {
  final VoidCallback? onSaveSuccess;
  final GameStats? initialGame;

  const AddGameScreen({super.key, this.onSaveSuccess, this.initialGame});

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final _dbHelper = DatabaseHelper();
  final picker = ImagePicker();
  File? _image;
  String? _userNickname;

  String gameResult = 'VICTORY';
  String duration = '00:00';
  DateTime matchDate = DateTime.now();

  List<PlayerStats> myTeam = List.generate(5, (i) => PlayerStats(nickname: 'Player ${i + 1}', hero: 'unknown', kda: '0/0/0', gold: '0', items: '', score: '0.0', isEnemy: false, isUser: false, role: 'unknown', spell: 'none'));
  List<PlayerStats> enemyTeam = List.generate(5, (i) => PlayerStats(nickname: 'Enemy ${i + 1}', hero: 'unknown', kda: '0/0/0', gold: '0', items: '', score: '0.0', isEnemy: true, isUser: false, role: 'unknown', spell: 'none'));

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    if (widget.initialGame != null) _loadInitialGame();
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userNickname = prefs.getString('userNickname'));
  }

  Future<void> _loadInitialGame() async {
    final game = widget.initialGame!;
    final players = await _dbHelper.getPlayersForGame(game.id!);
    setState(() {
      gameResult = game.result; duration = game.duration; matchDate = game.date;
      myTeam = players.where((p) => !p.isEnemy).toList();
      enemyTeam = players.where((p) => p.isEnemy).toList();
      while (myTeam.length < 5) myTeam.add(PlayerStats(nickname: 'Player', hero: 'unknown', kda: '0/0/0', gold: '0', items: '', score: '0.0', isEnemy: false, isUser: false, role: 'unknown', spell: 'none'));
      while (enemyTeam.length < 5) enemyTeam.add(PlayerStats(nickname: 'Enemy', hero: 'unknown', kda: '0/0/0', gold: '0', items: '', score: '0.0', isEnemy: true, isUser: false, role: 'unknown', spell: 'none'));
    });
  }

  Map<String, String?> _checkSuspicious(PlayerStats p) {
    Map<String, String?> issues = {};
    final kdaParts = p.kda.split('/');
    for (var part in kdaParts) {
      int? val = int.tryParse(part);
      if (val == null) issues['kda'] = "KDA error";
      else if (val > 99) issues['kda'] = "High KDA ($val)";
      else if (part.length > 1 && part.startsWith('0')) issues['kda'] = "Zero prefix ($part)";
    }
    if (p.gold.isEmpty || p.gold == "0") issues['gold'] = "No gold";
    else if (p.gold.length < 4 || p.gold.length > 5) issues['gold'] = "Odd gold (${p.gold})";
    if (p.score == "0.0" || p.score == "0") issues['score'] = "Score missing";
    else if (!RegExp(r'^\d{1,2}\.\d$').hasMatch(p.score)) issues['score'] = "Score format error";
    if (p.hero == 'unknown') issues['hero'] = "Hero unknown";
    if (p.role == 'unknown') issues['role'] = "Role missing";
    if (p.spell == 'none' || p.spell == 'unknown') issues['spell'] = "Spell missing";
    return issues;
  }

  bool _isAnySuspicious() {
    for (var p in [...myTeam, ...enemyTeam]) if (_checkSuspicious(p).isNotEmpty) return true;
    return false;
  }

  void _showProcessingDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Scanning...")] )));
  }

  void _showErrorDialog(String msg) {
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Error"), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))]));
  }

  Future<void> _scanScreenshot() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      _showProcessingDialog();
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        final ocrResult = await OcrParser.parseWithCropping(_image!);
        if (ocrResult != null) {
          setState(() {
            gameResult = ocrResult.result;
            duration = ocrResult.duration;
            for (int i = 0; i < ocrResult.players.length; i++) {
              final pStats = ocrResult.players[i].stats;
              // АВТО-ДЕТЕКТ USER: По нику из настроек
              bool isUserMatch = _userNickname != null && pStats.nickname.toLowerCase() == _userNickname!.toLowerCase();
              if (i < 5) myTeam[i] = pStats.copyWith(isUser: isUserMatch, isEnemy: false);
              else enemyTeam[i - 5] = pStats.copyWith(isUser: isUserMatch, isEnemy: true);
            }
          });
          final bytes = await _image!.readAsBytes();
          final fullImg = img.decodeImage(bytes);
          final heroIds = GameData.heroes.map((e) => e.id).toList();
          final itemIds = GameData.items.map((e) => e.id).toList();
          final blessingIds = GameData.blessings.map((e) => e.id).toList();
          final spellIds = GameData.spells.map((e) => e.id).toList();
          await ImageIdentifier.preloadAssets(heroIds, 'heroes');
          await ImageIdentifier.preloadAssets(itemIds, 'items');
          await ImageIdentifier.preloadAssets(blessingIds, 'blessings');
          await ImageIdentifier.preloadAssets(spellIds, 'spells');
          for (int i = 0; i < ocrResult.players.length; i++) {
            final det = ocrResult.players[i];
            final hCrop = ImageIdentifier.cropRect(fullImg!, det.heroRect);
            if (hCrop != null) {
              String hId = await ImageIdentifier.findBestMatch(hCrop, heroIds, 'heroes');
              if (hId != 'unknown') setState(() { if (i < 5) myTeam[i] = myTeam[i].copyWith(hero: hId); else enemyTeam[i-5] = enemyTeam[i-5].copyWith(hero: hId); });
            }
            List<String> itemsFound = [];
            for (var r in det.itemRects) {
              final iCrop = ImageIdentifier.cropRect(fullImg!, r);
              if (iCrop != null && !ImageIdentifier.isEmptySlot(iCrop)) {
                String iId = await ImageIdentifier.findBestMatch(iCrop, itemIds, 'items');
                if (iId == 'unknown') iId = await ImageIdentifier.findBestMatch(iCrop, blessingIds, 'blessings');
                if (iId != 'unknown') itemsFound.add(iId);
              }
            }
            if (itemsFound.isNotEmpty) setState(() {
              PlayerStats p = (i < 5) ? myTeam[i] : enemyTeam[i-5];
              String role = p.role; String spell = p.spell;
              if (itemsFound.any((id) => id.contains('retribution'))) { role = 'jungle'; spell = 'retribution'; }
              else if (itemsFound.any((id) => id.contains('conceal') || id.contains('favor') || id.contains('encourage') || id.contains('dire_hit'))) { role = 'roam'; }
              final updated = p.copyWith(items: itemsFound.join(','), role: role, spell: spell);
              if (i < 5) myTeam[i] = updated; else enemyTeam[i-5] = updated;
            });
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) { if (mounted) { Navigator.pop(context); _showErrorDialog("$e"); } }
    }
  }

  void _editPlayerStats(int index, bool isEnemy) {
    PlayerStats p = isEnemy ? enemyTeam[index] : myTeam[index];
    final kdaParts = p.kda.split('/');
    final killsCtrl = TextEditingController(text: kdaParts.isNotEmpty ? kdaParts[0] : "0");
    final deathsCtrl = TextEditingController(text: kdaParts.length > 1 ? kdaParts[1] : "0");
    final assistsCtrl = TextEditingController(text: kdaParts.length > 2 ? kdaParts[2] : "0");
    final nickCtrl = TextEditingController(text: p.nickname == "Unknown" ? "" : p.nickname);
    final goldCtrl = TextEditingController(text: p.gold);
    final scoreCtrl = TextEditingController(text: p.score);
    String currentHero = p.hero; String currentRole = p.role; String currentSpell = p.spell; 
    List<String> currentItems = p.items.isEmpty ? [] : p.items.split(',');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (stCtx, setModalState) {
        bool isSusp(String f, String v) {
          if (f == 'gold') return v.length < 4 || v.length > 5 || (v.length > 1 && v.startsWith('0')) || v == "0" || v.isEmpty;
          if (f == 'score') return !RegExp(r'^\d{1,2}\.\d$').hasMatch(v) || v == "0.0";
          if (f == 'kda') return int.tryParse(v) == null || int.tryParse(v)! > 99 || (v.length > 1 && v.startsWith('0'));
          return false;
        }

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(color: Color(0xFF1A1C2C), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Center(child: Text(isEnemy ? "Enemy ${index + 1}" : "Ally ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))),
              Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
                Row(children: [
                  GestureDetector(onTap: () async {
                    final h = await showModalBottomSheet<String>(context: context, builder: (c) => const HeroPicker());
                    if (h != null) setModalState(() => currentHero = h);
                  }, child: Stack(children: [DataUtils.getHeroIcon(currentHero, radius: 35), if (currentHero == 'unknown') const Positioned.fill(child: Icon(Icons.warning, color: Colors.redAccent))])),
                  const SizedBox(width: 15),
                  Expanded(child: TextField(controller: nickCtrl, decoration: const InputDecoration(labelText: "Nickname", border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 20),
                _buildRoleSelector(currentRole, (r) => setModalState(() => currentRole = r)),
                const SizedBox(height: 20),
                Row(children: [
                  _buildSpellSelector(currentSpell, (s) => setModalState(() => currentSpell = s)),
                  const SizedBox(width: 15),
                  Expanded(child: TextField(controller: killsCtrl, onChanged: (v)=>setModalState((){}), decoration: InputDecoration(labelText: "K", border: OutlineInputBorder(borderSide: BorderSide(color: isSusp('kda', killsCtrl.text) ? Colors.red : Colors.grey)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isSusp('kda', killsCtrl.text) ? Colors.red : Colors.white24))), keyboardType: TextInputType.number, textAlign: TextAlign.center)),
                  const SizedBox(width: 5), const Text("/", style: TextStyle(fontSize: 20, color: Colors.grey)), const SizedBox(width: 5),
                  Expanded(child: TextField(controller: deathsCtrl, onChanged: (v)=>setModalState((){}), decoration: InputDecoration(labelText: "D", border: OutlineInputBorder(borderSide: BorderSide(color: isSusp('kda', deathsCtrl.text) ? Colors.red : Colors.grey)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isSusp('kda', deathsCtrl.text) ? Colors.red : Colors.white24))), keyboardType: TextInputType.number, textAlign: TextAlign.center)),
                  const SizedBox(width: 5), const Text("/", style: TextStyle(fontSize: 20, color: Colors.grey)), const SizedBox(width: 5),
                  Expanded(child: TextField(controller: assistsCtrl, onChanged: (v)=>setModalState((){}), decoration: InputDecoration(labelText: "A", border: OutlineInputBorder(borderSide: BorderSide(color: isSusp('kda', assistsCtrl.text) ? Colors.red : Colors.grey)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isSusp('kda', assistsCtrl.text) ? Colors.red : Colors.white24))), keyboardType: TextInputType.number, textAlign: TextAlign.center)),
                ]),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(child: TextField(controller: goldCtrl, onChanged: (v)=>setModalState((){}), decoration: InputDecoration(labelText: "Gold", border: OutlineInputBorder(borderSide: BorderSide(color: isSusp('gold', goldCtrl.text) ? Colors.red : Colors.grey)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isSusp('gold', goldCtrl.text) ? Colors.red : Colors.white24))), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: scoreCtrl, onChanged: (v)=>setModalState((){}), decoration: InputDecoration(labelText: "Score", border: OutlineInputBorder(borderSide: BorderSide(color: isSusp('score', scoreCtrl.text) ? Colors.red : Colors.grey)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isSusp('score', scoreCtrl.text) ? Colors.red : Colors.white24))), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 25),
                const Text("Items", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                const SizedBox(height: 15),
                GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12), itemCount: currentItems.length + 1, itemBuilder: (c, i) {
                  if (i < currentItems.length) {
                    return Stack(children: [
                      GestureDetector(onTap: () async {
                        final item = await showModalBottomSheet<String>(context: context, builder: (c) => const ItemPicker());
                        if (item != null) setModalState(() { currentItems[i] = item; if (item.contains('retribution')) { currentRole='jungle'; currentSpell='retribution'; } else if (RegExp(r'conceal|favor|encourage|dire_hit').hasMatch(item)) { currentRole='roam'; } });
                      }, child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)), child: Center(child: DataUtils.getItemIcon(currentItems[i], size: 60)))),
                      Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setModalState(() => currentItems.removeAt(i)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)))),
                    ]);
                  } else {
                    return GestureDetector(onTap: () async {
                      final item = await showModalBottomSheet<String>(context: context, builder: (c) => const ItemPicker());
                      if (item != null) setModalState(() { currentItems.add(item); if (item.contains('retribution')) { currentRole='jungle'; currentSpell='retribution'; } else if (RegExp(r'conceal|favor|encourage|dire_hit').hasMatch(item)) { currentRole='roam'; } });
                    }, child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)), borderRadius: BorderRadius.circular(12), color: Colors.cyanAccent.withOpacity(0.05)), child: const Icon(Icons.add, color: Colors.cyanAccent, size: 30)));
                  }
                }),
                const SizedBox(height: 100),
              ]))),
              Padding(padding: const EdgeInsets.all(16), child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                icon: const Icon(Icons.check_circle), label: const Text("SAVE PLAYER", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    final finalKda = "${killsCtrl.text.isEmpty?'0':killsCtrl.text}/${deathsCtrl.text.isEmpty?'0':deathsCtrl.text}/${assistsCtrl.text.isEmpty?'0':assistsCtrl.text}";
                    // Мы не ставим isUser вручную, DatabaseHelper сам определит это по нику
                    bool isUserNow = _userNickname != null && nickCtrl.text.toLowerCase() == _userNickname!.toLowerCase();
                    final updated = p.copyWith(nickname: nickCtrl.text.isEmpty?"Unknown":nickCtrl.text, hero: currentHero, role: currentRole, spell: currentSpell, kda: finalKda, gold: goldCtrl.text, score: scoreCtrl.text, items: currentItems.join(','), isUser: isUserNow);
                    if (isEnemy) enemyTeam[index] = updated; else myTeam[index] = updated;
                  });
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        );
      }),
    ).then((_) => setState(() {}));
  }

  Future<void> _handleSaveGame() async {
    List<String> warnings = [];
    if (duration == "00:00" || duration.isEmpty) warnings.add("Match Duration: Missing or 00:00");
    for (int i=0; i<5; i++) {
      var iss = _checkSuspicious(myTeam[i]);
      if (iss.isNotEmpty) warnings.add("Ally ${i+1}: ${iss.values.join(', ')}");
    }
    for (int i=0; i<5; i++) {
      var iss = _checkSuspicious(enemyTeam[i]);
      if (iss.isNotEmpty) warnings.add("Enemy ${i+1}: ${iss.values.join(', ')}");
    }
    if (warnings.isNotEmpty) {
      bool proceed = await showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Check data"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: warnings.map((w) => Text("• $w", style: const TextStyle(fontSize: 11, color: Colors.redAccent))).toList())), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("FIX")), ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("SAVE ANYWAY"))])) ?? false;
      if (!proceed) return;
    }
    _performSave();
  }

  Future<void> _performSave() async {
    PlayerStats? userStats;
    try { userStats = [...myTeam, ...enemyTeam].firstWhere((p) => p.isUser); } catch (_) { userStats = null; }
    final game = GameStats(id: widget.initialGame?.id, result: gameResult, hero: userStats?.hero ?? 'none', kda: userStats?.kda ?? '', items: userStats?.items ?? '', players: '', date: matchDate, duration: duration, role: userStats?.role ?? 'unknown', spell: userStats?.spell ?? 'none');
    if (widget.initialGame != null) await _dbHelper.updateGameWithPlayers(game, [...myTeam, ...enemyTeam]);
    else await _dbHelper.insertGameWithPlayers(game, [...myTeam, ...enemyTeam]);
    if (widget.onSaveSuccess != null) widget.onSaveSuccess!();
    if (mounted) { if (Navigator.canPop(context)) Navigator.pop(context); else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match saved!"))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialGame != null ? "Edit Match" : "Add Match")),
      body: ListView(children: [
        _buildTopInfo(), const Divider(),
        _buildTeamHeader("MY TEAM", Colors.blue), ...List.generate(5, (i) => _buildPlayerTile(i, false)),
        const Divider(),
        _buildTeamHeader("ENEMY TEAM", Colors.red), ...List.generate(5, (i) => _buildPlayerTile(i, true)),
        const SizedBox(height: 120),
      ]),
      floatingActionButton: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton.extended(heroTag: "scan", onPressed: _scanScreenshot, label: const Text("SCAN"), icon: const Icon(Icons.camera_alt), backgroundColor: Colors.white10),
        const SizedBox(height: 10),
        FloatingActionButton.extended(heroTag: "save", onPressed: _handleSaveGame, label: const Text("SAVE MATCH"), icon: const Icon(Icons.save), backgroundColor: _isAnySuspicious() ? Colors.orange : Colors.cyanAccent, foregroundColor: Colors.black),
      ]),
    );
  }

  Widget _buildTopInfo() {
    return Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      DropdownButton<String>(value: gameResult, items: const [DropdownMenuItem(value: 'VICTORY', child: Text("VICTORY")), DropdownMenuItem(value: 'DEFEAT', child: Text("DEFEAT"))], onChanged: (v) => setState(() => gameResult = v!)),
      GestureDetector(onTap: () async {
        final ctrl = TextEditingController(text: duration);
        final newDur = await showDialog<String>(context: context, builder: (c) => AlertDialog(title: const Text("Edit Duration"), content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "MM:SS")), actions: [TextButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text("OK"))]));
        if (newDur != null) setState(() => duration = newDur);
      }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: (duration == "00:00" || duration.isEmpty) ? Colors.red.withOpacity(0.2) : Colors.white10, border: (duration == "00:00" || duration.isEmpty) ? Border.all(color: Colors.red) : null, borderRadius: BorderRadius.circular(8)), child: Text("Duration: $duration", style: const TextStyle(fontWeight: FontWeight.bold)))),
    ]));
  }

  Widget _buildTeamHeader(String label, Color col) => Container(padding: const EdgeInsets.all(8), color: col.withOpacity(0.1), child: Text(label, style: TextStyle(color: col, fontWeight: FontWeight.bold)));

  Widget _buildPlayerTile(int i, bool isEnemy) {
    final p = isEnemy ? enemyTeam[i] : myTeam[i];
    final itemsList = p.items.isEmpty ? [] : p.items.split(',');
    final suspicious = _checkSuspicious(p).isNotEmpty;
    bool roleSusp = p.role == 'unknown';
    bool spellSusp = p.spell == 'none' || p.spell == 'unknown';
    return ListTile(
      tileColor: suspicious ? Colors.red.withOpacity(0.05) : null,
      leading: Stack(children: [
        DataUtils.getHeroIcon(p.hero, radius: 25),
        Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(1), decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle, border: roleSusp ? Border.all(color: Colors.red, width: 1) : null), child: DataUtils.getRoleIcon(p.role, size: 14))),
        if (suspicious) const Positioned(top: 0, left: 0, child: Icon(Icons.error, color: Colors.red, size: 16)),
      ]),
      title: Text(p.nickname, style: TextStyle(fontWeight: p.isUser ? FontWeight.bold : FontWeight.normal, color: p.isUser ? Colors.cyanAccent : (suspicious ? Colors.redAccent : Colors.white))),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("KDA: ${p.kda} • ⭐ ${p.score}", style: TextStyle(color: suspicious ? Colors.red[200] : Colors.grey)),
        Text("💰 ${p.gold}", style: TextStyle(color: suspicious ? Colors.red[200] : Colors.grey)),
        if (itemsList.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(spacing: 4, children: itemsList.map((item) => SizedBox(width: 24, height: 24, child: DataUtils.getItemIcon(item, size: 24))).toList())),
      ]),
      trailing: Container(decoration: spellSusp ? BoxDecoration(border: Border.all(color: Colors.red, width: 1), borderRadius: BorderRadius.circular(4)) : null, child: DataUtils.getSpellIcon(p.spell, size: 24)),
      onTap: () => _editPlayerStats(i, isEnemy),
    );
  }

  Widget _buildRoleSelector(String current, Function(String) onSelect) {
    final roles = ['jungle', 'roam', 'mid', 'gold', 'exp'];
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: roles.map((r) => GestureDetector(onTap: () => onSelect(r), child: Container(width: 55, height: 50, decoration: BoxDecoration(color: current == r ? Colors.deepPurpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05), border: Border.all(color: current == r ? Colors.deepPurpleAccent : (current == 'unknown' ? Colors.redAccent : Colors.white10), width: 1.5), borderRadius: BorderRadius.circular(10)), child: Center(child: DataUtils.getRoleIcon(r, size: 28))))).toList());
  }

  Widget _buildSpellSelector(String current, Function(String) onSelect) {
    bool isSusp = current == 'none' || current == 'unknown';
    return GestureDetector(onTap: () async {
      final spell = await showModalBottomSheet<String>(context: context, backgroundColor: Colors.transparent, builder: (c) => Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Color(0xFF1A1C2C), borderRadius: BorderRadius.vertical(top: Radius.circular(25))), child: GridView.count(crossAxisCount: 4, mainAxisSpacing: 15, crossAxisSpacing: 15, children: GameData.spells.map((s) => GestureDetector(onTap: () => Navigator.pop(c, s.id), child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)), child: Center(child: DataUtils.getSpellIcon(s.id, size: 50))))).toList())));
      if (spell != null) onSelect(spell);
    }, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: isSusp ? Border.all(color: Colors.red, width: 1) : null), child: DataUtils.getSpellIcon(current, size: 35)));
  }
}
