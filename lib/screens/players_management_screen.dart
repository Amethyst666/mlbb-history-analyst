import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../utils/database_helper.dart';
import '../utils/app_strings.dart';
import 'player_profile_screen.dart';

class PlayersManagementScreen extends StatefulWidget {
  const PlayersManagementScreen({super.key});

  @override
  State<PlayersManagementScreen> createState() =>
      _PlayersManagementScreenState();
}

class _PlayersManagementScreenState extends State<PlayersManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<PlayerProfile> _profiles = [];
  List<PlayerProfile> _filteredProfiles = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _sortBy = 'last_match';
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _searchController.addListener(_onSearchChanged);
    _dbHelper.updateNotifier.addListener(_loadProfiles);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore && _searchController.text.trim().isEmpty) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _dbHelper.updateNotifier.removeListener(_loadProfiles);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _filteredProfiles = _profiles);
      return;
    }

    final results = await _dbHelper.searchProfilesByAnyNickname(query, sortBy: _sortBy);
    if (mounted) {
      setState(() => _filteredProfiles = results);
    }
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final profiles = await _dbHelper.getAllProfiles(limit: _limit, offset: 0, sortBy: _sortBy);
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _isLoading = false;
        _hasMore = profiles.length == _limit;
      });
      _onSearchChanged();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final moreProfiles = await _dbHelper.getAllProfiles(limit: _limit, offset: _profiles.length, sortBy: _sortBy);
    if (mounted) {
      setState(() {
        _profiles.addAll(moreProfiles);
        _isLoadingMore = false;
        _hasMore = moreProfiles.length == _limit;
        if (_searchController.text.trim().isEmpty) {
          _filteredProfiles = _profiles;
        }
      });
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('По последней игре'),
                trailing: _sortBy == 'last_match' ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                onTap: () {
                  setState(() => _sortBy = 'last_match');
                  Navigator.pop(context);
                  _loadProfiles();
                },
              ),
              ListTile(
                title: const Text('По алфавиту'),
                trailing: _sortBy == 'alpha' ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                onTap: () {
                  setState(() => _sortBy = 'alpha');
                  Navigator.pop(context);
                  _loadProfiles();
                },
              ),
              ListTile(
                title: const Text('По количеству игр'),
                trailing: _sortBy == 'games_count' ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                onTap: () {
                  setState(() => _sortBy = 'games_count');
                  Navigator.pop(context);
                  _loadProfiles();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(context, 'manage_players')),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.get(context, 'search_nick_hint'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
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
    if (list.isEmpty)
      return Center(
        child: Text(
          AppStrings.get(context, 'empty'),
          style: const TextStyle(color: Colors.grey),
        ),
      );
    return ListView.builder(
      controller: _scrollController,
      itemCount: list.length + (_hasMore && _searchController.text.trim().isEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == list.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final p = list[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: p.isUser
                ? Colors.cyanAccent
                : Colors.deepPurpleAccent,
            child: Icon(
              p.isUser ? Icons.person : Icons.people,
              color: Colors.black,
            ),
          ),
          title: Text(
            p.pinnedAlias ?? p.mainNickname,
            style: TextStyle(
              fontWeight: p.isUser ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.pinnedAlias != null)
                Text(
                  p.mainNickname,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              Text(
                "ID: ${p.id}",
                style: const TextStyle(fontSize: 10, color: Colors.white24),
              ),
              if (p.isUser)
                Text(
                  AppStrings.get(context, 'you_label'),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => PlayerProfileScreen(profile: p),
              ),
            );
          },
        );
      },
    );
  }
}
