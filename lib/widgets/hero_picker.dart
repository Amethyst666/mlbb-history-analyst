import 'package:flutter/material.dart';
import '../utils/game_data.dart';
import '../utils/data_utils.dart';

class HeroPicker extends StatefulWidget {
  const HeroPicker({super.key});

  @override
  State<HeroPicker> createState() => _HeroPickerState();
}

class _HeroPickerState extends State<HeroPicker> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filtered = GameData.heroes.where((h) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return h.id.toString().contains(query) ||
          h.en.toLowerCase().contains(query) ||
          h.ru.toLowerCase().contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search Hero...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final hero = filtered[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(
                    context,
                    hero.assetName,
                  ), // Returning assetName (String) for compatibility
                  child: Column(
                    children: [
                      Expanded(
                        child: DataUtils.getHeroIcon(hero.id, radius: 30),
                      ),
                      Text(
                        hero.en,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
