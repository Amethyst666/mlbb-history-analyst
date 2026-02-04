import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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
      version: 21, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        result TEXT, hero TEXT, kda TEXT, items TEXT, players TEXT,
        date TEXT, duration TEXT, role TEXT, spell TEXT,
        match_id TEXT, score INTEGER DEFAULT 0,
        end_date TEXT
      )
    ''');
    await db.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_games_match_id ON games(match_id) WHERE match_id IS NOT NULL AND match_id != ''");

    await db.execute('''
      CREATE TABLE game_players(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER, nickname TEXT, hero TEXT, kda TEXT, gold TEXT,
        items TEXT, score TEXT, role TEXT, spell TEXT, profile_id INTEGER,
        is_enemy INTEGER, is_user INTEGER,
        level INTEGER DEFAULT 0,
        gold_lane INTEGER DEFAULT 0,
        gold_kill INTEGER DEFAULT 0,
        gold_jungle INTEGER DEFAULT 0,
        gold_tower INTEGER DEFAULT 0,
        damage_hero INTEGER DEFAULT 0,
        damage_tower INTEGER DEFAULT 0,
        damage_taken INTEGER DEFAULT 0,
        heal INTEGER DEFAULT 0,
        cc_duration INTEGER DEFAULT 0,
        kill_streak INTEGER DEFAULT 0,
        server_id INTEGER DEFAULT 0,
        clan TEXT DEFAULT '',
        party_id INTEGER DEFAULT 0,
        FOREIGN KEY(game_id) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE player_profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        main_nickname TEXT,
        is_user INTEGER DEFAULT 0,
        game_account_id TEXT,
        pinned_alias TEXT,
        server_id INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE player_nicknames(
        nickname TEXT PRIMARY KEY,
        profile_id INTEGER,
        FOREIGN KEY(profile_id) REFERENCES player_profiles(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE player_comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER,
        comment TEXT,
        timestamp TEXT,
        FOREIGN KEY(profile_id) REFERENCES player_profiles(id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 12) {
      await _safeAddColumn(db, 'game_players', 'level', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'gold_lane', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'gold_kill', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'gold_tower', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'gold_roam', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'clan', 'TEXT DEFAULT ""');
      await _safeAddColumn(db, 'game_players', 'party_id', 'INTEGER DEFAULT 0');
    }
    if (oldVersion < 13) {
      await _safeAddColumn(db, 'game_players', 'gold_jungle', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'damage_hero', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'damage_tower', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'damage_taken', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'heal', 'INTEGER DEFAULT 0');
    }
    if (oldVersion < 14) {
      await _safeAddColumn(db, 'player_profiles', 'game_account_id', 'TEXT');
    }
    if (oldVersion < 15) {
      await _safeAddColumn(db, 'games', 'match_id', 'TEXT');
    }
    if (oldVersion < 16) {
      try {
        await db.execute('''
          DELETE FROM games 
          WHERE match_id != '' AND match_id IS NOT NULL 
          AND id NOT IN (
            SELECT MIN(id) FROM games 
            WHERE match_id != '' AND match_id IS NOT NULL 
            GROUP BY match_id
          )
        ''');
        await db.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_games_match_id ON games(match_id) WHERE match_id IS NOT NULL AND match_id != ''");
      } catch (e) {
        debugPrint("Error creating unique index: $e");
      }
    }
    if (oldVersion < 17) {
      await _safeAddColumn(db, 'games', 'score', 'INTEGER DEFAULT 0');
    }
    if (oldVersion < 18) {
      await _safeAddColumn(db, 'games', 'end_date', 'TEXT');
    }
    if (oldVersion < 19) {
      await _safeAddColumn(db, 'player_profiles', 'pinned_alias', 'TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS player_comments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          profile_id INTEGER,
          comment TEXT,
          timestamp TEXT,
          FOREIGN KEY(profile_id) REFERENCES player_profiles(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 20) {
      await _safeAddColumn(db, 'game_players', 'cc_duration', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'kill_streak', 'INTEGER DEFAULT 0');
    }
    if (oldVersion < 21) {
      await _safeAddColumn(db, 'player_profiles', 'server_id', 'INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'game_players', 'server_id', 'INTEGER DEFAULT 0');
    }
  }

  Future<void> _safeAddColumn(Database db, String table, String column, String type) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    } catch (e) {
      debugPrint("Column $column already exists in $table or error: $e");
    }
  }

  Future<bool> isGameExists(String matchId) async {
    if (matchId.isEmpty) return false;
    Database db = await database;
    final List<Map<String, dynamic>> res = await db.query('games', where: 'match_id = ?', whereArgs: [matchId]);
    return res.isNotEmpty;
  }

  Future<int> getOrCreateProfile(String nickname, {bool isUser = false, String? gameAccountId, int serverId = 0}) async {
    Database db = await database;
    final String cleanNick = nickname.trim();
    int? profileId;

    if (gameAccountId != null && gameAccountId.isNotEmpty && gameAccountId != '0') {
      final List<Map<String, dynamic>> byId = await db.query(
        'player_profiles', 
        columns: ['id', 'main_nickname'], 
        where: 'game_account_id = ?', 
        whereArgs: [gameAccountId]
      );
      if (byId.isNotEmpty) {
        profileId = byId.first['id'];
        if (byId.first['main_nickname'] != cleanNick) {
          await db.update('player_profiles', {'main_nickname': cleanNick, 'server_id': serverId}, where: 'id = ?', whereArgs: [profileId]);
        } else {
          await db.update('player_profiles', {'server_id': serverId}, where: 'id = ?', whereArgs: [profileId]);
        }
      }
    }

    if (profileId == null) {
      final List<Map<String, dynamic>> mapping = await db.query(
        'player_nicknames', 
        columns: ['profile_id'], 
        where: 'LOWER(nickname) = ?', 
        whereArgs: [cleanNick.toLowerCase()]
      );
      if (mapping.isNotEmpty) {
        profileId = mapping.first['profile_id'];
        await db.update('player_profiles', {'server_id': serverId}, where: 'id = ?', whereArgs: [profileId]);
        if (gameAccountId != null && gameAccountId.isNotEmpty && gameAccountId != '0') {
           await db.update('player_profiles', {'game_account_id': gameAccountId}, where: 'id = ?', whereArgs: [profileId]);
        }
      }
    }

    if (profileId == null) {
      int? customId;
      if (gameAccountId != null) {
        customId = int.tryParse(gameAccountId);
        if (customId != null && customId <= 0) customId = null;
      }
      
      try {
        profileId = await db.insert('player_profiles', {
          if (customId != null) 'id': customId,
          'main_nickname': cleanNick, 
          'is_user': isUser ? 1 : 0,
          'game_account_id': gameAccountId,
          'server_id': serverId
        });
      } catch (e) {
        profileId = await db.insert('player_profiles', {
          'main_nickname': cleanNick, 
          'is_user': isUser ? 1 : 0,
          'game_account_id': gameAccountId,
          'server_id': serverId
        });
      }
      
      await db.insert('player_nicknames', {'nickname': cleanNick, 'profile_id': profileId}, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      if (isUser) await db.update('player_profiles', {'is_user': 1}, where: 'id = ?', whereArgs: [profileId]);
    }
    
    return profileId!;
  }

  Future<void> updateMainNickname(int profileId, String newMainName) async {
    Database db = await database;
    await db.update('player_profiles', {'main_nickname': newMainName.trim()}, where: 'id = ?', whereArgs: [profileId]);
    updateNotifier.notifyListeners();
  }

  Future<List<PlayerProfile>> getAllProfiles() async {
    Database db = await database;
    // Join with game_players and games to get the latest match date
    final maps = await db.rawQuery('''
      SELECT p.id, p.main_nickname, p.is_user, p.pinned_alias, p.server_id,
             MAX(COALESCE(g.end_date, g.date)) as last_match
      FROM player_profiles p
      LEFT JOIN game_players gp ON p.id = gp.profile_id
      LEFT JOIN games g ON gp.game_id = g.id
      WHERE (p.id IN (SELECT DISTINCT profile_id FROM player_nicknames) OR p.is_user = 1)
      GROUP BY p.id
      ORDER BY last_match DESC, p.id DESC
    ''');
    return maps.map((m) => PlayerProfile.fromMap(m)).toList();
  }

  Future<List<PlayerProfile>> searchProfilesByAnyNickname(String query) async {
    Database db = await database;
    final String q = '%${query.toLowerCase()}%';
    final maps = await db.rawQuery('''
      SELECT p.id, p.main_nickname, p.is_user, p.pinned_alias, p.server_id,
             MAX(COALESCE(g.end_date, g.date)) as last_match
      FROM player_profiles p
      LEFT JOIN game_players gp ON p.id = gp.profile_id
      LEFT JOIN games g ON gp.game_id = g.id
      WHERE p.id IN (
        SELECT profile_id FROM player_nicknames WHERE LOWER(nickname) LIKE ?
      ) OR LOWER(p.main_nickname) LIKE ? OR LOWER(p.pinned_alias) LIKE ?
      GROUP BY p.id
      ORDER BY last_match DESC, p.id DESC
    ''', [q, q, q]);
    return maps.map((m) => PlayerProfile.fromMap(m)).toList();
  }

  Future<List<String>> getNicknamesForProfile(int profileId) async {
    Database db = await database;
    final maps = await db.query('player_nicknames', columns: ['nickname'], where: 'profile_id = ?', whereArgs: [profileId]);
    return maps.map((m) => m['nickname'] as String).toList();
  }

  Future<void> addAlias(int profileId, String alias) async {
    Database db = await database;
    await db.insert('player_nicknames', {'nickname': alias.trim(), 'profile_id': profileId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    updateNotifier.notifyListeners();
  }

  Future<void> deleteAlias(int profileId, String alias) async {
    Database db = await database;
    await db.delete('player_nicknames', where: 'profile_id = ? AND nickname = ?', whereArgs: [profileId, alias.trim()]);
    final List<Map<String, dynamic>> profile = await db.query('player_profiles', columns: ['pinned_alias'], where: 'id = ?', whereArgs: [profileId]);
    if (profile.isNotEmpty && profile.first['pinned_alias'] == alias.trim()) {
      await db.update('player_profiles', {'pinned_alias': null}, where: 'id = ?', whereArgs: [profileId]);
    }
    updateNotifier.notifyListeners();
  }

  Future<void> pinAlias(int profileId, String? alias) async {
    Database db = await database;
    await db.update('player_profiles', {'pinned_alias': alias?.trim()}, where: 'id = ?', whereArgs: [profileId]);
    updateNotifier.notifyListeners();
  }

  Future<void> addComment(int profileId, String text) async {
    Database db = await database;
    await db.insert('player_comments', {
      'profile_id': profileId,
      'comment': text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    updateNotifier.notifyListeners();
  }

  Future<void> deleteComment(int commentId) async {
    Database db = await database;
    await db.delete('player_comments', where: 'id = ?', whereArgs: [commentId]);
    updateNotifier.notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getComments(int profileId) async {
    Database db = await database;
    return await db.query('player_comments', where: 'profile_id = ?', orderBy: 'timestamp DESC', whereArgs: [profileId]);
  }

  Future<int> deleteUnusedProfiles() async {
    Database db = await database;
    int count = 0;
    await db.transaction((txn) async {
      count = await txn.rawDelete('''
        DELETE FROM player_profiles 
        WHERE is_user = 0
        AND id NOT IN (SELECT DISTINCT profile_id FROM game_players WHERE profile_id IS NOT NULL)
      ''');
      await txn.rawDelete('DELETE FROM player_nicknames WHERE profile_id NOT IN (SELECT id FROM player_profiles)');
    });
    updateNotifier.notifyListeners();
    return count;
  }

  Future<List<Map<String, dynamic>>> getHeroStatsForProfile(int profileId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT 
        gp.hero,
        COUNT(CASE WHEN gp.is_enemy = 0 THEN 1 END) as ally_games,
        COUNT(CASE WHEN gp.is_enemy = 0 AND g.result = 'VICTORY' THEN 1 END) as ally_wins,
        COUNT(CASE WHEN gp.is_enemy = 1 THEN 1 END) as enemy_games,
        COUNT(CASE WHEN gp.is_enemy = 1 AND g.result = 'DEFEAT' THEN 1 END) as enemy_wins
      FROM game_players gp
      JOIN games g ON gp.game_id = g.id
      WHERE gp.profile_id = ?
      GROUP BY gp.hero
      ORDER BY (COUNT(gp.id)) DESC
    ''', [profileId]);
  }

  Future<List<Map<String, dynamic>>> getGamesForProfile(int profileId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT g.*, gp.hero as player_hero, gp.kda as player_kda, gp.items as player_items, 
             gp.score as player_score, gp.role as player_role, gp.spell as player_spell,
             gp.is_enemy as player_is_enemy
      FROM games g
      JOIN game_players gp ON g.id = gp.game_id
      WHERE gp.profile_id = ?
      ORDER BY COALESCE(g.end_date, g.date) DESC
    ''', [profileId]);
  }

  Future<List<PlayerStats>> getPlayersForGame(int gameId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT gp.*, 
             pp.main_nickname as profile_main_name, 
             pp.is_user as profile_is_user,
             pp.game_account_id as profile_game_acc_id,
             pp.pinned_alias as profile_pinned_alias,
             pp.server_id as profile_server_id
      FROM game_players gp
      LEFT JOIN player_profiles pp ON gp.profile_id = pp.id
      WHERE gp.game_id = ?
    ''', [gameId]);
    return List.generate(maps.length, (i) {
      var map = Map<String, dynamic>.from(maps[i]);
      String displayName = map['profile_pinned_alias'] ?? map['profile_main_name'] ?? map['nickname'];
      map['nickname'] = displayName;
      bool isUser = (map['profile_is_user'] == 1) || (map['is_user'] == 1);
      map['is_user'] = isUser ? 1 : 0;
      map['playerId'] = map['profile_game_acc_id'];
      map['server_id'] = map['profile_server_id'] ?? map['server_id'] ?? 0;
      return PlayerStats.fromMap(map);
    });
  }

  Future<int> _getOrCreateProfileTxn(Transaction txn, String nickname, {bool? forceIsUser, String? gameAccountId, int serverId = 0}) async {
    final String cleanNick = nickname.trim();
    int? profileId;

    if (gameAccountId != null && gameAccountId.isNotEmpty && gameAccountId != '0') {
      final List<Map<String, dynamic>> byId = await txn.query(
        'player_profiles', 
        columns: ['id', 'main_nickname'], 
        where: 'game_account_id = ?', 
        whereArgs: [gameAccountId]
      );
      if (byId.isNotEmpty) {
        profileId = byId.first['id'];
        if (byId.first['main_nickname'] != cleanNick) {
          await txn.update('player_profiles', {'main_nickname': cleanNick, 'server_id': serverId}, where: 'id = ?', whereArgs: [profileId]);
        } else {
          await txn.update('player_profiles', {'server_id': serverId}, where: 'id = ?', whereArgs: [profileId]);
        }
      }
    }

    if (profileId == null) {
      final List<Map<String, dynamic>> mapping = await txn.query('player_nicknames', columns: ['profile_id'], where: 'LOWER(nickname) = ?', whereArgs: [cleanNick.toLowerCase()]);
      if (mapping.isNotEmpty) {
        profileId = mapping.first['profile_id'];
        await txn.update('player_profiles', {'server_id': serverId}, where: 'id = ?', whereArgs: [profileId]);
        if (gameAccountId != null && gameAccountId.isNotEmpty && gameAccountId != '0') {
           await txn.update('player_profiles', {'game_account_id': gameAccountId}, where: 'id = ?', whereArgs: [profileId]);
        }
      }
    }

    if (profileId == null) {
      int? customId;
      if (gameAccountId != null) {
        customId = int.tryParse(gameAccountId);
        if (customId != null && customId <= 0) customId = null;
      }

      try {
        profileId = await txn.insert('player_profiles', {
          if (customId != null) 'id': customId,
          'main_nickname': cleanNick, 
          'is_user': forceIsUser == true ? 1 : 0,
          'game_account_id': gameAccountId,
          'server_id': serverId
        });
      } catch (e) {
        profileId = await txn.insert('player_profiles', {
          'main_nickname': cleanNick, 
          'is_user': forceIsUser == true ? 1 : 0,
          'game_account_id': gameAccountId,
          'server_id': serverId
        });
      }
      
      await txn.insert('player_nicknames', {'nickname': cleanNick, 'profile_id': profileId});
    } else {
      if (forceIsUser == true) await txn.update('player_profiles', {'is_user': 1}, where: 'id = ?', whereArgs: [profileId]);
    }
    return profileId!;
  }

  Future<int> insertGameWithPlayers(GameStats game, List<PlayerStats> players) async {
    if (game.matchId.isNotEmpty && await isGameExists(game.matchId)) {
      debugPrint("Game with matchId ${game.matchId} already exists. Skipping.");
      return -1; 
    }

    Database db = await database;
    try {
      int id = await db.transaction((txn) async {
        for (int i = 0; i < players.length; i++) {
          int pid = await _getOrCreateProfileTxn(txn, players[i].nickname, forceIsUser: players[i].isUser, gameAccountId: players[i].playerId, serverId: players[i].serverId);
          players[i] = players[i].copyWith(profileId: pid);
        }
        int gameId = await txn.insert('games', game.toMap());
        for (var p in players) {
          var map = p.toMap(); map['game_id'] = gameId;
          await txn.insert('game_players', map);
        }
        return gameId;
      });
      updateNotifier.notifyListeners(); // Notify UI to refresh player list
      return id;
    } catch (e) {
      debugPrint("Error inserting game: $e");
      return -1;
    }
  }

  Future<List<GameStats>> getGames() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('games', orderBy: 'COALESCE(end_date, date) DESC');
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
    return (await db.rawQuery('SELECT * FROM games WHERE id IN ($ids) ORDER BY COALESCE(end_date, date) DESC')).map((m) => GameStats.fromMap(m)).toList();
  }

  Future<List<GameStats>> getGamesByHero(int heroId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('games', where: 'hero = ?', whereArgs: [heroId.toString()], orderBy: 'COALESCE(end_date, date) DESC');
    return maps.map((m) => GameStats.fromMap(m)).toList();
  }
}