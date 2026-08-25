import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/database_helper.dart';
import '../utils/data_utils.dart';
import 'recent_games_screen.dart';

class RolesStatisticsTab extends StatefulWidget {
  const RolesStatisticsTab({super.key});

  @override
  State<RolesStatisticsTab> createState() => _RolesStatisticsTabState();
}

class _RolesStatisticsTabState extends State<RolesStatisticsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _roleStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _dbHelper.updateNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    _dbHelper.updateNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final stats = await _dbHelper.getRoleStats();
    if (mounted) {
      setState(() {
        _roleStats = stats;
        _isLoading = false;
      });
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'exp': return Colors.orange;
      case 'mid': return Colors.blue;
      case 'roam': return Colors.green;
      case 'jungle': return Colors.purple;
      case 'gold': return Colors.amber;
      default: return Colors.grey;
    }
  }

  String _getRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'exp': return 'Опыт';
      case 'mid': return 'Мид';
      case 'roam': return 'Роум';
      case 'jungle': return 'Лес';
      case 'gold': return 'Золото';
      default: return 'Неизвестно';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_roleStats.isEmpty) {
      return const Center(child: Text('Нет данных о ролях', style: TextStyle(color: Colors.grey)));
    }

    int totalGames = _roleStats.fold(0, (sum, item) => sum + (item['my_games'] as int));

    return Column(
      children: [
        const SizedBox(height: 24),
        const Text('Популярность ролей', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _roleStats.map((item) {
                final count = item['my_games'] as int;
                final role = item['role'] as String;
                final pct = (count / totalGames * 100).toStringAsFixed(1);
                return PieChartSectionData(
                  color: _getRoleColor(role),
                  value: count.toDouble(),
                  title: '${_getRoleName(role)}\n$pct%',
                  radius: 70,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _roleStats.length,
            itemBuilder: (context, index) {
              final item = _roleStats[index];
              final role = item['role'] as String;
              final games = item['my_games'] as int;
              final wins = item['my_wins'] as int;
              final wr = games > 0 ? (wins / games * 100).toStringAsFixed(1) : '0.0';

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => RecentGamesScreen(
                        initialFilters: {'result': 'ALL', 'role': role},
                      ),
                    ),
                  );
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: DataUtils.getRoleIcon(role, size: 24)),
                ),
                title: Text(_getRoleName(role), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Игры: $games  •  Винрейт: $wr%'),
                trailing: Text(
                  '$wr%',
                  style: TextStyle(
                    color: (double.tryParse(wr) ?? 0) >= 50 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
