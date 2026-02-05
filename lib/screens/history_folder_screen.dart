import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game_stats.dart';
import '../utils/history_parser.dart';
import '../utils/database_helper.dart';
import '../utils/app_strings.dart';

class HistoryFolderScreen extends StatefulWidget {
  const HistoryFolderScreen({super.key});

  @override
  State<HistoryFolderScreen> createState() => _HistoryFolderScreenState();
}

class _HistoryFolderScreenState extends State<HistoryFolderScreen> {
  static const platform = MethodChannel('com.mlbb.stats.analyst/saf');

  String _mode = 'none';
  String? _safUriStr;

  final List<String> _basePaths = [
    '/storage/emulated/0/Android/data/com.mobile.legends/files/dragon2017/FightHistory',
    '/storage/emulated/0/Android/data/com.mobilelegends.hwag/files/dragon2017/FightHistory',
  ];

  List<String> _pathsToCheck = [];
  List<Map<dynamic, dynamic>> _files = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _safUriStr = prefs.getString('history_saf_uri');
    final savedMode = prefs.getString('history_mode') ?? 'none';

    if (savedMode == 'none') {
      setState(() {
        _mode = 'none';
        _isLoading = false;
      });
      return;
    }

    _mode = 'list';
    String customPath = prefs.getString('shizuku_custom_path') ?? '';
    _pathsToCheck = [..._basePaths];
    if (customPath.isNotEmpty) _pathsToCheck.add(customPath);

