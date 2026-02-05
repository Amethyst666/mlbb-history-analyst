import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../models/game_stats.dart';
import '../utils/database_helper.dart';
import '../utils/data_utils.dart';
import '../utils/app_strings.dart';
import 'game_details_screen.dart';
import 'player_settings_screen.dart';

class PlayerProfileScreen extends StatefulWidget {
  final PlayerProfile profile;
  const PlayerProfileScreen({super.key, required this.profile});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> _heroStats = [];
  List<Map<String, dynamic>> _playerGames = [];
  bool _isLoading = true;

  int _totalAllyGames = 0;
  int _totalEnemyGames = 0;
  int _totalStandaloneGames = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final stats = await _dbHelper.getHeroStatsForProfile(widget.profile.id!);
    final games = await _dbHelper.getGamesForProfile(widget.profile.id!);

    final profiles = await _dbHelper.getAllProfiles();
    final updatedProfile = profiles.firstWhere(
      (p) => p.id == widget.profile.id,
      orElse: () => widget.profile,
    );

    int ally = 0;
    int enemy = 0;
    int standalone = 0;
    for (var s in stats) {
      ally += (s['ally_games'] as num).toInt();
      enemy += (s['enemy_games'] as num).toInt();
      standalone += (s['standalone_games'] as num).toInt();
    }

