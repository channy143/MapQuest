import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for persistent custom coordinates of map pins.
/// Allows players/developers to visually drag and calibrate points in-game,
/// save them permanently to device storage, and copy the Dart code.
class MapPointStorage {
  MapPointStorage._();

  static const String _storageKey = 'map_points_custom_coordinates_v4';
  static Map<String, Offset> _cachedPositions = {};

  static Map<String, Offset> get cachedPositions =>
      Map.unmodifiable(_cachedPositions);

  /// Loads saved custom positions from SharedPreferences.
  static Future<Map<String, Offset>> loadCustomPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('map_points_custom_coordinates_v1')) {
        await prefs.remove('map_points_custom_coordinates_v1');
      }
      if (prefs.containsKey('map_points_custom_coordinates_v2')) {
        await prefs.remove('map_points_custom_coordinates_v2');
      }
      if (prefs.containsKey('map_points_custom_coordinates_v3')) {
        await prefs.remove('map_points_custom_coordinates_v3');
      }
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        final Map<String, Offset> loaded = {};
        decoded.forEach((key, value) {
          if (value is Map && value['x'] != null && value['y'] != null) {
            loaded[key] = Offset(
              (value['x'] as num).toDouble(),
              (value['y'] as num).toDouble(),
            );
          }
        });
        _cachedPositions = loaded;
      }
    } catch (e) {
      debugPrint('MapPointStorage load error: $e');
    }
    return Map<String, Offset>.from(_cachedPositions);
  }

  /// Gets the position for a given location, using cached override or falling back to default.
  static Offset getPosition(String id, double defaultX, double defaultY) {
    if (_cachedPositions.containsKey(id)) {
      return _cachedPositions[id]!;
    }
    return Offset(defaultX, defaultY);
  }

  /// Saves updated positions permanently to SharedPreferences.
  static Future<void> saveCustomPositions(Map<String, Offset> positions) async {
    _cachedPositions = Map.from(positions);
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toEncode = {};
      positions.forEach((key, offset) {
        toEncode[key] = {
          'x': double.parse(offset.dx.toStringAsFixed(4)),
          'y': double.parse(offset.dy.toStringAsFixed(4)),
        };
      });
      await prefs.setString(_storageKey, jsonEncode(toEncode));
    } catch (e) {
      debugPrint('MapPointStorage save error: $e');
    }
  }

  /// Clears saved positions and reverts to factory defaults.
  static Future<void> clearCustomPositions() async {
    _cachedPositions.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('MapPointStorage clear error: $e');
    }
  }

  /// Generates Dart code snippet that can be pasted directly into `game_screen.dart`.
  static String generateDartCode(Map<String, Offset> positions) {
    final buffer = StringBuffer();
    buffer.writeln('// Updated MapLocation coordinates:');
    positions.forEach((id, pos) {
      buffer.writeln(
        "// '$id': normalizedX: ${pos.dx.toStringAsFixed(3)}, normalizedY: ${pos.dy.toStringAsFixed(3)},",
      );
    });
    return buffer.toString();
  }

  /// Copies text to clipboard.
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
