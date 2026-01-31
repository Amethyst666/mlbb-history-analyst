import 'package:flutter/material.dart';
import '../models/game_stats.dart';
import '../utils/database_helper.dart';
import '../utils/data_utils.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
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
      appBar: AppBar(
        title: const Text('Game Statistics'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Player Name',
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
                ? const Center(child: Text('No games found.'))
                : ListView.builder(
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      return ListTile(
                        leading: DataUtils.getHeroIcon(game.hero, radius: 20),
                        title: Text('${game.hero} - ${game.kda}'),
                        subtitle: Text('Players: ${game.players}\nDate: ${game.date.toString().substring(0, 16)}'),
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
