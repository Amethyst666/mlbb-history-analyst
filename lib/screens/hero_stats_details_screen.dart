import 'package:flutter/material.dart';
import '../models/game_stats.dart';
import '../utils/database_helper.dart';
import '../utils/data_utils.dart';
import '../models/player_stats.dart';
import '../utils/game_data.dart';
import 'game_details_screen.dart';

class HeroStatsDetailsScreen extends StatefulWidget {
  final int heroId;
  final String heroName;

  const HeroStatsDetailsScreen({super.key, required this.heroId, required this.heroName});

  @override
  State<HeroStatsDetailsScreen> createState() => _HeroStatsDetailsScreenState();
}

class _HeroStatsDetailsScreenState extends State<HeroStatsDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.heroName),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Мои игры за этого героя'),
              Tab(text: 'В моей команде (включая меня)'),
              Tab(text: 'В моей команде (без меня)'),
              Tab(text: 'Во вражеской команде'),
              Tab(text: 'Любые'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HeroCategoryTab(heroId: widget.heroId, categoryIndex: 0),
            HeroCategoryTab(heroId: widget.heroId, categoryIndex: 1),
            HeroCategoryTab(heroId: widget.heroId, categoryIndex: 2),
            HeroCategoryTab(heroId: widget.heroId, categoryIndex: 3),
            HeroCategoryTab(heroId: widget.heroId, categoryIndex: 4),
          ],
        ),
      ),
    );
  }
}

class HeroCategoryTab extends StatefulWidget {
  final int heroId;
  final int categoryIndex;

  const HeroCategoryTab({super.key, required this.heroId, required this.categoryIndex});

  @override
  State<HeroCategoryTab> createState() => _HeroCategoryTabState();
}

