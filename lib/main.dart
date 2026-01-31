import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/recent_games_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_game_screen.dart';
import 'utils/app_strings.dart';
import 'utils/database_helper.dart'; // Add import

// Global Language Notifier
final ValueNotifier<Locale> appLocaleNotifier = ValueNotifier(const Locale('en'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DB and fix old records
  await DatabaseHelper().fixLegacyGames();

  final prefs = await SharedPreferences.getInstance();
  final String? savedLang = prefs.getString('language_code');
  if (savedLang != null) {
    appLocaleNotifier.value = Locale(savedLang);
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'MLBB Stats',
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.deepPurple,
            useMaterial3: true,
          ),
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ru'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const RecentGamesScreen(),
      const StatisticsScreen(),
      const SearchScreen(),
      AddGameScreen(onSaveSuccess: () {
        setState(() {
          _selectedIndex = 0;
        });
      }),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _screens.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: AppStrings.get(context, 'recent'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics),
            label: AppStrings.get(context, 'stats'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: AppStrings.get(context, 'search'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle, color: Colors.deepPurpleAccent),
            label: AppStrings.get(context, 'add'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: AppStrings.get(context, 'settings'),
          ),
        ],
      ),
    );
  }
}
