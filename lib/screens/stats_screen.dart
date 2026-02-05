import 'package:flutter/material.dart';
import '../models/game_stats.dart';
import '../utils/database_helper.dart';
import '../utils/data_utils.dart';
import '../utils/app_strings.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _SearchStatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<GameStats> _games = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final games = await _dbHelper.getGames();
    setState(() {
      _games = games;
    });
  }

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) {
      _loadGames();
      return;
    }
    final games = await _dbHelper.getGamesByPlayer(query);
    setState(() {
      _games = games;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get(context, 'game_stats_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: AppStrings.get(context, 'search_player_label'),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchGames(_searchController.text),
                ),
              ),
              onSubmitted: _searchGames,
            ),
          ),
          Expanded(
            child: _games.isEmpty
                ? Center(child: Text(AppStrings.get(context, 'no_games_found')))
                : ListView.builder(
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      return ListTile(
                        leading: DataUtils.getHeroIcon(game.heroId, radius: 20),
                        title: Row(
                          children: [
                            Text(
                              '${DataUtils.getLocalizedHeroName(game.heroId, context)} - ${game.kda} • ',
                            ),
                            DataUtils.getMedalIcon(game.score, size: 14),
                          ],
                        ),
                        subtitle: Text(
                          '${AppStrings.get(context, 'players_label')} ${game.players}\n${AppStrings.get(context, 'date_label')} ${game.date.toString().substring(0, 10)}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
