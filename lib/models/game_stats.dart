class GameStats {
  final int? id;
  final String result;
  final String hero;
  final String kda;
  final String items;
  final String players;
  final DateTime date;
  final String duration;
  final String role;
  final String spell; // New field

  GameStats({
    this.id,
    required this.result,
    required this.hero,
    required this.kda,
    required this.items,
    required this.players,
    required this.date,
    this.duration = '00:00',
    this.role = 'unknown',
    this.spell = 'none',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'result': result,
      'hero': hero,
      'kda': kda,
      'items': items,
      'players': players,
      'date': date.toIso8601String(),
      'duration': duration,
      'role': role,
      'spell': spell,
    };
  }

  factory GameStats.fromMap(Map<String, dynamic> map) {
    return GameStats(
      id: map['id'],
      result: map['result'],
      hero: map['hero'],
      kda: map['kda'],
      items: map['items'],
      players: map['players'],
      date: DateTime.parse(map['date']),
      duration: map['duration'] ?? '00:00',
      role: map['role'] ?? 'unknown',
      spell: map['spell'] ?? 'none',
    );
  }
}