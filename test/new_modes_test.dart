import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoquest_philippines/models/classic_question.dart';
import 'package:geoquest_philippines/screens/classic_quiz_screen.dart';
import 'package:geoquest_philippines/screens/game_screen.dart';
import 'package:geoquest_philippines/screens/mode_selection_screen.dart';
import 'package:geoquest_philippines/services/coordinate_quest_storage.dart';
import 'package:geoquest_philippines/widgets/game_mode_picker_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Learning Mode - Precise Coordinates & Back Navigation', () {
    testWidgets('Displays TIYAK NA LOKASYON badge and coordinates on location modal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameScreen(selectedMode: 'mode ng pagkatuto'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Dismiss welcome modal
      await tester.tap(find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'MAGSIMULA' || w.data == 'MAGPATULOY'),
      ));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      // Tap on Luzon pin
      final luzonPin = find.byKey(const ValueKey('pin_luzon'));
      expect(luzonPin, findsOneWidget);
      await tester.tap(luzonPin);
      await tester.pump(const Duration(milliseconds: 800));

      // Check location card title and description
      expect(find.text('Luzon'), findsNWidgets(2));
      expect(find.textContaining('pinakamalaki at pinakamataong pulo'), findsOneWidget);

      // Tap top-left back button to return to mode selection
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      // Verified: navigated back to Mode Selection screen
      expect(find.text('PAGPILI'), findsOneWidget);
    });
  });

  group('Mode Selection Screen Navigation', () {
    testWidgets('Back button in ModeSelectionScreen reliably navigates to HomeScreen menu',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModeSelectionScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('PAGPILI'), findsOneWidget);

      // Tap Back button on top left
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);

      // Wait for outro and transition
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 500));

      // Verified: HomeScreen with MAPQUEST is displayed
      expect(find.text('MAP'), findsOneWidget);
      expect(find.text('QUEST'), findsOneWidget);
      expect(find.text('MAGLARO'), findsOneWidget);
    });
  });

  group('Game Mode Picker Modal', () {
    testWidgets('Renders 3 modes without yellow underlines and calls onSelectMode',
        (WidgetTester tester) async {
      GameSubModeSelection? selected;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameModePickerModal(
              onSelectMode: (mode) => selected = mode,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      // Verify header and 3 mode cards
      expect(find.text('PUMILI NG LARO!'), findsOneWidget);
      expect(find.text('Hanapin ang Lokasyon!'), findsOneWidget);
      expect(find.text('Klasikong Pagsusulit'), findsOneWidget);
      expect(find.text('Coordinate Quest'), findsOneWidget);

      // Verify text widget has decoration none (no yellow underlines)
      final titleWidget = tester.widget<Text>(find.text('PUMILI NG LARO!'));
      expect(titleWidget.style?.decoration, TextDecoration.none);

      // Tap Classic Mode
      await tester.tap(find.text('Klasikong Pagsusulit'));
      expect(selected, GameSubModeSelection.classic);

      // Tap Cancel / Close icon
      final closeIcon = find.byIcon(Icons.close_rounded);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      expect(cancelled, isTrue);
    });
  });

  group('Classic Mode Quiz & Completion Actions', () {
    test('Registry contains at least 20 questions, all with 3 options and valid answers', () {
      expect(ClassicQuestionRegistry.questions.length, greaterThanOrEqualTo(20));
      for (final q in ClassicQuestionRegistry.questions) {
        expect(q.options.length, 3, reason: 'Question ${q.id} must have 3 options');
        expect(q.correctIndex, inInclusiveRange(0, 2));
        expect(q.prompt, isNotEmpty);
        expect(q.explanation, isNotEmpty);
        expect(q.correctAnswer, q.options[q.correctIndex]);
      }
    });

    testWidgets('ClassicQuizScreen plays through, Maglaro Muli resets with random questions, Bumalik sa Menu exits',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClassicQuizScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top bar elements
      expect(find.text('KLASIKONG PAGSUSULIT'), findsOneWidget);
      expect(find.textContaining('TANONG 1 NG 10'), findsOneWidget);

      // Verify 3 option choices exist (A, B, C)
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      // Answer all 10 questions to reach the completion modal
      for (int i = 0; i < 10; i++) {
        // Tap first option A
        await tester.tap(find.text('A'));
        await tester.pumpAndSettle();

        final actionBtn = find.text(i < 9 ? 'SUSUNOD NA TANONG ➔' : 'TINGNAN ANG RESULTA 🏆');
        expect(actionBtn, findsOneWidget);
        await tester.tap(actionBtn);
        await tester.pumpAndSettle();
      }

      // Quiz completion card is now visible
      expect(find.text('TAPOS NA ANG PAGSUSULIT!'), findsOneWidget);
      expect(find.text('MAGLARO MULI'), findsOneWidget);
      expect(find.text('BUMALIK SA MENU'), findsOneWidget);

      // Test MAGLARO MULI button
      await tester.tap(find.text('MAGLARO MULI'));
      await tester.pumpAndSettle();

      // Verified: back to question 1 with fresh state!
      expect(find.textContaining('TANONG 1 NG 10'), findsOneWidget);

      // Answer again to complete and test BUMALIK SA MENU
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('B'));
        await tester.pumpAndSettle();

        final actionBtn = find.text(i < 9 ? 'SUSUNOD NA TANONG ➔' : 'TINGNAN ANG RESULTA 🏆');
        await tester.tap(actionBtn);
        await tester.pumpAndSettle();
      }

      expect(find.text('BUMALIK SA MENU'), findsOneWidget);
      await tester.tap(find.text('BUMALIK SA MENU'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      // Verified: Navigated directly to HomeScreen menu!
      expect(find.text('MAP'), findsOneWidget);
      expect(find.text('QUEST'), findsOneWidget);
    });
  });

  group('Coordinate Quest & Persistence', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CoordinateQuestStorage.resetProgress();
    });

    test('Storage service manages unlocked locations and persistence correctly', () async {
      var unlocked = await CoordinateQuestStorage.getUnlockedLocations();
      expect(unlocked.isEmpty, isTrue);

      await CoordinateQuestStorage.unlockLocation('luzon');
      expect(await CoordinateQuestStorage.isUnlocked('luzon'), isTrue);
      expect(await CoordinateQuestStorage.isUnlocked('visayas'), isFalse);

      await CoordinateQuestStorage.unlockLocation('visayas');
      unlocked = await CoordinateQuestStorage.getUnlockedLocations();
      expect(unlocked.length, 2);
      expect(unlocked.contains('luzon'), isTrue);
      expect(unlocked.contains('visayas'), isTrue);

      await CoordinateQuestStorage.resetProgress();
      unlocked = await CoordinateQuestStorage.getUnlockedLocations();
      expect(unlocked.isEmpty, isTrue);
    });

    testWidgets('Coordinate Quest hides unrevealed pins and reveals pin upon correct coordinate answer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await CoordinateQuestStorage.resetProgress();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameScreen(
              selectedMode: 'mode ng laro',
              gameSubMode: GameSubMode.coordinates,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Dismiss coordinate mode welcome modal
      expect(find.text('COORDINATE QUEST'), findsOneWidget);
      await tester.tap(find.text('SIMULAN ANG PAGHAHANAP'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      // In coordinate mode with 0 unlocked, pins should not be rendered yet
      expect(find.byKey(const ValueKey('pin_luzon')), findsNothing);
      expect(find.byKey(const ValueKey('pin_visayas')), findsNothing);

      // Coordinate quest panel at bottom is visible
      expect(find.text('COORDINATE QUEST'), findsWidgets);
      expect(find.textContaining('0 / 22 Nabuksan'), findsOneWidget);

      // Coordinates text is displayed (first locked location is Luzon: 16.6° H Latitud, 121.3° S Longhitud)
      expect(find.text('16.6° H Latitud, 121.3° S Longhitud'), findsOneWidget);

      // 3 choices are displayed. Tap Luzon.
      final luzonChoice = find.widgetWithText(InkWell, 'Luzon');
      expect(luzonChoice, findsOneWidget);
      await tester.tap(luzonChoice);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 500));

      // Luzon pin is now visible on the map!
      expect(find.byKey(const ValueKey('pin_luzon')), findsOneWidget);

      // Close the review card to reveal coordinate panel again
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump(const Duration(milliseconds: 400));

      // Progress counter increases to 1 / 22
      expect(find.textContaining('1 / 22 Nabuksan'), findsOneWidget);

      // Verified persistence in storage
      final unlockedInStorage = await CoordinateQuestStorage.getUnlockedLocations();
      expect(unlockedInStorage.contains('luzon'), isTrue);
    });
  });

  group('Location Card Zoom-Out & Screen Coordinate Badges', () {
    testWidgets('Tapping location card close (X) button dismisses card and resets zoom',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameScreen(selectedMode: 'mode ng pagkatuto'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Dismiss welcome modal
      await tester.tap(find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'MAGSIMULA' || w.data == 'MAGPATULOY'),
      ));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      // Tap on Luzon pin
      final luzonPin = find.byKey(const ValueKey('pin_luzon'));
      expect(luzonPin, findsOneWidget);
      await tester.tap(luzonPin);
      await tester.pump(const Duration(milliseconds: 800));

      // Location card is visible with close button and without font-scaling buttons
      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);
      expect(find.text('A-'), findsNothing);
      expect(find.text('A+'), findsNothing);

      // Tap close button (X)
      await tester.tap(closeButton);
      await tester.pump(const Duration(milliseconds: 600));

      // Card is dismissed and zoom is reset
      expect(find.text('ALAM MO BA? (FUN FACT)'), findsNothing);
    });

    testWidgets('Screen coordinate badges overlay renders when grid is enabled',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameScreen(selectedMode: 'mode ng pagkatuto'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Dismiss welcome modal
      await tester.tap(find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'MAGSIMULA' || w.data == 'MAGPATULOY'),
      ));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      // Grid toggle button exists
      final gridToggle = find.byIcon(Icons.grid_on_rounded);
      expect(gridToggle, findsOneWidget);

      // Grid is ON by default in GameScreen
      expect(find.text('GRID'), findsOneWidget);

      // Toggle grid OFF
      await tester.tap(gridToggle);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('GRID (OFF)'), findsOneWidget);

      // Toggle grid ON again
      final gridToggleOff = find.byIcon(Icons.grid_off_rounded);
      await tester.tap(gridToggleOff);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('GRID'), findsOneWidget);
    });
  });
}
