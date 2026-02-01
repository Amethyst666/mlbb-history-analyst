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

class _PlayersManagementScreenState extends State<PlayersManagementScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;
  
  List<PlayerProfile> _profiles = [];
  List<PlayerProfile> _filteredProfiles = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfiles();
    _searchController.addListener(_onSearchChanged);
    _dbHelper.updateNotifier.addListener(_loadProfiles);
  }

  @override
  void dispose() {
    _dbHelper.updateNotifier.removeListener(_loadProfiles);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ОБНОВЛЕНО: Поиск по всем именам в БД
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

  void _showAliasManagementDialog(PlayerProfile profile) async {
    List<String> currentNicks = await _dbHelper.getNicknamesForProfile(profile.id!);
    List<Map<String, dynamic>> searchResults = [];
    
    final newAliasController = TextEditingController();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (stCtx, setModalState) {
        
        // Внутренняя функция для обновления списка внутри модалки
        Future<void> refreshLocalState() async {
          final updatedNicks = await _dbHelper.getNicknamesForProfile(profile.id!);
          final input = newAliasController.text.trim();
          List<Map<String, dynamic>> results = [];
          if (input.isNotEmpty) {
            results = await _dbHelper.searchOtherProfilesForMerge(profile.id!, input);
          }
          setModalState(() {
            currentNicks = updatedNicks;
            searchResults = results;
          });
        }

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Алиасы: ${profile.mainNickname}", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.cyanAccent)),
              const SizedBox(height: 15),
              
              const Text("Текущие ники (нажмите для выбора главного):", style: TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: currentNicks.map((n) {
                  bool isMain = n.toLowerCase() == profile.mainNickname.toLowerCase();
                  bool canDelete = currentNicks.length > 1;

                  return InputChip(
                    label: Text(n),
                    labelStyle: TextStyle(color: isMain ? Colors.black : Colors.white, fontWeight: isMain ? FontWeight.bold : FontWeight.normal),
                    backgroundColor: isMain ? Colors.cyanAccent : Colors.white10,
                    selected: isMain,
                    selectedColor: Colors.cyanAccent,
                    showCheckmark: false,
                    onPressed: () async {
                      if (!isMain) {
                        await _dbHelper.updateMainNickname(profile.id!, n);
                        profile.mainNickname = n;
                        await refreshLocalState();
                      }
                    },
                    onDeleted: (canDelete && !isMain) ? () async {
                      await _dbHelper.detachNicknameFromProfile(n);
                      await refreshLocalState(); // НЕ ЗАКРЫВАЕМ, а обновляем
                    } : null,
                    deleteIcon: Icon(Icons.cancel, size: 16, color: isMain ? Colors.black54 : Colors.white54),
                  );
                }).toList(),
              ),
              
              const Divider(height: 30, color: Colors.white24),
              const Text("Присоединить игрока или новый ник:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: newAliasController,
                onChanged: (v) => refreshLocalState(),
                decoration: InputDecoration(
                  hintText: "Поиск игрока или ввод ника...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
                    onPressed: () async {
                      final val = newAliasController.text.trim();
                      if (val.isNotEmpty) {
                        await _dbHelper.associateNicknameWithProfile(val, profile.id!);
                        newAliasController.clear();
                        await refreshLocalState(); // НЕ ЗАКРЫВАЕМ
                      }
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: searchResults.isEmpty && newAliasController.text.isNotEmpty
                  ? const Center(child: Text("Других игроков с таким ником не найдено", style: TextStyle(fontSize: 12, color: Colors.white24)))
                  : ListView.separated(
                      itemCount: searchResults.length,
                      separatorBuilder: (c, i) => const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (c, i) {
                        final other = searchResults[i];
                        return ListTile(
                          title: Text(other['main_nickname']),
                          subtitle: const Text("Объединить профили", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          trailing: const Icon(Icons.merge_type, color: Colors.cyanAccent, size: 20),
                          onTap: () async {
                            await _dbHelper.mergeProfiles(other['id'], profile.id!);
                            newAliasController.clear();
                            await refreshLocalState(); // НЕ ЗАКРЫВАЕМ
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(context, 'manage_players')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Поиск по нику или алиасу...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.white10,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.cyanAccent,
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "ВСЕ"),
                  Tab(text: "ВЕРИФИЦИРОВАННЫЕ"),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildPlayerList(_filteredProfiles),
              _buildPlayerList(_filteredProfiles.where((p) => p.isVerified).toList()),
            ],
          ),
    );
  }

  Widget _buildPlayerList(List<PlayerProfile> list) {
    if (list.isEmpty) return const Center(child: Text("Пусто", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: p.isUser ? Colors.cyanAccent : Colors.deepPurpleAccent,
                child: Icon(p.isUser ? Icons.person : Icons.people, color: Colors.black),
              ),
              if (p.isVerified)
                const Positioned(
                  bottom: 0, right: 0,
                  child: CircleAvatar(
                    radius: 8, backgroundColor: Colors.black,
                    child: Icon(Icons.verified, color: Colors.cyanAccent, size: 12),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  p.mainNickname,
                  style: TextStyle(fontWeight: p.isUser ? FontWeight.bold : FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (p.isVerified) const SizedBox(width: 5),
              if (p.isVerified) const Icon(Icons.verified, color: Colors.cyanAccent, size: 16),
            ],
          ),
          subtitle: p.isUser ? const Text("Это вы", style: TextStyle(color: Colors.cyanAccent, fontSize: 12)) : null,
          trailing: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white54),
            onPressed: () => _showAliasManagementDialog(p),
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => PlayerProfileScreen(profile: p)));
          },
        );
      },
    );
  }
}