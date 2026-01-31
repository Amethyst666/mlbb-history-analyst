class PlayerStats {
  final int? id;
  final int? gameId; // Foreign key to games table
  final String nickname;
  final String hero;
  final String kda;
  final String gold;
  final String items;
  final String score; // e.g., "9.8" or "MVP"
  final String role; // 'exp', 'gold', 'mid', 'roam', 'jungle', 'unknown'
  final String spell;
  final int? profileId; // New field
  final bool isEnemy; // false = my team, true = enemy team
  final bool isUser;  // true if this is the app user

  PlayerStats({
    this.id,
    this.gameId,
    required this.nickname,
    required this.hero,
    required this.kda,
    required this.gold,
    required this.items,
    required this.score,
    this.role = 'unknown',
    this.spell = 'none',
    this.profileId,
    required this.isEnemy,
    required this.isUser,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'nickname': nickname,
      'hero': hero,
      'kda': kda,
      'gold': gold,
      'items': items,
      'score': score,
      'role': role,
      'spell': spell,
      'profile_id': profileId,
      'is_enemy': isEnemy ? 1 : 0,
      'is_user': isUser ? 1 : 0,
    };
  }

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      id: map['id'],
      gameId: map['game_id'],
      nickname: map['nickname'],
      hero: map['hero'],
      kda: map['kda'],
      gold: map['gold'],
      items: map['items'],
      score: map['score'],
      role: map['role'] ?? 'unknown',
      spell: map['spell'] ?? 'none',
      profileId: map['profile_id'],
      isEnemy: map['is_enemy'] == 1,
      isUser: map['is_user'] == 1,
    );
  }

  PlayerStats copyWith({
    int? id,
    int? gameId,
    String? nickname,
    String? hero,
    String? kda,
    String? gold,
    String? items,
    String? score,
    String? role,
    String? spell,
    int? profileId,
    bool? isEnemy,
    bool? isUser,
  }) {
    return PlayerStats(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      nickname: nickname ?? this.nickname,
      hero: hero ?? this.hero,
      kda: kda ?? this.kda,
      gold: gold ?? this.gold,
      items: items ?? this.items,
      score: score ?? this.score,
      role: role ?? this.role,
      spell: spell ?? this.spell,
      profileId: profileId ?? this.profileId,
      isEnemy: isEnemy ?? this.isEnemy,
      isUser: isUser ?? this.isUser,
    );
  }
}
