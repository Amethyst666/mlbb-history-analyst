import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/game_stats.dart';
import '../models/player_stats.dart';
import 'game_data.dart';

class ParsedGameData {
  final GameStats game;
  final List<PlayerStats> players;
  ParsedGameData({required this.game, required this.players});
}

class HistoryParser {
  static (int, int) _rv(Uint8List data, int offset) {
    int value = 0;
    int shift = 0;
    while (true) {
      if (offset >= data.length) return (0, offset);
      int b = data[offset];
      offset++;
      value |= (b & 0x7f) << shift;
      if ((b & 0x80) == 0) break;
      shift += 7;
    }
    return (value, offset);
  }

  static Future<ParsedGameData?> parseFile(File file, {String? userGameId, String? matchId}) async {
    try {
      final String content = await file.readAsString();
      final Uint8List data = base64Decode(content.trim());
      
      List<PlayerStats> playersList = [];
      int cursor = 0;
      int winnerTeamId = 0;
      int myTeamId = 0;
      List<Map<String, dynamic>> tempPlayers = [];

      while (cursor < data.length - 1) {
        int startBlock = -1;
        for (int i = cursor; i < data.length - 1; i++) {
          if (data[i] == 0x70 && data[i+1] == 0x50) {
            startBlock = i;
            break;
          }
        }
        if (startBlock == -1) break; 

        cursor = startBlock + 2; 

        List<int> itemIds = [];
        if (cursor < data.length) {
          int itemCount = data[cursor];
          cursor += 2; 
          
          for (int k = 0; k < itemCount; k++) {
            if (cursor + 1 >= data.length) break;
            int itemVal = data[cursor] | (data[cursor+1] << 8);
            if (itemVal > 0) itemIds.add(itemVal);
            cursor += 2; 
            while (cursor < data.length && data[cursor] == 0x00) cursor++;
            if (cursor < data.length && data[cursor] == 0x01) break;
          }
        }

        int heroId = 0;
        int k = 0, d = 0, a = 0;
        int level = 0;
        int totalGoldFromTag8 = 0;

        if (cursor < data.length && data[cursor] == 0x01) {
          cursor += 2; 
          while (cursor < data.length) {
            int tag = data[cursor];
            if (tag == 0x02) { var r = _rv(data, cursor + 1); heroId = r.$1; cursor = r.$2; }
            else if (tag == 0x03) { var r = _rv(data, cursor + 1); k = r.$1; cursor = r.$2; }
            else if (tag == 0x04) { var r = _rv(data, cursor + 1); d = r.$1; cursor = r.$2; }
            else if (tag == 0x05) { var r = _rv(data, cursor + 1); a = r.$1; cursor = r.$2; }
            else if (tag == 0x06) { var r = _rv(data, cursor + 1); level = r.$1; cursor = r.$2; }
            else if (tag == 0x07) { var r = _rv(data, cursor + 1); cursor = r.$2; }
            else if (tag == 0x08) { var r = _rv(data, cursor + 1); totalGoldFromTag8 = r.$1; cursor = r.$2; } 
            else break;
          }
        }

        int endBlock = -1;
        for (int i = cursor; i < data.length - 1; i++) {
          if (data[i] == 0x5F && data[i+1] == 0x58) {
            endBlock = i;
            break;
          }
        }
        if (endBlock == -1) endBlock = data.length;

        String name = "Unknown";
        String clanName = "";
        String playerIdStr = "";
        Map<int, int> fields = {};
        bool seenClanId = false;
        
        int localCursor = cursor;
        while (localCursor < endBlock) {
          int byte = data[localCursor];
          if (byte == 0x4d && localCursor + 1 < endBlock) {
             int len = data[localCursor + 1];
             if (len > 0 && len < 50 && (localCursor + 2 + len) <= endBlock) {
                try {
                  String potentialName = utf8.decode(data.sublist(localCursor + 2, localCursor + 2 + len));
                  if (potentialName.runes.every((r) => r >= 32)) {
                    name = potentialName;
                    localCursor += 2 + len;
                    if (localCursor < endBlock && data[localCursor] == 0x0e) {
                       var res = _rv(data, localCursor + 1);
                       playerIdStr = res.$1.toString();
                       localCursor = res.$2;
                    }
                    continue;
                  }
                } catch (_) {}
             }
          }
          if (byte == 0x0e) {
            var res = _rv(data, localCursor + 1);
            playerIdStr = res.$1.toString();
            localCursor = res.$2;
            continue;
          }
          if (byte == 0x0f && localCursor + 1 < endBlock) {
            int fid = data[localCursor + 1];
            var res = _rv(data, localCursor + 2);
            fields[fid] = res.$1;
            localCursor = res.$2;
            if (fid == 30) seenClanId = true;
            continue;
          }
          if (seenClanId && clanName.isEmpty && localCursor + 1 < endBlock) {
             int len = data[localCursor + 1];
             if (len >= 2 && len <= 20 && (localCursor + 2 + len) <= endBlock) {
                try {
                   String potentialClan = utf8.decode(data.sublist(localCursor + 2, localCursor + 2 + len));
                   if (potentialClan.runes.every((r) => r >= 32)) {
                      clanName = potentialClan;
                      localCursor += 2 + len;
                      continue;
                   }
                } catch (_) {}
             }
          }
          localCursor++;
        }

        int gold = totalGoldFromTag8;
        int damageHero = fields[19] ?? 0;
        int damageTower = fields[20] ?? 0;
        int damageTaken = fields[21] ?? 0;
        int heal = (fields[84] ?? 0) + (fields[85] ?? 0);
        int ccDuration = fields[83] ?? 0;
        int killStreak = fields[38] ?? 0;
        int serverId = fields[17] ?? 0;
        int score = fields[18] ?? 0; 
        
        String clanIdStr = (fields[30] ?? 0).toString();
        if (clanIdStr == '0') clanIdStr = '';
        String finalClanStr = clanName.isNotEmpty ? "$clanName [$clanIdStr]" : (clanIdStr.isNotEmpty ? clanIdStr : '');
        int lobbyId = fields[34] ?? 0;
        int roleId = fields[77] ?? fields[76] ?? 0;
        String role = 'unknown';
        if (roleId == 1) role = 'exp';
        else if (roleId == 2) role = 'mid';
        else if (roleId == 3) role = 'roam';
        else if (roleId == 4) role = 'jungle';
        else if (roleId == 5) role = 'gold';

        int teamId = fields[22] ?? 0;
        if (score == 1) winnerTeamId = teamId;

        bool isMe = false;
        if (userGameId != null && playerIdStr == userGameId.trim()) {
          isMe = true;
          myTeamId = teamId;
        }

        int fieldSpellId = fields[15] ?? 0;
        int finalSpellId = fieldSpellId;
        List<int> cleanItems = [];
        for (var it in itemIds) {
           final spellEntity = GameData.getSpell(it);
           if (spellEntity != null) finalSpellId = it; else cleanItems.add(it);
        }

        tempPlayers.add({
          'stats': PlayerStats(
            nickname: name, heroId: heroId, kda: "$k/$d/$a", gold: gold.toString(),
            itemIds: cleanItems, score: score, isEnemy: false, isUser: isMe, role: role,
            spellId: finalSpellId, playerId: playerIdStr, teamId: teamId, serverId: serverId,
            level: level, goldLane: fields[87] ?? 0, goldKill: fields[86] ?? 0, goldJungle: fields[82] ?? 0,
            damageHero: damageHero, damageTower: damageTower, damageTaken: damageTaken, heal: heal,
            ccDuration: ccDuration, killStreak: killStreak, clan: finalClanStr, partyId: lobbyId,
          )
        });
        cursor = endBlock + 2; 
      }

      String? foundMatchId;
      int durSecs = 0;
      int matchIdPos = -1;
      for (int i = cursor; i < data.length - 15; i++) {
        bool isDigit = true;
        for (int j = 0; j < 15; j++) { if (data[i + j] < 48 || data[i + j] > 57) { isDigit = false; break; } }
        if (isDigit) {
          matchIdPos = i;
          int endId = i;
          while (endId < data.length && data[endId] >= 48 && data[endId] <= 57) { endId++; }
          foundMatchId = utf8.decode(data.sublist(i, endId));
          break;
        }
      }

      if (matchIdPos != -1) {
        int gapSearch = cursor;
        while (gapSearch < matchIdPos - 1) {
          if (data[gapSearch] == 0x04) {
            var res = _rv(data, gapSearch + 1);
            int val = res.$1;
            if (val > 300000 && val < 4000000) { durSecs = val ~/ 1000; break; }
          }
          gapSearch++;
        }
      }

      if (durSecs == 0) {
        int footerCursor = matchIdPos != -1 ? matchIdPos : cursor;
        while (footerCursor < data.length - 1) {
          if (data[footerCursor] == 0x0e) {
            var res = _rv(data, footerCursor + 1);
            durSecs = res.$1;
            break;
          }
          footerCursor++;
        }
      }

      var (endTs, _) = _rv(data, 2);
      DateTime endTime = DateTime.fromMillisecondsSinceEpoch(endTs * 1000);
      DateTime startTime = durSecs > 0 ? endTime.subtract(Duration(seconds: durSecs)) : endTime;
      
      String formattedDuration = "00:00";
      if (durSecs > 0) {
        int mins = durSecs ~/ 60;
        int secs = durSecs % 60;
        formattedDuration = "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
      }

      String gameResult = 'DEFEAT';
      if (myTeamId != 0 && winnerTeamId != 0) if (myTeamId == winnerTeamId) gameResult = 'VICTORY';

      for (var pMap in tempPlayers) {
        PlayerStats p = pMap['stats'];
        bool isEnemy = false;
        if (myTeamId != 0) isEnemy = p.teamId != myTeamId;
        playersList.add(p.copyWith(isEnemy: isEnemy));
      }

      var mainPlayer = playersList.firstWhere((p) => p.isUser, orElse: () => playersList.first);

      return ParsedGameData(
        game: GameStats(
          matchId: foundMatchId ?? matchId ?? "", result: gameResult, heroId: mainPlayer.heroId, 
          kda: mainPlayer.kda, itemIds: mainPlayer.itemIds, score: mainPlayer.score,
          players: playersList.map((p) => p.nickname).join(', '),
          date: startTime, endDate: endTime, duration: formattedDuration, 
        ),
        players: playersList,
      );
    } catch (e) {
      debugPrint("Error parsing history file: $e");
      return null;
    }
  }
}
