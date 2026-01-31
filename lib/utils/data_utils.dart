import 'package:flutter/material.dart';
import 'game_data.dart';

class DataUtils {
  static String getLocalizedHeroName(String heroId, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final entity = GameData.heroes.firstWhere(
        (e) => e.id == heroId,
        orElse: () => GameEntity(id: heroId, en: heroId, ru: heroId),
      );
      return locale == 'ru' ? entity.ru : entity.en;
    } catch (e) {
      return heroId;
    }
  }

  static String getHeroIdByName(String name) {
    final lower = name.toLowerCase();
    try {
      return GameData.heroes.firstWhere(
        (e) => e.en.toLowerCase() == lower || e.ru.toLowerCase() == lower || e.id == lower
      ).id;
    } catch (e) {
      return name; 
    }
  }

  static Widget getHeroIcon(String heroId, {double radius = 15}) {
    final heroName = heroId.isNotEmpty ? heroId[0].toUpperCase() : "?";
    final assetId = heroId.toLowerCase();
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: ClipOval(
        child: Image.asset(
          'assets/heroes/$assetId.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text(
            heroName,
            style: TextStyle(color: Colors.white, fontSize: radius * 0.8),
          ),
        ),
      ),
    );
  }

  static Widget getRoleIcon(String role, {double size = 12}) {
    if (role == 'unknown') return const SizedBox.shrink();

    return Image.asset(
      'assets/roles/$role.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        IconData icon = Icons.help_outline;
        Color color = Colors.grey;
        if (role == 'jungle') { icon = Icons.forest; color = Colors.green; }
        else if (role == 'roam') { icon = Icons.flag; color = Colors.blue; }
        else if (role == 'gold') { icon = Icons.monetization_on; color = Colors.amber; }
        else if (role == 'mid') { icon = Icons.flash_on; color = Colors.purpleAccent; }
        else if (role == 'exp') { icon = Icons.shield; color = Colors.brown; }
        return Icon(icon, size: size, color: color);
      },
    );
  }

  static String getLocalizedSpellName(String spellId, BuildContext context) {
    if (spellId == 'none') return "";
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final entity = GameData.spells.firstWhere(
        (e) => e.id == spellId,
        orElse: () => GameEntity(id: spellId, en: spellId, ru: spellId),
      );
      return locale == 'ru' ? entity.ru : entity.en;
    } catch (e) {
      return spellId;
    }
  }

  static Widget getSpellIcon(String spellId, {double size = 30}) {
    if (spellId == 'none') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black12,
          border: Border.all(color: Colors.grey, width: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.flash_on, size: size * 0.6, color: Colors.grey),
      );
    }

    return ClipOval(
      child: Image.asset(
        'assets/spells/$spellId.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Colors.deepPurpleAccent,
          child: Center(
            child: Text(spellId.isNotEmpty ? spellId[0].toUpperCase() : "?", 
            style: TextStyle(color: Colors.white, fontSize: size * 0.5)),
          ),
        ),
      ),
    );
  }

  static String getLocalizedItemName(String fullItemId, BuildContext context) {
    if (fullItemId.isEmpty) return "";
    final locale = Localizations.localeOf(context).languageCode;
    final parts = fullItemId.split('@');
    final baseId = parts[0];
    final blessingId = parts.length > 1 ? parts[1] : null;

    String baseName = baseId;
    try {
      final entity = GameData.items.firstWhere(
        (e) => e.id == baseId,
        orElse: () => GameEntity(id: baseId, en: baseId, ru: baseId),
      );
      baseName = locale == 'ru' ? entity.ru : entity.en;
    } catch (_) {}

    if (blessingId != null) {
      String blessingName = blessingId;
      try {
        final bEntity = GameData.blessings.firstWhere(
          (e) => e.id == blessingId,
          orElse: () => GameEntity(id: blessingId, en: blessingId, ru: blessingId),
        );
        blessingName = locale == 'ru' ? bEntity.ru : bEntity.en;
      } catch (_) {}
      return "$baseName ($blessingName)";
    }
    return baseName;
  }

  static Widget getItemIcon(String fullItemId, {double size = 40, BoxFit fit = BoxFit.cover}) {
    if (fullItemId.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black12,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.add, size: size * 0.5, color: Colors.grey),
      );
    }

    final parts = fullItemId.split('@');
    final baseId = parts[0];
    final blessingId = parts.length > 1 ? parts[1] : null;

    Widget iconWidget = Image.asset(
      'assets/items/$baseId.png',
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Check blessings folder as fallback
        return Image.asset(
          'assets/blessings/$baseId.png',
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            final int hash = baseId.codeUnits.fold(0, (prev, element) => prev + element);
            final Color color = Colors.primaries[hash % Colors.primaries.length];
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  baseId.isNotEmpty ? baseId[0].toUpperCase() : "?",
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: size * 0.5),
                ),
              ),
            );
          },
        );
      },
    );

    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(4), child: iconWidget),
        if (blessingId != null)
          Positioned(right: 0, bottom: 0, child: _buildBlessingIndicator(blessingId, size * 0.45)),
      ],
    );
  }

  static Widget _buildBlessingIndicator(String blessingId, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/blessings/$blessingId.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            Color color = Colors.grey;
            IconData icon = Icons.circle;
            if (blessingId.contains('flame')) { color = Colors.redAccent; icon = Icons.local_fire_department; }
            else if (blessingId.contains('ice')) { color = Colors.lightBlueAccent; icon = Icons.ac_unit; }
            else if (blessingId.contains('bloody')) { color = Colors.purpleAccent; icon = Icons.bloodtype; }
            else if (blessingId.contains('conceal')) { color = Colors.grey[400]!; icon = Icons.visibility_off; }
            else if (blessingId.contains('encourage')) { color = Colors.amber; icon = Icons.arrow_upward; }
            else if (blessingId.contains('favor')) { color = Colors.greenAccent; icon = Icons.favorite; }
            else if (blessingId.contains('dire_hit')) { color = Colors.deepOrange; icon = Icons.flash_on; }
            return Center(child: Icon(icon, size: size * 0.7, color: color));
          },
        ),
      ),
    );
  }
}