    if (mounted) {
      setState(() {
        widget.profile.pinnedAlias = updatedProfile.pinnedAlias;
        widget.profile.mainNickname = updatedProfile.mainNickname;
        widget.profile.serverId = updatedProfile.serverId;
        _heroStats = stats;
        _playerGames = games;
        _totalAllyGames = ally;
        _totalEnemyGames = enemy;
        _totalStandaloneGames = standalone;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName =
        widget.profile.pinnedAlias ?? widget.profile.mainNickname;
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => PlayerSettingsScreen(profile: widget.profile),
                ),
              );
              _loadStats();
            },
          ),
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
                  Text(
                    AppStrings.get(context, 'history'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._playerGames.map((g) => _buildGameTile(g)).toList(),
                ],
                const SizedBox(height: 50),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    String displayName =
        widget.profile.pinnedAlias ?? widget.profile.mainNickname;
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: widget.profile.isUser
                ? Colors.cyanAccent
                : Colors.deepPurpleAccent,
            child: Icon(
              widget.profile.isUser ? Icons.person : Icons.people,
              size: 45,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (widget.profile.pinnedAlias != null)
            Text(
              "(${widget.profile.mainNickname})",
              style: const TextStyle(color: Colors.white24, fontSize: 14),
            ),
          const SizedBox(height: 4),
          Text(
            "ID: ${widget.profile.id} (${widget.profile.serverId})",
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.profile.isUser
                ? AppStrings.get(context, 'your_profile')
                : AppStrings.get(context, 'player_profile'),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (!widget.profile.isUser) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatBadge(
                  AppStrings.get(context, 'with_me'),
                  _totalAllyGames,
                  Colors.blueAccent,
                ),
                const SizedBox(width: 10),
                _buildStatBadge(
                  AppStrings.get(context, 'against_me'),
                  _totalEnemyGames,
                  Colors.redAccent,
                ),
                const SizedBox(width: 10),
                _buildStatBadge(
                  AppStrings.get(context, 'without_me'),
                  _totalStandaloneGames,
                  Colors.grey,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatsSection() {
    final top3 = _heroStats.take(3).toList();
    final others = _heroStats.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get(context, 'top_heroes'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(height: 15),
        ...top3.map((s) => _buildHeroStatRow(s, isTop: true)).toList(),
        if (others.isNotEmpty)
          ExpansionTile(
            title: Text(
              "${AppStrings.get(context, 'other_heroes')} (${others.length})",
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
            tilePadding: EdgeInsets.zero,
            children: others.map((s) => _buildHeroStatRow(s)).toList(),
          ),
      ],
    );
  }

  Widget _buildHeroStatRow(Map<String, dynamic> s, {bool isTop = false}) {
    final int heroId = int.tryParse(s['hero'].toString()) ?? 0;
    final int allyGames = (s['ally_games'] as num).toInt();
    final int allyWins = (s['ally_wins'] as num).toInt();
    final int enemyGames = (s['enemy_games'] as num).toInt();
    final int enemyWins = (s['enemy_wins'] as num).toInt();
    final int standaloneGames = (s['standalone_games'] as num).toInt();
    final int standaloneWins = (s['standalone_wins'] as num).toInt();
    final int totalGames = allyGames + enemyGames + standaloneGames;

    double allyWr = allyGames > 0 ? (allyWins / allyGames) * 100 : 0;
    double enemyWr = enemyGames > 0 ? (enemyWins / enemyGames) * 100 : 0;
    double standaloneWr = standaloneGames > 0
        ? (standaloneWins / standaloneGames) * 100
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: isTop
            ? Border.all(color: Colors.cyanAccent.withOpacity(0.1))
            : null,
      ),
      child: Row(
        children: [
          DataUtils.getHeroIcon(heroId, radius: 25),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DataUtils.getLocalizedHeroName(heroId, context),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${AppStrings.get(context, 'games_count')} $totalGames",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (allyGames > 0)
                      Expanded(
                        child: _buildSmallWrBar(
                          AppStrings.get(context, 'with_me'),
                          allyWr,
                          allyGames,
                          Colors.blueAccent,
                        ),
                      ),
                    if (allyGames > 0 &&
                        (enemyGames > 0 || standaloneGames > 0))
                      const SizedBox(width: 10),
                    if (enemyGames > 0)
                      Expanded(
                        child: _buildSmallWrBar(
                          AppStrings.get(context, 'against_me'),
                          enemyWr,
                          enemyGames,
                          Colors.redAccent,
                        ),
                      ),
                    if (enemyGames > 0 && standaloneGames > 0)
                      const SizedBox(width: 10),
                    if (standaloneGames > 0)
                      Expanded(
                        child: _buildSmallWrBar(
                          AppStrings.get(context, 'without_me'),
                          standaloneWr,
                          standaloneGames,
                          Colors.grey,
                        ),
                      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
            Text(
              "${wr.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    final int heroId = int.tryParse(g['player_hero'] ?? '0') ?? 0;
    final String role = g['player_role'] ?? 'unknown';
    final String kda = g['player_kda'] ?? '0/0/0';
    final int score = int.tryParse(g['player_score'].toString()) ?? 0;
    final bool isEnemy = g['player_is_enemy'] == 1;
    final bool isVictory = game.result == 'VICTORY';
    final bool userPresent =
        (int.tryParse(g['user_present'].toString()) ?? 0) != 0;

    final bool playerWon = (!isEnemy && isVictory) || (isEnemy && !isVictory);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white.withOpacity(0.02),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => GameDetailsScreen(game: game)),
          );
        },
        leading: Stack(
          children: [
            DataUtils.getHeroIcon(heroId, radius: 22),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: DataUtils.getRoleIcon(role, size: 12),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            if (userPresent) ...[
              Text(
                playerWon
                    ? AppStrings.get(context, 'victory')
                    : AppStrings.get(context, 'defeat'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: playerWon ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                DataUtils.getLocalizedHeroName(heroId, context),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              "${AppStrings.get(context, 'kda')}: $kda",
              style: const TextStyle(fontSize: 11),
            ),
            const Text(" • ", style: TextStyle(color: Colors.white24)),
            DataUtils.getMedalIcon(score, size: 14),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              userPresent
                  ? (isEnemy
                        ? AppStrings.get(context, 'enemy')
                        : AppStrings.get(context, 'ally'))
                  : AppStrings.get(context, 'standalone'),
              style: TextStyle(
                fontSize: 10,
                color: userPresent
                    ? (isEnemy
                          ? Colors.redAccent.withOpacity(0.7)
                          : Colors.blueAccent.withOpacity(0.7))
                    : Colors.grey,
              ),
            ),
            Text(
              game.date.toString().substring(5, 10),
              style: const TextStyle(fontSize: 10, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}
