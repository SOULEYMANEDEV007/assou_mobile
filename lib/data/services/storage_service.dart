import 'dart:convert';
import 'package:ASSOU/data/models/gift_challenge_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _rewardKey = 'gift_challenge_stats';
  static const String _lastUpdateKey = 'last_gift_challenge_update';

  String _getRewardKey(int userId) => '${_rewardKey}_user_$userId';

  Future<void> saveStats(RewardStats stats, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getRewardKey(userId), jsonEncode(stats.toJson()));
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  Future<RewardStats?> getSavedStats(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_getRewardKey(userId));
    if (statsJson != null) {
      try {
        return RewardStats.fromJson(jsonDecode(statsJson));
      } catch (e) {
        print('Error decoding saved stats: $e');
        return null;
      }
    }
    return null;
  }

  Future<bool> shouldRefreshRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(_lastUpdateKey);

    if (lastUpdate == null) return true;

    final lastUpdateTime = DateTime.parse(lastUpdate);
    final now = DateTime.now();

    // Rafraîchir toutes les 5 minutes au lieu de 1 heure
    return now.difference(lastUpdateTime).inMinutes >= 5;
  }

  static const String _lastUserIdKey = 'last_reward_user_id';

  Future<int?> getLastUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastUserIdKey);
  }

  Future<void> saveLastUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUserIdKey, userId);
  }
}
