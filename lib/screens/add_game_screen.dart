import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_stats.dart';
import '../models/game_stats.dart';
import '../utils/game_data.dart';
import '../utils/database_helper.dart';
import '../utils/history_parser.dart';
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
  File? _file;
  String? _userId;
  String? _matchId;

  String gameResult = 'VICTORY';
  String duration = '00:00';
  DateTime matchDate = DateTime.now();

  List<PlayerStats> myTeam = List.generate(5, (i) => PlayerStats(nickname: 'Player ${i + 1}', heroId: 0, kda: '0/0/0', gold: '0', itemIds: [], score: 0, isEnemy: false, isUser: false, role: 'unknown', spellId: 0));
  List<PlayerStats> enemyTeam = List.generate(5, (i) => PlayerStats(nickname: 'Enemy ${i + 1}', heroId: 0, kda: '0/0/0', gold: '0', itemIds: [], score: 0, isEnemy: true, isUser: false, role: 'unknown', spellId: 0));

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    if (widget.initialGame != null) _loadInitialGame();
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getString('userId'));
  }

  Future<void> _loadInitialGame() async {
    final game = widget.initialGame!;
    final players = await _dbHelper.getPlayersForGame(game.id!);
    setState(() {
      gameResult = game.result; 
      duration = game.duration; 
      matchDate = game.date;
      _matchId = game.matchId;
      myTeam = players.where((p) => !p.isEnemy).toList();
      enemyTeam = players.where((p) => p.isEnemy).toList();
      while (myTeam.length < 5) myTeam.add(PlayerStats(nickname: 'Player', heroId: 0, kda: '0/0/0', gold: '0', itemIds: [], score: 0, isEnemy: false, isUser: false, role: 'unknown', spellId: 0));
      while (enemyTeam.length < 5) enemyTeam.add(PlayerStats(nickname: 'Enemy', heroId: 0, kda: '0/0/0', gold: '0', itemIds: [], score: 0, isEnemy: true, isUser: false, role: 'unknown', spellId: 0));
    });
  }

  void _showProcessingDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Parsing History...")] )));
  }

  void _showErrorDialog(String msg) {
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Error"), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))]));
  }

  Future<void> _pickHistoryFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final path = result.files.single.path!;
      final filename = result.files.single.name;
      
      setState(() {
        _file = File(path);
        if (filename.startsWith('His-')) {
          var parts = filename.split('-');
          if (parts.length >= 3) _matchId = parts.last.split('.').first;
        }
      });

      _showProcessingDialog();
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        final parsedData = await HistoryParser.parseFile(_file!, userGameId: _userId, matchId: _matchId);
        if (parsedData != null) {
          setState(() {
            gameResult = parsedData.game.result;
            duration = parsedData.game.duration;
            
            final allPlayers = parsedData.players;
            
            int myTeamId = -1;
            try {
              final me = allPlayers.firstWhere((p) => p.isUser);
              myTeamId = me.teamId;
            } catch (_) {
              if (_userId != null && _userId!.isNotEmpty) {
                try {
                  final me = allPlayers.firstWhere((p) => p.playerId == _userId);
                  myTeamId = me.teamId;
                } catch (_) {}
              }
            }
            
            if (myTeamId == -1 && allPlayers.isNotEmpty) {
               myTeamId = allPlayers.first.teamId;
            }

            List<PlayerStats> allies = [];
            List<PlayerStats> enemies = [];

            for (var p in allPlayers) {
              bool isMe = (p.playerId == _userId);
              bool isAlly = (p.teamId == myTeamId);
              final updated = p.copyWith(isEnemy: !isAlly, isUser: isMe);
              if (isAlly) allies.add(updated); else enemies.add(updated);
            }

            while (allies.length < 5) allies.add(PlayerStats(nickname: 'Player', heroId: 0, kda: '0/0/0', gold: '0', itemIds: [], score: 0, isEnemy: false, isUser: false));
            while (enemies.length < 5) enemies.add(PlayerStats(nickname: 'Enemy', heroId: 0, kda: '0/0/0', gold: '0', itemIds: [], score: 0, isEnemy: true, isUser: false));

            myTeam = allies;
            enemyTeam = enemies;
          });
        }
        if (mounted) Navigator.pop(context);
      } catch (e) { if (mounted) { Navigator.pop(context); _showErrorDialog("$e"); } }
    }
  }

  void _editPlayerStats(int index, bool isEnemy) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manual edit temporarily disabled in V2")));
  }

  Future<void> _handleSaveGame() async {
    _performSave();
  }

  Future<void> _performSave() async {
    PlayerStats? userStats;
    try { userStats = [...myTeam, ...enemyTeam].firstWhere((p) => p.isUser); } catch (_) { userStats = null; }
    
    final game = GameStats(
      id: widget.initialGame?.id, 
      matchId: _matchId ?? '',
      result: gameResult, 
      heroId: userStats?.heroId ?? 0, 
      kda: userStats?.kda ?? '', 
      itemIds: userStats?.itemIds ?? [], 
      score: userStats?.score ?? 0, // Save user's score/medal
      players: '', 
      date: matchDate, 
      duration: duration, 
      role: userStats?.role ?? 'unknown', 
      spellId: userStats?.spellId ?? 0
    );
    
    int resultId;
    if (widget.initialGame != null) {
      await _dbHelper.updateGameWithPlayers(game, [...myTeam, ...enemyTeam]);
      resultId = game.id!;
    } else {
      resultId = await _dbHelper.insertGameWithPlayers(game, [...myTeam, ...enemyTeam]);
    }
    
    if (resultId == -1) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Игра уже существует!"), backgroundColor: Colors.red));
       return;
    }

    if (widget.onSaveSuccess != null) widget.onSaveSuccess!();
    if (mounted) { if (Navigator.canPop(context)) Navigator.pop(context); else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Match saved!"))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialGame != null ? "Edit Match" : "Add Match (File)")),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButton<String>(
            value: gameResult, 
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'VICTORY', child: Text("VICTORY", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))), 
              DropdownMenuItem(value: 'DEFEAT', child: Text("DEFEAT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
            ], 
            onChanged: (v) => setState(() => gameResult = v!)
          ),
        ),
        const Divider(),
        _buildTeamHeader("MY TEAM", Colors.blue), ...List.generate(5, (i) => _buildPlayerTile(i, false)),
        const Divider(),
        _buildTeamHeader("ENEMY TEAM", Colors.red), ...List.generate(5, (i) => _buildPlayerTile(i, true)),
        const SizedBox(height: 120),
      ]),
      floatingActionButton: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton.extended(heroTag: "scan", onPressed: _pickHistoryFile, label: const Text("OPEN FILE"), icon: const Icon(Icons.folder_open), backgroundColor: Colors.white10),
        const SizedBox(height: 10),
        FloatingActionButton.extended(heroTag: "save", onPressed: _handleSaveGame, label: const Text("SAVE MATCH"), icon: const Icon(Icons.save), backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
      ]),
    );
  }

  Widget _buildTeamHeader(String label, Color col) => Container(padding: const EdgeInsets.all(8), color: col.withOpacity(0.1), child: Text(label, style: TextStyle(color: col, fontWeight: FontWeight.bold)));

  Widget _buildPlayerTile(int i, bool isEnemy) {
    final p = isEnemy ? enemyTeam[i] : myTeam[i];
    return ListTile(
      leading: Stack(children: [
        DataUtils.getHeroIcon(p.heroId, radius: 25),
        Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(1), decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle), child: DataUtils.getRoleIcon(p.role, size: 14))),
      ]),
      title: Text(p.nickname, style: TextStyle(fontWeight: p.isUser ? FontWeight.bold : FontWeight.normal, color: p.isUser ? Colors.cyanAccent : Colors.white)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("KDA: ${p.kda} • ", style: const TextStyle(color: Colors.grey)),
            DataUtils.getMedalIcon(p.score, size: 14),
          ],
        ),
        Text("💰 ${p.gold}", style: const TextStyle(color: Colors.grey)),
        if (p.itemIds.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(spacing: 4, children: p.itemIds.map((item) => SizedBox(width: 24, height: 24, child: DataUtils.getItemIcon(item, size: 24))).toList())),
      ]),
      trailing: DataUtils.getSpellIcon(DataUtils.getDisplaySpellId(p.spellId, p.itemIds), size: 24),
      onTap: () => _editPlayerStats(i, isEnemy),
    );
  }
}
