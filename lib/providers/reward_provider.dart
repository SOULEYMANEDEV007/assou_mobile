// lib/providers/reward_provider.dart
import 'dart:async';
import 'package:ASSOU/data/models/gift_challenge_model.dart';
import 'package:ASSOU/data/services/gift_challenge_service.dart';
import 'package:ASSOU/data/services/storage_service.dart';
import 'package:ASSOU/data/services/user_service.dart';
import 'package:flutter/foundation.dart';

class RewardProvider with ChangeNotifier {
  RewardStats? _stats;
  List<LeaderboardEntry> _leaderboard = [];
  List<PointHistoryItem> _history = [];
  List<Badge> _allBadges = [];

  bool _isStatsLoading = false;
  bool _isLeaderboardLoading = false;
  bool _isHistoryLoading = false;
  bool _isBadgesLoading = false;

  bool get isLoading =>
      _isStatsLoading ||
      _isLeaderboardLoading ||
      _isHistoryLoading ||
      _isBadgesLoading;
  bool get isStatsLoading => _isStatsLoading;
  bool get isLeaderboardLoading => _isLeaderboardLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get isBadgesLoading => _isBadgesLoading;

  String _error = '';
  final StorageService _storageService = StorageService();

  // Milestone tracking
  int? _previousPoints;
  final StreamController<MilestoneEvent> _milestoneController =
      StreamController<MilestoneEvent>.broadcast();

  RewardStats? get stats => _stats;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  List<PointHistoryItem> get history => _history;
  List<Badge> get allBadges => _allBadges;

  String get error => _error;
  Stream<MilestoneEvent> get milestoneStream => _milestoneController.stream;

  /// Initialiser les données (charger du cache puis rafraîchir si nécessaire)
  Future<void> init() async {
    print('DEBUG [REWARDS] RewardProvider.init() started');
    final user = await UserService.getCurrentUser();
    final userId = user?.id;

    // Charger le dernier utilisateur connu depuis le stockage persistant
    final lastUserId = await _storageService.getLastUserId();
    print('DEBUG [REWARDS] Last seen user: $lastUserId, Current user: $userId');

    // Détecter un changement d'utilisateur et réinitialiser l'état
    if (userId != lastUserId) {
      print('DEBUG [REWARDS] User change detected. Clearing state.');
      _stats = null;
      _leaderboard = [];
      _history = [];
      _allBadges = [];
      notifyListeners();

      if (userId != null) {
        await _storageService.saveLastUserId(userId);
      }
    }

    if (userId != null) {
      print('DEBUG [REWARDS] Loading cached stats for user: $userId');
      _stats = await _storageService.getSavedStats(userId);
      print('DEBUG [REWARDS] Cached stats found: ${_stats != null}');
      notifyListeners();

      // Forcer le rafraîchissement au démarrage pour s'assurer d'avoir les données fraîches
      // ou si le délai est passé. On est moins restrictif pour éviter les données périmées.
      final shouldRefresh = await _storageService.shouldRefreshRewards();
      print(
          'DEBUG [REWARDS] Should refresh from storage rules: $shouldRefresh');

      if (_stats == null || shouldRefresh) {
        print('DEBUG [REWARDS] Triggering auto-refresh in init()');
        refreshAll();
      }
    } else {
      print('DEBUG [REWARDS] Cannot init Rewards: userId is null');
    }
  }

  /// Rafraîchir toutes les données
  Future<void> refreshAll() async {
    print('DEBUG [REWARDS] refreshAll() triggered');

    // On ne met pas de await ici pour qu'elles se lancent en parallèle
    // et que chaque onglet puisse se mettre à jour indépendamment
    loadStats(forceRefresh: true);
    loadLeaderboard();
    loadHistory();
    loadBadges();

    print('DEBUG [REWARDS] refreshAll(): all loads initiated');
  }

  Future<void> loadStats({bool forceRefresh = false}) async {
    print('DEBUG [REWARDS] loadStats(forceRefresh: $forceRefresh) started');
    if (!forceRefresh && _stats != null) {
      print(
          'DEBUG [REWARDS] loadStats skipped: already have stats and not forced');
      return;
    }

    _isStatsLoading = true;
    _error = '';
    notifyListeners();

    try {
      final freshStats = await GiftChallengeService.getStats();
      if (freshStats != null) {
        print(
            'DEBUG [REWARDS] Stats received: ${freshStats.pointsMensuels} pts');
        // Check for milestone crossing
        _checkMilestone(freshStats.pointsMensuels);
        _stats = freshStats;

        final user = await UserService.getCurrentUser();
        if (user != null) {
          print('DEBUG [REWARDS] Saving stats for user ${user.id} to storage');
          await _storageService.saveStats(freshStats, user.id);
        }
      } else {
        print('DEBUG [REWARDS] GiftChallengeService.getStats() returned null');
      }
    } catch (e) {
      _error = 'Erreur lors du chargement des statistiques: $e';
      print('DEBUG [REWARDS] loadStats error: $e');
    } finally {
      print('DEBUG [REWARDS] loadStats finished');
      _isStatsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard() async {
    _isLeaderboardLoading = true;
    _error = '';
    notifyListeners();

    try {
      final list = await GiftChallengeService.getLeaderboard();
      _leaderboard = list;
    } catch (e) {
      _error = 'Erreur lors du chargement du classement: $e';
      print('DEBUG [REWARDS] loadLeaderboard error: $e');
    } finally {
      _isLeaderboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _isHistoryLoading = true;
    _error = '';
    notifyListeners();

    try {
      final list = await GiftChallengeService.getHistory();
      _history = list;
    } catch (e) {
      _error = 'Erreur lors du chargement de l\'historique: $e';
      print('DEBUG [REWARDS] loadHistory error: $e');
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBadges() async {
    _isBadgesLoading = true;
    _error = '';
    notifyListeners();

    try {
      final list = await GiftChallengeService.getBadges();
      _allBadges = list;
    } catch (e) {
      _error = 'Erreur lors du chargement des badges: $e';
      print('DEBUG [REWARDS] loadBadges error: $e');
    } finally {
      _isBadgesLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  /// Check if a milestone has been crossed and emit event
  void _checkMilestone(int currentPoints) {
    if (_previousPoints == null) {
      _previousPoints = currentPoints;
      return;
    }

    final milestones = [10, 50, 100, 150, 200, 250];
    for (final milestone in milestones) {
      if (_previousPoints! < milestone && currentPoints >= milestone) {
        String message = _getMilestoneMessage(milestone);
        _milestoneController.add(MilestoneEvent(
          points: milestone,
          message: message,
        ));
        print('DEBUG [REWARDS] Milestone reached: $milestone points');
      }
    }
    _previousPoints = currentPoints;
  }

  /// Get the appropriate message for each milestone
  String _getMilestoneMessage(int milestone) {
    switch (milestone) {
      case 10:
        return 'Félicitations ! Vos premiers pas dans le partage du bonheur.';
      case 50:
        return '50 points ! Vous commencez à créer un bel impact.';
      case 100:
        return '100 points — Déjà une belle fête de générosité !';
      case 150:
        return '150 points — Votre cercle de partage s\'agrandit !';
      case 200:
        return '200 points atteints — Tu illumines ta communauté !';
      case 250:
        return 'Objectif atteint ! Tu es au sommet du Gift Challenge !';
      default:
        return 'Félicitations !';
    }
  }

  @override
  void dispose() {
    _milestoneController.close();
    super.dispose();
  }
}

/// Event emitted when a milestone is reached
class MilestoneEvent {
  final int points;
  final String message;

  MilestoneEvent({
    required this.points,
    required this.message,
  });
}
