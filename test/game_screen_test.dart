import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoquest_philippines/screens/game_screen.dart';
import 'package:geoquest_philippines/services/map_point_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('MapLocation data validation and category checks', () {
    const screen = GameScreen(selectedMode: 'explore');
    expect(screen.selectedMode, 'explore');

    // Test CategoryFilter enum values and attributes
    expect(CategoryFilter.values.length, 4);
    expect(CategoryFilter.bisinal.label, 'BISINAL');
    expect(CategoryFilter.bisinal.accentColor, const Color(0xFF00E676));
    expect(CategoryFilter.insular.label, 'INSULAR');
    expect(CategoryFilter.pilipinas.label, 'PILIPINAS');
    expect(CategoryFilter.lahat.label, 'LAHAT');
  });

  testWidgets('GameScreen mounts, dismisses modal, and shows category filter button',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameScreen(selectedMode: 'explore'),
        ),
      ),
    );

    // Initial frame + wait 1s for entrance and map mount
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Tap MAGSIMULA to dismiss the message modal
    final magsimulaFinder = find.byWidgetPredicate(
      (w) => w is Text && (w.data == 'MAGSIMULA' || w.data == 'MAGPATULOY'),
    );
    expect(magsimulaFinder, findsOneWidget);
    await tester.tap(magsimulaFinder);

    // Modal reverseDuration is 700ms; wait 800ms for slide exit
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    // Category button is now visible on top center
    final categoryBtn = find.byKey(const ValueKey('category_filter_button'));
    expect(categoryBtn, findsOneWidget);
    expect(find.text('LAHAT'), findsOneWidget);

    // Tap category button to switch to Bisinal
    await tester.tap(categoryBtn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('BISINAL'), findsOneWidget);

    // Tap again to switch to Insular
    await tester.tap(categoryBtn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('INSULAR'), findsOneWidget);

    // Tap again to switch to Pilipinas
    await tester.tap(categoryBtn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PILIPINAS'), findsOneWidget);

    // Tap again to switch back to Lahat
    await tester.tap(categoryBtn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LAHAT'), findsOneWidget);
  });

  testWidgets('Selecting a location opens detailed description and fun fact card',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameScreen(selectedMode: 'explore'),
        ),
      ),
    );

    // Let modal slide into place and map mount
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Dismiss modal
    await tester.tap(find.byWidgetPredicate(
      (w) => w is Text && (w.data == 'MAGSIMULA' || w.data == 'MAGPATULOY'),
    ));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    // Tap on Cambodia pin by its ValueKey 'pin_cambodia'
    final cambodiaPin = find.byKey(const ValueKey('pin_cambodia'));
    expect(cambodiaPin, findsOneWidget);
    await tester.tap(cambodiaPin);
    await tester.pump(const Duration(milliseconds: 800));

    // Verify detailed description modal (title appears on pin tooltip and in modal title)
    expect(find.text('Cambodia'), findsNWidgets(2));
    expect(find.text('ALAM MO BA? (FUN FACT)'), findsOneWidget);
    expect(find.textContaining('Angkor Wat'), findsOneWidget);
    expect(find.textContaining('Timog-Silangang Asya'), findsOneWidget);
    expect(find.text('BUMALIK SA BUONG MAPA'), findsOneWidget);
  });

  testWidgets(
      'Category button is perfectly centered horizontally and location modal supports mouse drag',
      (WidgetTester tester) async {
    // Test on 390x844 mobile phone viewport (matches user's screenshot)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameScreen(selectedMode: 'explore'),
        ),
      ),
    );

    // Settle intro and dismiss welcome modal
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.tap(find.byWidgetPredicate(
      (w) => w is Text && (w.data == 'MAGSIMULA' || w.data == 'MAGPATULOY'),
    ));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    // Verify category button is perfectly centered horizontally (dx == 390 / 2 = 195.0)
    final categoryBtn = find.byKey(const ValueKey('category_filter_button'));
    expect(categoryBtn, findsOneWidget);
    final categoryCenter = tester.getCenter(categoryBtn);
    expect(categoryCenter.dx, closeTo(195.0, 1.0));

    // Tap on Cambodia pin
    final cambodiaPin = find.byKey(const ValueKey('pin_cambodia'));
    expect(cambodiaPin, findsOneWidget);
    await tester.tap(cambodiaPin);
    await tester.pump(const Duration(milliseconds: 800));

    // Verify mouse click-and-drag scrolling works on the modal
    final descriptionFinder = find.textContaining('Timog-Silangang Asya');
    expect(descriptionFinder, findsOneWidget);

    // Perform mouse drag gesture
    await tester.drag(descriptionFinder, const Offset(0, -60),
        kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 200));

    // Scrollbar and content are intact and interactive
    expect(find.byType(RawScrollbar), findsOneWidget);
    expect(find.text('ALAM MO BA? (FUN FACT)'), findsOneWidget);
  });

  testWidgets(
      'Zoom buttons are removed, InteractiveViewer supports pinch zoom, and Game Mission modal is elevated and enlarged',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameScreen(selectedMode: 'laro'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Tap SIMULAN ANG MISYON to dismiss welcome dialog in Game Mode
    final startBtn = find.text('SIMULAN ANG MISYON');
    expect(startBtn, findsOneWidget);
    await tester.tap(startBtn);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    // Verify zoom buttons are NOT present in the widget tree
    expect(find.byIcon(Icons.zoom_in), findsNothing);
    expect(find.byIcon(Icons.zoom_out), findsNothing);
    expect(find.byIcon(Icons.restart_alt), findsNothing);
    expect(find.text('+'), findsNothing);
    expect(find.text('-'), findsNothing);

    // Verify InteractiveViewer is configured for pinch zoom & pan
    final viewerFinder = find.byType(InteractiveViewer);
    expect(viewerFinder, findsOneWidget);
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    expect(viewer.panEnabled, isTrue);
    expect(viewer.scaleEnabled, isTrue);
    expect(viewer.trackpadScrollCausesScale, isTrue);

    // Verify Game Mission panel is rendered and elevated
    final missionFinder = find.byKey(const ValueKey('mission_panel_0'));
    expect(missionFinder, findsOneWidget);

    final missionRect = tester.getRect(missionFinder);
    // On 844px height, bottom edge should be well above 800px (elevated by at least 52px)
    expect(missionRect.bottom, lessThanOrEqualTo(844.0 - 52.0));
    // Verify width is comfortably wide on mobile (94% of 390 is ~366.6px)
    expect(missionRect.width, greaterThan(340.0));
  });

  testWidgets('Calibration mode allows moving points, saves to storage, and locks them permanently',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await MapPointStorage.clearCustomPositions();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameScreen(
            selectedMode: 'explore',
            enableCalibration: true,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Dismiss welcome dialog
    await tester.tap(find.byWidgetPredicate(
      (w) => w is Text && (w.data == 'MAGSIMULA' || w.data == 'MAGPATULOY'),
    ));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    // Verify "AYUSIN ANG MGA PUNTO" button is visible
    final calibrateBtnFinder = find.text('AYUSIN ANG MGA PUNTO');
    expect(calibrateBtnFinder, findsOneWidget);

    // Initial position of Luzon pin
    final luzonPinFinder = find.byKey(const ValueKey('pin_luzon'));
    expect(luzonPinFinder, findsOneWidget);
    final initialPos = tester.getCenter(luzonPinFinder);

    // Tap "AYUSIN ANG MGA PUNTO" to enter calibration mode
    await tester.tap(calibrateBtnFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify calibration control bar is now displayed
    expect(find.text('PAG-AAYOS NG MGA PUNTO SA MAPA'), findsOneWidget);
    expect(find.text('TANGGAPIN / I-SAVE'), findsOneWidget);
    expect(find.text('KODIGO'), findsOneWidget);
    expect(find.text('I-RESET'), findsOneWidget);
    expect(find.text('KANSELA'), findsOneWidget);

    // Drag the Luzon pin by 50px horizontally and 50px vertically
    await tester.drag(luzonPinFinder, const Offset(50, 50));
    await tester.pump(const Duration(milliseconds: 300));

    final movedPos = tester.getCenter(luzonPinFinder);
    // Pin should have moved
    expect((movedPos.dx - initialPos.dx).abs(), greaterThan(10));
    expect((movedPos.dy - initialPos.dy).abs(), greaterThan(10));

    // Tap TANGGAPIN / I-SAVE to lock in the new coordinates permanently
    await tester.tap(find.text('TANGGAPIN / I-SAVE'));
    await tester.pump(const Duration(milliseconds: 500));

    // Calibration control bar should now be gone (mode exited)
    expect(find.text('PAG-AAYOS NG MGA PUNTO SA MAPA'), findsNothing);
    expect(find.text('AYUSIN ANG MGA PUNTO'), findsOneWidget);

    // Verify coordinates were persisted in MapPointStorage
    final saved = await MapPointStorage.loadCustomPositions();
    expect(saved.containsKey('luzon'), isTrue);

    // Verify that the pin's calibrated normalized coordinate is locked
    final pinWidgetBefore = tester.widget<MapPointPin>(luzonPinFinder);
    expect(pinWidgetBefore.isCalibrationMode, isFalse);

    // Dragging across map now pans the map rather than re-calibrating the pin
    await tester.drag(luzonPinFinder, const Offset(60, 60));
    await tester.pump(const Duration(milliseconds: 300));

    final pinWidgetAfter = tester.widget<MapPointPin>(luzonPinFinder);
    expect(pinWidgetAfter.currentOffset, equals(pinWidgetBefore.currentOffset));
    final savedAfter = await MapPointStorage.loadCustomPositions();
    expect(savedAfter['luzon'], equals(saved['luzon']));

    // Tapping the pin now triggers normal gameplay interaction (opens location card)
    await tester.tap(luzonPinFinder);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('PANGUNAHING PULO NG PILIPINAS'), findsOneWidget);

    // Clean up
    await MapPointStorage.clearCustomPositions();
  });
}

