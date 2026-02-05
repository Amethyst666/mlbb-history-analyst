import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../utils/app_strings.dart';
import '../utils/database_helper.dart';
import 'asset_gallery_screen.dart';
import 'history_folder_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const platform = MethodChannel('com.mlbb.stats.analyst/saf');
  final _dbHelper = DatabaseHelper();

  final _nickController = TextEditingController();
  final _customShizukuPathController = TextEditingController();

  bool _isDeveloperMode = false;
  bool _autoImport = false;
  String _accessMode = 'none';
  String? _safUri;
  String _appVersion = '2.3.2';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _dbHelper.updateNotifier.addListener(_loadSettings);
  }

  @override
  void dispose() {
    _dbHelper.updateNotifier.removeListener(_loadSettings);
    _nickController.dispose();
    _customShizukuPathController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final mode = prefs.getString('history_mode') ?? 'none';
    final uri = prefs.getString('history_saf_uri');
    final auto = prefs.getBool('auto_import') ?? false;
    final customPath = prefs.getString('shizuku_custom_path') ?? '';

    final packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _isDeveloperMode = prefs.getBool('isDeveloperMode') ?? false;
      _autoImport = auto;
      _nickController.text = userId;
      _customShizukuPathController.text = customPath;
      _accessMode = mode;
      _safUri = uri;
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _toggleAutoImport(bool value) async {
    if (value && _accessMode == 'none') {
      _showSetupWizard();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_import', value);
    setState(() => _autoImport = value);
    _dbHelper.updateNotifier.notifyListeners();
  }

  Future<void> _resetAccessMethod() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history_mode', 'none');
    await prefs.remove('history_saf_uri');
    setState(() {
      _accessMode = 'none';
      _safUri = null;
    });
    _dbHelper.updateNotifier.notifyListeners();
  }

  void _showSetupWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryFolderScreen()),
    ).then((result) {
      if (result != null && result is String) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result)));
      }
      _loadSettings();
      _dbHelper.updateNotifier.notifyListeners();
    });
  }

  Future<void> _toggleDeveloperMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDeveloperMode', value);
    setState(() => _isDeveloperMode = value);
    _dbHelper.updateNotifier.notifyListeners();
  }

  Future<void> _saveNickname(String value) async {
    if (value.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', value.trim());
    await _dbHelper.updateUserIdentity(value.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get(context, 'save_id_success'))),
      );
    }
  }

  Future<void> _saveCustomShizukuPath(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shizuku_custom_path', value.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get(context, 'path_saved'))),
      );
    }
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
    final langName = Localizations.localeOf(context).languageCode == 'en'
        ? 'English'
        : 'Русский';

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get(context, 'settings'))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nickController,
              decoration: InputDecoration(
                labelText: AppStrings.get(context, 'my_game_id_label'),
                prefixIcon: const Icon(Icons.perm_identity),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveNickname(_nickController.text),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const Divider(),

          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: Text(AppStrings.get(context, 'auto_import_title')),
            subtitle: Text(AppStrings.get(context, 'auto_import_desc')),
            value: _autoImport,
            onChanged: _toggleAutoImport,
            activeColor: Colors.cyanAccent,
          ),

          if (_accessMode == 'none')
            ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.amber),
              title: Text(AppStrings.get(context, 'setup_access')),
              subtitle: Text(AppStrings.get(context, 'import_method_desc')),
              onTap: _showSetupWizard,
            )
          else
            ListTile(
              leading: Icon(
                _accessMode == 'saf' ? Icons.folder_shared : Icons.adb,
                color: _accessMode == 'saf' ? Colors.amber : Colors.blueAccent,
              ),
              title: Text(
                AppStrings.get(context, 'access_label') +
                    _accessMode.toUpperCase(),
              ),
              subtitle: Text(AppStrings.get(context, 'reset_access_desc')),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(AppStrings.get(context, 'reset_access_desc')),
                    content: Text(
                      AppStrings.get(context, 'reset_access_desc') + "?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: Text(AppStrings.get(context, 'cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          _resetAccessMethod();
                          if (_autoImport) _toggleAutoImport(false);
                          Navigator.pop(c);
                        },
                        child: Text(
                          AppStrings.get(context, 'ok'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppStrings.get(context, 'language')),
            subtitle: Text(langName),
            onTap: _changeLanguage,
          ),
          const Divider(),

          SwitchListTile(
            secondary: const Icon(Icons.developer_mode),
            title: Text(AppStrings.get(context, 'developer_mode')),
            value: _isDeveloperMode,
            onChanged: _toggleDeveloperMode,
            activeColor: Colors.deepPurpleAccent,
          ),

          if (_isDeveloperMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _customShizukuPathController,
                decoration: InputDecoration(
                  labelText: AppStrings.get(context, 'custom_shizuku_path'),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () => _saveCustomShizukuPath(
                      _customShizukuPathController.text,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.collections),
              title: Text(AppStrings.get(context, 'asset_gallery')),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssetGalleryScreen(),
                ),
              ),
            ),
          ],

          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppStrings.get(context, 'about')),
            subtitle: Text("MLBB Analyst v$_appVersion"),
          ),
        ],
      ),
    );
  }
}
