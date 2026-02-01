class PlayerProfile {
  final int? id;
  String mainNickname;
  final bool isUser;
  bool isVerified;

  PlayerProfile({
    this.id,
    required this.mainNickname,
    this.isUser = false,
    this.isVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'main_nickname': mainNickname,
      'is_user': isUser ? 1 : 0,
      'is_verified': isVerified ? 1 : 0,
    };
  }

  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    return PlayerProfile(
      id: map['id'],
      mainNickname: map['main_nickname'] ?? 'Unknown',
      isUser: map['is_user'] == 1,
      // БЕЗОПАСНОЕ ЧТЕНИЕ: если колонки нет в результате запроса, ставим false
      isVerified: map.containsKey('is_verified') ? (map['is_verified'] == 1) : false,
    );
  }
}