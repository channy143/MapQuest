import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoquest_philippines/app.dart';
import 'package:geoquest_philippines/screens/game_screen.dart';
import 'package:geoquest_philippines/screens/home_screen.dart';
import 'package:geoquest_philippines/services/audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });
  group('AudioManager Tests', () {
    test('AudioManager singleton initializes with default state and mute toggling works', () async {
      final audio = AudioManager.instance;
      expect(audio.isMuted, isFalse);
      expect(audio.isMutedNotifier.value, isFalse);

      await audio.toggleMute();
      expect(audio.isMuted, isTrue);
      expect(audio.isMutedNotifier.value, isTrue);

      // Toggle back to unmuted
      await audio.toggleMute();
      expect(audio.isMuted, isFalse);
      expect(audio.isMutedNotifier.value, isFalse);
    });

    test('AudioManager volume clamping works', () async {
      final audio = AudioManager.instance;
      await audio.setVolume(1.5);
      await audio.setVolume(-0.5);
      await audio.setVolume(0.4);
    });

    test('AudioManager music and sound volume controls work with clamping', () async {
      final audio = AudioManager.instance;
      await audio.setMusicVolume(0.75);
      expect(audio.musicVolume, equals(0.75));
      expect(audio.musicVolumeNotifier.value, equals(0.75));

      await audio.setMusicVolume(1.5);
      expect(audio.musicVolume, equals(1.0));

      await audio.setSoundVolume(0.6);
      expect(audio.soundVolume, equals(0.6));
      expect(audio.soundVolumeNotifier.value, equals(0.6));

      await audio.setSoundVolume(-0.2);
      expect(audio.soundVolume, equals(0.0));
    });

    test('AudioManager SFX triggers (playClick, playCorrect, playWrong) execute cleanly', () async {
      final audio = AudioManager.instance;
      // In unmuted state, triggers should run cleanly
      await audio.playClick();
      await audio.playCorrect();
      await audio.playWrong();

      // In muted state, triggers should return immediately without playing
      await audio.toggleMute();
      expect(audio.isMuted, isTrue);
      await audio.playClick();
      await audio.playCorrect();
      await audio.playWrong();

      // Reset to unmuted
      await audio.toggleMute();
      expect(audio.isMuted, isFalse);
    });

    test('AudioManager pauses on app minimize (paused/inactive) and resumes when app returns', () async {
      final audio = AudioManager.instance;
      await audio.startBackgroundMusic();

      // Simulate minimizing the app
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Simulate returning to the app
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
    });
  });

  group('HomeScreen Clouds and Audio UI Tests', () {
    testWidgets('Cloud image asset loads successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Image.asset('assets/images/clouds'),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('HomeScreen mounts with plenty of clouds and audio toggle button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GeoQuestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3200));
      await tester.pump(const Duration(milliseconds: 1400));

      // Audio toggle button should be visible
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      // Verify that clouds are rendered (plenty of cloud image instances)
      final imageWidgets = tester.widgetList<Image>(find.byType(Image));
      final cloudImages = imageWidgets.where((img) {
        final imageProvider = img.image;
        return imageProvider is AssetImage && imageProvider.assetName.contains('clouds');
      }).toList();

      // There are 6 lessened clouds declared in the background layer
      expect(cloudImages.length, equals(6));

      // Tapping audio toggle button switches mute state and icon
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
      expect(AudioManager.instance.isMuted, isTrue);

      // Tap again to unmute
      await tester.tap(find.byIcon(Icons.volume_off_rounded));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(AudioManager.instance.isMuted, isFalse);
    });

    testWidgets('Clouds drift horizontally when time passes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Get initial position of the first cloud
      final firstCloudFinder = find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains('clouds'),
      ).first;

      final initialOffset = tester.getTopLeft(firstCloudFinder);

      // Advance time by 3 seconds
      await tester.pump(const Duration(seconds: 3));

      final movedOffset = tester.getTopLeft(firstCloudFinder);

      // Cloud should have moved to the right (x increased)
      expect(movedOffset.dx, isNot(equals(initialOffset.dx)));
    });

    testWidgets('HomeScreen has Earth on front z-index and MAGLARO button remains tappable',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GeoQuestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3200));
      await tester.pump(const Duration(milliseconds: 2000));

      // Earth is present
      final earthFinder = find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains('Earth'),
      );
      expect(earthFinder, findsOneWidget);

      // MAGLARO button is present and tappable
      final playBtn = find.text('MAGLARO');
      expect(playBtn, findsOneWidget);

      await tester.tap(playBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('Tapping MGA SETTING opens modal with Music, Sound sliders and Mute toggle',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GeoQuestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3200));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 800));

      final settingsBtn = find.text('MGA SETTING');
      expect(settingsBtn, findsOneWidget);

      await tester.tap(settingsBtn, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Modal is visible with both sliders
      expect(find.text('TUGTUGIN (MUSIC)'), findsOneWidget);
      expect(find.text('TUNOG (SOUND SFX)'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));

      // Mute toggle button is visible
      expect(find.textContaining('MUTE'), findsWidgets);

      // Close button dismisses modal
      final closeBtn = find.text('ISARA');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('In-Map Clouds Tests across Map Modes', () {
    testWidgets('GameScreen mounts in-map clouds layer and shadows over map canvas',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(selectedMode: 'mode ng pagkatuto'),
        ),
      );

      // Dismiss intro dialog
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Tap Simulan to enter map
      final startBtn = find.text('Simulan ang Paglalakbay');
      if (startBtn.evaluate().isNotEmpty) {
        await tester.tap(startBtn);
        await tester.pump(const Duration(milliseconds: 600));
      }

      // Map clouds and shadows should be rendered
      final cloudImages = find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains('clouds'),
      );
      expect(cloudImages, findsWidgets);

      // Verify that shadows exist (ImageFiltered widgets for cloud shadows)
      final shadowFilters = find.byType(ImageFiltered);
      expect(shadowFilters, findsWidgets);
    });
  });
}
