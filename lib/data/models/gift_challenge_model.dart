// lib/data/models/gift_challenge_model.dart

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: (json['slug'] ?? json['id'])?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      isUnlocked: json['is_unlocked'] ??
          json['unlocked'] ??
          (json['unlocked_at'] != null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'is_unlocked': isUnlocked,
    };
  }
}

class RewardStats {
  final int pointsMensuels;
  final int pointsTotaux;
  final double goalProgress;
  final int rank;
  final int monthlyGoal;
  final List<Badge> unlockedBadges;
  final List<Badge> availableBadges;

  RewardStats({
    required this.pointsMensuels,
    required this.pointsTotaux,
    required this.goalProgress,
    required this.rank,
    this.monthlyGoal = 250,
    required this.unlockedBadges,
    required this.availableBadges,
  });

  factory RewardStats.fromJson(Map<String, dynamic> json) {
    // The user guide says data is under 'data' key or directly in stats
    var stats = json['data'] ?? json;

    // Support parsing from both nested and flat structures
    int pointsMensuels = 0;
    int rank = 0;
    if (stats['current_user'] is Map) {
      pointsMensuels = stats['current_user']['points'] ?? 0;
      rank = stats['current_user']['rank'] ?? 0;
    } else if (stats['current_month'] is Map) {
      pointsMensuels = stats['current_month']['points'] ?? 0;
      rank = stats['current_rank'] ?? 0;
    } else {
      pointsMensuels = stats['points_mensuels'] ?? 0;
      rank = stats['current_rank'] ?? 0;
    }

    return RewardStats(
      pointsMensuels: pointsMensuels,
      pointsTotaux: stats['total_points'] ?? pointsMensuels,
      goalProgress: (stats['goal_progress'] as num?)?.toDouble() ?? 0.0,
      rank: rank,
      monthlyGoal: stats['monthly_goal'] ?? 250,
      unlockedBadges: (stats['user_badges'] as List?)
              ?.map((i) => Badge.fromJson(i))
              .toList() ??
          [],
      availableBadges: (stats['available_badges'] as List?)
              ?.map((i) => Badge.fromJson(i))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_points': pointsTotaux,
      'points_mensuels': pointsMensuels,
      'goal_progress': goalProgress,
      'current_rank': rank,
      'monthly_goal': monthlyGoal,
      'user_badges': unlockedBadges.map((b) => b.toJson()).toList(),
      'available_badges': availableBadges.map((b) => b.toJson()).toList(),
    };
  }
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final String? avatar;
  final int points;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    this.avatar,
    required this.points,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      name: json['name'] ?? '',
      avatar: json['avatar'],
      points: json['points'] ?? 0,
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'name': name,
      'avatar': avatar,
      'points': points,
      'is_current_user': isCurrentUser,
    };
  }
}

class PointHistoryItem {
  final int points;
  final String description;
  final DateTime date;
  final String type;

  PointHistoryItem({
    required this.points,
    required this.description,
    required this.date,
    required this.type,
  });

  factory PointHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      if (json['date'] != null && json['date'].toString().contains('/')) {
        // Format: "28/01/2026 07:56"
        final dateStr = json['date'].toString();
        final parts = dateStr.split(' ');
        final dateParts = parts[0].split('/');
        final timeParts = parts[1].split(':');
        parsedDate = DateTime(
          int.parse(dateParts[2]), // année
          int.parse(dateParts[1]), // mois
          int.parse(dateParts[0]), // jour
          int.parse(timeParts[0]), // heure
          int.parse(timeParts[1]), // minute
        );
      } else {
        parsedDate = DateTime.parse(json['date'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String());
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return PointHistoryItem(
      points: json['points'] ?? 0,
      description: json['description'] ?? '',
      date: parsedDate,
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'description': description,
      'created_at': date.toIso8601String(),
      'type': type,
    };
  }
}
