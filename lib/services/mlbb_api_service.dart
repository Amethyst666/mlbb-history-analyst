import 'dart:convert';
import 'package:http/http.dart' as http;

class HeroGlobalStats {
  final double winRate;
  final double pickRate;
  final double banRate;

  HeroGlobalStats({
    required this.winRate,
    required this.pickRate,
    required this.banRate,
  });

  factory HeroGlobalStats.fromJson(Map<String, dynamic> json) {
    // Attempt to safely parse whatever structure the API returns.
    // Sometimes it's nested under 'data', sometimes it's direct.
    final data = json['data'] ?? json;
    
    double parseRate(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
      }
      return 0.0;
    }

    return HeroGlobalStats(
      winRate: parseRate(data['win_rate'] ?? data['winRate']),
      pickRate: parseRate(data['pick_rate'] ?? data['pickRate']),
      banRate: parseRate(data['ban_rate'] ?? data['banRate']),
    );
  }
}

class MlbbApiService {
  static const String baseUrl = 'https://mlbb.rone.dev/api';

  static Future<HeroGlobalStats?> getHeroStats(int heroId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/heroes/$heroId/stats')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return HeroGlobalStats.fromJson(json);
      }
    } catch (e) {
      // Ignore network or parsing errors and fallback gracefully
    }
    return null;
  }
}
