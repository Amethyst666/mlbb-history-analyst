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

  static Future<ParsedGameData?> parseFile(
    File file, {
    String? userGameId,
    String? matchId,
  }) async {
    try {
      final String content = await file.readAsString();
      final Uint8List data = base64Decode(content.trim());
      return parseData(data, userGameId: userGameId, matchId: matchId);
    } catch (_) {
      return null;
    }
  }

  static ParsedGameData? parseData(
    Uint8List data, {
    String? userGameId,
    String? matchId,
  }) {
    try {
      List<PlayerStats> playersList = [];
      int cursor = 0;
      int winnerTeamId = 0;
      int myTeamId = 0;
      List<Map<String, dynamic>> tempPlayers = [];

      while (cursor < data.length - 1 && tempPlayers.length < 10) {
        int startBlock = -1;
        for (int i = cursor; i < data.length - 1; i++) {
          if (data[i] == 0x70 && data[i + 1] == 0x50) {
            startBlock = i;
            break;
          }
        }
        if (startBlock == -1) break;
        cursor = startBlock + 2;

        // 1. Items
        List<int> itemIds = [];
        int itemCount = data[cursor];
        cursor += 2;
        for (int k = 0; k < itemCount; k++) {
          if (cursor + 1 >= data.length) break;
          int itemVal = data[cursor] | (data[cursor + 1] << 8);
          if (itemVal > 0) itemIds.add(itemVal);
          cursor += 2;
          while (cursor < data.length && data[cursor] == 0x00) cursor++;
          if (cursor < data.length && data[cursor] == 0x01) break;
        }

        // 2. KDA Block (01 -> Length -> Tags 02-08)
        int heroId = 0, k = 0, d = 0, a = 0, level = 0, totalGold = 0;
        if (cursor < data.length && data[cursor] == 0x01) {
          cursor++;
          var resLen = _rv(data, cursor); // Read and skip the block length
          cursor = resLen.$2;

          while (cursor < data.length) {
            int tag = data[cursor];
            if (tag >= 0x02 && tag <= 0x09) {
              var r = _rv(data, cursor + 1);
              if (tag == 0x02)
                heroId = r.$1;
              else if (tag == 0x03)
                k = r.$1;
              else if (tag == 0x04)
                d = r.$1;
              else if (tag == 0x05)
                a = r.$1;
              else if (tag == 0x06)
                level = r.$1;
              else if (tag == 0x08)
                totalGold = r.$1;
              cursor = r.$2;
            } else
              break;
          }
        }

        // 3. Nickname Search (Tag 4d)
        String name = "Unknown";
        int ns = cursor;
        while (ns < cursor + 200 && ns < data.length - 2) {
          if (data[ns] == 0x4d) {
            int len = data[ns + 1];
            if (len > 2 && len < 35 && ns + 2 + len <= data.length) {
              try {
                String n = utf8.decode(data.sublist(ns + 2, ns + 2 + len));
                if (n.runes.every((r) => r >= 32) && !n.contains('/')) {
                  name = n;
                  cursor = ns + 2 + len;
                  break;
                }
              } catch (_) {}
            }
          }
          ns++;
        }

        // 4. Detailed Fields (ID, Server, Battle Stats)
        String pId = "";
        int srv = 0;
        Map<int, int> f = {};
        int fc = cursor;
        while (fc < cursor + 800 && fc < data.length - 1) {
          if (data[fc] == 0x0e) {
            var r = _rv(data, fc + 1);
            if (r.$1 > 1000000) {
              pId = r.$1.toString();
              fc = r.$2;
              continue;
            }
          }
          if (data[fc] == 0x0f) {
            int fid = data[fc + 1];
            var r = _rv(data, fc + 2);
            f[fid] = r.$1;
            if (fid == 17) srv = r.$1;
            fc = r.$2;
            continue;
          }
          if (data[fc] == 0x5f && data[fc + 1] == 0x58) {
            fc += 2;
            break;
          }
          fc++;
        }

        int teamId = f[22] ?? 0;
        if ((f[18] ?? 0) == 1) winnerTeamId = teamId;
        bool isMe = (userGameId != null && pId == userGameId.trim());
        if (isMe) myTeamId = teamId;

        int rid = f[77] ?? f[76] ?? 0;
        String role = 'unknown';
        if (rid == 1)
          role = 'exp';
        else if (rid == 2)
          role = 'mid';
        else if (rid == 3)
          role = 'roam';
        else if (rid == 4)
          role = 'jungle';
        else if (rid == 5)
          role = 'gold';

        tempPlayers.add({
          'stats': PlayerStats(
            nickname: name,
            heroId: heroId,
            kda: "$k/$d/$a",
            gold: totalGold.toString(),
            itemIds: itemIds,
            score: f[18] ?? 0,
            isEnemy: false,
            isUser: isMe,
            role: role,
            spellId: f[15] ?? 0,
            playerId: pId,
            teamId: teamId,
            serverId: srv,
            level: level,
            goldLane: f[87] ?? 0,
            goldKill: f[86] ?? 0,
            goldJungle: f[82] ?? 0,
            damageHero: f[19] ?? 0,
            damageTower: f[20] ?? 0,
            damageTaken: f[21] ?? 0,
            heal: (f[84] ?? 0) + (f[85] ?? 0),
            ccDuration: f[83] ?? 0,
            killStreak: f[38] ?? 0,
            clan: "",
            partyId: f[34] ?? 0,
          ),
        });
        cursor = fc;
      }

      // Final Team Splitting
      int refTeam = myTeamId != 0
          ? myTeamId
          : (tempPlayers.isNotEmpty ? tempPlayers.first['stats'].teamId : 0);
      List<PlayerStats> finalPlayers = [];
      for (var p in tempPlayers) {
        PlayerStats s = p['stats'];
        finalPlayers.add(s.copyWith(isEnemy: s.teamId != refTeam));
      }

      // Metadata: Match ID and Precise Duration
      String? foundMatchId;
      int durSecs = 0;
      int matchIdPos = -1;
      for (int i = cursor; i < data.length - 15; i++) {
        bool isDigit = true;
        for (int j = 0; j < 15; j++) {
          if (data[i + j] < 48 || data[i + j] > 57) {
            isDigit = false;
            break;
          }
        }
        if (isDigit) {
          matchIdPos = i;
          int endId = i;
          while (endId < data.length &&
              data[endId] >= 48 &&
              data[endId] <= 57) {
            endId++;
          }
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
            if (val > 300000 && val < 4000000) {
              durSecs = val ~/ 1000;
              break;
            }
          }
          gapSearch++;
        }
      }

      var (endTs, _) = _rv(data, 2);
      DateTime et = DateTime.fromMillisecondsSinceEpoch(endTs * 1000);
      DateTime st = durSecs > 0 ? et.subtract(Duration(seconds: durSecs)) : et;
      String formattedDuration = "00:00";
      if (durSecs > 0) {
        int mins = durSecs ~/ 60;
        int secs = durSecs % 60;
        formattedDuration =
            "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
      }

      PlayerStats? m;
      try {
        m = finalPlayers.firstWhere((p) => p.isUser);
      } catch (_) {
        m = null;
      }

      return ParsedGameData(
        game: GameStats(
          matchId: foundMatchId ?? matchId ?? "",
          result: (myTeamId != 0 && myTeamId == winnerTeamId)
              ? 'VICTORY'
              : 'DEFEAT',
          heroId: m?.heroId ?? 0,
          kda: m?.kda ?? "0/0/0",
          itemIds: m?.itemIds ?? [],
          score: m?.score ?? 0,
          role: m?.role ?? 'unknown',
          spellId: m?.spellId ?? 0,
          players: finalPlayers.map((p) => p.nickname).join(', '),
          date: st,
          endDate: et,
          duration: formattedDuration,
        ),
        players: finalPlayers,
      );
    } catch (_) {
      return null;
    }
  }
}
