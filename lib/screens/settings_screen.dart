import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils/app_strings.dart';
import '../utils/database_helper.dart';
import 'asset_gallery_screen.dart';
import 'players_management_screen.dart';
import 'calibration_screen.dart';
import 'ocr_debug_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeveloperMode = false;
  final TextEditingController _nickController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final userNick = prefs.getString('userNickname') ?? 'You';
    setState(() {
      _isDeveloperMode = prefs.getBool('isDeveloperMode') ?? false;
      _nickController.text = userNick;
    });
  }

  Future<void> _saveNickname(String value) async {
    if (value.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userNickname', value.trim());
    
    int profileId = await _dbHelper.getOrCreateProfile(value.trim(), isUser: true);
    await _dbHelper.updateMainNickname(profileId, value.trim());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Никнейм сохранен")),
      );
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
            child: TextField(
              controller: _nickController,
              decoration: InputDecoration(
                labelText: AppStrings.get(context, 'my_nickname'),
                hintText: "Nickname",
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveNickname(_nickController.text),
                ),
              ),
              onSubmitted: _saveNickname,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text(AppStrings.get(context, 'manage_players')),
            subtitle: Text(AppStrings.get(context, 'players_desc')),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const PlayersManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.screenshot_monitor),
            title: Text(AppStrings.get(context, 'calibration')),
            subtitle: Text(AppStrings.get(context, 'calibration_desc')),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const CalibrationScreen()));
            },
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
          if (_isDeveloperMode)
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('OCR Debug'),
              subtitle: const Text('Visualize parsing zones'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OcrDebugScreen()));
              },
            ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppStrings.get(context, 'about')),
            subtitle: const Text('Version 1.2.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}