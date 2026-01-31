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

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'game_stats.db');
    return await openDatabase(
      path,
      version: 9, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        result TEXT,
        hero TEXT,
        kda TEXT,
        items TEXT,
        players TEXT,
        date TEXT,
        duration TEXT,
        role TEXT,
        spell TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE game_players(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER,
        nickname TEXT,
        hero TEXT,
        kda TEXT,
        gold TEXT,
        items TEXT,
        score TEXT,
        role TEXT,
        spell TEXT,
        profile_id INTEGER,
        is_enemy INTEGER,
        is_user INTEGER,
        FOREIGN KEY(game_id) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE player_profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        main_nickname TEXT,
        is_user INTEGER DEFAULT 0
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
    if (oldVersion < 9) {
      await db.execute('CREATE TABLE IF NOT EXISTS player_profiles(id INTEGER PRIMARY KEY AUTOINCREMENT, main_nickname TEXT, is_user INTEGER DEFAULT 0)');
      await db.execute('CREATE TABLE IF NOT EXISTS player_nicknames(nickname TEXT PRIMARY KEY, profile_id INTEGER)');
    }
  }

  Future<int> getOrCreateProfile(String nickname, {bool isUser = false}) async {
    Database db = await database;
    final String lowNick = nickname.toLowerCase().trim();
    final List<Map<String, dynamic>> mapping = await db.query('player_nicknames', where: 'LOWER(nickname) = ?', whereArgs: [lowNick]);
    
    if (mapping.isNotEmpty) {
      int pid = mapping.first['profile_id'];
      if (isUser) await db.update('player_profiles', {'is_user': 1}, where: 'id = ?', whereArgs: [pid]);
      return pid;
    }
    
    int profileId = await db.insert('player_profiles', {'main_nickname': nickname, 'is_user': isUser ? 1 : 0});
    await db.insert('player_nicknames', {'nickname': lowNick, 'profile_id': profileId});
    return profileId;
  }

  Future<void> associateNicknameWithProfile(String nickname, int targetProfileId) async {
    Database db = await database;
    final String lowNick = nickname.toLowerCase().trim();
    await db.transaction((txn) async {
      await txn.insert('player_nicknames', {'nickname': lowNick, 'profile_id': targetProfileId}, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.update('game_players', {'profile_id': targetProfileId}, where: 'LOWER(nickname) = ?', whereArgs: [lowNick]);
    });
  }

  Future<void> updateMainNickname(int profileId, String newMainName) async {
    Database db = await database;
    await db.update('player_profiles', {'main_nickname': newMainName}, where: 'id = ?', whereArgs: [profileId]);
  }

  Future<List<PlayerProfile>> getAllProfiles() async {
    Database db = await database;
    final maps = await db.query('player_profiles', orderBy: 'main_nickname ASC');
    return maps.map((m) => PlayerProfile.fromMap(m)).toList();
  }

  Future<List<String>> getNicknamesForProfile(int profileId) async {
    Database db = await database;
    final maps = await db.query('player_nicknames', columns: ['nickname'], where: 'profile_id = ?', whereArgs: [profileId]);
    return maps.map((m) => m['nickname'] as String).toList();
  }

  Future<void> fixLegacyGames() async {
    Database db = await database;
    final prefs = await SharedPreferences.getInstance();
    final String? userNick = prefs.getString('user_nickname')?.toLowerCase().trim();

    // 1. Собираем все ID профилей, которые могут быть ВАШИМИ
    Set<int> userPids = {};
    
    // А) По нику из настроек
    if (userNick != null && userNick.isNotEmpty) {
      final List<Map<String, dynamic>> mapping = await db.query('player_nicknames', where: 'LOWER(nickname) = ?', whereArgs: [userNick]);
      for (var m in mapping) userPids.add(m['profile_id']);
    }

    // Б) По старому техническому нику "You"
    final List<Map<String, dynamic>> youMapping = await db.query('player_nicknames', where: 'LOWER(nickname) = ?', whereArgs: ['you']);
    for (var m in youMapping) userPids.add(m['profile_id']);

    // В) По уже существующему флагу is_user в профилях
    final List<Map<String, dynamic>> markedProfiles = await db.query('player_profiles', where: 'is_user = 1');
    for (var m in markedProfiles) userPids.add(m['id']);

    // 2. Сбрасываем и проставляем актуальные флаги в базе
    await db.update('player_profiles', {'is_user': 0});
    await db.update('game_players', {'is_user': 0});
    
    if (userPids.isNotEmpty) {
      String idList = userPids.join(',');
      await db.update('player_profiles', {'is_user': 1}, where: 'id IN ($idList)');
      await db.update('game_players', {'is_user': 1}, where: 'profile_id IN ($idList)');
      
      // На всякий случай: если profile_id в game_players еще не был проставлен (старая база)
      // Ищем по никам, связанным с этими профилями
      final List<Map<String, dynamic>> nicks = await db.query('player_nicknames', where: 'profile_id IN ($idList)');
      for (var row in nicks) {
        await db.update('game_players', {'is_user': 1}, where: 'LOWER(nickname) = ?', whereArgs: [row['nickname'].toString().toLowerCase()]);
      }
    }

    // 3. Синхронизируем игры
    final List<Map<String, dynamic>> games = await db.query('games');
    for (var g in games) {
      int gameId = g['id'];
      final List<Map<String, dynamic>> userInGame = await db.query('game_players', where: 'game_id = ? AND is_user = 1', whereArgs: [gameId]);

      if (userInGame.isNotEmpty) {
        final p = userInGame.first;
        await db.update('games', {
          'hero': p['hero'],
          'kda': p['kda'],
          'items': p['items'],
          'role': p['role'] ?? 'unknown',
          'spell': p['spell'] ?? 'none',
        }, where: 'id = ?', whereArgs: [gameId]);
      } else {
        await db.update('games', {'hero': 'none'}, where: 'id = ?', whereArgs: [gameId]);
      }
    }
  }

  Future<List<PlayerStats>> getPlayersForGame(int gameId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT gp.*, pp.main_nickname as profile_main_name, pp.is_user as profile_is_user
      FROM game_players gp
      LEFT JOIN player_profiles pp ON gp.profile_id = pp.id
      WHERE gp.game_id = ?
    ''', [gameId]);

    return List.generate(maps.length, (i) {
      var map = Map<String, dynamic>.from(maps[i]);
      if (map['profile_main_name'] != null) map['nickname'] = map['profile_main_name'];
      // Метка is_user теперь берется либо из профиля, либо из самой записи игрока
      bool isUser = (map['profile_is_user'] == 1) || (map['is_user'] == 1);
      map['is_user'] = isUser ? 1 : 0;
      return PlayerStats.fromMap(map);
    });
  }

  Future<int> _getOrCreateProfileTxn(Transaction txn, String nickname, {bool isUser = false}) async {
    final String lowNick = nickname.toLowerCase().trim();
    final List<Map<String, dynamic>> mapping = await txn.query('player_nicknames', where: 'LOWER(nickname) = ?', whereArgs: [lowNick]);
    if (mapping.isNotEmpty) return mapping.first['profile_id'];
    
    int profileId = await txn.insert('player_profiles', {'main_nickname': nickname, 'is_user': isUser ? 1 : 0});
    await txn.insert('player_nicknames', {'nickname': lowNick, 'profile_id': profileId});
    return profileId;
  }

  Future<int> insertGameWithPlayers(GameStats game, List<PlayerStats> players) async {
    Database db = await database;
    return await db.transaction((txn) async {
      for (int i = 0; i < players.length; i++) {
        final p = players[i];
        int profileId = await _getOrCreateProfileTxn(txn, p.nickname, isUser: p.isUser);
        players[i] = p.copyWith(profileId: profileId);
      }
      int gameId = await txn.insert('games', game.toMap());
      for (var player in players) {
        var playerMap = player.toMap();
        playerMap['game_id'] = gameId;
        await txn.insert('game_players', playerMap);
      }
      return gameId;
    });
  }

  Future<void> updateGameWithPlayers(GameStats game, List<PlayerStats> players) async {
    if (game.id == null) return;
    Database db = await database;
    await db.transaction((txn) async {
      for (int i = 0; i < players.length; i++) {
        final p = players[i];
        int profileId = await _getOrCreateProfileTxn(txn, p.nickname, isUser: p.isUser);
        players[i] = p.copyWith(profileId: profileId);
      }
      await txn.update('games', game.toMap(), where: 'id = ?', whereArgs: [game.id]);
      await txn.delete('game_players', where: 'game_id = ?', whereArgs: [game.id]);
      for (var player in players) {
        var playerMap = player.toMap();
        playerMap['game_id'] = game.id;
        await txn.insert('game_players', playerMap);
      }
    });
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
  }

  Future<List<GameStats>> getGamesByPlayer(String playerName) async {
    Database db = await database;
    final List<Map<String, dynamic>> playerMatches = await db.rawQuery('''
      SELECT DISTINCT game_id FROM game_players 
      WHERE profile_id IN (SELECT profile_id FROM player_nicknames WHERE LOWER(nickname) LIKE ?)
    ''', ['%${playerName.toLowerCase()}%']);
    if (playerMatches.isEmpty) return [];
    String ids = playerMatches.map((m) => m['game_id']).join(',');
    List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM games WHERE id IN ($ids) ORDER BY date DESC');
    return maps.map((m) => GameStats.fromMap(m)).toList();
  }

  Future<List<GameStats>> getGamesByHero(String heroName) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('games', where: 'hero LIKE ?', whereArgs: ['%$heroName%'], orderBy: 'date DESC');
    return maps.map((m) => GameStats.fromMap(m)).toList();
  }

  Future<List<String>> getAllUniqueNicknames() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('player_nicknames', columns: ['nickname'], orderBy: 'nickname ASC');
    return maps.map((e) => e['nickname'] as String).toList();
  }
}