    if (savedMode == 'shizuku') {
      await _refreshShizukuFiles();
    } else if (savedMode == 'saf') {
      await _refreshSafFiles();
    }
  }

  Future<void> _refreshSafFiles() async {
    if (_safUriStr == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final List<dynamic>? result = await platform.invokeMethod('listFiles', {
        'uri': _safUriStr,
      });
      if (result != null) {
        _processFileList(result.cast<Map<dynamic, dynamic>>(), 'uri');
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshShizukuFiles() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> allFiles = [];
    try {
      for (var path in _pathsToCheck) {
        final String output = await platform.invokeMethod('shizukuShell', {
          'cmd': 'ls "$path"',
        });
        if (output.trim().isNotEmpty && !output.contains("Permission denied")) {
          for (var line in LineSplitter.split(output)) {
            if (line.trim().startsWith('His')) {
              allFiles.add({
                'name': line.trim(),
                'id': '$path/${line.trim()}',
                'lastModified': 0,
              });
            }
          }
        }
      }
      _processFileList(allFiles, 'id');
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _processFileList(List<Map<dynamic, dynamic>> list, String idKey) {
    final filtered = list
        .where((f) => f['name'].toString().startsWith('His'))
        .toList();
    filtered.sort(
      (a, b) => (b['lastModified'] ?? 0).compareTo(a['lastModified'] ?? 0),
    );

    if (mounted) {
      setState(() {
        _files = filtered;
        for (var f in _files) {
          f['id'] = f[idKey] ?? f['id'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _setMode(String mode) async {
    if (mode == 'saf') {
      setState(() => _mode = 'saf_info');
    } else if (mode == 'shizuku') {
      _checkShizuku();
    }
  }

  Future<void> _checkShizuku() async {
    try {
      final String status = await platform.invokeMethod(
        'checkShizukuAvailable',
      );
      if (status == 'GRANTED') {
        _saveMode(
          'shizuku',
          message: AppStrings.get(context, 'shizuku_granted'),
        );
      } else {
        final bool granted = await platform.invokeMethod(
          'requestShizukuPermission',
        );
        if (granted) {
          _saveMode(
            'shizuku',
            message: AppStrings.get(context, 'shizuku_granted'),
          );
        } else {
          setState(() => _mode = 'shizuku_info');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.get(context, 'shizuku_unavailable')),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _mode = 'shizuku_info');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get(context, 'shizuku_error_friendly')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveMode(String mode, {String? message}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history_mode', mode);

    DatabaseHelper().updateNotifier.notifyListeners();

    if (_mode == 'none' || _mode == 'shizuku_info' || _mode == 'saf_info') {
      if (mounted) Navigator.pop(context, message ?? true);
    } else {
      if (mounted && message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      _init();
    }
  }

  Future<void> _pickSafFolder() async {
    const initialUri =
        "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fdata%2Fcom.mobile.legends";
    try {
      final String? uri = await platform.invokeMethod('openDocumentTree', {
        'initialUri': initialUri,
      });
      if (uri != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('history_saf_uri', uri);
        await _saveMode(
          'saf',
          message:
              AppStrings.get(context, 'saf_method') +
              " " +
              AppStrings.get(context, 'ok'),
        );
      }
    } catch (_) {}
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id))
        _selectedIds.remove(id);
      else
        _selectedIds.add(id);
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _files.length)
        _selectedIds.clear();
      else
        _selectedIds.addAll(_files.map((f) => f['id'] as String));
    });
  }

  Future<void> _processSelected() async {
    if (_selectedIds.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('history_mode');
    List<ParsedGameData> parsedGames = [];
    int successCount = 0;

    for (var id in _selectedIds) {
      try {
        Uint8List? bytes;
        var fileInfo = _files.firstWhere((f) => f['id'] == id);
        String filename = fileInfo['name'];

        if (mode == 'shizuku') {
          final String content = await platform.invokeMethod('shizukuShell', {
            'cmd': 'cat "$id"',
          });
          if (content.trim().isNotEmpty) bytes = base64Decode(content.trim());
        } else if (mode == 'saf') {
          final rawBytes = await platform.invokeMethod('readFile', {'uri': id});
          if (rawBytes != null)
            bytes = base64Decode(utf8.decode(rawBytes).trim());
        }

        if (bytes != null) {
          String? matchId;
          if (filename.startsWith('His-')) {
            var parts = filename.split('-');
            if (parts.length >= 3) matchId = parts.last.split('.').first;
          }
          final parsed = HistoryParser.parseData(
            bytes,
            userGameId: _userId,
            matchId: matchId,
          );
          if (parsed != null) parsedGames.add(parsed);
        }
      } catch (_) {}
    }

    final dbHelper = DatabaseHelper();
    for (var data in parsedGames) {
      if (await dbHelper.insertGameWithPlayers(data.game, data.players) != -1)
        successCount++;
    }

    if (mounted) {
      Navigator.of(context).pop();
      Navigator.pop(context, successCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _mode != 'list')
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_mode == 'none') return _buildMethodSelection();
    if (_mode == 'saf_info') return _buildSafInstructions();
    if (_mode == 'shizuku_info') return _buildShizukuInstructions();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(context, 'history')),
        actions: [
          if (_files.isNotEmpty)
            IconButton(
              icon: Icon(
                _selectedIds.length == _files.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              onPressed: _selectAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? Center(child: Text(AppStrings.get(context, 'no_files_found')))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final id = file['id'] as String;
                final isSelected = _selectedIds.contains(id);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) => _toggleSelection(id),
                  title: Text(
                    file['name'],
                    style: const TextStyle(fontSize: 13),
                  ),
                  secondary: const Icon(Icons.description),
                );
              },
            ),
      floatingActionButton: _selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _processSelected,
              label: Text(
                "${AppStrings.get(context, 'add')} (${_selectedIds.length})",
              ),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildMethodSelection() {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get(context, 'setup_access'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.folder_shared,
              size: 80,
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.get(context, 'import_method'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildOptionCard(
              icon: Icons.folder_open,
              color: Colors.amber,
              title: AppStrings.get(context, 'saf_method'),
              desc: AppStrings.get(context, 'saf_desc'),
              onTap: () => _setMode('saf'),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              icon: Icons.adb,
              color: Colors.blueAccent,
              title: AppStrings.get(context, 'shizuku_method'),
              desc: AppStrings.get(context, 'shizuku_desc'),
              onTap: () => _setMode('shizuku'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSafInstructions() {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get(context, 'saf_info_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get(context, 'saf_info_title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 20),
            _buildStep(1, AppStrings.get(context, 'saf_step1')),
            _buildStep(2, AppStrings.get(context, 'saf_step2')),
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 16),
              child: Text(
                AppStrings.get(context, 'saf_step2_hw'),
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.white38,
                ),
              ),
            ),
            _buildStep(3, AppStrings.get(context, 'saf_step3')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _pickSafFolder,
                child: Text(
                  AppStrings.get(context, 'open_picker'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShizukuInstructions() {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(context, 'shizuku_info_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get(context, 'shizuku_not_running'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.white12,
                  child: const Text("1", style: TextStyle(fontSize: 10)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get(context, 'shizuku_step1'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse(AppStrings.get(context, 'shizuku_link')),
                        ),
                        child: Text(
                          AppStrings.get(context, 'shizuku_download'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStep(2, AppStrings.get(context, 'shizuku_step2')),
            _buildStep(3, AppStrings.get(context, 'shizuku_step3')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _checkShizuku,
                child: Text(
                  AppStrings.get(context, 'check_status'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.white12,
            child: Text(
              number.toString(),
              style: const TextStyle(fontSize: 10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
