class PlayerStats {
  final int? id;
  final String nickname;
  final int heroId;
  final String kda;
  final String gold;
  final List<int> itemIds;
  final String score;
  final bool isEnemy;
  final bool isUser;
  final String role;
  final int spellId;
  final int? gameId;
  final int? profileId;
  final String? playerId;
  final int teamId;
  
  // New fields
  final int level;
  final int goldLane; // 87
  final int goldKill; // 86
  final int goldTower; // Not mapped in user description, but maybe 20 is damage tower? User said "gold from sources... 87 creeps". Let's stick to user desc: 82 jungle, 86 kills, 87 lane.
  // Wait, user said "82 -- в лесу, 86 -- за убийства, 87 -- за крипов на линии". 
  final int goldJungle; // 82
  
  // Damage Stats
  final int damageHero; // 19
  final int damageTower; // 20
  final int damageTaken; // 21
  final int heal; // 84 + 85
  
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
    this.level = 0,
    this.goldLane = 0,
    this.goldKill = 0,
    this.goldTower = 0,
    this.goldJungle = 0,
    this.damageHero = 0,
    this.damageTower = 0,
    this.damageTaken = 0,
    this.heal = 0,
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
      'level': level,
      'gold_lane': goldLane,
      'gold_kill': goldKill,
      'gold_jungle': goldJungle,
      'damage_hero': damageHero,
      'damage_tower': damageTower,
      'damage_taken': damageTaken,
      'heal': heal,
      'clan': clan,
      'party_id': partyId,
    };
  }

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    List<int> parsedItems = [];
    if (map['items'] != null && map['items'].toString().isNotEmpty) {
      parsedItems = map['items'].toString().split(',').map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();
    }
    
    return PlayerStats(
      id: map['id'],
      nickname: map['nickname'] ?? '',
      heroId: int.tryParse(map['hero'] ?? '0') ?? 0,
      kda: map['kda'] ?? '0/0/0',
      gold: map['gold'] ?? '0',
      itemIds: parsedItems,
      score: map['score'] ?? '0.0',
      isEnemy: map['is_enemy'] == 1,
      isUser: map['is_user'] == 1,
      role: map['role'] ?? 'unknown',
      spellId: int.tryParse(map['spell'] ?? '0') ?? 0,
      gameId: map['game_id'],
      profileId: map['profile_id'],
      level: map['level'] ?? 0,
      goldLane: map['gold_lane'] ?? 0,
      goldKill: map['gold_kill'] ?? 0,
      goldJungle: map['gold_jungle'] ?? 0,
      damageHero: map['damage_hero'] ?? 0,
      damageTower: map['damage_tower'] ?? 0,
      damageTaken: map['damage_taken'] ?? 0,
      heal: map['heal'] ?? 0,
      clan: map['clan'] ?? '',
      partyId: map['party_id'] ?? 0,
      playerId: map['playerId'], // Added
    );
  }

  PlayerStats copyWith({
    int? id,
    String? nickname,
    int? heroId,
    String? kda,
    String? gold,
    List<int>? itemIds,
    String? score,
    bool? isEnemy,
    bool? isUser,
    String? role,
    int? spellId,
    int? gameId,
    int? profileId,
    String? playerId,
    int? teamId,
    int? level,
    int? goldLane,
    int? goldKill,
    int? goldJungle,
    int? damageHero,
    int? damageTower,
    int? damageTaken,
    int? heal,
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
      level: level ?? this.level,
      goldLane: goldLane ?? this.goldLane,
      goldKill: goldKill ?? this.goldKill,
      goldJungle: goldJungle ?? this.goldJungle,
      damageHero: damageHero ?? this.damageHero,
      damageTower: damageTower ?? this.damageTower,
      damageTaken: damageTaken ?? this.damageTaken,
      heal: heal ?? this.heal,
      clan: clan ?? this.clan,
      partyId: partyId ?? this.partyId,
    );
  }
}
