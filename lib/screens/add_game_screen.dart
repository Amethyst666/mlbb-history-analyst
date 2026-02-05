import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_stats.dart';
import '../models/game_stats.dart';
import '../utils/game_data.dart';
import '../utils/database_helper.dart';
import '../utils/history_parser.dart';
import '../utils/data_utils.dart';
import '../utils/app_strings.dart';

class AddGameScreen extends StatefulWidget {
  final VoidCallback? onSaveSuccess;

  const AddGameScreen({super.key, this.onSaveSuccess});

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final _dbHelper = DatabaseHelper();
  File? _file;
  String? _userId;
  String? _matchId;

  String gameResult = 'VICTORY';
  String duration = '00:00';
  DateTime matchDate = DateTime.now();
  List<PlayerStats> players = [];
  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      String mId = fileName;
      if (fileName.contains('-')) {
        mId = fileName.split('-').last;
      }
      mId = mId.replaceAll(RegExp(r'\..*$'), '');

      setState(() {
        _file = file;
        _matchId = mId;
        _isParsing = true;
      });

      final parsed = await HistoryParser.parseFile(
        file,
        userGameId: _userId,
        matchId: _matchId,
      );

      if (parsed != null) {
        setState(() {
          gameResult = parsed.game.result;
          duration = parsed.game.duration;
          matchDate = parsed.game.date;
          players = parsed.players;
          _isParsing = false;
        });
      } else {
        setState(() => _isParsing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.get(context, 'parse_failed'))),
          );
        }
      }
    }
  }

  Future<void> _saveGame() async {
    if (players.isEmpty) return;

    PlayerStats? userStats;
    try {
      userStats = players.firstWhere((p) => p.isUser);
    } catch (_) {
      userStats = null;
    }

    final game = GameStats(
      matchId: _matchId ?? "",
      result: gameResult,
      heroId: userStats?.heroId ?? 0,
      kda: userStats?.kda ?? "0/0/0",
      itemIds: userStats?.itemIds ?? [],
      score: userStats?.score ?? 0,
      role: userStats?.role ?? 'unknown',
      spellId: userStats?.spellId ?? 0,
      players: players.map((p) => p.nickname).join(', '),
      date: matchDate,
      duration: duration,
    );

    int id = await _dbHelper.insertGameWithPlayers(game, players);
    if (id != -1) {
      if (widget.onSaveSuccess != null) widget.onSaveSuccess!();
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get(context, 'save_error'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get(context, 'add'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_open),
              label: Text(
                _file == null
                    ? AppStrings.get(context, 'select_history_file')
                    : AppStrings.get(context, 'change_file'),
              ),
            ),
            if (_file != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "File: ${_file!.path.split('/').last}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            const Divider(),
            if (_isParsing) const Center(child: CircularProgressIndicator()),
            if (!_isParsing && players.isNotEmpty) ...[
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(
                        "${AppStrings.get(context, 'result_label')}${gameResult == 'VICTORY' ? AppStrings.get(context, 'victory') : AppStrings.get(context, 'defeat')}",
                        style: TextStyle(
                          color: gameResult == 'VICTORY'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${AppStrings.get(context, 'date_label')}${matchDate.toString().substring(0, 16)} | ${AppStrings.get(context, 'duration')}: $duration",
                      ),
                    ),
                    const Divider(),
                    ...players
                        .map(
                          (p) => ListTile(
                            leading: DataUtils.getHeroIcon(
                              p.heroId,
                              radius: 20,
                            ),
                            title: Text(
                              p.nickname,
                              style: TextStyle(
                                fontWeight: p.isUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: p.isUser
                                    ? Colors.cyanAccent
                                    : Colors.white,
                              ),
                            ),
                            subtitle: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "${AppStrings.get(context, 'kda')}: ${p.kda} • ",
                                ),
                                DataUtils.getMedalIcon(p.score, size: 14),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.monetization_on,
                                  color: Color(0xFFFFD700),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  p.gold,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppStrings.get(context, 'save_match')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
