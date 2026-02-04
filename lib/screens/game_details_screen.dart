import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';
import '../models/player_stats.dart';
import '../utils/database_helper.dart';
import '../utils/app_strings.dart';
import '../utils/data_utils.dart'; 

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
    final prefs = await SharedPreferences.getInstance(); // Import shared_preferences if needed, wait, it is imported in RecentGames but not here?
    // Check imports. Ah, I need to add shared_preferences import.
    // Assuming SharedPreferences is available or I can import it.
    // The previous read_file showed imports, shared_preferences was NOT imported.
    // I will add the import in a separate block or assume it works if I add it to the top.
    // Wait, replace doesn't allow adding imports easily unless I replace the whole file or top block.
    // I will use a separate replace for imports if needed, but for now I'll stick to the logic.
    // Actually, I can just replace the whole file content if I want to be safe, but let's try to fit in.
    // I'll assume I can add the import.
    
    // START LOGIC
    final isDev = prefs.getBool('isDeveloperMode') ?? false;

    if (widget.game.id == null) return;
    final players = await _dbHelper.getPlayersForGame(widget.game.id!);
    
    if (players.isEmpty) {
       // ... (existing fallback logic) ...
      final userPlayer = PlayerStats(
        nickname: 'You',
        heroId: widget.game.heroId,
        kda: widget.game.kda,
        gold: '0',
        itemIds: widget.game.itemIds,
        score: 0,
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
// ... (rest of the file)


  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isVictory = game.result == 'VICTORY';
    final resultColor = isVictory ? const Color(0xFFEBC348) : const Color(0xFFC73636);
    final backgroundColor = const Color(0xFF1E1E2C);
    
    final myTeam = _players.where((p) => !p.isEnemy).toList();
    final enemyTeam = _players.where((p) => p.isEnemy).toList();

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
                      colors: [
                        resultColor.withOpacity(0.3),
                        backgroundColor,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          isVictory ? AppStrings.get(context, 'victory') : AppStrings.get(context, 'defeat'),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: resultColor,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: resultColor.withOpacity(0.5),
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        if (game.matchId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "#${game.matchId}",
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'),
                          ),
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
                      _buildTableHeader(),
                      ...myTeam.map((p) => _buildPlayerRow(p)).toList(),

                      const SizedBox(height: 25),

                      if (enemyTeam.isNotEmpty) ...[
                        _buildTeamHeader(AppStrings.get(context, 'enemy_team'), Colors.redAccent),
                        _buildTableHeader(),
                        ...enemyTeam.map((p) => _buildPlayerRow(p)).toList(),
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
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: Text(AppStrings.get(context, 'hero'), style: const TextStyle(color: Colors.grey, fontSize: 10))),
            Expanded(flex: 3, child: Center(child: Text("${AppStrings.get(context, 'kda')} / Stats", style: const TextStyle(color: Colors.grey, fontSize: 10)))),
            Expanded(flex: 2, child: Center(child: Text("${AppStrings.get(context, 'gold')}/${AppStrings.get(context, 'score')}", style: const TextStyle(color: Colors.grey, fontSize: 10)))),
          ],
        ),
        const Divider(color: Colors.white24),
      ],
    );
  }

  Color _getPartyColor(int partyId) {
    if (partyId == 0) return Colors.transparent;
    // Hardcoded 10 high-contrast colors
    final colors = [
      Colors.deepOrange, // 0
      Colors.green,      // 1
      Colors.indigo,     // 2
      Colors.pink,       // 3
      Colors.cyan,       // 4
      Colors.amber,      // 5
      Colors.purple,     // 6
      Colors.teal,       // 7
      Colors.lime,       // 8
      Colors.lightBlue,  // 9
    ];
    // Use modulo to cycle through 10 colors if partyId > 9
    return colors[partyId % colors.length];
  }

  String _formatNumber(int num) {
    if (num >= 1000) {
      return "${(num / 1000).toStringAsFixed(1)}k";
    }
    return "$num";
  }

  Widget _buildPlayerRow(PlayerStats player) {
    final heroName = DataUtils.getLocalizedHeroName(player.heroId, context);
    final partyColor = _getPartyColor(player.partyId);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: player.isUser ? const Color(0xFF3D3D5C) : const Color(0xFF2B2B3D),
        borderRadius: BorderRadius.circular(6),
        border: player.isUser ? Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5), width: 1) : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Party Indicator
            if (player.partyId != 0)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: partyColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                ),
              ),
            
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
                                  // Role Icon
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: DataUtils.getRoleIcon(player.role, size: 10),
                                    ),
                                  ),
                                  // Level Badge
                                  if (player.level > 0)
                                    Positioned(
                                      top: -2,
                                      left: -2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.white30, width: 0.5),
                                        ),
                                        child: Text(
                                          "${player.level}",
                                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      heroName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    Text(player.nickname, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
                                    Wrap(
                                      spacing: 4,
                                      children: [
                                        if (player.clan.isNotEmpty)
                                          Text("[${player.clan}]", style: const TextStyle(color: Colors.white54, fontSize: 9)),
                                        if (player.playerId != null && player.playerId!.isNotEmpty)
                                          Text("#${player.playerId}", style: const TextStyle(color: Colors.white30, fontSize: 9)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(player.kda, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                              const SizedBox(height: 2),
                              // Damage Stats
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 4,
                                children: [
                                  if (player.damageHero > 0) 
                                    Text("⚔️${_formatNumber(player.damageHero)}", style: const TextStyle(color: Colors.redAccent, fontSize: 9)),
                                  if (player.damageTower > 0) 
                                    Text("🏰${_formatNumber(player.damageTower)}", style: const TextStyle(color: Colors.orangeAccent, fontSize: 9)),
                                  if (player.damageTaken > 0) 
                                    Text("🛡️${_formatNumber(player.damageTaken)}", style: const TextStyle(color: Colors.grey, fontSize: 9)),
                                  if (player.heal > 0) 
                                    Text("➕${_formatNumber(player.heal)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 9)),
                                ],
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               DataUtils.getMedalIcon(player.score, size: 16),
                               Text("${player.gold}g", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10)),
                               // Gold Breakdown
                               if (player.goldLane > 0 || player.goldKill > 0 || player.goldJungle > 0)
                                 Text(
                                   "L:${_formatNumber(player.goldLane)} J:${_formatNumber(player.goldJungle)} K:${_formatNumber(player.goldKill)}",
                                   style: const TextStyle(color: Colors.grey, fontSize: 8),
                                 ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Items Row
                    if (player.itemIds.isNotEmpty || player.spellId != 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const SizedBox(width: 38), 
                                          if (player.spellId != 0) ...[
                                            Column(
                                              children: [
                                                DataUtils.getSpellIcon(DataUtils.getDisplaySpellId(player.spellId, player.itemIds), size: 20),
                                                if (_isDeveloperMode)
                                                  Text("${player.spellId}", style: const TextStyle(fontSize: 6, color: Colors.white30)),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            Container(width: 1, height: 15, color: Colors.white24),
                                            const SizedBox(width: 8),
                                          ],                          ...player.itemIds.map((itemId) => Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Column(
                              children: [
                                DataUtils.getItemIcon(itemId, size: 20),
                                if (_isDeveloperMode)
                                  Text("$itemId", style: const TextStyle(fontSize: 6, color: Colors.white30)),
                              ],
                            ), 
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
    );
  }
}
