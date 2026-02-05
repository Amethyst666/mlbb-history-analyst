import 'package:flutter/material.dart';
import '../utils/game_data.dart';
import '../utils/data_utils.dart';
import '../utils/app_strings.dart';

class AssetGalleryScreen extends StatelessWidget {
  const AssetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get(context, 'asset_gallery')),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: AppStrings.get(context, 'heroes_tab')),
              Tab(text: AppStrings.get(context, 'items_tab')),
              Tab(text: AppStrings.get(context, 'roles_tab')),
              Tab(text: AppStrings.get(context, 'blessings_tab')),
              Tab(text: AppStrings.get(context, 'spells_tab')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHeroGrid(context),
            _buildItemGrid(context),
            _buildRoleGrid(context),
            _buildBlessingGrid(context),
            _buildSpellGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroGrid(BuildContext context) {
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
            Text(
              DataUtils.getLocalizedHeroName(hero.id, context),
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemGrid(BuildContext context) {
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
            Text(
              DataUtils.getLocalizedItemName(item.id, context),
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleGrid(BuildContext context) {
    final roles = ['exp', 'jungle', 'mid', 'gold', 'roam'];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: roles
            .map(
              (role) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DataUtils.getRoleIcon(role, size: 60),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DataUtils.getLocalizedRoleName(role, context).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBlessingGrid(BuildContext context) {
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
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/blessings/${b.assetName}.png',
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50, color: Colors.red),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DataUtils.getLocalizedBlessingName(b.id, context),
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpellGrid(BuildContext context) {
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
            Text(
              DataUtils.getLocalizedSpellName(spell.id, context),
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        );
      },
    );
  }
}
