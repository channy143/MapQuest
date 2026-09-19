import 'package:shared_preferences/shared_preferences.dart';

/// Storage service managing game mode completion and badge unlocks across MapQuest.
class GameProgressStorage {
  static const String _completedGamesKey = 'mapquest_completed_games_v1';
  static const String _unlockedBadgesKey = 'mapquest_unlocked_badges_v1';

  static Set<String> _cachedCompletedGames = {};
  static Set<String> _cachedUnlockedBadges = {};
  static bool _isLoaded = false;

  /// Game identifiers
  static const String gameHanapinLokasyon = 'hanapin_lokasyon';
  static const String gameHanapinKayamanan = 'hanapin_kayamanan';
  static const String gameSubukinKaalaman = 'subukin_kaalaman';

  /// Badge identifiers
  static const String badgeDirectionMaster = 'direction_master';
  static const String badgeMapDetective = 'map_detective';
  static const String badgeUltimateExplorer = 'ultimate_explorer';

  /// Synchronous cache getters
  static Set<String> get completedGames => Set.unmodifiable(_cachedCompletedGames);
  static Set<String> get unlockedBadges => Set.unmodifiable(_cachedUnlockedBadges);

  /// Load from SharedPreferences
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final games = prefs.getStringList(_completedGamesKey);
      if (games != null) _cachedCompletedGames = games.toSet();

      final badges = prefs.getStringList(_unlockedBadgesKey);
      if (badges != null) _cachedUnlockedBadges = badges.toSet();

      _isLoaded = true;
    } catch (_) {
      // In-memory fallback
    }
  }

  static Future<void> _ensureLoaded() async {
    if (!_isLoaded) await load();
  }

  /// Mark a game as completed and check for the Ultimate Explorer badge
  static Future<bool> recordGameCompleted(String gameKey) async {
    await _ensureLoaded();
    _cachedCompletedGames.add(gameKey);

    // If Hanapin ang Kayamanan completed, award Map Detective
    if (gameKey == gameHanapinKayamanan) {
      _cachedUnlockedBadges.add(badgeMapDetective);
    }

    // If Hanapin ang Lokasyon completed, award Direction Master
    if (gameKey == gameHanapinLokasyon) {
      _cachedUnlockedBadges.add(badgeDirectionMaster);
    }

    // Check if all 3 games are finished -> award Ultimate Explorer!
    bool newlyEarnedUltimate = false;
    if (_cachedCompletedGames.contains(gameHanapinLokasyon) &&
        _cachedCompletedGames.contains(gameHanapinKayamanan) &&
        _cachedCompletedGames.contains(gameSubukinKaalaman)) {
      if (!_cachedUnlockedBadges.contains(badgeUltimateExplorer)) {
        _cachedUnlockedBadges.add(badgeUltimateExplorer);
        newlyEarnedUltimate = true;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedGamesKey, _cachedCompletedGames.toList());
      await prefs.setStringList(_unlockedBadgesKey, _cachedUnlockedBadges.toList());
    } catch (_) {
      // In-memory fallback
    }

    return newlyEarnedUltimate;
  }

  /// Check if a specific game is completed
  static Future<bool> isGameCompleted(String gameKey) async {
    await _ensureLoaded();
    return _cachedCompletedGames.contains(gameKey);
  }

  /// Check if a badge is unlocked
  static Future<bool> isBadgeUnlocked(String badgeId) async {
    await _ensureLoaded();
    return _cachedUnlockedBadges.contains(badgeId);
  }

  /// Reset all progress (useful for replay / testing)
  static Future<void> resetProgress() async {
    _cachedCompletedGames.clear();
    _cachedUnlockedBadges.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_completedGamesKey);
      await prefs.remove(_unlockedBadgesKey);
    } catch (_) {
      // In-memory fallback
    }
  }

  /// For testing
  static void setMockData({
    Set<String>? completed,
    Set<String>? badges,
  }) {
    if (completed != null) _cachedCompletedGames = Set.from(completed);
    if (badges != null) _cachedUnlockedBadges = Set.from(badges);
    _isLoaded = true;
  }
}
