import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';
import '../utils/database_helper.dart';
import '../utils/import_helper.dart';
import 'game_details_screen.dart';
import 'add_game_screen.dart';
import '../utils/app_strings.dart';
import '../utils/data_utils.dart';
import 'history_folder_screen.dart';

class RecentGamesScreen extends StatefulWidget {
  const RecentGamesScreen({super.key});

  @override
  State<RecentGamesScreen> createState() => _RecentGamesScreenState();
}

class _RecentGamesScreenState extends State<RecentGamesScreen>
    with WidgetsBindingObserver {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<GameStats> _games = [];
  bool _isDeveloperMode = false;
  bool _autoImportEnabled = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData().then((_) {
      if (_autoImportEnabled && !_isImporting) {
        _runAutoImport();
      }
    });
    _dbHelper.updateNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dbHelper.updateNotifier.removeListener(_loadData);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _autoImportEnabled &&
        !_isImporting) {
      _runAutoImport();
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final isDev = prefs.getBool('isDeveloperMode') ?? false;
    final auto = prefs.getBool('auto_import') ?? false;
    final games = await _dbHelper.getGames();

    if (mounted) {
      setState(() {
        _isDeveloperMode = isDev;
        _autoImportEnabled = auto;
        _games = games;
      });
    }
  }

  Future<void> _runAutoImport() async {
    setState(() => _isImporting = true);
    try {
      final count = await ImportHelper.autoImportAll();
      if (mounted) {
        if (count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${AppStrings.get(context, 'import_success')}$count",
              ),
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.get(context, 'no_new_games')),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _deleteGame(int index) async {
    final game = _games[index];
    if (game.id != null) {
      await _dbHelper.deleteGame(game.id!);
      // Note: No need to manually remove from list, updateNotifier will trigger _loadData
    }
  }

  Future<void> _handleImportPress() async {
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryFolderScreen()),
      );

      // Always reload data and settings after returning from History screen
      await _loadData();

      if (result != null) {
        if (result is String) {
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(result)));
        } else if (result is int) {
          if (mounted) {
            if (result > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${AppStrings.get(context, 'import_success')}$result",
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.get(context, 'no_new_games')),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }
    }
  }

  void _openManualPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGameScreen(
          onSaveSuccess: () {
            _loadData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_games.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppStrings.get(context, 'no_games')),
            if (_isImporting) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      );
    } else {
      content = ListView.builder(
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          final isVictory = game.result == 'VICTORY';
          final resultText = isVictory
              ? AppStrings.get(context, 'victory')
              : AppStrings.get(context, 'defeat');
          final bool noUser = game.heroId == 0;

          final heroName = noUser
              ? AppStrings.get(context, 'match_no_player')
              : DataUtils.getLocalizedHeroName(game.heroId, context);

          final startStr = game.date.toString().substring(5, 16);
          final endTimeStr =
              game.endDate?.toString().substring(11, 16) ?? "??:??";

          final dateDisplay = "$startStr - $endTimeStr";

          final cardContent = Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameDetailsScreen(game: game),
                  ),
                ).then((_) => _loadData());
              },
              leading: noUser
                  ? const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person_off, color: Colors.grey),
                    )
                  : Stack(
                      children: [
                        DataUtils.getHeroIcon(game.heroId, radius: 25),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: DataUtils.getRoleIcon(game.role, size: 12),
                          ),
                        ),
                      ],
                    ),
              title: Text(
                heroName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: noUser ? Colors.grey : Colors.white,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!noUser) ...[
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${AppStrings.get(context, 'kda')}: ${game.kda} • ',
                          style: const TextStyle(fontSize: 11),
                        ),
                        DataUtils.getMedalIcon(game.score, size: 14),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: game.itemIds
                          .map(
                            (item) => SizedBox(
                              width: 20,
                              height: 20,
                              child: DataUtils.getItemIcon(item, size: 20),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    dateDisplay,
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                ],
              ),
              isThreeLine: !noUser,
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!noUser)
                    Text(
                      resultText,
                      style: TextStyle(
                        color: isVictory ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    game.duration,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );

          if (_isDeveloperMode) {
            return Dismissible(
              key: Key(
                "${game.id}_${_isDeveloperMode}",
              ), // Key depends on mode to force rebuild
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

    return Scaffold(
      body: content,
      floatingActionButton: _autoImportEnabled
          ? null
          : GestureDetector(
              onLongPress: _openManualPicker,
              child: FloatingActionButton(
                onPressed: _handleImportPress,
                tooltip: AppStrings.get(context, 'manual_import_hint'),
                backgroundColor: Colors.deepPurpleAccent,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
    );
  }
}
