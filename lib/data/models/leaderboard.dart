// lib/data/models/leaderboard.dart

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.value,
    this.isYou = false,
  });

  final int rank;
  final String name;
  final String value;
  final bool isYou;
}
