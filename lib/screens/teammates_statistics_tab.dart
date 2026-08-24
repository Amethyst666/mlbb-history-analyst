import 'package:flutter/material.dart';
import '../utils/database_helper.dart';
import 'player_profile_screen.dart';

class TeammatesStatisticsTab extends StatefulWidget {
  const TeammatesStatisticsTab({super.key});

  @override
  State<TeammatesStatisticsTab> createState() => _TeammatesStatisticsTabState();
}

class _TeammatesStatisticsTabState extends State<TeammatesStatisticsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _stats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await _dbHelper.getTeammatesStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats.isEmpty) {
      return const Center(child: Text('Нет данных о союзниках', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: _stats.length,
      itemBuilder: (context, index) {
        final item = _stats[index];
        final name = item['name'] as String;
        final games = item['games_count'] as int;
        final wins = item['wins'] as int;
        final wr = games > 0 ? (wins / games * 100).toStringAsFixed(1) : '0.0';

        final profileId = item['profile_id'] as int;
        
        return ListTile(
          onTap: () async {
            final profile = await _dbHelper.getProfileById(profileId);
            if (profile != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => PlayerProfileScreen(profile: profile)),
              );
            }
          },
          leading: const CircleAvatar(
            backgroundColor: Colors.deepPurpleAccent,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Игры вместе: $games'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Винрейт', style: TextStyle(fontSize: 10, color: Colors.white54)),
              Text(
                '$wr%',
                style: TextStyle(
                  color: (double.tryParse(wr) ?? 0) >= 50 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
