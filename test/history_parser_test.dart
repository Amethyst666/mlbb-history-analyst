import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mlbb_history_analyst/utils/history_parser.dart';

void main() {
  test('parses new MVP score ID correctly', () async {
    final file = File('/home/user/coding/mlbb-stats/tmp/His-23984353-455365310819251843');
    final parsed = await HistoryParser.parseFile(file);
    expect(parsed, isNotNull);
    
    expect(parsed!.game.result, 'VICTORY'); // since winnerTeamId should now match correctly if user played in team 0
    
    final faramis = parsed.players.firstWhere((p) => p.heroId == 81);
    expect(faramis.score, 7);
    
    print('Game Result: \${parsed.game.result}');
    print('Faramis Score: \${faramis.score}');
  });
}
