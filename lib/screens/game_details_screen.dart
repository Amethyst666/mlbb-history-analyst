import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    if (widget.game.id == null) return;
    
    final players = await _dbHelper.getPlayersForGame(widget.game.id!);
    
    if (players.isEmpty) {
      final userPlayer = PlayerStats(
        nickname: 'You',
        hero: widget.game.hero,
        kda: widget.game.kda,
        gold: widget.game.items.replaceAll('Gold:', '').trim(),
        items: '',
        score: '',
        isEnemy: false,
        isUser: true,
      );
      players.add(userPlayer);
    }

    if (mounted) {
      setState(() {
        _players = players;
        _isLoading = false;
      });
    }
  }

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
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              game.date.toString().substring(0, 16),
                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                            ),
                            const SizedBox(width: 15),
                            const Icon(Icons.timer, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              game.duration,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
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
            Expanded(flex: 2, child: Center(child: Text(AppStrings.get(context, 'kda'), style: const TextStyle(color: Colors.grey, fontSize: 10)))),
            Expanded(flex: 2, child: Center(child: Text("${AppStrings.get(context, 'gold')}/${AppStrings.get(context, 'score')}", style: const TextStyle(color: Colors.grey, fontSize: 10)))),
          ],
        ),
        const Divider(color: Colors.white24),
      ],
    );
  }

  Widget _buildPlayerRow(PlayerStats player) {
    final heroName = DataUtils.getLocalizedHeroName(player.hero, context);
    final items = player.items.split(',').where((e) => e.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: player.isUser ? const Color(0xFF3D3D5C) : const Color(0xFF2B2B3D),
        borderRadius: BorderRadius.circular(6),
        border: player.isUser ? Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5), width: 1) : null,
      ),
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
                        DataUtils.getHeroIcon(player.hero, radius: 15),
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
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(heroName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                          Text(player.nickname, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(player.kda, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(player.score, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                     Text("${player.gold}g", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          // Items Row
          if (items.isNotEmpty || player.spell != 'none') ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 38), // Indent to align with text
                if (player.spell != 'none') ...[
                  DataUtils.getSpellIcon(player.spell, size: 20),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 15, color: Colors.white24),
                  const SizedBox(width: 8),
                ],
                ...items.map((itemId) => Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: DataUtils.getItemIcon(itemId, size: 20), // Smaller icon for list
                )),
              ],
            )
          ]
        ],
      ),
    );
  }
}