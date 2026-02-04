class PlayerStats {
  final int? id;
  final String nickname;
  final int heroId;
  final String kda;
  final String gold;
  final List<int> itemIds;
  final int score; 
  final bool isEnemy;
  final bool isUser;
  final String role;
  final int spellId;
  final int? gameId;
  final int? profileId;
  final String? playerId;
  final int teamId;
  final int serverId; // Tag 17
  
  final int level;
  final int goldLane; 
  final int goldKill; 
  final int goldTower; 
  final int goldJungle; 
  
  final int damageHero; 
  final int damageTower; 
  final int damageTaken; 
  final int heal; 
  final int ccDuration; 
  final int killStreak; 
  
  final String clan;
  final int partyId;

  PlayerStats({
    this.id,
    required this.nickname,
    required this.heroId,
    required this.kda,
    required this.gold,
    required this.itemIds,
    required this.score,
    required this.isEnemy,
    required this.isUser,
    this.role = 'unknown',
    this.spellId = 0,
    this.gameId,
    this.profileId,
    this.playerId,
    this.teamId = 0,
    this.serverId = 0,
    this.level = 0,
    this.goldLane = 0,
    this.goldKill = 0,
    this.goldTower = 0,
    this.goldJungle = 0,
    this.damageHero = 0,
    this.damageTower = 0,
    this.damageTaken = 0,
    this.heal = 0,
    this.ccDuration = 0,
    this.killStreak = 0,
    this.clan = '',
    this.partyId = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'hero': heroId.toString(),
      'kda': kda,
      'gold': gold,
      'items': itemIds.join(','),
      'score': score, 
      'is_enemy': isEnemy ? 1 : 0,
      'is_user': isUser ? 1 : 0,
      'role': role,
      'spell': spellId.toString(),
      'game_id': gameId,
      'profile_id': profileId,
      'server_id': serverId,
      'level': level,
      'gold_lane': goldLane,
      'gold_kill': goldKill,
      'gold_jungle': goldJungle,
      'damage_hero': damageHero,
      'damage_tower': damageTower,
      'damage_taken': damageTaken,
      'heal': heal,
      'cc_duration': ccDuration,
      'kill_streak': killStreak,
      'clan': clan,
      'party_id': partyId,
    };
  }

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    List<int> parsedItems = [];
    if (map['items'] != null && map['items'].toString().isNotEmpty) {
      parsedItems = map['items'].toString().split(',').map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();
    }
    
    int parsedScore = 0;
    if (map['score'] is int) {
      parsedScore = map['score'];
    } else if (map['score'] != null) {
      parsedScore = double.tryParse(map['score'].toString())?.toInt() ?? 0;
    }

    return PlayerStats(
      id: map['id'],
      nickname: map['nickname'] ?? '',
      heroId: int.tryParse(map['hero'] ?? '0') ?? 0,
      kda: map['kda'] ?? '0/0/0',
      gold: map['gold'] ?? '0',
      itemIds: parsedItems,
      score: parsedScore,
      isEnemy: map['is_enemy'] == 1,
      isUser: map['is_user'] == 1,
      role: map['role'] ?? 'unknown',
      spellId: int.tryParse(map['spell'] ?? '0') ?? 0,
      gameId: map['game_id'],
      profileId: map['profile_id'],
      serverId: map['server_id'] ?? 0,
      level: map['level'] ?? 0,
      goldLane: map['gold_lane'] ?? 0,
      goldKill: map['gold_kill'] ?? 0,
      goldJungle: map['gold_jungle'] ?? 0,
      damageHero: map['damage_hero'] ?? 0,
      damageTower: map['damage_tower'] ?? 0,
      damageTaken: map['damage_taken'] ?? 0,
      heal: map['heal'] ?? 0,
      ccDuration: map['cc_duration'] ?? 0,
      killStreak: map['kill_streak'] ?? 0,
      clan: map['clan'] ?? '',
      partyId: map['party_id'] ?? 0,
      playerId: map['playerId'], 
    );
  }

  PlayerStats copyWith({
    int? id,
    String? nickname,
    int? heroId,
    String? kda,
    String? gold,
    List<int>? itemIds,
    int? score, 
    bool? isEnemy,
    bool? isUser,
    String? role,
    int? spellId,
    int? gameId,
    int? profileId,
    String? playerId,
    int? teamId,
    int? serverId,
    int? level,
    int? goldLane,
    int? goldKill,
    int? goldJungle,
    int? damageHero,
    int? damageTower,
    int? damageTaken,
    int? heal,
    int? ccDuration,
    int? killStreak,
    String? clan,
    int? partyId,
  }) {
    return PlayerStats(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      heroId: heroId ?? this.heroId,
      kda: kda ?? this.kda,
      gold: gold ?? this.gold,
      itemIds: itemIds ?? this.itemIds,
      score: score ?? this.score,
      isEnemy: isEnemy ?? this.isEnemy,
      isUser: isUser ?? this.isUser,
      role: role ?? this.role,
      spellId: spellId ?? this.spellId,
      gameId: gameId ?? this.gameId,
      profileId: profileId ?? this.profileId,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      serverId: serverId ?? this.serverId,
      level: level ?? this.level,
      goldLane: goldLane ?? this.goldLane,
      goldKill: goldKill ?? this.goldKill,
      goldJungle: goldJungle ?? this.goldJungle,
      damageHero: damageHero ?? this.damageHero,
      damageTower: damageTower ?? this.damageTower,
      damageTaken: damageTaken ?? this.damageTaken,
      heal: heal ?? this.heal,
      ccDuration: ccDuration ?? this.ccDuration,
      killStreak: killStreak ?? this.killStreak,
      clan: clan ?? this.clan,
      partyId: partyId ?? this.partyId,
    );
  }
}