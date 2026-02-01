import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../utils/database_helper.dart';

class PlayerProfileScreen extends StatefulWidget {
  final PlayerProfile profile;
  const PlayerProfileScreen({super.key, required this.profile});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final _dbHelper = DatabaseHelper();
  late bool _isVerified;

  @override
  void initState() {
    super.initState();
    _isVerified = widget.profile.isVerified;
  }

  void _toggleVerify() async {
    setState(() => _isVerified = !_isVerified);
    await _dbHelper.toggleVerification(widget.profile.id!, _isVerified);
    widget.profile.isVerified = _isVerified;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.mainNickname),
        backgroundColor: const Color(0xFF1A1C2C),
        actions: [
          IconButton(
            icon: Icon(_isVerified ? Icons.verified : Icons.verified_outlined, 
              color: _isVerified ? Colors.cyanAccent : Colors.white54),
            onPressed: _toggleVerify,
            tooltip: "Верифицировать игрока",
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: widget.profile.isUser ? Colors.cyanAccent : Colors.deepPurpleAccent,
                  child: Icon(widget.profile.isUser ? Icons.person : Icons.people, size: 50, color: Colors.black),
                ),
                if (_isVerified)
                  const Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      radius: 15, backgroundColor: Color(0xFF1A1C2C),
                      child: Icon(Icons.verified, color: Colors.cyanAccent, size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.profile.mainNickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                if (_isVerified) const SizedBox(width: 8),
                if (_isVerified) const Icon(Icons.verified, color: Colors.cyanAccent, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(widget.profile.isUser ? "Это ваш профиль" : (_isVerified ? "Верифицированный игрок" : "Профиль игрока"), 
              style: TextStyle(color: _isVerified ? Colors.cyanAccent.withOpacity(0.7) : Colors.grey)),
            const SizedBox(height: 40),
            const Text("Статистика будет здесь...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white24)),
          ],
        ),
      ),
    );
  }
}