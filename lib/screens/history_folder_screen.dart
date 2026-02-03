import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/game_stats.dart';
import '../models/player_stats.dart';
import '../utils/history_parser.dart';
import '../utils/database_helper.dart';

class HistoryFolderScreen extends StatefulWidget {
  const HistoryFolderScreen({super.key});

  @override
  State<HistoryFolderScreen> createState() => _HistoryFolderScreenState();
}

class _HistoryFolderScreenState extends State<HistoryFolderScreen> {
  String? _historyPath;
  List<FileSystemEntity> _files = [];
  final Set<String> _selectedFiles = {};
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    // Request Storage Permission (Manage External Storage for Android 11+)
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    
    // Also try legacy storage if manage isn't applicable/granted (e.g. older Android)
    if (!status.isGranted) {
       var statusLegacy = await Permission.storage.status;
       if (!statusLegacy.isGranted) {
         await Permission.storage.request();
       }
    }

    // Double check status before proceeding
    if (!await Permission.manageExternalStorage.isGranted && !await Permission.storage.isGranted) {
       if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Нет разрешения на доступ к файлам")));
       }
       return;
    }

    final prefs = await SharedPreferences.getInstance();
    _historyPath = prefs.getString('historyPath');
    _userId = prefs.getString('userId');

    if (_historyPath == null || _historyPath!.isEmpty) {
// ... rest of logic
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Папка с историей не выбрана в настройках")));
      }
      return;
    }

    final dir = Directory(_historyPath!);
    if (await dir.exists()) {
      List<FileSystemEntity> entities = await dir.list().toList();
      // Filter logic: maybe only files, maybe sort by modification date descending
      entities = entities.whereType<File>().toList();
      entities.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified)); // Newest first
      
      if (mounted) {
        setState(() {
          _files = entities;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Папка не существует")));
      }
    }
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedFiles.contains(path)) {
        _selectedFiles.remove(path);
      } else {
        _selectedFiles.add(path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedFiles.length == _files.length) {
        _selectedFiles.clear();
      } else {
        for (var f in _files) {
          _selectedFiles.add(f.path);
        }
      }
    });
  }

  Future<void> _processSelected() async {
    if (_selectedFiles.isEmpty) return;

    // 1. Parse all to get IDs
    List<ParsedGameData> parsedGames = [];
    List<String> gameIds = []; // We can try to extract ID from filename or if parser gives it?
    // Current parser assumes ID logic internally for user match, but doesn't return "Match ID".
    // We can infer Match ID from filename usually: His-{UserID}-{MatchID}
    
    // Let's assume we show the filename or date for confirmation.
    
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    
    for (String path in _selectedFiles) {
      final file = File(path);
      String filename = file.uri.pathSegments.last;
      String? extractedMatchId;
      
      if (filename.startsWith('His-')) {
         var parts = filename.split('-');
         if (parts.length >= 3) {
           extractedMatchId = parts.last;
         }
      }

      final data = await HistoryParser.parseFile(file, userGameId: _userId, matchId: extractedMatchId);
      if (data != null) {
        parsedGames.add(data);
        gameIds.add(extractedMatchId ?? filename);
      }
    }
    
    if (mounted) Navigator.pop(context); // Close loading dialog

    if (parsedGames.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Не удалось прочитать файлы")));
      return;
    }

    // 2. Confirmation Dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Добавить ${parsedGames.length} игр?"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Будут добавлены игры со следующими ID/Именами:"),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: gameIds.length,
                  itemBuilder: (c, i) => Text("• ${gameIds[i]}", style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ОТМЕНА")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("ДОБАВИТЬ")),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // 3. Save
    final dbHelper = DatabaseHelper();
    int addedCount = 0;
    
    for (var data in parsedGames) {
      await _saveGame(dbHelper, data);
      addedCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Добавлено игр: $addedCount")));
      Navigator.pop(context, true); // Return success
    }
  }

  Future<void> _saveGame(DatabaseHelper dbHelper, ParsedGameData data) async {
    // Logic similar to AddGameScreen but simplified
    // Determine teams logic is already in ParsedGameData (isEnemy flag)
    // We just need to separate them into a single list for the DB method? 
    // No, insertGameWithPlayers takes List<PlayerStats>.
    
    // We might want to fill placeholders if < 10 players?
    // The parser returns what is in the file. Usually 10.
    
    // Just save as is.
    await dbHelper.insertGameWithPlayers(data.game, data.players);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Выбор файлов истории"),
        actions: [
          if (_files.isNotEmpty)
            IconButton(
              icon: Icon(_selectedFiles.length == _files.length ? Icons.deselect : Icons.select_all),
              onPressed: _selectAll,
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _files.isEmpty 
          ? Center(child: Text("Файлы не найдены в:\n$_historyPath", textAlign: TextAlign.center))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final name = file.uri.pathSegments.last;
                final isSelected = _selectedFiles.contains(file.path);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) => _toggleSelection(file.path),
                  title: Text(name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(file.statSync().modified.toString().substring(0, 16), style: const TextStyle(fontSize: 11)),
                  secondary: const Icon(Icons.description),
                );
              },
            ),
      floatingActionButton: _selectedFiles.isNotEmpty 
        ? FloatingActionButton.extended(
            onPressed: _processSelected,
            label: Text("Добавить (${_selectedFiles.length})"),
            icon: const Icon(Icons.add),
          )
        : null,
    );
  }
}
