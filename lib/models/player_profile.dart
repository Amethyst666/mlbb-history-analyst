class PlayerProfile {
  final int? id;
  String mainNickname;
  final bool isUser;
  String? pinnedAlias; 
  int serverId; // Added serverId

  PlayerProfile({
    this.id,
    required this.mainNickname,
    this.isUser = false,
    this.pinnedAlias,
    this.serverId = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'main_nickname': mainNickname,
      'is_user': isUser ? 1 : 0,
      'pinned_alias': pinnedAlias,
      'server_id': serverId,
    };
  }

  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    return PlayerProfile(
      id: map['id'],
      mainNickname: map['main_nickname'] ?? 'Unknown',
      isUser: map['is_user'] == 1,
      pinnedAlias: map['pinned_alias'],
      serverId: map['server_id'] ?? 0,
    );
  }
}