import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';
import '../utils/database_helper.dart';
import 'game_details_screen.dart';
import 'add_game_screen.dart'; // Added missing import
import '../utils/app_strings.dart';
import '../utils/data_utils.dart'; // Added import

class RecentGamesScreen extends StatefulWidget {
  const RecentGamesScreen({super.key});

  @override
  State<RecentGamesScreen> createState() => _RecentGamesScreenState();
}

class _RecentGamesScreenState extends State<RecentGamesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<GameStats> _games = [];
  bool _isDeveloperMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData(); 
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final isDev = prefs.getBool('isDeveloperMode') ?? false;
    final games = await _dbHelper.getGames();
    
    if (mounted) {
      setState(() {
        _isDeveloperMode = isDev;
        _games = games;
      });
    }
  }

  Future<void> _deleteGame(int index) async {
    final game = _games[index];
    if (game.id != null) {
      await _dbHelper.deleteGame(game.id!);
      setState(() {
        _games.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get(context, 'delete_game'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_games.isEmpty) {
      return Center(child: Text(AppStrings.get(context, 'no_games')));
    }

    return ListView.builder(
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];
        final isVictory = game.result == 'VICTORY';
        final resultText = isVictory ? AppStrings.get(context, 'victory') : AppStrings.get(context, 'defeat');
        final bool noUser = game.hero == 'none';
        
        // Use DataUtils to translate ID
        final heroName = noUser ? "Матч без игрока" : DataUtils.getLocalizedHeroName(game.hero, context);

        final cardContent = Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameDetailsScreen(game: game),
                ),
              );
            },
            leading: noUser 
              ? const CircleAvatar(radius: 25, backgroundColor: Colors.white10, child: Icon(Icons.person_off, color: Colors.grey))
              : Stack(
                  children: [
                    DataUtils.getHeroIcon(game.hero, radius: 25),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: DataUtils.getRoleIcon(game.role, size: 14),
                      ),
                    ),
                  ],
                ),
            title: Text(heroName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: noUser ? Colors.grey : Colors.white,
                )),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!noUser) ...[
                  Text('${AppStrings.get(context, 'kda')}: ${game.kda}'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: game.items.split(',').where((i) => i.isNotEmpty).map((item) => 
                      SizedBox(width: 20, height: 20, child: DataUtils.getItemIcon(item, size: 20))
                    ).toList(),
                  ),
                ] else
                  Text(game.date.toString().substring(0, 10)), // Keep only date for games without me
              ],
            ),
            isThreeLine: !noUser,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(resultText,
                    style: TextStyle(
                        color: isVictory ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold)),
                if (_isDeveloperMode)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddGameScreen(
                            initialGame: game,
                            onSaveSuccess: () {
                              _loadData();
                            },
                          ),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                    ),
                  ),
              ],
            ),
          ),
        );

        if (_isDeveloperMode) {
          return Dismissible(
            key: Key(game.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              _deleteGame(index);
            },
            child: cardContent,
          );
        } else {
          return cardContent;
        }
      },
    );
  }
}
