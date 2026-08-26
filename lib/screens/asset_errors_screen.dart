import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
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

  Future<bool> _assetFileExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkAssets() async {
    try {
      final playerRows = await _dbHelper.getAllPlayerHeroesAndItems();

      Map<int, List<Map<String, String>>> heroOccurrences = {};
      Map<int, List<Map<String, String>>> itemOccurrences = {};

      for (var row in playerRows) {
        final matchId = (row['match_id'] ?? '').toString();
        final nickname = (row['nickname'] ?? 'Неизвестный').toString();
        final heroStr = (row['hero'] ?? '0').toString();
        final itemsStr = (row['items'] ?? '').toString();

        final heroId = int.tryParse(heroStr) ?? 0;
        if (heroId > 0) {
          heroOccurrences.putIfAbsent(heroId, () => []);
          heroOccurrences[heroId]!.add({
            'match_id': matchId,
            'nickname': nickname,
            'hero_str': heroStr,
          });
        }

        final items = itemsStr.split(',').where((i) => i.trim() != '0' && i.trim().isNotEmpty);
        for (var itemIdStr in items) {
          final itemId = int.tryParse(itemIdStr.trim()) ?? 0;
          if (itemId > 0) {
            itemOccurrences.putIfAbsent(itemId, () => []);
            itemOccurrences[itemId]!.add({
              'match_id': matchId,
              'nickname': nickname,
              'hero_str': heroStr,
            });
          }
        }
      }

      List<Map<String, dynamic>> missingH = [];
      List<Map<String, dynamic>> missingI = [];

      for (var entry in heroOccurrences.entries) {
        final heroId = entry.key;
        final occurrences = entry.value;
        final entity = GameData.getHero(heroId);

        if (entity == null) {
          missingH.add({
            'id': heroId,
            'name': 'Неизвестный Герой $heroId',
            'reason': 'Отсутствует в GameData',
            'occurrences': occurrences,
          });
        } else {
          final assetPath = 'assets/heroes/${entity.assetName}.png';
          final exists = await _assetFileExists(assetPath);
          if (!exists) {
            missingH.add({
              'id': heroId,
              'name': entity.ru,
              'reason': 'Отсутствует файл ассета: $assetPath',
              'occurrences': occurrences,
            });
          }
        }
      }

      for (var entry in itemOccurrences.entries) {
        final itemId = entry.key;
        final occurrences = entry.value;
        final entity = GameData.getItem(itemId);

        if (entity == null) {
          missingI.add({
            'id': itemId,
            'name': 'Неизвестный Предмет $itemId',
            'reason': 'Отсутствует в GameData',
            'occurrences': occurrences,
          });
        } else {
          final assetPath = 'assets/items/${entity.assetName}.png';
          final exists = await _assetFileExists(assetPath);
          if (!exists) {
            missingI.add({
              'id': itemId,
              'name': entity.ru,
              'reason': 'Отсутствует файл ассета: $assetPath',
              'occurrences': occurrences,
            });
          }
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _isLoading = true);
                _checkAssets();
              },
            ),
          ],
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.greenAccent),
            SizedBox(height: 12),
            Text(
              'Ошибок нет! Все ассеты найдены.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final item = items[index];
        final occurrences = item['occurrences'] as List<Map<String, String>>;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ExpansionTile(
            leading: const Icon(Icons.error_outline, color: Colors.redAccent),
            title: Text(
              '${item['name']} (ID: ${item['id']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item['reason']}\nВстречается в ${occurrences.length} матчах',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            children: occurrences.map((occ) {
              final matchId = occ['match_id'] ?? '';
              final nickname = occ['nickname'] ?? '';
              final heroId = int.tryParse(occ['hero_str'] ?? '0') ?? 0;
              final heroEntity = GameData.getHero(heroId);
              final heroName = heroEntity?.ru ?? 'Герой #$heroId';

              return ListTile(
                dense: true,
                title: Text('Матч: $matchId'),
                subtitle: Text('Игрок: $nickname ($heroName)'),
                trailing: const Icon(Icons.copy, size: 16),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: matchId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Match ID скопирован: $matchId')),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
