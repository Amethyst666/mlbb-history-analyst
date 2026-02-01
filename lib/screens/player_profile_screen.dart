import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../models/game_stats.dart';
import '../utils/database_helper.dart';
import '../utils/data_utils.dart';
import '../utils/app_strings.dart';
import 'game_details_screen.dart';

class PlayerProfileScreen extends StatefulWidget {
  final PlayerProfile profile;
  const PlayerProfileScreen({super.key, required this.profile});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _dbHelper = DatabaseHelper();
  late bool _isVerified;
  
  List<Map<String, dynamic>> _heroStats = [];
  List<Map<String, dynamic>> _playerGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isVerified = widget.profile.isVerified;
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _dbHelper.getHeroStatsForProfile(widget.profile.id!);
    final games = await _dbHelper.getGamesForProfile(widget.profile.id!);
    if (mounted) {
      setState(() {
        _heroStats = stats;
        _playerGames = games;
        _isLoading = false;
      });
    }
  }

  void _toggleVerify() async {
    setState(() => _isVerified = !_isVerified);
    await _dbHelper.toggleVerification(widget.profile.id!, _isVerified);
    widget.profile.isVerified = _isVerified;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.mainNickname),
        actions: [
          IconButton(
            icon: Icon(_isVerified ? Icons.verified : Icons.verified_outlined, 
              color: _isVerified ? Colors.cyanAccent : Colors.white54),
            onPressed: _toggleVerify,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              if (_heroStats.isNotEmpty) ...[
                _buildHeroStatsSection(),
                const SizedBox(height: 30),
              ],
              if (_playerGames.isNotEmpty) ...[
                const Text("ИСТОРИЯ ИГР", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                const SizedBox(height: 10),
                ..._playerGames.map((g) => _buildGameTile(g)).toList(),
              ],
              const SizedBox(height: 50),
            ],
          ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: widget.profile.isUser ? Colors.cyanAccent : Colors.deepPurpleAccent,
                child: Icon(widget.profile.isUser ? Icons.person : Icons.people, size: 45, color: Colors.black),
              ),
              if (_isVerified)
                const Positioned(
                  bottom: 0, right: 0,
                  child: CircleAvatar(
                    radius: 14, backgroundColor: Color(0xFF1A1C2C),
                    child: Icon(Icons.verified, color: Colors.cyanAccent, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.profile.mainNickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (_isVerified) const SizedBox(width: 8),
              if (_isVerified) const Icon(Icons.verified, color: Colors.cyanAccent, size: 18),
            ],
          ),
          Text(widget.profile.isUser ? "Ваш профиль" : "Профиль игрока", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHeroStatsSection() {
    final top3 = _heroStats.take(3).toList();
    final others = _heroStats.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ТОП ГЕРОЕВ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
        const SizedBox(height: 15),
        ...top3.map((s) => _buildHeroStatRow(s, isTop: true)).toList(),
        if (others.isNotEmpty)
          ExpansionTile(
            title: Text("ОСТАЛЬНЫЕ ГЕРОИ (${others.length})", style: const TextStyle(fontSize: 13, color: Colors.white54)),
            tilePadding: EdgeInsets.zero,
            children: others.map((s) => _buildHeroStatRow(s)).toList(),
          ),
      ],
    );
  }

  Widget _buildHeroStatRow(Map<String, dynamic> s, {bool isTop = false}) {
    final String hero = s['hero'];
    final int allyGames = s['ally_games'] ?? 0;
    final int allyWins = s['ally_wins'] ?? 0;
    final int enemyGames = s['enemy_games'] ?? 0;
    final int enemyWins = s['enemy_wins'] ?? 0;
    final int totalGames = allyGames + enemyGames;

    double allyWr = allyGames > 0 ? (allyWins / allyGames) * 100 : 0;
    double enemyWr = enemyGames > 0 ? (enemyWins / enemyGames) * 100 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: isTop ? Border.all(color: Colors.cyanAccent.withOpacity(0.1)) : null,
      ),
      child: Row(
        children: [
          DataUtils.getHeroIcon(hero, radius: 25),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DataUtils.getLocalizedHeroName(hero, context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Игр: $totalGames", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildSmallWrBar("За меня", allyWr, allyGames, Colors.blueAccent)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSmallWrBar("Против", enemyWr, enemyGames, Colors.redAccent)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallWrBar(String label, double wr, int games, Color color) {
    if (games == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            Text("${wr.toStringAsFixed(1)}%", style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: wr / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildGameTile(Map<String, dynamic> g) {
    final game = GameStats.fromMap(g);
    final String hero = g['player_hero'];
    final String kda = g['player_kda'];
    final double score = double.tryParse(g['player_score'].toString()) ?? 0.0;
    final bool isEnemy = g['player_is_enemy'] == 1;
    final bool isVictory = game.result == 'VICTORY';
    
    // Результат для КОНКРЕТНОГО игрока
    // Если он союзник и Victory -> он выиграл.
    // Если он враг и Defeat -> он выиграл.
    final bool playerWon = (!isEnemy && isVictory) || (isEnemy && !isVictory);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white.withOpacity(0.02),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => GameDetailsScreen(game: game)));
        },
        leading: Stack(
          children: [
            DataUtils.getHeroIcon(hero, radius: 22),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                child: DataUtils.getRoleIcon(g['player_role'], size: 12),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(playerWon ? "ПОБЕДА" : "ПОРАЖЕНИЕ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: playerWon ? Colors.green : Colors.red)),
            const SizedBox(width: 8),
            Text(isEnemy ? "(Враг)" : "(Союзник)", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        subtitle: Text("KDA: $kda  •  ⭐ $score", style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(game.duration, style: const TextStyle(fontSize: 11, color: Colors.white54)),
            Text(game.date.toString().substring(5, 10), style: const TextStyle(fontSize: 10, color: Colors.white24)),
          ],
        ),
      ),
    );
  }
}
