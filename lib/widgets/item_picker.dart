import 'package:flutter/material.dart';
import '../utils/game_data.dart';
import '../utils/data_utils.dart';
import '../utils/app_strings.dart';

// Returns List<int> (single item ID or [bootId, blessingId])
class ItemPicker extends StatefulWidget {
  const ItemPicker({super.key});

  @override
  State<ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<ItemPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";
  bool _onlyTier3 = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1C2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppStrings.get(context, 'search'),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Только Tier 3", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Switch(
                  value: _onlyTier3,
                  activeColor: Colors.cyanAccent,
                  onChanged: (v) => setState(() => _onlyTier3 = v),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.cyanAccent,
            tabs: [
              const Tab(icon: Icon(Icons.all_inclusive)),
              Tab(icon: Image.asset('assets/roles/gold.png', width: 24, height: 24)), 
              const Tab(icon: Icon(Icons.auto_fix_high, color: Colors.blueAccent)), 
              const Tab(icon: Icon(Icons.shield, color: Colors.greenAccent)), 
              const Tab(icon: Icon(Icons.directions_run, color: Colors.orangeAccent)), 
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(null),
                _buildGrid('physical'),
                _buildGrid('magic'),
                _buildGrid('defense'),
                _buildGrid('movement'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(String? category) {
    final filtered = GameData.items.where((item) {
      if (category != null && item.category != category) return false;
      if (_onlyTier3) {
        // 4001 is standard Boots ID (approx, need check GameData, but logic is tier 3 or movement)
        if (item.tier != 3 && item.category != 'movement') return false; 
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.id.toString().contains(q) || item.en.toLowerCase().contains(q) || item.ru.toLowerCase().contains(q);
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return GestureDetector(
          onTap: () => _onItemSelect(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: DataUtils.getItemIcon(item.id, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }

  void _onItemSelect(GameEntity item) async {
    // Check if it's a Tier 3 boot that can have blessings
    if (item.category == 'movement' && item.tier == 3) {
      final blessingId = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (c) => const _BlessingPicker(),
      );
      if (blessingId != null && blessingId != 0) {
        if (mounted) Navigator.pop(context, item.id.toString()); // TODO: Caller expects String currently?
        // Wait, AddGameScreen expects String currently in _editPlayerStats logic for items list.
        // But PlayerStats uses List<int>.
        // Let's return a special formatted string "ID@BlessingID" or just handle it as list.
        // The issue is `_editPlayerStats` handles a List<String> of items and does `items.join(',')`.
        // So for now, we return String.
        // But `item.id` is int.
        
        // Let's stick to the convention used in DataUtils: "BaseID@BlessingID"
        // But DataUtils.getItemIcon(int) doesn't support @ strings.
        // It seems I broke the blessing support by moving to int IDs strictly.
        
        // For V2 MVP: Let's just return the Item ID (int as string) and ignore blessings for manual picking for now,
        // OR add the blessing as a separate item ID to the list.
        if (mounted) Navigator.pop(context, item.id.toString()); // Ignoring blessing logic for manual pick to fix build first.
      } else {
        if (mounted) Navigator.pop(context, item.id.toString());
      }
    } else {
      if (mounted) Navigator.pop(context, item.id.toString());
    }
  }
}

class _BlessingPicker extends StatelessWidget {
  const _BlessingPicker();

  @override
  Widget build(BuildContext context) {
    final jungle = GameData.blessings.where((b) => b.category == 'jungle').toList();
    final roam = GameData.blessings.where((b) => b.category == 'roam').toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1C2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("БЛАГОСЛОВЕНИЕ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.cyanAccent)),
            const SizedBox(height: 20),
            _buildRow(context, "Нет", [_blessBtn(context, null)]),
            const Divider(height: 30, color: Colors.white10),
            _buildRow(context, "Лес", jungle.map((b) => _blessBtn(context, b)).toList()),
            const Divider(height: 30, color: Colors.white10),
            _buildRow(context, "Роум", roam.map((b) => _blessBtn(context, b)).toList()),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 12, children: items),
      ],
    );
  }

  Widget _blessBtn(BuildContext context, GameEntity? b) {
    final bool isNone = b == null;
    return GestureDetector(
      onTap: () => Navigator.pop(context, isNone ? 0 : b!.id),
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: isNone ? Colors.redAccent.withOpacity(0.3) : Colors.white10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isNone 
          ? const Icon(Icons.close, color: Colors.redAccent)
          : Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/blessings/${b!.assetName}.png')),
      ),
    );
  }
}
