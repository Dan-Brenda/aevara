// lib/data/models/challenge.dart

enum ChallengeStatus { active, upcoming, completed }

class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.goal,
    required this.progress,
    required this.unit,
    required this.timeLabel,
    required this.participants,
    required this.yourRank,
  });

  final String id;
  final String title;
  final String description;
  final ChallengeStatus status;
  final int goal;
  final int progress;
  final String unit;
  final String timeLabel;
  final List<String> participants;
  final int? yourRank;

  double get fraction => goal == 0 ? 0 : (progress / goal).clamp(0.0, 1.0);
}
