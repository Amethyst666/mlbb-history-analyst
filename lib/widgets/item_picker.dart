import 'package:flutter/material.dart';
import '../utils/game_data.dart';
import '../utils/data_utils.dart';
import '../utils/app_strings.dart';

class ItemPicker extends StatefulWidget {
  const ItemPicker({super.key});

  @override
  State<ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<ItemPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";

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
            padding: const EdgeInsets.all(12.0),
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
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.cyanAccent,
            tabs: [
              const Tab(icon: Icon(Icons.all_inclusive)),
              Tab(icon: Image.asset('assets/roles/gold.png', width: 24, height: 24)), // Physical
              const Tab(icon: Icon(Icons.auto_fix_high, color: Colors.blueAccent)), // Magic
              const Tab(icon: Icon(Icons.shield, color: Colors.greenAccent)), // Defense
              const Tab(icon: Icon(Icons.directions_run, color: Colors.orangeAccent)), // Movement
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
      // Filter: Only Tier 3 OR basic boots OR any movement item
      if (item.tier != 3 && item.id != 'boots' && item.category != 'movement') return false; 
      
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.id.contains(q) || item.en.toLowerCase().contains(q) || item.ru.toLowerCase().contains(q);
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
    if (item.category == 'movement' && item.id != 'boots') {
      final blessing = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (c) => const _BlessingPicker(),
      );
      if (blessing != null && blessing != 'none') {
        Navigator.pop(context, "${item.id}@$blessing");
      } else if (blessing == 'none') {
        Navigator.pop(context, item.id);
      }
    } else {
      Navigator.pop(context, item.id);
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
      onTap: () => Navigator.pop(context, isNone ? 'none' : b.id),
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: isNone ? Colors.redAccent.withOpacity(0.3) : Colors.white10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isNone 
          ? const Icon(Icons.close, color: Colors.redAccent)
          : Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/blessings/${b.id}.png')),
      ),
    );
  }
}
