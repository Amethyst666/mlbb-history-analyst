import 'package:flutter/material.dart';
import 'game_data.dart';
import 'app_strings.dart';

class DataUtils {
  static int getHeroIdByName(String name) {
    final lower = name.toLowerCase();
    try {
      return GameData.heroes.firstWhere(
        (e) => e.en.toLowerCase() == lower || e.ru.toLowerCase() == lower || e.assetName.toLowerCase() == lower
      ).id;
    } catch (e) {
      return 0; 
    }
  }

  static String getLocalizedHeroName(int heroId, BuildContext context) {
    if (heroId == 0) return AppStrings.get(context, 'unknown');
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final entity = GameData.getHero(heroId);
      if (entity == null) return "Hero $heroId";
      return locale == 'ru' ? entity.ru : entity.en;
    } catch (e) {
      return "Hero $heroId";
    }
  }

  static String getLocalizedRoleName(String role, BuildContext context) {
    if (role == 'unknown' || role == 'none') return AppStrings.get(context, 'unknown');
    
    // Map internal role IDs to AppStrings keys if necessary
    String key = role;
    if (role == 'gold') key = 'gold_lane';
    if (role == 'exp') key = 'exp_lane';
    
    return AppStrings.get(context, key);
  }

  static Widget getHeroIcon(int heroId, {double radius = 15}) {
    final entity = GameData.getHero(heroId);
    final String assetName = entity?.assetName ?? 'unknown';
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: ClipOval(
        child: Image.asset(
          'assets/heroes/$assetName.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text(
            "?",
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

  static String getLocalizedSpellName(int spellId, BuildContext context) {
    if (spellId == 0) return "";
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final entity = GameData.getSpell(spellId);
      if (entity == null) return "Spell $spellId";
      return locale == 'ru' ? entity.ru : entity.en;
    } catch (e) {
      return "Spell $spellId";
    }
  }

  static Widget getSpellIcon(int spellId, {double size = 30}) {
    if (spellId == 0) {
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

    final entity = GameData.getSpell(spellId);
    final String assetName = entity?.assetName ?? 'unknown';

    return ClipOval(
      child: Image.asset(
        'assets/spells/$assetName.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Try blessings folder
          return Image.asset(
            'assets/blessings/$assetName.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              color: Colors.deepPurpleAccent,
              child: Center(
                child: Text("?", 
                style: TextStyle(color: Colors.white, fontSize: size * 0.5)),
              ),
            ),
          );
        },
      ),
    );
  }

  static String getLocalizedItemName(int itemId, BuildContext context) {
    if (itemId == 0) return "";
    final locale = Localizations.localeOf(context).languageCode;
    
    // TODO: Handle combined item IDs (e.g. Boots + Blessing) here
    
    try {
      final entity = GameData.getItem(itemId);
      if (entity == null) return "Item $itemId";
      return locale == 'ru' ? entity.ru : entity.en;
    } catch (_) {
      return "Item $itemId";
    }
  }

  static Widget getItemIcon(int itemId, {double size = 40, BoxFit fit = BoxFit.cover}) {
    if (itemId == 0) {
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

    final entity = GameData.getItem(itemId);
    final String assetName = entity?.assetName ?? itemId.toString();

    Widget baseIcon = Image.asset(
      'assets/items/$assetName.png',
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        final int hash = itemId;
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
              "?",
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: size * 0.5),
            ),
          ),
        );
      },
    );

    // If item has a blessing (Roam/Jungle), overlay it
    if (entity?.blessingId != null) {
       final blessingEntity = GameData.getSpell(entity!.blessingId!);
       if (blessingEntity != null) {
         return Stack(
           children: [
             ClipRRect(borderRadius: BorderRadius.circular(4), child: baseIcon),
             Positioned(
               bottom: 0,
               right: 0,
               child: Container(
                 width: size * 0.5,
                 height: size * 0.5,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   border: Border.all(color: Colors.white, width: 0.2),
                   color: Colors.black54,
                 ),
                 child: ClipOval(
                   child: Image.asset(
                    'assets/blessings/${blessingEntity.assetName}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => const Icon(Icons.star, size: 8, color: Colors.amber),
                   ),
                 ),
               ),
             ),
           ],
         );
       }
    }

    return ClipRRect(borderRadius: BorderRadius.circular(4), child: baseIcon);
  }

  static Widget getMedalIcon(int score, {double size = 20}) {
    if (score == 0) return const SizedBox.shrink();
    
    int medalId = score;
    String assetName = '';
    if (medalId == 1) assetName = 'mvp';
    else if (medalId == 2) assetName = 'gold_medal';
    else if (medalId == 3) assetName = 'silver_medal';
    else if (medalId == 4) assetName = 'bronze_medal';
    
    if (assetName.isNotEmpty) {
      return Image.asset(
        'assets/medals/$assetName.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Text(
          "$score", 
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: size * 0.8)
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  static int getDisplaySpellId(int spellId, List<int> itemIds) {
    if (spellId != 20020) return spellId; // Only upgrade Retribution (20020)

    for (var itemId in itemIds) {
      final item = GameData.getItem(itemId);
      if (item?.blessingId != null) {
        // If it's a jungle blessing (20001-20003), upgrade the spell icon
        if (item!.blessingId! >= 20001 && item.blessingId! <= 20003) {
          return item.blessingId!;
        }
      }
    }
    return spellId;
  }
}
