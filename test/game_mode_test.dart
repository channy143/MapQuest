import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoquest_philippines/models/game_mission.dart';
import 'package:geoquest_philippines/screens/game_screen.dart';

void main() {
  group('GameMissionRegistry Tests', () {
    test('contains exactly 10 curated missions', () {
      expect(GameMissionRegistry.missions.length, 10);
    });

    test('validates Misyon 1 - Luzon, Visayas, Mindanao multi-target tap', () {
      final m1 = GameMissionRegistry.missions[0];
      expect(m1.missionNumber, 1);
      expect(m1.title, 'MISYON 1');
      expect(m1.type, MissionType.tapMap);
      expect(m1.requireAllTargets, isTrue);
      expect(m1.isTargetLocation('luzon'), isTrue);
      expect(m1.isTargetLocation('visayas'), isTrue);
      expect(m1.isTargetLocation('mindanao'), isTrue);
      expect(m1.isTargetLocation('taiwan'), isFalse);
    });

    test('validates Misyon 2 - Karatig-bansa sa hilaga (Taiwan)', () {
      final m2 = GameMissionRegistry.missions[1];
      expect(m2.missionNumber, 2);
      expect(m2.title, 'MISYON 2');
      expect(m2.isTargetLocation('taiwan'), isTrue);
      expect(m2.isTargetLocation('indonesia'), isFalse);
    });

    test('validates Misyon 3 - Anyong tubig sa kanluran (West Philippine Sea)', () {
      final m3 = GameMissionRegistry.missions[2];
      expect(m3.missionNumber, 3);
      expect(m3.title, 'MISYON 3');
      expect(m3.isTargetLocation('west_ph_sea'), isTrue);
      expect(m3.isTargetLocation('pacific_ocean'), isFalse);
    });

    test('validates Misyon 4 - Direksyon ng Vietnam (Kanluran)', () {
      final m4 = GameMissionRegistry.missions[3];
      expect(m4.missionNumber, 4);
      expect(m4.title, 'MISYON 4');
      expect(m4.type, MissionType.choice);
      expect(m4.isCorrectChoice(1), isTrue); // Kanluran
      expect(m4.isCorrectChoice(0), isFalse);
    });

    test('validates Misyon 5 - Karatig-bansa sa timog (Indonesia)', () {
      final m5 = GameMissionRegistry.missions[4];
      expect(m5.missionNumber, 5);
      expect(m5.title, 'MISYON 5');
      expect(m5.isTargetLocation('indonesia'), isTrue);
      expect(m5.isTargetLocation('taiwan'), isFalse);
    });

    test('validates Misyon 6 - Lost Explorer progressive clues (China)', () {
      final m6 = GameMissionRegistry.missions[5];
      expect(m6.missionNumber, 6);
      expect(m6.title, 'MISYON 6');
      expect(m6.type, MissionType.cluesMap);
      expect(m6.clues.length, 3);
      expect(m6.isTargetLocation('china'), isTrue);
    });

    test('validates Misyon 7 - Paglalayag patungong Palau (Timog-silangan)', () {
      final m7 = GameMissionRegistry.missions[6];
      expect(m7.missionNumber, 7);
      expect(m7.title, 'MISYON 7');
      expect(m7.type, MissionType.choice);
      expect(m7.isCorrectChoice(2), isTrue); // Timog-silangan
    });

    test('validates Misyon 8 - Anyong tubig sa hilaga (Basi Channel)', () {
      final m8 = GameMissionRegistry.missions[7];
      expect(m8.missionNumber, 8);
      expect(m8.title, 'MISYON 8');
      expect(m8.type, MissionType.choice);
      expect(m8.isCorrectChoice(0), isTrue); // Basi Channel
    });

    test('validates Misyon 9 - Pinapalibutan ng Vietnam, Myanmar, etc. (Thailand)', () {
      final m9 = GameMissionRegistry.missions[8];
      expect(m9.missionNumber, 9);
      expect(m9.title, 'MISYON 9');
      expect(m9.type, MissionType.tapMap);
      expect(m9.isTargetLocation('thailand'), isTrue);
    });

    test('validates Misyon 10 - Tiyak na Lokasyon ng Pilipinas', () {
      final m10 = GameMissionRegistry.missions[9];
      expect(m10.missionNumber, 10);
      expect(m10.title, 'MISYON 10');
      expect(m10.type, MissionType.choice);
      expect(m10.isCorrectChoice(0), isTrue); // 4-21 N, 116-127 E
    });

    test('verifies single Direction Master badge in registry with no subtitle', () {
      expect(GameMissionRegistry.availableBadges.length, 1);
      final badge = GameMissionRegistry.availableBadges.first;
      expect(badge.id, 'direction_master');
      expect(badge.title, 'Direction Master');
      expect(badge.subtitle, isEmpty);
    });
  });

  group('GameScreen Widget Tests', () {
    testWidgets('Hanapin ang Lokasyon Mode displays intro and start button',
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

      expect(find.text('HANAPIN ANG LOKASYON!'), findsOneWidget);
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

      // Bottom Mission Panel is visible with clean title "MISYON 1"
      expect(find.byKey(const ValueKey('mission_panel_0')), findsOneWidget);
      expect(find.text('MISYON 1'), findsOneWidget);
    });
  });
}
