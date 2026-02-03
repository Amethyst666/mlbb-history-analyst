import 'package:flutter/material.dart';
import '../models/game_stats.dart';
import '../utils/database_helper.dart';
import '../utils/app_strings.dart';
import '../utils/data_utils.dart'; // Added import
import 'game_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<GameStats> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'Player'; 

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    List<GameStats> results;
    if (_searchType == 'Player') {
      results = await _dbHelper.getGamesByPlayer(query);
    } else {
      // 1. Convert user query to ID
      final heroId = DataUtils.getHeroIdByName(query);
      
      // 2. Search by ID
      if (heroId != 0) {
        results = await _dbHelper.getGamesByHero(heroId);
      } else {
        results = [];
      }
    }

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text(AppStrings.get(context, 'nickname')),
                    selected: _searchType == 'Player',
                    onSelected: (selected) {
                      setState(() {
                        _searchType = 'Player';
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: Text(AppStrings.get(context, 'hero')),
                    selected: _searchType == 'Hero',
                    onSelected: (selected) {
                      setState(() {
                        _searchType = 'Hero';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: AppStrings.get(context, 'search_hint'),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _searchGames(_searchController.text),
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: _searchGames,
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(child: Text(AppStrings.get(context, 'search_hint')))
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final game = _searchResults[index];
                    final isVictory = game.result == 'VICTORY';
                    
                    final heroName = DataUtils.getLocalizedHeroName(game.heroId, context);

                    return ListTile(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (c) => GameDetailsScreen(game: game)));
                      },
                      leading: DataUtils.getHeroIcon(game.heroId, radius: 20),
                      title: Text('$heroName (${isVictory ? AppStrings.get(context, 'victory') : AppStrings.get(context, 'defeat')})'),
                      subtitle: Text(
                          '${AppStrings.get(context, 'kda')}: ${game.kda}'),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
      ],
    );
  }
}