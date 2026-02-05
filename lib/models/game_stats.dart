class GameStats {
  final int? id;
  final String matchId; // Added Match ID from Game
  final String result;
  final int heroId; // Changed from String hero
  final String kda;
  final List<int> itemIds; // Changed from String items
  final int score; // Added user's score (medal ID)
  final String players;
  final DateTime date;
  final DateTime? endDate; // Added End Date
  final String duration;
  final String role;
  final int spellId; // Changed from String spell

  GameStats({
    this.id,
    this.matchId = '',
    required this.result,
    required this.heroId,
    required this.kda,
    required this.itemIds,
    this.score = 0,
    required this.players,
    required this.date,
    this.endDate,
    this.duration = '00:00',
    this.role = 'unknown',
    this.spellId = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'match_id': matchId,
      'result': result,
      'hero': heroId.toString(),
      'kda': kda,
      'items': itemIds.join(','),
      'score': score,
      'players': players,
      'date': date.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'duration': duration,
      'role': role,
      'spell': spellId.toString(),
    };
  }

  factory GameStats.fromMap(Map<String, dynamic> map) {
    List<int> parsedItems = [];
    if (map['items'] != null && map['items'].toString().isNotEmpty) {
      parsedItems = map['items']
          .toString()
          .split(',')
          .map((e) => int.tryParse(e) ?? 0)
          .where((e) => e != 0)
          .toList();
    }

    return GameStats(
      id: map['id'],
      matchId: map['match_id'] ?? '',
      result: map['result'],
      heroId: int.tryParse(map['hero'] ?? '0') ?? 0,
      kda: map['kda'],
      itemIds: parsedItems,
      score: map['score'] ?? 0,
      players: map['players'] ?? '',
      date: DateTime.parse(map['date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      duration: map['duration'] ?? '00:00',
      role: map['role'] ?? 'unknown',
      spellId: int.tryParse(map['spell'] ?? '0') ?? 0,
    );
  }
}