class _HeroCategoryTabState extends State<HeroCategoryTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _dbHelper.getGamesAndStatsForHeroCategory(widget.heroId, widget.categoryIndex);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Нет игр в этой категории'));

    int gamesCount = _data.length;
    int wins = 0;
    
    int totalKills = 0, totalDeaths = 0, totalAssists = 0;
    int totalGold = 0, totalDamageHero = 0, totalDamageTower = 0, totalDamageTaken = 0;
    int totalHeal = 0;
    double totalMinutes = 0;
    
    Map<String, int> roleCounts = {};
    Map<String, int> spellCounts = {};
    Map<String, int> spellWins = {};
    Map<String, int> itemCounts = {};
    Map<String, int> itemWins = {};

    for (var row in _data) {
      final heroIsEnemy = row['hero_is_enemy'] as int;
      final result = row['result'] as String;
      
      if ((heroIsEnemy == 0 && result == 'VICTORY') || (heroIsEnemy == 1 && result == 'DEFEAT')) {
        wins++;
      }

      final durationStr = row['duration'] as String?;
      if (durationStr != null && durationStr.isNotEmpty) {
        final parts = durationStr.split(':');
        if (parts.length == 2) {
          totalMinutes += (int.tryParse(parts[0]) ?? 0) + ((int.tryParse(parts[1]) ?? 0) / 60.0);
        } else if (parts.length == 3) {
          totalMinutes += (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0) + ((int.tryParse(parts[2]) ?? 0) / 60.0);
        }
      }

      final kdaStr = row['hero_kda'] as String;
      final kdaParts = kdaStr.split('/');
      if (kdaParts.length == 3) {
        totalKills += int.tryParse(kdaParts[0]) ?? 0;
        totalDeaths += int.tryParse(kdaParts[1]) ?? 0;
        totalAssists += int.tryParse(kdaParts[2]) ?? 0;
      }

      totalGold += int.tryParse(row['hero_gold'].toString()) ?? 0;
      totalDamageHero += int.tryParse(row['hero_damage_hero'].toString()) ?? 0;
      totalDamageTower += int.tryParse(row['hero_damage_tower'].toString()) ?? 0;
      totalDamageTaken += int.tryParse(row['hero_damage_taken'].toString()) ?? 0;
      totalHeal += int.tryParse(row['hero_heal'].toString()) ?? 0;

      final role = row['hero_role'] as String;
      if (role.isNotEmpty && role != 'unknown') {
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }
      final isWin = (heroIsEnemy == 0 && result == 'VICTORY') || (heroIsEnemy == 1 && result == 'DEFEAT');

      final spell = row['hero_spell'].toString();
      final itemsStr = row['hero_items'] as String;
      
      String spellKey = spell;
      if (spell == '20020' && itemsStr.isNotEmpty) {
        final items = itemsStr.split(',').where((i) => i != '0' && i.isNotEmpty);
        for (var iStr in items) {
          final itemId = int.tryParse(iStr) ?? 0;
          final entity = GameData.getItem(itemId);
          if (entity?.blessingId != null) {
            spellKey = '${spell}_${entity!.blessingId}';
            break;
          }
        }
      }

      if (spellKey != '0' && spellKey.isNotEmpty) {
        spellCounts[spellKey] = (spellCounts[spellKey] ?? 0) + 1;
        if (isWin) {
          spellWins[spellKey] = (spellWins[spellKey] ?? 0) + 1;
        }
      }

      if (itemsStr.isNotEmpty) {
        final items = itemsStr.split(',').where((i) => i != '0' && i.isNotEmpty).toSet();
        for (var i in items) {
          itemCounts[i] = (itemCounts[i] ?? 0) + 1;
          if (isWin) {
            itemWins[i] = (itemWins[i] ?? 0) + 1;
          }
        }
      }
    }

    double winrate = (wins / gamesCount) * 100;
    String avgKda = "${(totalKills / gamesCount).toStringAsFixed(1)} / ${(totalDeaths / gamesCount).toStringAsFixed(1)} / ${(totalAssists / gamesCount).toStringAsFixed(1)}";

    String topRole = roleCounts.entries.isEmpty ? '' : roleCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    String topSpell = spellCounts.entries.isEmpty ? '' : spellCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    List<MapEntry<String, int>> topItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<String> top6Items = topItems.take(6).map((e) => e.key).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Игр: $gamesCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Винрейт: ${winrate.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: winrate >= 50 ? Colors.green : Colors.red)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Средний KDA:'),
                            Text(avgKda, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Среднее золото:'),
                            Text('${totalMinutes > 0 ? (totalGold / totalMinutes).round() : 0} / мин', style: const TextStyle(color: Colors.amber)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Урон по героям:'),
                            Text('${totalMinutes > 0 ? (totalDamageHero / totalMinutes).round() : 0} / мин'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Урон по башням:'),
                            Text('${gamesCount > 0 ? (totalDamageTower / gamesCount).round() : 0}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Полученный урон:'),
                            Text('${totalMinutes > 0 ? (totalDamageTaken / totalMinutes).round() : 0} / мин'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Лечение:'),
                            Text('${totalMinutes > 0 ? (totalHeal / totalMinutes).round() : 0} / мин', style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (topRole.isNotEmpty) ...[
                              DataUtils.getRoleIcon(topRole, size: 24),
                              const SizedBox(width: 8),
                            ],
                            if (topSpell.isNotEmpty) ...[
                              GestureDetector(
                                onTap: () => _showSpellsDialog(context, spellCounts, spellWins, gamesCount),
                                child: () {
                                  final parts = topSpell.split('_');
                                  final spellId = int.tryParse(parts[0]) ?? 0;
                                  final blessingId = parts.length > 1 ? int.tryParse(parts[1]) : null;
                                  return DataUtils.getSpellIcon(spellId, blessingId: blessingId, size: 24);
                                }(),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (top6Items.isNotEmpty)
                GestureDetector(
                  onTap: () => _showItemsDialog(context, itemCounts, itemWins, gamesCount),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Популярные предметы (нажмите для всех):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: top6Items.map((item) {
                              final count = itemCounts[item] ?? 0;
                              final wins = itemWins[item] ?? 0;
                              final wr = count > 0 ? (wins / count * 100).toStringAsFixed(1) : '0.0';
                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Column(
                                  children: [
                                    DataUtils.getItemIcon(int.parse(item), size: 40),
                                    const SizedBox(height: 4),
                                    Text('$count игр', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                    Text('$wr%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: (double.tryParse(wr) ?? 0) >= 50 ? Colors.green : Colors.red)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(alignment: Alignment.centerLeft, child: Text('Список игр:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              ..._data.map((row) {
                final game = GameStats.fromMap(row);
                final isHeroWin = (row['hero_is_enemy'] == 0 && game.result == 'VICTORY') || 
                                  (row['hero_is_enemy'] == 1 && game.result == 'DEFEAT');
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        DataUtils.getHeroIcon(widget.heroId, radius: 25),
                        if (row['hero_role'].toString().isNotEmpty && row['hero_role'] != 'unknown')
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: DataUtils.getRoleIcon(row['hero_role'], size: 12),
                            ),
                          ),
                      ],
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row['hero_player_nickname']?.toString() ?? 'Неизвестно',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(row['hero_kda'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(width: 4),
                            DataUtils.getMedalIcon(int.tryParse(row['hero_score'].toString()) ?? 0, size: 14),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          game.date.toString().substring(0, 16),
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  trailing: Text(
                    isHeroWin ? 'ПОБЕДА' : 'ПОРАЖЕНИЕ',
                    style: TextStyle(
                      color: isHeroWin ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => GameDetailsScreen(game: game)),
                    );
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    ],
    );
  }

  void _showSpellsDialog(BuildContext context, Map<String, int> spellCounts, Map<String, int> spellWins, int totalGames) {
    final sortedSpells = spellCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Популярные спеллы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedSpells.length,
                  itemBuilder: (context, index) {
                    final spellKey = sortedSpells[index].key;
                    final count = sortedSpells[index].value;
                    final wins = spellWins[spellKey] ?? 0;
                    
                    final parts = spellKey.split('_');
                    final spellId = int.tryParse(parts[0]) ?? 0;
                    final blessingId = parts.length > 1 ? int.tryParse(parts[1]) : null;
                    
                    final pickRate = (count / totalGames * 100).toStringAsFixed(1);
                    final winRate = (wins / count * 100).toStringAsFixed(1);
                    
                    String spellName = DataUtils.getLocalizedSpellName(spellId, context);
                    if (blessingId != null) {
                      final blessingName = DataUtils.getLocalizedSpellName(blessingId, context);
                      spellName += ' ($blessingName)';
                    }
                    
                    return ListTile(
                      leading: DataUtils.getSpellIcon(spellId, blessingId: blessingId, size: 40),
                      title: Text(spellName),
                      subtitle: Text('Пикрейт: $pickRate% ($count игр)'),
                      trailing: Text(
                        '$winRate%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (wins / count * 100) >= 50 ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showItemsDialog(BuildContext context, Map<String, int> itemCounts, Map<String, int> itemWins, int totalGames) {
    final sortedItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Популярные предметы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedItems.length,
                  itemBuilder: (context, index) {
                    final itemIdStr = sortedItems[index].key;
                    final itemId = int.tryParse(itemIdStr) ?? 0;
                    final count = sortedItems[index].value;
                    final wins = itemWins[itemIdStr] ?? 0;
                    
                    final pickRate = (count / totalGames * 100).toStringAsFixed(1);
                    final winRate = count > 0 ? (wins / count * 100).toStringAsFixed(1) : '0.0';
                    
                    final itemName = DataUtils.getLocalizedItemName(itemId, context);
                    
                    return ListTile(
                      leading: DataUtils.getItemIcon(itemId, size: 40),
                      title: Text(itemName),
                      subtitle: Text('Пикрейт: $pickRate% ($count игр)'),
                      trailing: Text(
                        '$winRate%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (count > 0 && (wins / count * 100) >= 50) ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
