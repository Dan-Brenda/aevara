// lib/data/services/leaderboard_service.dart
import '../models/leaderboard.dart';

abstract class LeaderboardService {
  List<LeaderboardEntry> weeklySteps();
  List<LeaderboardEntry> sleepStreaks();
  List<LeaderboardEntry> experimentGains();
}
