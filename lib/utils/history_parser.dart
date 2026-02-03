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
  // VarInt decoder: returns (value, new_offset)
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
      final Uint8List data = base64Decode(content);
      
      List<PlayerStats> playersList = [];
      DateTime date = await file.lastModified(); 

      int cursor = 0;
      int winnerTeamId = 0;
      int myTeamId = 0;

      // Temporary list to hold parsed data before setting relative flags (enemy/victory)
      List<Map<String, dynamic>> tempPlayers = [];

      while (cursor < data.length - 1) {
        // 1. Find Start of Player Block (70 50)
        int startBlock = -1;
        for (int i = cursor; i < data.length - 1; i++) {
          if (data[i] == 0x70 && data[i+1] == 0x50) {
            startBlock = i;
            break;
          }
        }
        if (startBlock == -1) break; // No more players

        cursor = startBlock + 2; // Move past 70 50

        // 2. Parse Items
        // Format: [Count] [00] [Item1_Lo] [Item1_Hi] [00] [Item2_Lo] [Item2_Hi] ...
        List<int> itemIds = [];
        if (cursor < data.length) {
          int itemCount = data[cursor];
          debugPrint("Player found. Item count: $itemCount, Cursor: $cursor");
          cursor++; 
          cursor++; // Skip empty byte
          
          for (int k = 0; k < itemCount; k++) {
            if (cursor + 1 >= data.length) break;
            
            // Read Item
            int itemVal = data[cursor] | (data[cursor+1] << 8); // Little Endian
            if (itemVal > 0) itemIds.add(itemVal);
            cursor += 2; 
            
            // Exit if we reached the count limit
            if (k == itemCount - 1) break;
            
            if (cursor >= data.length) break;
            int nextByte = data[cursor];

            if (nextByte == 0x01) {
               // Found 01 marker immediately - End of items
               debugPrint("Hit 0x01 marker at index $k. End of items.");
               break;
            } else if (nextByte == 0x00) {
               // Check for double zero (padding)
               if (cursor + 1 < data.length && data[cursor + 1] == 0x00) {
                   debugPrint("Hit 0x00 0x00 padding at index $k. Skipping zeros...");
                   // Consume all zeros
                   while (cursor < data.length && data[cursor] == 0x00) {
                     cursor++;
                   }
                   // Loop ends, we expect to be at 01 now
                   break;
               } else {
                   // Standard single separator
                   cursor++; 
               }
            } else {
               // Unexpected byte, safer to stop
               debugPrint("Unexpected byte $nextByte at separator position. Stopping items.");
               break;
            }
          }
        }
        
        debugPrint("Cursor after items: $cursor. Next bytes: ${data.sublist(cursor, cursor + 5 > data.length ? data.length : cursor + 5)}");

        // 3. Parse KDA & Hero
        // Format: 01 [byte] 02 [HID] 03 [K] 04 [D] 05 [A] 06 [Lvl]
        int heroId = 0;
        int k = 0, d = 0, a = 0;
        int level = 0;

        if (cursor < data.length && data[cursor] == 0x01) {
          cursor += 2; // Skip 01 and the "unnecessary byte"
          
          while (cursor < data.length) {
            int tag = data[cursor];
            debugPrint("Found tag: $tag at $cursor");
            
            if (tag == 0x02) { var r = _rv(data, cursor + 1); heroId = r.$1; cursor = r.$2; debugPrint("Hero: $heroId"); }
            else if (tag == 0x03) { var r = _rv(data, cursor + 1); k = r.$1; cursor = r.$2; debugPrint("K: $k"); }
            else if (tag == 0x04) { var r = _rv(data, cursor + 1); d = r.$1; cursor = r.$2; debugPrint("D: $d"); }
            else if (tag == 0x05) { var r = _rv(data, cursor + 1); a = r.$1; cursor = r.$2; debugPrint("A: $a"); }
            else if (tag == 0x06) { var r = _rv(data, cursor + 1); level = r.$1; cursor = r.$2; debugPrint("Lvl: $level"); }
            else {
              // We hit unknown bytes after KDA block, break loop to scan for Name/Fields
              debugPrint("Unknown tag $tag at $cursor. Breaking KDA loop.");
              break; 
            }
          }
        } else {
           debugPrint("Expected 0x01 at $cursor but found ${data[cursor]}");
        }

        // 4. Find End of Block (5F 58) to limit search
        int endBlock = -1;
        for (int i = cursor; i < data.length - 1; i++) {
          if (data[i] == 0x5F && data[i+1] == 0x58) {
            endBlock = i;
            break;
          }
        }
        if (endBlock == -1) endBlock = data.length;

        // 5. Parse Name, ID and Fields within this range
        String name = "Unknown";
        String clanName = "";
        String playerIdStr = "";
        Map<int, int> fields = {};
        bool seenClanId = false;
        
        // Scan cursor -> endBlock
        int localCursor = cursor;
        while (localCursor < endBlock) {
          int byte = data[localCursor];

          // Name Check: 0x4D [Len] [String]
          if (byte == 0x4d && localCursor + 1 < endBlock) {
             int len = data[localCursor + 1];
             if (len > 0 && len < 50 && (localCursor + 2 + len) <= endBlock) {
                try {
                  String potentialName = utf8.decode(data.sublist(localCursor + 2, localCursor + 2 + len));
                  // Basic validation
                  if (potentialName.runes.every((r) => r >= 32)) {
                    name = potentialName;
                    localCursor += 2 + len;
                    
                    // Strict ID Check: Look for 0x0E immediately after name
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
          
          // ID Check: 0x0E [VarInt]
          if (byte == 0x0e) {
            var res = _rv(data, localCursor + 1);
            playerIdStr = res.$1.toString();
            localCursor = res.$2;
            continue;
          }

          // Fields Check: 0x0F [Tag] [VarInt]
          if (byte == 0x0f && localCursor + 1 < endBlock) {
            int fid = data[localCursor + 1];
            var res = _rv(data, localCursor + 2);
            fields[fid] = res.$1;
            localCursor = res.$2;
            
            if (fid == 30) seenClanId = true;
            continue;
          }
          
          // Clan Name Search: If we saw Clan ID (30) recently, check for string
          // Assuming format: [Tag] [Len] [String]
          // Tag is unknown, but likely 0x32, 0x3A, or just any byte that isn't 0F/0E
          if (seenClanId && clanName.isEmpty && localCursor + 1 < endBlock) {
             int len = data[localCursor + 1];
             // Heuristic: Length must be reasonable for a clan name (e.g., 2-15 chars)
             if (len >= 2 && len <= 20 && (localCursor + 2 + len) <= endBlock) {
                try {
                   String potentialClan = utf8.decode(data.sublist(localCursor + 2, localCursor + 2 + len));
                   // Strict validation for clan name characters
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

        // 6. Assemble Player Stats
        int goldJungle = fields[82] ?? 0;
        int goldKill = fields[86] ?? 0;
        int goldLane = fields[87] ?? 0;
        int gold = goldJungle + goldKill + goldLane;
        
        int damageHero = fields[19] ?? 0;
        int damageTower = fields[20] ?? 0;
        int damageTaken = fields[21] ?? 0;
        int heal = (fields[84] ?? 0) + (fields[85] ?? 0);

        String score = "${fields[18] ?? 0.0}"; 
        
        // Extra info
        String clanIdStr = (fields[30] ?? 0).toString();
        if (clanIdStr == '0') clanIdStr = '';
        
        // Combine Clan Name and ID if available
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
        
        // Score field 18 is Medal. 1=MVP
        int medal = fields[18] ?? 0;
        if (medal == 1) {
          winnerTeamId = teamId;
        }

        // Check if this is user
        bool isMe = false;
        debugPrint("Player: $name, ID: $playerIdStr, Team: $teamId. Searching for UserID: $userGameId");
        if (userGameId != null && playerIdStr == userGameId.trim()) {
          isMe = true;
          myTeamId = teamId;
          debugPrint(">>> FOUND USER! Team ID: $myTeamId");
        }

        int fieldSpellId = fields[15] ?? 0;
        
        // Check for Spells in item list (Blessings override generic spells)
        int finalSpellId = fieldSpellId;
        List<int> cleanItems = [];
        for (var it in itemIds) {
           if (GameData.getSpell(it) != null) {
             finalSpellId = it;
           } else {
             cleanItems.add(it);
           }
        }

        tempPlayers.add({
          'stats': PlayerStats(
            nickname: name,
            heroId: heroId,
            kda: "$k/$d/$a",
            gold: gold.toString(),
            itemIds: cleanItems,
            score: score,
            isEnemy: false, // Calculated later
            isUser: isMe, 
            role: role,
            spellId: finalSpellId,
            playerId: playerIdStr,
            teamId: teamId,
            level: level,
            goldLane: goldLane,
            goldKill: goldKill,
            goldJungle: goldJungle,
            damageHero: damageHero,
            damageTower: damageTower,
            damageTaken: damageTaken,
            heal: heal,
            clan: finalClanStr,
            partyId: lobbyId,
          )
        });

        cursor = endBlock + 2; 
      }

      // Final pass to set relative stats
      String gameResult = 'DEFEAT';
      if (myTeamId != 0 && winnerTeamId != 0) {
        if (myTeamId == winnerTeamId) gameResult = 'VICTORY';
      }

      for (var pMap in tempPlayers) {
        PlayerStats p = pMap['stats'];
        bool isEnemy = false;
        if (myTeamId != 0) {
          isEnemy = p.teamId != myTeamId;
        }
        playersList.add(p.copyWith(isEnemy: isEnemy));
      }

      // Determine main hero for the game record (User's hero or MVP or first)
      var mainPlayer = playersList.firstWhere((p) => p.isUser, orElse: () => playersList.first);

      return ParsedGameData(
        game: GameStats(
          matchId: matchId ?? "",
          result: gameResult,
          heroId: mainPlayer.heroId, 
          kda: mainPlayer.kda,
          itemIds: mainPlayer.itemIds,
          players: playersList.map((p) => p.nickname).join(', '),
          date: date,
          duration: "00:00", 
        ),
        players: playersList,
      );
      
    } catch (e) {
      debugPrint("Error parsing history file: $e");
      return null;
    }
  }
}
