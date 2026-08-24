import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../utils/database_helper.dart';
import '../utils/game_data.dart';

class AssetErrorsScreen extends StatefulWidget {
  const AssetErrorsScreen({super.key});

  @override
  State<AssetErrorsScreen> createState() => _AssetErrorsScreenState();
}

class _AssetErrorsScreenState extends State<AssetErrorsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _missingHeroes = [];
  List<Map<String, dynamic>> _missingItems = [];

  @override
  void initState() {
    super.initState();
    _checkAssets();
  }

  Future<void> _checkAssets() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final Set<String> assetPaths = manifestMap.keys.toSet();

      final heroRows = await _dbHelper.getDistinctHeroesWithGames();
      final itemRows = await _dbHelper.getDistinctItemsWithGames();

      List<Map<String, dynamic>> missingH = [];
      List<Map<String, dynamic>> missingI = [];

      for (var row in heroRows) {
        final heroIdStr = row['hero'] as String;
        final heroId = int.tryParse(heroIdStr) ?? 0;
        if (heroId == 0) continue;

        final gameIdsStr = row['games'] as String;
        final gameIds = gameIdsStr.split(',').toSet().toList();

        final entity = GameData.getHero(heroId);
        if (entity == null) {
          missingH.add({'id': heroId, 'name': 'Неизвестный Герой $heroId', 'games': gameIds, 'reason': 'Отсутствует в GameData'});
          continue;
        }
        
        final assetPath = 'assets/heroes/${entity.assetName}.png';
        if (!assetPaths.contains(assetPath)) {
          missingH.add({'id': heroId, 'name': entity.ru, 'games': gameIds, 'reason': 'Нет файла: $assetPath'});
        }
      }

      Map<int, Set<String>> itemGamesMap = {};
      for (var row in itemRows) {
        final itemsStr = row['items'] as String;
        final gameIdsStr = row['games'] as String;
        final gameIds = gameIdsStr.split(',');

        final items = itemsStr.split(',').where((i) => i != '0' && i.isNotEmpty);
        for (var itemIdStr in items) {
          final itemId = int.tryParse(itemIdStr) ?? 0;
          if (itemId == 0) continue;
          
          itemGamesMap.putIfAbsent(itemId, () => <String>{});
          itemGamesMap[itemId]!.addAll(gameIds);
        }
      }

      for (var entry in itemGamesMap.entries) {
        final itemId = entry.key;
        final gameIds = entry.value.toList();

        final entity = GameData.getItem(itemId);
        if (entity == null) {
          missingI.add({'id': itemId, 'name': 'Неизвестный Предмет $itemId', 'games': gameIds, 'reason': 'Отсутствует в GameData'});
          continue;
        }
        
        final assetPath = 'assets/items/${entity.assetName}.png';
        if (!assetPaths.contains(assetPath)) {
          missingI.add({'id': itemId, 'name': entity.ru, 'games': gameIds, 'reason': 'Нет файла: $assetPath'});
        }
      }

      if (mounted) {
        setState(() {
          _missingHeroes = missingH;
          _missingItems = missingI;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ошибки в ассетах'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Герои'),
              Tab(text: 'Предметы'),
            ],
          ),
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(_missingHeroes),
                  _buildList(_missingItems),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Ошибок нет! Все ассеты найдены.'));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final games = item['games'] as List<String>;
        return ExpansionTile(
          title: Text('${item['name']} (ID: ${item['id']})'),
          subtitle: Text('${item['reason']}\nВстречается в ${games.length} матчах', style: const TextStyle(color: Colors.redAccent)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Game IDs: ${games.join(', ')}'),
              ),
            ),
          ],
        );
      },
    );
  }
}
