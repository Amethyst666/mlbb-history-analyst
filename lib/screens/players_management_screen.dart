import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../utils/database_helper.dart';
import '../utils/app_strings.dart';

class PlayersManagementScreen extends StatefulWidget {
  const PlayersManagementScreen({super.key});

  @override
  State<PlayersManagementScreen> createState() => _PlayersManagementScreenState();
}

class _PlayersManagementScreenState extends State<PlayersManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<PlayerProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await _dbHelper.getAllProfiles();
    setState(() {
      _profiles = profiles;
      _isLoading = false;
    });
  }

  void _editProfile(PlayerProfile profile) async {
    final nicknames = await _dbHelper.getNicknamesForProfile(profile.id!);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile.mainNickname),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Associated Nicknames:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: nicknames.map((n) => Chip(
                label: Text(n, style: const TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const Divider(),
            const Text("Change Main Nickname:", style: TextStyle(fontSize: 12)),
            TextField(
              decoration: const InputDecoration(hintText: "Enter new name"),
              onSubmitted: (newName) async {
                if (newName.isNotEmpty) {
                  await _dbHelper.updateMainNickname(profile.id!, newName);
                  Navigator.pop(context);
                  _loadProfiles();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            onPressed: () => _showMergeDialog(profile),
            child: const Text("Merge with another..."),
          ),
        ],
      ),
    );
  }

  void _showMergeDialog(PlayerProfile sourceProfile) async {
    Navigator.pop(context); // Close edit dialog
    final otherProfiles = _profiles.where((p) => p.id != sourceProfile.id).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Merge Profiles"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: otherProfiles.length,
            itemBuilder: (context, index) {
              final target = otherProfiles[index];
              return ListTile(
                title: Text(target.mainNickname),
                subtitle: const Text("Click to merge INTO this profile"),
                onTap: () async {
                  final nicks = await _dbHelper.getNicknamesForProfile(sourceProfile.id!);
                  for (var nick in nicks) {
                    await _dbHelper.associateNicknameWithProfile(nick, target.id!);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadProfiles();
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Players")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _profiles.length,
            itemBuilder: (context, index) {
              final p = _profiles[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.isUser ? Colors.deepPurpleAccent : Colors.blueGrey,
                  child: Icon(p.isUser ? Icons.person : Icons.person_outline, color: Colors.white),
                ),
                title: Text(p.mainNickname, style: TextStyle(fontWeight: p.isUser ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(p.isUser ? "This is You" : "Player Profile"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editProfile(p),
              );
            },
          ),
    );
  }
}
