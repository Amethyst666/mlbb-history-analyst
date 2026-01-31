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
  String duration = '15:00';
  DateTime matchDate = DateTime.now();

  List<PlayerStats> myTeam = List.generate(5, (i) => PlayerStats(nickname: 'Player ${i + 1}', hero: 'unknown', kda: '0/0/0', gold: '0', items: '', score: '0.0', isEnemy: false, isUser: false));
  List<PlayerStats> enemyTeam = List.generate(5, (i) => PlayerStats(nickname: 'Enemy ${i + 1}', hero: 'unknown', kda: '0/0/0', gold: '0', items: '', score: '0.0', isEnemy: true, isUser: false));

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    if (widget.initialGame != null) _loadInitialGame();
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNickname = prefs.getString('user_nickname');
    });
  }

  Future<void> _loadInitialGame() async {
    final game = widget.initialGame!;
    final players = await _dbHelper.getPlayersForGame(game.id!);
    setState(() {
      gameResult = game.result;
      duration = game.duration;
      matchDate = game.date;
      myTeam = players.where((p) => !p.isEnemy).toList();
      enemyTeam = players.where((p) => p.isEnemy).toList();
      while (myTeam.length < 5) myTeam.add(PlayerStats(nickname: 'Player', hero: 'unknown', kda: '0/0/0', gold: '0', items: '', score: '0.0', isEnemy: false, isUser: false));
      while (enemyTeam.length < 5) enemyTeam.add(PlayerStats(nickname: 'Enemy', hero: 'unknown', kda: '0/0/0', gold: '0', items: '', score: '0.0', isEnemy: true, isUser: false));
    });
  }

  Future<void> _scanScreenshot() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      _showProcessingDialog();
      try {
        final bytes = await _image!.readAsBytes();
        final fullImg = img.decodeImage(bytes);
        final ocrResult = await OcrParser.parseWithCropping(_image!);
        
        if (ocrResult != null && fullImg != null) {
          _populateTeamsFromOcr(ocrResult);
          final heroIds = GameData.heroes.map((e) => e.id).toList();
          final itemIds = GameData.items.map((e) => e.id).toList();
          final blessingIds = GameData.blessings.map((e) => e.id).toList();
          
          await ImageIdentifier.preloadAssets(heroIds, 'heroes');
          await ImageIdentifier.preloadAssets(itemIds, 'items');
          await ImageIdentifier.preloadAssets(blessingIds, 'blessings');

          for (int i = 0; i < ocrResult.players.length; i++) {
            final det = ocrResult.players[i];
            final hCrop = ImageIdentifier.cropRect(fullImg, det.heroRect);
            if (hCrop != null) {
              String hId = await ImageIdentifier.findBestMatch(hCrop, heroIds, 'heroes');
              if (hId != 'unknown') {
                setState(() {
                  if (i < 5) myTeam[i] = myTeam[i].copyWith(hero: hId);
                  else enemyTeam[i-5] = enemyTeam[i-5].copyWith(hero: hId);
                });
              }
            }

            List<String> itemsFound = [];
            for (var r in det.itemRects) {
              final iCrop = ImageIdentifier.cropRect(fullImg, r);
              if (iCrop != null && !ImageIdentifier.isEmptySlot(iCrop)) {
                String iId = await ImageIdentifier.findBestMatch(iCrop, itemIds, 'items');
                if (iId == 'unknown') iId = await ImageIdentifier.findBestMatch(iCrop, blessingIds, 'blessings');
                if (iId != 'unknown') itemsFound.add(iId);
              }
            }
            if (itemsFound.isNotEmpty) {
              setState(() {
                PlayerStats p = (i < 5) ? myTeam[i] : enemyTeam[i-5];
                String role = p.role;
                String spell = p.spell;
                if (itemsFound.any((id) => id.contains('retribution'))) { role = 'jungle'; spell = 'retribution'; }
                else if (itemsFound.any((id) => id.contains('conceal') || id.contains('favor') || id.contains('encourage') || id.contains('dire_hit'))) { role = 'roam'; }
                final updated = p.copyWith(items: itemsFound.join(','), role: role, spell: spell);
                if (i < 5) myTeam[i] = updated; else enemyTeam[i-5] = updated;
              });
            }
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) { Navigator.pop(context); _showErrorDialog("Error: $e"); }
      }
    }
  }

  void _populateTeamsFromOcr(OcrResult data) {
    setState(() {
      gameResult = data.result;
      duration = data.duration;
      for (int i = 0; i < data.players.length; i++) {
        final pStats = data.players[i].stats;
        // Check if this player is the user based on nickname
        bool isUser = false;
        if (_userNickname != null && _userNickname!.isNotEmpty) {
          isUser = pStats.nickname.toLowerCase() == _userNickname!.toLowerCase();
        }

        if (i < 5) {
          myTeam[i] = pStats.copyWith(isUser: isUser, isEnemy: false);
        } else {
          enemyTeam[i - 5] = pStats.copyWith(isUser: isUser, isEnemy: true);
        }
      }
    });
  }

  void _showProcessingDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Scanning...")] )));
  }

  void _showErrorDialog(String msg) {
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Notice"), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))]));
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
    String currentHero = p.hero;
    String currentRole = p.role;
    String currentSpell = p.spell;
    bool currentIsUser = p.isUser;
    List<String> currentItems = p.items.isEmpty ? [] : p.items.split(',');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (stCtx, setModalState) {
        void checkAutoRole(String item) {
          if (item.contains('retribution')) { currentRole = 'jungle'; currentSpell = 'retribution'; }
          else if (item.contains('conceal') || item.contains('favor') || item.contains('encourage') || item.contains('dire_hit')) { currentRole = 'roam'; }
        }

        return Container(
          decoration: const BoxDecoration(color: Color(0xFF1A1C2C), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEnemy ? "Enemy ${index + 1}" : "Ally ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Row(
                      children: [
                        const Text("Это я", style: TextStyle(fontSize: 12)),
                        Switch(
                          value: currentIsUser, 
                          onChanged: (v) => setModalState(() => currentIsUser = v)
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final h = await showModalBottomSheet<String>(context: context, builder: (c) => const HeroPicker());
                        if (h != null) setModalState(() => currentHero = h);
                      },
                      child: DataUtils.getHeroIcon(currentHero, radius: 35),
                    ),
                    const SizedBox(width: 15),
                    Expanded(child: TextField(controller: nickCtrl, decoration: const InputDecoration(labelText: "Nickname", border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 20),
                _buildRoleSelector(currentRole, (r) => setModalState(() => currentRole = r)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSpellSelector(currentSpell, (s) => setModalState(() => currentSpell = s)),
                    const SizedBox(width: 15),
                    Expanded(child: TextField(controller: killsCtrl, decoration: const InputDecoration(labelText: "K", border: OutlineInputBorder()), keyboardType: TextInputType.number, textAlign: TextAlign.center)),
                    const SizedBox(width: 5), const Text("/", style: TextStyle(fontSize: 20, color: Colors.grey)), const SizedBox(width: 5),
                    Expanded(child: TextField(controller: deathsCtrl, decoration: const InputDecoration(labelText: "D", border: OutlineInputBorder()), keyboardType: TextInputType.number, textAlign: TextAlign.center)),
                    const SizedBox(width: 5), const Text("/", style: TextStyle(fontSize: 20, color: Colors.grey)), const SizedBox(width: 5),
                    Expanded(child: TextField(controller: assistsCtrl, decoration: const InputDecoration(labelText: "A", border: OutlineInputBorder()), keyboardType: TextInputType.number, textAlign: TextAlign.center)),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: TextField(controller: goldCtrl, decoration: const InputDecoration(labelText: "Gold", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: scoreCtrl, decoration: const InputDecoration(labelText: "Score", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 25),
                const Text("Items", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                const SizedBox(height: 15),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1),
                  itemCount: currentItems.length + 1,
                  itemBuilder: (c, i) {
                    if (i < currentItems.length) {
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final item = await showModalBottomSheet<String>(context: context, builder: (c) => const ItemPicker());
                              if (item != null) setModalState(() { currentItems[i] = item; checkAutoRole(item); });
                            },
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: DataUtils.getItemIcon(currentItems[i], size: 60)),
                            ),
                          ),
                          Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setModalState(() => currentItems.removeAt(i)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)))),
                        ],
                      );
                    } else {
                      return GestureDetector(
                        onTap: () async {
                          final item = await showModalBottomSheet<String>(context: context, builder: (c) => const ItemPicker());
                          if (item != null) setModalState(() { currentItems.add(item); checkAutoRole(item); });
                        },
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)), borderRadius: BorderRadius.circular(12), color: Colors.cyanAccent.withOpacity(0.05)),
                          child: const Icon(Icons.add, color: Colors.cyanAccent, size: 30),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    setState(() {
                      // If this player is set as user, unmark all others
                      if (currentIsUser) {
                        for (int j = 0; j < 5; j++) myTeam[j] = myTeam[j].copyWith(isUser: false);
                        for (int j = 0; j < 5; j++) enemyTeam[j] = enemyTeam[j].copyWith(isUser: false);
                      }
                      
                      final finalKda = "${killsCtrl.text.isEmpty ? '0' : killsCtrl.text}/${deathsCtrl.text.isEmpty ? '0' : deathsCtrl.text}/${assistsCtrl.text.isEmpty ? '0' : assistsCtrl.text}";
                      final updated = p.copyWith(
                        nickname: nickCtrl.text.isEmpty ? "Unknown" : nickCtrl.text,
                        hero: currentHero, role: currentRole, spell: currentSpell,
                        kda: finalKda, gold: goldCtrl.text, score: scoreCtrl.text,
                        items: currentItems.join(','), isUser: currentIsUser,
                      );
                      if (isEnemy) enemyTeam[index] = updated; else myTeam[index] = updated;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("SAVE CHANGES"),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRoleSelector(String current, Function(String) onSelect) {
    final roles = ['jungle', 'roam', 'mid', 'gold', 'exp'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: roles.map((r) => GestureDetector(
        onTap: () => onSelect(r),
        child: Container(
          width: 55, height: 50,
          decoration: BoxDecoration(
            color: current == r ? Colors.deepPurpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            border: Border.all(color: current == r ? Colors.deepPurpleAccent : Colors.white10, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: DataUtils.getRoleIcon(r, size: 28)),
        ),
      )).toList(),
    );
  }

  Widget _buildSpellSelector(String current, Function(String) onSelect) {
    return GestureDetector(
      onTap: () async {
        final spell = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (c) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFF1A1C2C), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: GameData.spells.map((s) => GestureDetector(
                onTap: () => Navigator.pop(c, s.id),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                  child: Center(child: DataUtils.getSpellIcon(s.id, size: 50)),
                ),
              )).toList(),
            ),
          ),
        );
        if (spell != null) onSelect(spell);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
        child: DataUtils.getSpellIcon(current, size: 35),
      ),
    );
  }

  Future<void> _saveGame() async {
    final hasUser = myTeam.any((p) => p.isUser) || enemyTeam.any((p) => p.isUser);
    PlayerStats? userStats;
    try {
      userStats = [...myTeam, ...enemyTeam].firstWhere((p) => p.isUser);
    } catch (_) {
      userStats = null;
    }
    
    final game = GameStats(id: widget.initialGame?.id, result: gameResult, hero: userStats?.hero ?? 'none', kda: userStats?.kda ?? '', items: userStats?.items ?? '', players: '', date: matchDate, duration: duration, role: userStats?.role ?? 'unknown', spell: userStats?.spell ?? 'none');
    List<PlayerStats> allPlayers = [...myTeam, ...enemyTeam];
    if (widget.initialGame != null) await _dbHelper.updateGameWithPlayers(game, allPlayers);
    else await _dbHelper.insertGameWithPlayers(game, allPlayers);
    if (widget.onSaveSuccess != null) widget.onSaveSuccess!();
    
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match saved!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialGame != null ? "Edit Match" : "Add Match"), actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveGame)]),
      body: ListView(
        children: [
          _buildTopInfo(),
          const Divider(),
          _buildTeamHeader("MY TEAM", Colors.blue),
          ...List.generate(5, (i) => _buildPlayerTile(i, false)),
          const Divider(),
          _buildTeamHeader("ENEMY TEAM", Colors.red),
          ...List.generate(5, (i) => _buildPlayerTile(i, true)),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _scanScreenshot, label: const Text("SCAN"), icon: const Icon(Icons.camera_alt)),
    );
  }

  Widget _buildTopInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: gameResult,
            items: const [DropdownMenuItem(value: 'VICTORY', child: Text("VICTORY")), DropdownMenuItem(value: 'DEFEAT', child: Text("DEFEAT"))],
            onChanged: (v) => setState(() => gameResult = v!),
          ),
          Text("Duration: $duration"),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(String label, Color col) {
    return Container(padding: const EdgeInsets.all(8), color: col.withOpacity(0.1), child: Text(label, style: TextStyle(color: col, fontWeight: FontWeight.bold)));
  }

  Widget _buildPlayerTile(int i, bool isEnemy) {
    final p = isEnemy ? enemyTeam[i] : myTeam[i];
    final itemsList = p.items.isEmpty ? [] : p.items.split(',');
    return ListTile(
      leading: Stack(
        children: [
          DataUtils.getHeroIcon(p.hero, radius: 25),
          Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(1), decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle), child: DataUtils.getRoleIcon(p.role, size: 14))),
        ],
      ),
      title: Text(p.nickname, style: TextStyle(fontWeight: p.isUser ? FontWeight.bold : FontWeight.normal, color: p.isUser ? Colors.cyanAccent : Colors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("KDA: ${p.kda} • ⭐ ${p.score}"),
          Text("💰 ${p.gold}"),
          if (itemsList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(spacing: 4, children: itemsList.map((item) => SizedBox(width: 24, height: 24, child: DataUtils.getItemIcon(item, size: 24))).toList()),
            ),
        ],
      ),
      trailing: DataUtils.getSpellIcon(p.spell, size: 24),
      onTap: () => _editPlayerStats(i, isEnemy),
    );
  }
}
