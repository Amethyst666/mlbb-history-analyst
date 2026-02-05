import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/database_helper.dart';
import '../utils/history_parser.dart';

class ImportHelper {
  static const platform = MethodChannel('com.mlbb.stats.analyst/saf');

  static const List<String> _basePaths = [
    '/storage/emulated/0/Android/data/com.mobile.legends/files/dragon2017/FightHistory',
    '/storage/emulated/0/Android/data/com.mobilelegends.hwag/files/dragon2017/FightHistory',
  ];

  static Future<int> autoImportAll() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('history_mode') ?? 'none';
    final userId = prefs.getString('userId');
    final safUri = prefs.getString('history_saf_uri');
    final customPath = prefs.getString('shizuku_custom_path') ?? '';

    if (mode == 'none') return 0;

    List<Map<dynamic, dynamic>> allFiles = [];

    if (mode == 'saf' && safUri != null) {
      try {
        final List<dynamic>? result = await platform.invokeMethod('listFiles', {
          'uri': safUri,
        });
        if (result != null) allFiles = result.cast<Map<dynamic, dynamic>>();
      } catch (_) {}
    } else if (mode == 'shizuku') {
      List<String> paths = [..._basePaths];
      if (customPath.isNotEmpty) paths.add(customPath);
      for (var path in paths) {
        try {
          final String output = await platform.invokeMethod('shizukuShell', {
            'cmd': 'ls "$path"',
          });
          if (output.trim().isNotEmpty && !output.contains("Permission")) {
            for (var line in LineSplitter.split(output)) {
              if (line.trim().startsWith('His')) {
                allFiles.add({
                  'id': '$path/${line.trim()}',
                  'name': line.trim(),
                });
              }
            }
          }
        } catch (_) {}
      }
    } else if (mode == 'native') {
      if (await Permission.manageExternalStorage.isGranted) {
        for (var path in _basePaths) {
          try {
            final List<dynamic>? result = await platform.invokeMethod(
              'listNativeDirectory',
              {'path': path},
            );
            if (result != null)
              allFiles.addAll(result.cast<Map<dynamic, dynamic>>());
          } catch (_) {}
        }
      }
    }

    if (allFiles.isEmpty) return 0;

    // Filter only match files
    final matches = allFiles
        .where((f) => f['name'].toString().startsWith('His'))
        .toList();
    final dbHelper = DatabaseHelper();
    int importedCount = 0;

    for (var file in matches) {
      final String id =
          file['id'] ?? (mode == 'saf' ? file['uri'] : file['path']);
      final String filename = file['name'];

      String? matchId;
      if (filename.startsWith('His-')) {
        var parts = filename.split('-');
        if (parts.length >= 3) matchId = parts.last.split('.').first;
      }

      // Check if already exists to avoid heavy parsing
      if (matchId != null && await dbHelper.isGameExists(matchId)) continue;

      try {
        Uint8List? bytes;
        if (mode == 'shizuku') {
          final String content = await platform.invokeMethod('shizukuShell', {
            'cmd': 'cat "$id"',
          });
          if (content.trim().isNotEmpty) bytes = base64Decode(content.trim());
        } else if (mode == 'saf') {
          final rawBytes = await platform.invokeMethod('readFile', {'uri': id});
          if (rawBytes != null)
            bytes = base64Decode(utf8.decode(rawBytes).trim());
        } else {
          bytes = base64Decode((await File(id).readAsString()).trim());
        }

        if (bytes != null) {
          final parsed = HistoryParser.parseData(
            bytes,
            userGameId: userId,
            matchId: matchId,
          );
          if (parsed != null) {
            if (await dbHelper.insertGameWithPlayers(
                  parsed.game,
                  parsed.players,
                ) !=
                -1) {
              importedCount++;
            }
          }
        }
      } catch (_) {}
    }

    return importedCount;
  }
}
