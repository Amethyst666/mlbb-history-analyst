import 'package:flutter/material.dart';
import '../models/player_stats.dart';
import '../utils/data_utils.dart';
import '../utils/app_strings.dart';
import '../models/player_profile.dart';
import '../screens/player_profile_screen.dart';

class PlayerMatchStatsDialog extends StatelessWidget {
  final PlayerStats player;
  final Map<String, int> teamTotals;
  final bool isDeveloperMode;

  const PlayerMatchStatsDialog({
    super.key,
    required this.player,
    required this.teamTotals,
    this.isDeveloperMode = false,
  });

  String _formatFullNumber(int num) {
    return num.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    final heroName = DataUtils.getLocalizedHeroName(player.heroId, context);
    
    final kdaParts = player.kda.split('/');
    int pKills = int.tryParse(kdaParts[0]) ?? 0;
    int pAssists = kdaParts.length > 2 ? (int.tryParse(kdaParts[2]) ?? 0) : 0;
    int teamKills = teamTotals['kills'] ?? 1;
    double killPart = teamKills > 0 ? (pKills + pAssists) / teamKills : 0.0;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  DataUtils.getHeroIcon(player.heroId, radius: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (player.profileId != null) {
                              Navigator.of(context).pop();
                              Navigator.push(context, MaterialPageRoute(builder: (c) => PlayerProfileScreen(profile: PlayerProfile(id: player.profileId, mainNickname: player.nickname))));
                            }
                          },
                          child: Text(
                            player.nickname,
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(isDeveloperMode ? "$heroName (${player.heroId})" : heroName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        if (player.playerId != null && player.playerId!.isNotEmpty)
                          Text("ID: ${player.playerId}", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                      ],
                    ),
                  ),
                  DataUtils.getMedalIcon(player.score, size: 30),
                ],
              ),
              const Divider(color: Colors.white24, height: 30),

              // Basic Info
              _buildStatRow(AppStrings.get(context, 'kda'), player.kda, icon: Icons.bolt),
              _buildStatRow(AppStrings.get(context, 'level'), player.level.toString(), icon: Icons.trending_up),
              _buildStatRow(AppStrings.get(context, 'role'), DataUtils.getLocalizedRoleName(player.role, context), icon: Icons.shield, trailing: DataUtils.getRoleIcon(player.role, size: 18)),
              if (player.spellId != 0)
                _buildStatRow(AppStrings.get(context, 'spell'), "", icon: Icons.auto_fix_high, trailing: DataUtils.getSpellIcon(DataUtils.getDisplaySpellId(player.spellId, player.itemIds), size: 24)),

              const SizedBox(height: 20),
              _buildSectionTitle(AppStrings.get(context, 'items').toUpperCase(), trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(player.gold, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 12),
                ],
              )),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: player.itemIds.map((id) => DataUtils.getItemIcon(id, size: 35)).toList(),
              ),

              const SizedBox(height: 25),
              _buildSectionTitle(AppStrings.get(context, 'battle_stats')),
              _buildStatWithBar(AppStrings.get(context, 'damage_hero'), player.damageHero, teamTotals['damageHero']!, Colors.redAccent),
              _buildStatWithBar(AppStrings.get(context, 'damage_tower'), player.damageTower, teamTotals['damageTower']!, Colors.orangeAccent),
              _buildStatWithBar(AppStrings.get(context, 'damage_taken'), player.damageTaken, teamTotals['damageTaken']!, Colors.grey),
              _buildStatWithBar(AppStrings.get(context, 'heal_label'), player.heal, teamTotals['heal']!, Colors.greenAccent),
              
              const SizedBox(height: 10),
              _buildStatRow(AppStrings.get(context, 'kill_part'), "${(killPart * 100).toStringAsFixed(1)}%", icon: Icons.group),
              _buildStatRow(AppStrings.get(context, 'cc_label'), player.ccDuration.toString(), icon: Icons.timer_outlined),
              _buildStatRow(AppStrings.get(context, 'best_streak'), player.killStreak.toString(), icon: Icons.military_tech),

              const SizedBox(height: 25),
              _buildSectionTitle(AppStrings.get(context, 'gold_sources')),
              _buildStatWithBar(AppStrings.get(context, 'lane_gold'), player.goldLane, int.tryParse(player.gold) ?? 0, Colors.amberAccent),
              _buildStatWithBar(AppStrings.get(context, 'kill_gold'), player.goldKill, int.tryParse(player.gold) ?? 0, Colors.amber),
              _buildStatWithBar(AppStrings.get(context, 'jungle_gold'), player.goldJungle, int.tryParse(player.gold) ?? 0, Colors.orange),

              const SizedBox(height: 30),
              Center(
                child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppStrings.get(context, 'close'), style: const TextStyle(color: Colors.white54))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {IconData? icon, Color? color, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: Colors.white38), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  Widget _buildStatWithBar(String label, int value, int total, Color color) {
    double percent = (total > 0) ? (value / total) : 0.0;
    if (percent > 1.0) percent = 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text("${_formatFullNumber(value)} (${(percent * 100).toStringAsFixed(1)}%)", 
                   style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
