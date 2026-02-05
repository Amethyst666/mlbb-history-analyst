import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../utils/database_helper.dart';
import '../utils/app_strings.dart';

class PlayerSettingsScreen extends StatefulWidget {
  final PlayerProfile profile;
  const PlayerSettingsScreen({super.key, required this.profile});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  final _dbHelper = DatabaseHelper();
  final _aliasController = TextEditingController();
  final _commentController = TextEditingController();

  List<String> _aliases = [];
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final aliases = await _dbHelper.getNicknamesForProfile(widget.profile.id!);
    final comments = await _dbHelper.getComments(widget.profile.id!);
    setState(() {
      _aliases = aliases;
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _addAlias() async {
    final alias = _aliasController.text.trim();
    if (alias.isEmpty) return;
    await _dbHelper.addAlias(widget.profile.id!, alias);
    _aliasController.clear();
    _loadData();
  }

  Future<void> _deleteAlias(String alias) async {
    await _dbHelper.deleteAlias(widget.profile.id!, alias);
    _loadData();
  }

  Future<void> _pinAlias(String? alias) async {
    await _dbHelper.pinAlias(widget.profile.id!, alias);
    widget.profile.pinnedAlias = alias;
    _loadData();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    await _dbHelper.addComment(widget.profile.id!, text);
    _commentController.clear();
    _loadData();
  }

  Future<void> _deleteComment(int id) async {
    await _dbHelper.deleteComment(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get(context, 'player_settings'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle(AppStrings.get(context, 'alias')),
                const SizedBox(height: 10),
                _buildAliasInput(),
                const SizedBox(height: 10),
                ..._aliases.map((a) => _buildAliasTile(a)).toList(),
                const SizedBox(height: 30),
                _buildSectionTitle(AppStrings.get(context, 'comments')),
                const SizedBox(height: 10),
                _buildCommentInput(),
                const SizedBox(height: 10),
                ..._comments.map((c) => _buildCommentTile(c)).toList(),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.cyanAccent,
        fontSize: 16,
      ),
    );
  }

  Widget _buildAliasInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _aliasController,
            decoration: InputDecoration(
              hintText: AppStrings.get(context, 'add_alias'),
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
          onPressed: _addAlias,
        ),
      ],
    );
  }

  Widget _buildAliasTile(String alias) {
    final bool isPinned = widget.profile.pinnedAlias == alias;
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: ListTile(
        title: Text(alias),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: isPinned ? Colors.orangeAccent : Colors.white38,
              ),
              onPressed: () => _pinAlias(isPinned ? null : alias),
              tooltip: isPinned
                  ? AppStrings.get(context, 'unpin')
                  : AppStrings.get(context, 'pin_desc'),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () => _deleteAlias(alias),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: AppStrings.get(context, 'add_comment_hint'),
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_comment, color: Colors.cyanAccent),
          onPressed: _addComment,
        ),
      ],
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> c) {
    final DateTime date = DateTime.parse(c['timestamp']);
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: ListTile(
        title: Text(c['comment']),
        subtitle: Text(
          date.toString().substring(0, 16),
          style: const TextStyle(fontSize: 10, color: Colors.white24),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 20,
          ),
          onPressed: () => _deleteComment(c['id']),
        ),
      ),
    );
  }
}
