import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
import '../utils/app_strings.dart';
import '../utils/database_helper.dart';
import 'asset_gallery_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeveloperMode = false;
  final TextEditingController _nickController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nickController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final historyPath = prefs.getString('historyPath') ?? '';
    setState(() {
      _isDeveloperMode = prefs.getBool('isDeveloperMode') ?? false;
      _nickController.text = userId;
      _pathController.text = historyPath;
    });
  }

  Future<void> _saveNickname(String value) async {
    if (value.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', value.trim());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID пользователя сохранен")),
      );
    }
  }

  Future<void> _pickHistoryFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('historyPath', selectedDirectory);
      setState(() {
        _pathController.text = selectedDirectory;
      });
    }
  }

  Future<void> _toggleDeveloperMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDeveloperMode', value);
    setState(() {
      _isDeveloperMode = value;
    });
  }

  Future<void> _changeLanguage() async {
    final currentLang = appLocaleNotifier.value.languageCode;
    final newLang = currentLang == 'en' ? 'ru' : 'en';
    appLocaleNotifier.value = Locale(newLang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLang);
  }

  @override
  Widget build(BuildContext context) {
    final currentLangCode = Localizations.localeOf(context).languageCode;
    final langName = currentLangCode == 'en' ? 'English' : 'Русский';

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get(context, 'settings'))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nickController,
                  decoration: InputDecoration(
                    labelText: "Мой Game ID (для авто-определения)", 
                    hintText: "Например: 12345678",
                    prefixIcon: const Icon(Icons.perm_identity),
                    border: const OutlineInputBorder(),
                    helperText: "Нужен для автоматического определения 'Меня' при импорте.",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: () => _saveNickname(_nickController.text),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: _saveNickname,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pathController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Папка с историей игр",
                    hintText: "Выберите папку...",
                    prefixIcon: const Icon(Icons.folder),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: _pickHistoryFolder,
                    ),
                  ),
                  onTap: _pickHistoryFolder,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppStrings.get(context, 'language')),
            subtitle: Text(langName),
            trailing: const Icon(Icons.swap_horiz),
            onTap: _changeLanguage,
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(AppStrings.get(context, 'theme')),
            subtitle: const Text('Dark Mode'),
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.developer_mode),
            title: Text(AppStrings.get(context, 'developer_mode')),
            subtitle: const Text('Enable advanced features'),
            trailing: Switch(
              value: _isDeveloperMode,
              onChanged: _toggleDeveloperMode,
              activeColor: Colors.deepPurpleAccent,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.collections),
            title: const Text('Asset Gallery'),
            subtitle: const Text('Check icons'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AssetGalleryScreen()));
            },
          ),
          if (_isDeveloperMode) ...[
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.orangeAccent),
              title: const Text('Очистить базу игроков'),
              subtitle: const Text('Удалить игроков, которых нет ни в одном матче'),
              onTap: () async {
                final count = await _dbHelper.deleteUnusedProfiles();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Удалено профилей: $count")),
                  );
                }
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppStrings.get(context, 'about')),
            subtitle: const Text('Version 2.1.0 (Batch Import)'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}