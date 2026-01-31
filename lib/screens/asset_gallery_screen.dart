import 'package:flutter/material.dart';
import '../utils/game_data.dart';
import '../utils/data_utils.dart';

class AssetGalleryScreen extends StatelessWidget {
  const AssetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Asset Gallery'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Heroes'),
              Tab(text: 'Items'),
              Tab(text: 'Roles'),
              Tab(text: 'Blessings'),
              Tab(text: 'Spells'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHeroGrid(),
            _buildItemGrid(),
            _buildRoleGrid(),
            _buildBlessingGrid(),
            _buildSpellGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: GameData.heroes.length,
      itemBuilder: (context, index) {
        final hero = GameData.heroes[index];
        return Column(
          children: [
            DataUtils.getHeroIcon(hero.id, radius: 30),
            const SizedBox(height: 4),
            Text(hero.en, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center, maxLines: 1),
          ],
        );
      },
    );
  }

  Widget _buildItemGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.8,
      ),
      itemCount: GameData.items.length,
      itemBuilder: (context, index) {
        final item = GameData.items[index];
        return Column(
          children: [
            DataUtils.getItemIcon(item.id, size: 40),
            const SizedBox(height: 4),
            Text(item.en, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, maxLines: 1),
          ],
        );
      },
    );
  }

  Widget _buildRoleGrid() {
    final roles = ['exp', 'jungle', 'mid', 'gold', 'roam'];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: roles.map((role) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
              child: DataUtils.getRoleIcon(role, size: 60),
            ),
            const SizedBox(height: 8),
            Text(role.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildBlessingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: GameData.blessings.length,
      itemBuilder: (context, index) {
        final b = GameData.blessings[index];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
              child: Image.asset(
                'assets/blessings/${b.id}.png',
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.red),
              ),
            ),
            const SizedBox(height: 4),
            Text(b.en, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ],
        );
      },
    );
  }

  Widget _buildSpellGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: GameData.spells.length,
      itemBuilder: (context, index) {
        final spell = GameData.spells[index];
        return Column(
          children: [
            DataUtils.getSpellIcon(spell.id, size: 50),
            const SizedBox(height: 4),
            Text(spell.en, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center, maxLines: 1),
          ],
        );
      },
    );
  }
}
