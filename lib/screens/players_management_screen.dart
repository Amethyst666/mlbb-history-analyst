import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../utils/database_helper.dart';
import '../utils/app_strings.dart';
import 'player_profile_screen.dart';

class PlayersManagementScreen extends StatefulWidget {
  const PlayersManagementScreen({super.key});

  @override
  State<PlayersManagementScreen> createState() => _PlayersManagementScreenState();
}

class _PlayersManagementScreenState extends State<PlayersManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<PlayerProfile> _profiles = [];
  List<PlayerProfile> _filteredProfiles = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _searchController.addListener(_onSearchChanged);
    _dbHelper.updateNotifier.addListener(_loadProfiles);
  }

  @override
  void dispose() {
    _dbHelper.updateNotifier.removeListener(_loadProfiles);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _filteredProfiles = _profiles);
      return;
    }
    
    final results = await _dbHelper.searchProfilesByAnyNickname(query);
    if (mounted) {
      setState(() => _filteredProfiles = results);
    }
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final profiles = await _dbHelper.getAllProfiles();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
      _onSearchChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(context, 'manage_players')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Поиск по нику...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.white10,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildPlayerList(_filteredProfiles),
    );
  }

  Widget _buildPlayerList(List<PlayerProfile> list) {
    if (list.isEmpty) return const Center(child: Text("Пусто", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: p.isUser ? Colors.cyanAccent : Colors.deepPurpleAccent,
            child: Icon(p.isUser ? Icons.person : Icons.people, color: Colors.black),
          ),
          title: Text(
            p.mainNickname,
            style: TextStyle(fontWeight: p.isUser ? FontWeight.bold : FontWeight.normal),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ID: ${p.id}", style: const TextStyle(fontSize: 10, color: Colors.white24)),
              if (p.isUser) const Text("Это вы", style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
            ],
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => PlayerProfileScreen(profile: p)));
          },
        );
      },
    );
  }
}
