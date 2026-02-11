// lib/data/services/gift_challenge_service.dart
import 'package:ASSOU/config/api_endpoints.dart';
import 'package:ASSOU/config/environment.dart';
import 'package:ASSOU/data/models/gift_challenge_model.dart';
import 'api_service.dart';
import 'user_service.dart';

class GiftChallengeService {
  /// Récupérer les statistiques du Dashboard (Points, Progrès, Badges)
  static Future<RewardStats?> getStats() async {
    try {
      final url = ApiEndpoints.giftChallengeStats;
      print('DEBUG [REWARDS] Fetching stats from: $url');
      final response = await ApiService.get<Map<String, dynamic>>(url);

      if (response.isSuccess && response.data != null) {
        return RewardStats.fromJson(response.data!);
      }
      print(
          'DEBUG [REWARDS] getStats failed: ${response.statusCode} - ${response.message}');
      return null;
    } catch (e) {
      if (Environment.debugMode) {
        print('GiftChallengeService.getStats error: $e');
      }
      return null;
    }
  }

  /// Récupérer le Top 20 des utilisateurs du mois
  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final url = ApiEndpoints.giftChallengeLeaderboard;
      print('DEBUG [REWARDS] Fetching leaderboard from: $url');
      final response = await ApiService.get<Map<String, dynamic>>(url);

      if (response.isSuccess && response.data != null) {
        print('DEBUG [REWARDS] Response data keys: ${response.data!.keys}');

        // ApiService already extracts the 'data' object from API response
        // Access leaderboard array directly from response.data
        final leaderboardList = response.data!['leaderboard'] as List?;
        if (leaderboardList == null || leaderboardList.isEmpty) {
          print('DEBUG [REWARDS] Leaderboard is null or empty');
          return [];
        }

        // Get current user ID if available
        // Check multiple possible keys for user ID
        final currentUser = response.data!['current_user'];
        print('DEBUG [REWARDS] current_user content: $currentUser');

        dynamic currentUserId;
        if (currentUser is Map) {
          currentUserId = currentUser['user_id'] ??
              currentUser['id'] ??
              currentUser['userId'];
        } else if (currentUser is int) {
          currentUserId = currentUser;
        }

        // Fallback: use local user ID if not provided by leaderboard API
        if (currentUserId == null) {
          final localUser = await UserService.getCurrentUser();
          currentUserId = localUser?.id;
          print('DEBUG [REWARDS] Using fallback local user ID: $currentUserId');
        }

        print(
            'DEBUG [REWARDS] Identified current user ID from leaderboard data: $currentUserId');

        print('DEBUG [REWARDS] Found ${leaderboardList.length} entries');
        print('DEBUG [REWARDS] Current user ID: $currentUserId');

        // Map to LeaderboardEntry and mark current user
        return leaderboardList.map((item) {
          final entry = item as Map<String, dynamic>;

          // Get entry ID robustly
          final dynamic entryId =
              entry['user_id'] ?? entry['id'] ?? entry['userId'];

          // Mark as current user if IDs match (with string fallback to be safe)
          if (currentUserId != null &&
              entryId != null &&
              entryId.toString() == currentUserId.toString()) {
            entry['is_current_user'] = true;
          } else {
            entry['is_current_user'] = false;
          }
          return LeaderboardEntry.fromJson(entry);
        }).toList();
      }

      print(
          'DEBUG [REWARDS] getLeaderboard failed or empty: ${response.statusCode} - ${response.message}');
      return [];
    } catch (e) {
      print('DEBUG [REWARDS] getLeaderboard error: $e');
      if (Environment.debugMode) {
        print('GiftChallengeService.getLeaderboard error: $e');
      }
      return [];
    }
  }

  /// Récupérer l'historique détaillé des points
  static Future<List<PointHistoryItem>> getHistory() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.giftChallengeHistory,
      );

      if (response.isSuccess && response.data != null) {
        var list = response.data!['data'] as List?;
        return list?.map((i) => PointHistoryItem.fromJson(i)).toList() ?? [];
      }
      return [];
    } catch (e) {
      if (Environment.debugMode) {
        print('GiftChallengeService.getHistory error: $e');
      }
      return [];
    }
  }

  /// Récupérer la liste exhaustive des badges
  static Future<List<Badge>> getBadges() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.giftChallengeBadges,
      );

      if (response.isSuccess && response.data != null) {
        var list = response.data!['data'] as List?;
        return list?.map((i) => Badge.fromJson(i)).toList() ?? [];
      }
      return [];
    } catch (e) {
      if (Environment.debugMode) {
        print('GiftChallengeService.getBadges error: $e');
      }
      return [];
    }
  }
}
