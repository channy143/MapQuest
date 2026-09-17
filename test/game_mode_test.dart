import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoquest_philippines/models/game_mission.dart';
import 'package:geoquest_philippines/screens/game_screen.dart';

void main() {
  group('GameMissionRegistry Tests', () {
    test('contains exactly 10 curated missions', () {
      expect(GameMissionRegistry.missions.length, 10);
    });

    test('validates Mission 1 - Hanapin ang Pilipinas targets', () {
      final m1 = GameMissionRegistry.missions[0];
      expect(m1.missionNumber, 1);
      expect(m1.type, MissionType.tapMap);
      expect(m1.isTargetLocation('luzon'), isTrue);
      expect(m1.isTargetLocation('visayas'), isTrue);
      expect(m1.isTargetLocation('mindanao'), isTrue);
      expect(m1.isTargetLocation('palawan'), isTrue);
      expect(m1.isTargetLocation('taiwan'), isFalse);
    });

    test('validates Mission 2 - Karatig-bansa sa hilaga (Taiwan)', () {
      final m2 = GameMissionRegistry.missions[1];
      expect(m2.missionNumber, 2);
      expect(m2.isTargetLocation('taiwan'), isTrue);
      expect(m2.isTargetLocation('indonesia'), isFalse);
    });

    test('validates Mission 3 - Anyong tubig sa kanluran (West Philippine Sea)', () {
      final m3 = GameMissionRegistry.missions[2];
      expect(m3.missionNumber, 3);
      expect(m3.isTargetLocation('west_ph_sea'), isTrue);
      expect(m3.isTargetLocation('pacific_ocean'), isFalse);
    });

    test('validates Mission 4 - Direction Challenge (Hilaga)', () {
      final m4 = GameMissionRegistry.missions[3];
      expect(m4.missionNumber, 4);
      expect(m4.type, MissionType.choice);
      expect(m4.isCorrectChoice(0), isTrue); // Hilaga
      expect(m4.isCorrectChoice(1), isFalse);
    });

    test('validates Mission 5 - Karatig-bansa sa timog (Indonesia)', () {
      final m5 = GameMissionRegistry.missions[4];
      expect(m5.missionNumber, 5);
      expect(m5.isTargetLocation('indonesia'), isTrue);
      expect(m5.isTargetLocation('taiwan'), isFalse);
    });

    test('validates Mission 6 - Lost Explorer progressive clues (Taiwan)', () {
      final m6 = GameMissionRegistry.missions[5];
      expect(m6.missionNumber, 6);
      expect(m6.type, MissionType.cluesMap);
      expect(m6.clues.length, 3);
      expect(m6.isTargetLocation('taiwan'), isTrue);
    });

    test('validates Mission 7 - Plan Your Journey (Hilaga)', () {
      final m7 = GameMissionRegistry.missions[6];
      expect(m7.missionNumber, 7);
      expect(m7.type, MissionType.choice);
      expect(m7.isCorrectChoice(0), isTrue); // Hilaga
    });

    test('validates Mission 8 - Map Comparison (Taiwan vs Japan)', () {
      final m8 = GameMissionRegistry.missions[7];
      expect(m8.missionNumber, 8);
      expect(m8.type, MissionType.choice);
      expect(m8.isCorrectChoice(0), isTrue); // Taiwan
    });

    test('validates Mission 9 - Geography Detective (Cambodia)', () {
      final m9 = GameMissionRegistry.missions[8];
      expect(m9.missionNumber, 9);
      expect(m9.type, MissionType.cluesMap);
      expect(m9.clues.length, 3);
      expect(m9.isTargetLocation('cambodia'), isTrue);
    });

    test('validates Mission 10 - Absolute Location', () {
      final m10 = GameMissionRegistry.missions[9];
      expect(m10.missionNumber, 10);
      expect(m10.type, MissionType.choice);
      expect(m10.isCorrectChoice(0), isTrue); // 4-21 N, 116-127 E
    });

    test('verifies available badges in registry', () {
      expect(GameMissionRegistry.availableBadges.length, 5);
      final badgeIds = GameMissionRegistry.availableBadges.map((b) => b.id).toList();
      expect(badgeIds, containsAll([
        'first_discovery',
        'direction_master',
        'map_detective',
        'asia_explorer',
        'ultimate_explorer',
      ]));
    });
  });

  group('GameScreen Widget Tests', () {
    testWidgets('Game Mode displays intro and start button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(selectedMode: 'Game Mode'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('MAPQUEST EXPLORER'), findsOneWidget);
      final startBtn = find.text('SIMULAN ANG MISYON');
      expect(startBtn, findsOneWidget);
      expect(
        find.textContaining('Handa ka na bang maging isang MapQuest Explorer?'),
        findsOneWidget,
      );

      // Dismiss intro by tapping SIMULAN ANG MISYON
      await tester.tap(startBtn);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      // Top Game HUD header is now visible
      expect(find.byKey(const ValueKey('game_hud_header')), findsOneWidget);
      expect(find.text('Misyon 1 / 10'), findsOneWidget);
      expect(find.text('100'), findsOneWidget); // ⭐ Puntos: 100

      // Bottom Mission Panel is visible
      expect(find.byKey(const ValueKey('mission_panel_0')), findsOneWidget);
      expect(find.text('MISYON 1 – HANAPIN ANG PILIPINAS'), findsOneWidget);
    });
  });
}
