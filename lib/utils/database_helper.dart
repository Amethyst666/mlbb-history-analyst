import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';
import '../models/player_stats.dart';
import '../models/player_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final ChangeNotifier updateNotifier = ChangeNotifier();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'game_stats.db');
    return await openDatabase(
      path,
      version: 10, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        // ПРИНУДИТЕЛЬНАЯ МИГРАЦИЯ: если колонка потерялась при сбое версии
        var tableInfo = await db.rawQuery('PRAGMA table_info(player_profiles)');
        bool hasVerified = tableInfo.any((column) => column['name'] == 'is_verified');
        if (!hasVerified) {
          await db.execute('ALTER TABLE player_profiles ADD COLUMN is_verified INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        result TEXT, hero TEXT, kda TEXT, items TEXT, players TEXT,
        date TEXT, duration TEXT, role TEXT, spell TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE game_players(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER, nickname TEXT, hero TEXT, kda TEXT, gold TEXT,
        items TEXT, score TEXT, role TEXT, spell TEXT, profile_id INTEGER,
        is_enemy INTEGER, is_user INTEGER,
        FOREIGN KEY(game_id) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE player_profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        main_nickname TEXT,
        is_user INTEGER DEFAULT 0,
        is_verified INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE player_nicknames(
        nickname TEXT PRIMARY KEY,
        profile_id INTEGER,
        FOREIGN KEY(profile_id) REFERENCES player_profiles(id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 10) {
      var tableInfo = await db.rawQuery('PRAGMA table_info(player_profiles)');
      if (!tableInfo.any((column) => column['name'] == 'is_verified')) {
        await db.execute('ALTER TABLE player_profiles ADD COLUMN is_verified INTEGER DEFAULT 0');
      }
    }
  }

  Future<void> toggleVerification(int profileId, bool status) async {
    Database db = await database;
    await db.update('player_profiles', {'is_verified': status ? 1 : 0}, where: 'id = ?', whereArgs: [profileId]);
    updateNotifier.notifyListeners();
  }

  Future<int> getOrCreateProfile(String nickname, {bool isUser = false}) async {
    Database db = await database;
    final String cleanNick = nickname.trim();
    final List<Map<String, dynamic>> mapping = await db.query('player_nicknames', columns: ['profile_id'], where: 'LOWER(nickname) = ?', whereArgs: [cleanNick.toLowerCase()]);
    if (mapping.isNotEmpty) {
      int pid = mapping.first['profile_id'];
      if (isUser) await db.update('player_profiles', {'is_user': 1}, where: 'id = ?', whereArgs: [pid]);
      return pid;
    }
    int profileId = await db.insert('player_profiles', {'main_nickname': cleanNick, 'is_user': isUser ? 1 : 0, 'is_verified': 0});
    await db.insert('player_nicknames', {'nickname': cleanNick, 'profile_id': profileId}, conflictAlgorithm: ConflictAlgorithm.replace);
    return profileId;
  }

  Future<void> associateNicknameWithProfile(String nickname, int targetProfileId) async {
    Database db = await database;
    final String cleanNick = nickname.trim();
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> oldMapping = await txn.query('player_nicknames', columns: ['profile_id'], where: 'LOWER(nickname) = ?', whereArgs: [cleanNick.toLowerCase()]);
      int? oldProfileId;
      if (oldMapping.isNotEmpty) oldProfileId = oldMapping.first['profile_id'];
      await txn.insert('player_nicknames', {'nickname': cleanNick, 'profile_id': targetProfileId}, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.update('game_players', {'profile_id': targetProfileId}, where: 'LOWER(nickname) = ?', whereArgs: [cleanNick.toLowerCase()]);
      if (oldProfileId != null && oldProfileId != targetProfileId) {
        final List<Map<String, dynamic>> remainingNicks = await txn.query('player_nicknames', where: 'profile_id = ?', whereArgs: [oldProfileId]);
        if (remainingNicks.isEmpty) {
          await txn.delete('player_profiles', where: 'id = ? AND is_user = 0', whereArgs: [oldProfileId]);
        }
      }
    });
    updateNotifier.notifyListeners();
  }

  Future<void> mergeProfiles(int sourceProfileId, int targetProfileId) async {
    if (sourceProfileId == targetProfileId) return;
    Database db = await database;
    await db.transaction((txn) async {
      await txn.update('player_nicknames', {'profile_id': targetProfileId}, where: 'profile_id = ?', whereArgs: [sourceProfileId]);
      await txn.update('game_players', {'profile_id': targetProfileId}, where: 'profile_id = ?', whereArgs: [sourceProfileId]);
      final List<Map<String, dynamic>> sourceInfo = await txn.query('player_profiles', columns: ['is_user', 'is_verified'], where: 'id = ?', whereArgs: [sourceProfileId]);
      if (sourceInfo.isNotEmpty) {
        Map<String, dynamic> updates = {};
        if (sourceInfo.first['is_user'] == 1) updates['is_user'] = 1;
        if (sourceInfo.first['is_verified'] == 1) updates['is_verified'] = 1;
        
        if (updates.isNotEmpty) {
          await txn.update('player_profiles', updates, where: 'id = ?', whereArgs: [targetProfileId]);
        }
      }
      await txn.delete('player_profiles', where: 'id = ?', whereArgs: [sourceProfileId]);
    });
    updateNotifier.notifyListeners();
  }

  Future<void> detachNicknameFromProfile(String nickname) async {
    Database db = await database;
    final String cleanNick = nickname.trim();
    await db.transaction((txn) async {
      int newProfileId = await txn.insert('player_profiles', {'main_nickname': cleanNick, 'is_user': 0, 'is_verified': 0});
      await txn.update('player_nicknames', {'profile_id': newProfileId}, where: 'LOWER(nickname) = ?', whereArgs: [cleanNick.toLowerCase()]);
      await txn.update('game_players', {'profile_id': newProfileId}, where: 'LOWER(nickname) = ?', whereArgs: [cleanNick.toLowerCase()]);
    });
    updateNotifier.notifyListeners();
  }

  Future<void> updateMainNickname(int profileId, String newMainName) async {
    Database db = await database;
    await db.update('player_profiles', {'main_nickname': newMainName.trim()}, where: 'id = ?', whereArgs: [profileId]);
    updateNotifier.notifyListeners();
  }

  Future<List<PlayerProfile>> getAllProfiles() async {
    Database db = await database;
    // ЯВНОЕ ПЕРЕЧИСЛЕНИЕ КОЛОНОК для предотвращения CursorWindow ошибки
    final maps = await db.rawQuery('''
      SELECT id, main_nickname, is_user, is_verified 
      FROM player_profiles 
      WHERE (id IN (SELECT DISTINCT profile_id FROM player_nicknames) OR is_user = 1)
      GROUP BY LOWER(main_nickname)
      ORDER BY id DESC
    ''');
    return maps.map((m) => PlayerProfile.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> getOtherMainNicknames(int excludeId) async {
    Database db = await database;
    return await db.query('player_profiles', columns: ['id', 'main_nickname'], where: 'id != ?', whereArgs: [excludeId], orderBy: 'main_nickname ASC');
  }

  Future<List<String>> getNicknamesForProfile(int profileId) async {
    Database db = await database;
    final maps = await db.query('player_nicknames', columns: ['nickname'], where: 'profile_id = ?', whereArgs: [profileId]);
    return maps.map((m) => m['nickname'] as String).toList();
  }

  Future<List<String>> getAllUniqueNicknames() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('player_nicknames', columns: ['nickname'], orderBy: 'nickname ASC');
    return maps.map((e) => e['nickname'] as String).toList();
  }

  Future<int> deleteUnusedProfiles() async {
    Database db = await database;
    int count = 0;
    await db.transaction((txn) async {
      count = await txn.rawDelete('''
        DELETE FROM player_profiles 
        WHERE is_user = 0 AND is_verified = 0
        AND id NOT IN (SELECT DISTINCT profile_id FROM game_players WHERE profile_id IS NOT NULL)
      ''');
      await txn.rawDelete('DELETE FROM player_nicknames WHERE profile_id NOT IN (SELECT id FROM player_profiles)');
    });
    updateNotifier.notifyListeners();
    return count;
  }

  Future<List<PlayerStats>> getPlayersForGame(int gameId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT gp.id, gp.nickname, gp.hero, gp.kda, gp.gold, gp.items, gp.score, gp.role, gp.spell, 
             gp.is_enemy, gp.is_user, pp.main_nickname as profile_main_name, 
             pp.is_user as profile_is_user, pp.is_verified as profile_is_verified
      FROM game_players gp
      LEFT JOIN player_profiles pp ON gp.profile_id = pp.id
      WHERE gp.game_id = ?
    ''', [gameId]);
    return List.generate(maps.length, (i) {
      var map = Map<String, dynamic>.from(maps[i]);
      if (map['profile_main_name'] != null) map['nickname'] = map['profile_main_name'];
      bool isUser = (map['profile_is_user'] == 1) || (map['is_user'] == 1);
      map['is_user'] = isUser ? 1 : 0;
      return PlayerStats.fromMap(map);
    });
  }

  Future<int> _getOrCreateProfileTxn(Transaction txn, String nickname, {bool? forceIsUser}) async {
    final String cleanNick = nickname.trim();
    final List<Map<String, dynamic>> mapping = await txn.query('player_nicknames', columns: ['profile_id'], where: 'LOWER(nickname) = ?', whereArgs: [cleanNick.toLowerCase()]);
    if (mapping.isNotEmpty) {
      int pid = mapping.first['profile_id'];
      if (forceIsUser == true) await txn.update('player_profiles', {'is_user': 1}, where: 'id = ?', whereArgs: [pid]);
      return pid;
    }
    int profileId = await txn.insert('player_profiles', {'main_nickname': cleanNick, 'is_user': forceIsUser == true ? 1 : 0, 'is_verified': 0});
    await txn.insert('player_nicknames', {'nickname': cleanNick, 'profile_id': profileId});
    return profileId;
  }

  Future<int> insertGameWithPlayers(GameStats game, List<PlayerStats> players) async {
    Database db = await database;
    int id = await db.transaction((txn) async {
      for (int i = 0; i < players.length; i++) {
        int pid = await _getOrCreateProfileTxn(txn, players[i].nickname, forceIsUser: players[i].isUser);
        players[i] = players[i].copyWith(profileId: pid);
      }
      for (int i = 0; i < players.length; i++) {
        final List<Map<String, dynamic>> pInfo = await txn.query('player_profiles', columns: ['is_user'], where: 'id = ?', whereArgs: [players[i].profileId]);
        if (pInfo.isNotEmpty && pInfo.first['is_user'] == 1) players[i] = players[i].copyWith(isUser: true);
      }
      int gameId = await txn.insert('games', game.toMap());
      for (var p in players) {
        var map = p.toMap(); map['game_id'] = gameId;
        await txn.insert('game_players', map);
      }
      return gameId;
    });
    await fixLegacyGames(); 
    return id;
  }

  Future<void> updateGameWithPlayers(GameStats game, List<PlayerStats> players) async {
    if (game.id == null) return;
    Database db = await database;
    await db.transaction((txn) async {
      for (int i = 0; i < players.length; i++) {
        int pid = await _getOrCreateProfileTxn(txn, players[i].nickname, forceIsUser: players[i].isUser);
        players[i] = players[i].copyWith(profileId: pid);
      }
      for (int i = 0; i < players.length; i++) {
        final List<Map<String, dynamic>> pInfo = await txn.query('player_profiles', columns: ['is_user'], where: 'id = ?', whereArgs: [players[i].profileId]);
        if (pInfo.isNotEmpty && pInfo.first['is_user'] == 1) players[i] = players[i].copyWith(isUser: true);
      }
      await txn.update('games', game.toMap(), where: 'id = ?', whereArgs: [game.id]);
      await txn.delete('game_players', where: 'game_id = ?', whereArgs: [game.id]);
      for (var p in players) {
        var map = p.toMap(); map['game_id'] = game.id;
        await txn.insert('game_players', map);
      }
    });
    await fixLegacyGames();
  }

  Future<List<GameStats>> getGames() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('games', orderBy: 'date DESC');
    return maps.map((m) => GameStats.fromMap(m)).toList();
  }

  Future<void> deleteGame(int id) async {
    Database db = await database;
    await db.delete('game_players', where: 'game_id = ?', whereArgs: [id]);
    await db.delete('games', where: 'id = ?', whereArgs: [id]);
    updateNotifier.notifyListeners();
  }

  Future<List<GameStats>> getGamesByPlayer(String playerName) async {
    Database db = await database;
    final List<Map<String, dynamic>> playerMatches = await db.rawQuery('''
      SELECT DISTINCT game_id FROM game_players 
      WHERE profile_id IN (SELECT profile_id FROM player_nicknames WHERE LOWER(nickname) LIKE ?)
    ''', ['%${playerName.toLowerCase()}%']);
    if (playerMatches.isEmpty) return [];
    String ids = playerMatches.map((m) => m['game_id']).join(',');
    return (await db.rawQuery('SELECT * FROM games WHERE id IN ($ids) ORDER BY date DESC')).map((m) => GameStats.fromMap(m)).toList();
  }

  Future<List<GameStats>> getGamesByHero(String heroName) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('games', where: 'hero LIKE ?', whereArgs: ['%$heroName%'], orderBy: 'date DESC');
    return maps.map((m) => GameStats.fromMap(m)).toList();
  }

  Future<void> fixLegacyGames() async {
    Database db = await database;
    final prefs = await SharedPreferences.getInstance();
    final String? userNick = prefs.getString('userNickname')?.toLowerCase().trim();
    Set<int> userPids = {};
    if (userNick != null && userNick.isNotEmpty) {
      final List<Map<String, dynamic>> mapping = await db.query('player_nicknames', columns: ['profile_id'], where: 'LOWER(nickname) = ?', whereArgs: [userNick]);
      for (var m in mapping) userPids.add(m['profile_id'] as int);
    }
    final List<Map<String, dynamic>> youMapping = await db.query('player_nicknames', columns: ['profile_id'], where: 'LOWER(nickname) = ?', whereArgs: ['you']);
    for (var m in youMapping) userPids.add(m['profile_id'] as int);
    final List<Map<String, dynamic>> markedProfiles = await db.query('player_profiles', columns: ['id'], where: 'is_user = 1');
    for (var m in markedProfiles) userPids.add(m['id'] as int);
    if (userPids.isEmpty) return;
    await db.transaction((txn) async {
      String idList = userPids.join(',');
      await txn.update('player_profiles', {'is_user': 1}, where: "id IN ($idList)");
      await txn.update('game_players', {'is_user': 1}, where: "profile_id IN ($idList)");
      final List<Map<String, dynamic>> games = await txn.query('games');
      for (var g in games) {
        int gameId = g['id'];
        final List<Map<String, dynamic>> userInGame = await txn.query('game_players', columns: ['hero', 'kda', 'items', 'role', 'spell'], where: 'game_id = ? AND is_user = 1', whereArgs: [gameId]);
        if (userInGame.isNotEmpty) {
          final p = userInGame.first;
          await txn.update('games', {'hero': p['hero'], 'kda': p['kda'], 'items': p['items'], 'role': p['role'] ?? 'unknown', 'spell': p['spell'] ?? 'none'}, where: 'id = ?', whereArgs: [gameId]);
        } else {
          await txn.update('games', {'hero': 'none'}, where: 'id = ?', whereArgs: [gameId]);
        }
      }
    });
    updateNotifier.notifyListeners();
  }
}
