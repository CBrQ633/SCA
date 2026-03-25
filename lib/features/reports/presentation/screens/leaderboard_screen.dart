import 'package:flutter/material.dart';
import 'package:smart_call_assistant/features/auth/data/auth_repository.dart';
import 'package:animate_do/animate_do.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final AuthRepository _authRepo = AuthRepository();
  List<Map<String, dynamic>> _leaders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    final data = await _authRepo.getGlobalLeaderboard();
    if (mounted) {
      setState(() {
        _leaders = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isArabic ? 'لوحة الشرف' : 'Leaderboard', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildTopThree(theme, isArabic),
                  const SizedBox(height: 32),
                  Text(
                    isArabic ? 'الترتيب العام' : 'Global Rankings',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_leaders.length, (index) {
                    if (index < 3) return const SizedBox.shrink(); // Already shown in top three
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 50),
                      child: _buildRankTile(index + 1, _leaders[index], theme),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildTopThree(ThemeData theme, bool isArabic) {
    if (_leaders.isEmpty) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        if (_leaders.length > 1) _buildPodiumItem(_leaders[1], 2, 120, Colors.grey, theme),
        
        // 1st Place
        if (_leaders.length > 0) _buildPodiumItem(_leaders[0], 1, 160, Colors.amber, theme),
        
        // 3rd Place
        if (_leaders.length > 2) _buildPodiumItem(_leaders[2], 3, 100, Colors.brown, theme),
      ],
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int rank, double height, Color color, ThemeData theme) {
    return Column(
      children: [
        CircleAvatar(
          radius: rank == 1 ? 35 : 28,
          backgroundColor: color.withOpacity(0.2),
          child: Text(user['full_name']?[0].toUpperCase() ?? 'U', style: TextStyle(color: color, fontSize: rank == 1 ? 24 : 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(user['full_name'] ?? 'User', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankTile(int rank, Map<String, dynamic> user, ThemeData theme) {
    double progress = user['score'] ?? 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey.withOpacity(0.1),
          child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        title: Text(user['full_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SCA ID: ${user['sca_id']}', style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 4, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary)),
            ),
          ],
        ),
        trailing: Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
