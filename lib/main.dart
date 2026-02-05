import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/recent_games_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/search_screen.dart';
import 'screens/players_management_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_strings.dart';

final appLocaleNotifier = ValueNotifier(const Locale('en'));
final appThemeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final savedLang = prefs.getString('language_code');
  if (savedLang != null) appLocaleNotifier.value = Locale(savedLang);

  // Force Dark Theme
  appThemeNotifier.value = ThemeMode.dark;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeNotifier,
          builder: (context, themeMode, child) {
            return MaterialApp(
              title: 'MLBB Analyst',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: Brightness.light,
                primarySwatch: Colors.deepPurple,
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFFF5F5F7),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primarySwatch: Colors.deepPurple,
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFF121212),
              ),
              themeMode: themeMode,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('ru')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const MainScreen(),
            );
          },
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

  final List<Widget> _screens = [
    const RecentGamesScreen(),
    const StatisticsScreen(),
    const SearchScreen(),
    const PlayersManagementScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: [
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
            icon: const Icon(Icons.people),
            label: AppStrings.get(context, 'manage_players'),
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
