import 'package:shared_preferences/shared_preferences.dart';

/// Storage service managing persistence of unlocked map locations in Coordinate Quest mode.
class CoordinateQuestStorage {
  static const String _storageKey = 'coordinate_quest_unlocked_ids_v1';
  static Set<String> _inMemoryCache = {};
  static bool _hasLoaded = false;

  /// In-memory cache for synchronous access once loaded.
  static Set<String> get cachedUnlockedLocations => Set.unmodifiable(_inMemoryCache);

  /// Loads the set of unlocked location IDs from persistent storage.
  static Future<Set<String>> getUnlockedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey);
      if (list != null) {
        _inMemoryCache = list.toSet();
      }
      _hasLoaded = true;
    } catch (_) {
      // Fallback to in-memory cache if platform storage is unavailable
    }
    return Set<String>.from(_inMemoryCache);
  }

  /// Adds [locationId] to the unlocked set and saves to persistent storage.
  static Future<void> saveUnlockedLocation(String locationId) async {
    _inMemoryCache.add(locationId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _inMemoryCache.toList());
    } catch (_) {
      // In-memory fallback
    }
  }

  /// Convenience alias for [saveUnlockedLocation].
  static Future<void> unlockLocation(String locationId) => saveUnlockedLocation(locationId);

  /// Checks whether [locationId] has been unlocked.
  static Future<bool> isUnlocked(String locationId) async {
    if (!_hasLoaded) {
      await getUnlockedLocations();
    }
    return _inMemoryCache.contains(locationId);
  }

  /// Resets all unlocked locations for a fresh playthrough.
  static Future<void> resetProgress() async {
    _inMemoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {
      // In-memory fallback
    }
  }

  /// Set in-memory cache directly (useful for tests).
  static void setMockCache(Set<String> ids) {
    _inMemoryCache = Set<String>.from(ids);
    _hasLoaded = true;
  }
}
