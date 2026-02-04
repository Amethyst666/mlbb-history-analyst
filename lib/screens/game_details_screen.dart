import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';
import '../models/player_stats.dart';
import '../utils/database_helper.dart';
import '../utils/app_strings.dart';
import '../utils/data_utils.dart'; 
import '../widgets/player_match_stats_dialog.dart';

class GameDetailsScreen extends StatefulWidget {
  final GameStats game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<PlayerStats> _players = [];
  bool _isLoading = true;
  bool _isDeveloperMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final isDev = prefs.getBool('isDeveloperMode') ?? false;

    if (widget.game.id == null) return;
    final players = await _dbHelper.getPlayersForGame(widget.game.id!);
    
    if (players.isEmpty) {
      final userPlayer = PlayerStats(
        nickname: 'You',
        heroId: widget.game.heroId,
        kda: widget.game.kda,
        gold: '0',
        itemIds: widget.game.itemIds,
        score: widget.game.score,
        isEnemy: false,
        isUser: true,
      );
      players.add(userPlayer);
    }

    if (mounted) {
      setState(() {
        _players = players;
        _isDeveloperMode = isDev;
        _isLoading = false;
      });
    }
  }

  Map<String, int> _getTeamTotals(bool isEnemy) {
    final team = _players.where((p) => p.isEnemy == isEnemy).toList();
    int totalKills = 0;
    for (var p in team) {
      final parts = p.kda.split('/');
      if (parts.isNotEmpty) totalKills += int.tryParse(parts[0]) ?? 0;
    }

    return {
      'damageHero': team.fold(0, (sum, p) => sum + p.damageHero),
      'damageTower': team.fold(0, (sum, p) => sum + p.damageTower),
      'damageTaken': team.fold(0, (sum, p) => sum + p.damageTaken),
      'heal': team.fold(0, (sum, p) => sum + p.heal),
      'gold': team.fold(0, (sum, p) => sum + (int.tryParse(p.gold) ?? 0)),
      'kills': totalKills,
      'goldLane': team.fold(0, (sum, p) => sum + p.goldLane),
      'goldKill': team.fold(0, (sum, p) => sum + p.goldKill),
      'goldJungle': team.fold(0, (sum, p) => sum + p.goldJungle),
    };
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isVictory = game.result == 'VICTORY';
    final resultColor = isVictory ? const Color(0xFFEBC348) : const Color(0xFFC73636);
    final backgroundColor = const Color(0xFF1E1E2C);
    
    final myTeam = _players.where((p) => !p.isEnemy).toList();
    final enemyTeam = _players.where((p) => p.isEnemy).toList();

    final myTeamTotals = _getTeamTotals(false);
    final enemyTeamTotals = _getTeamTotals(true);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppStrings.get(context, 'match_details'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [resultColor.withOpacity(0.3), backgroundColor],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          isVictory ? AppStrings.get(context, 'victory') : AppStrings.get(context, 'defeat'),
                          style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.w900, color: resultColor, letterSpacing: 2.0,
                            shadows: [Shadow(blurRadius: 10.0, color: resultColor.withOpacity(0.5))],
                          ),
                        ),
                        if (game.matchId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text("#${game.matchId}", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace')),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          "${game.date.toString().substring(0, 10)} (${game.date.toString().substring(11, 16)} - ${game.endDate?.toString().substring(11, 16) ?? '??:??'})  •  ${game.duration}",
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTeamHeader(AppStrings.get(context, 'my_team'), Colors.blueAccent),
                      ...myTeam.map((p) => _buildPlayerRow(p, myTeamTotals)).toList(),

                      const SizedBox(height: 25),

                      if (enemyTeam.isNotEmpty) ...[
                        _buildTeamHeader(AppStrings.get(context, 'enemy_team'), Colors.redAccent),
                        ...enemyTeam.map((p) => _buildPlayerRow(p, enemyTeamTotals)).toList(),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTeamHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
    );
  }

  Color _getPartyColor(int partyId) {
    if (partyId == 0) return Colors.transparent;
    final colors = [Colors.deepOrange, Colors.green, Colors.indigo, Colors.pink, Colors.cyan, Colors.amber, Colors.purple, Colors.teal, Colors.lime, Colors.lightBlue];
    return colors[partyId % colors.length];
  }

  Widget _buildPlayerRow(PlayerStats player, Map<String, int> teamTotals) {
    final heroName = DataUtils.getLocalizedHeroName(player.heroId, context);
    final partyColor = _getPartyColor(player.partyId);
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => PlayerMatchStatsDialog(
            player: player,
            teamTotals: teamTotals,
            isDeveloperMode: _isDeveloperMode,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: player.isUser ? const Color(0xFF3D3D5C) : const Color(0xFF2B2B3D),
          borderRadius: BorderRadius.circular(6),
          border: player.isUser ? Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5), width: 1) : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (player.partyId != 0)
                Container(width: 4, decoration: BoxDecoration(color: partyColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    DataUtils.getHeroIcon(player.heroId, radius: 18),
                                    Positioned(
                                      bottom: -2, right: -2,
                                      child: Container(padding: const EdgeInsets.all(1), decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle), child: DataUtils.getRoleIcon(player.role, size: 10)),
                                    ),
                                    if (player.level > 0)
                                      Positioned(
                                        top: -2, left: -2,
                                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white30, width: 0.5)),
                                          child: Text("${player.level}", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_isDeveloperMode ? "$heroName (${player.heroId})" : heroName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                      Text(player.nickname, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
                                      if (player.clan.isNotEmpty)
                                        Text(_isDeveloperMode ? player.clan : player.clan.split(' [').first, style: const TextStyle(color: Colors.white54, fontSize: 9)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Center(child: Text(player.kda, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                 DataUtils.getMedalIcon(player.score, size: 18),
                                 Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Text(player.gold, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                                     const SizedBox(width: 2),
                                     const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 10),
                                   ],
                                 ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (player.itemIds.isNotEmpty || player.spellId != 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const SizedBox(width: 38), 
                            if (player.spellId != 0) ...[
                              Column(children: [DataUtils.getSpellIcon(DataUtils.getDisplaySpellId(player.spellId, player.itemIds), size: 20), if (_isDeveloperMode) Text("${player.spellId}", style: const TextStyle(fontSize: 6, color: Colors.white30))]),
                              const SizedBox(width: 8),
                              Container(width: 1, height: 15, color: Colors.white24),
                              const SizedBox(width: 8),
                            ],
                            ...player.itemIds.map((itemId) => Padding(padding: const EdgeInsets.only(right: 4.0),
                              child: Column(children: [DataUtils.getItemIcon(itemId, size: 20), if (_isDeveloperMode) Text("$itemId", style: const TextStyle(fontSize: 6, color: Colors.white30))]),
                            )),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}