import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/database_helper.dart';
import '../utils/data_utils.dart';
import '../utils/game_data.dart';
import 'hero_stats_details_screen.dart';
import 'roles_statistics_tab.dart';
import 'teammates_statistics_tab.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _topHeroes = [];
  List<Map<String, dynamic>> _filteredHeroes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _sortBy = 'my_games';

  @override
  void initState() {
    super.initState();
    _loadHeroes();
    _searchController.addListener(_onSearchChanged);
    _dbHelper.updateNotifier.addListener(_loadHeroes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _dbHelper.updateNotifier.removeListener(_loadHeroes);
    super.dispose();
  }

  Future<void> _loadHeroes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final playedHeroes = await _dbHelper.getTopUserHeroes();
      final Map<int, Map<String, dynamic>> playedStats = {
        for (var h in playedHeroes)
          int.tryParse(h['hero_id'].toString()) ?? 0: h
      };

      List<Map<String, dynamic>> allHeroes = [];
      for (var entity in GameData.heroes) {
        if (entity.id == 0) continue;
        final stats = playedStats[entity.id];
        allHeroes.add({
          'hero_id': entity.id,
          'my_games': stats?['my_games'] ?? 0,
          'my_wins': stats?['my_wins'] ?? 0,
          'total_games': stats?['total_games'] ?? 0,
          'total_wins': stats?['total_wins'] ?? 0,
        });
      }

      if (mounted) {
        setState(() {
          _topHeroes = allHeroes;
          _isLoading = false;
        });
        _applySort();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySort() {
    _topHeroes.sort((a, b) {
      if (_sortBy == 'alpha') {
        final nameA = DataUtils.getLocalizedHeroName(a['hero_id'], context).toLowerCase();
        final nameB = DataUtils.getLocalizedHeroName(b['hero_id'], context).toLowerCase();
        return nameA.compareTo(nameB);
      } else if (_sortBy == 'total_games') {
        int cmp = b['total_games'].compareTo(a['total_games']);
        if (cmp != 0) return cmp;
      } else if (_sortBy == 'my_power') {
        int powerA = 2 * (a['my_wins'] as int) - (a['my_games'] as int);
        int powerB = 2 * (b['my_wins'] as int) - (b['my_games'] as int);
        int cmp = powerB.compareTo(powerA);
        if (cmp != 0) return cmp;
      } else if (_sortBy == 'total_power') {
        int powerA = 2 * (a['total_wins'] as int) - (a['total_games'] as int);
        int powerB = 2 * (b['total_wins'] as int) - (b['total_games'] as int);
        int cmp = powerB.compareTo(powerA);
        if (cmp != 0) return cmp;
      } else {
        int cmp = b['my_games'].compareTo(a['my_games']);
        if (cmp != 0) return cmp;
      }
      final nameA = DataUtils.getLocalizedHeroName(a['hero_id'], context).toLowerCase();
      final nameB = DataUtils.getLocalizedHeroName(b['hero_id'], context).toLowerCase();
      return nameA.compareTo(nameB);
    });
    _onSearchChanged();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredHeroes = _topHeroes);
      return;
    }
    setState(() {
      _filteredHeroes = _topHeroes.where((hero) {
        final heroId = int.tryParse(hero['hero_id'].toString()) ?? 0;
        final name = DataUtils.getLocalizedHeroName(heroId, context).toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('По моим играм'),
                trailing: _sortBy == 'my_games' ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                onTap: () {
                  setState(() => _sortBy = 'my_games');
                  Navigator.pop(context);
                  _applySort();
                },
              ),
              ListTile(
                title: const Text('По играм всего'),
                trailing: _sortBy == 'total_games' ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                onTap: () {
                  setState(() => _sortBy = 'total_games');
                  Navigator.pop(context);
                  _applySort();
                },
              ),
              ListTile(
                title: const Text('По моей силе'),
                trailing: _sortBy == 'my_power' ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                onTap: () {
                  setState(() => _sortBy = 'my_power');
                  Navigator.pop(context);
                  _applySort();
                },
              ),
              ListTile(
                title: const Text('По общей силе'),
                trailing: _sortBy == 'total_power' ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                onTap: () {
                  setState(() => _sortBy = 'total_power');
                  Navigator.pop(context);
                  _applySort();
                },
              ),
              ListTile(
                title: const Text('По алфавиту'),
                trailing: _sortBy == 'alpha' ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                onTap: () {
                  setState(() => _sortBy = 'alpha');
                  Navigator.pop(context);
                  _applySort();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get(context, 'stats')),
          actions: [
            Builder(builder: (ctx) {
              final tabController = DefaultTabController.of(ctx);
              return IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () {
                  if (tabController.index == 0) _showSortOptions();
                },
              );
            }),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Герои'),
              Tab(text: 'Линии'),
              Tab(text: 'Союзники'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFavoriteHeroesTab(),
            const RolesStatisticsTab(),
            const TeammatesStatisticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteHeroesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск героя...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              filled: true,
              fillColor: Colors.white10,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredHeroes.isEmpty
                  ? Center(child: Text(AppStrings.get(context, 'empty')))
                  : ListView.builder(
                      itemCount: _filteredHeroes.length,
                      itemBuilder: (context, index) {
                        final hero = _filteredHeroes[index];
                        final heroId = int.tryParse(hero['hero_id'].toString()) ?? 0;
                        final myGames = hero['my_games'] as int;
                        final myWins = hero['my_wins'] as int;
                        final totalGames = hero['total_games'] as int;
                        final totalWins = hero['total_wins'] as int;
                        
                        final myWr = myGames > 0 ? (myWins / myGames * 100).toStringAsFixed(1) : '0.0';
                        final totalWr = totalGames > 0 ? (totalWins / totalGames * 100).toStringAsFixed(1) : '0.0';

                        return ListTile(
                          leading: DataUtils.getHeroIcon(heroId),
                          title: Text(DataUtils.getLocalizedHeroName(heroId, context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Мои игры: $myGames  •  Винрейт: $myWr%'),
                              Text('Всего игр: $totalGames  •  Винрейт героя: $totalWr%', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => HeroStatsDetailsScreen(
                                  heroId: heroId,
                                  heroName: DataUtils.getLocalizedHeroName(heroId, context),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
