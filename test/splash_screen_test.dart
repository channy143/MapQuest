import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoquest_philippines/screens/splash_screen.dart';

void main() {
  group('SplashScreen Widget Tests', () {
    testWidgets('Renders splash art, "Please w8....loading core assets", and vertical progress bar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verify intro splash art Earth is rendered
      final earthFinder = find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains('Earth'),
      );
      expect(earthFinder, findsOneWidget);

      // Verify MapQuest branding
      expect(find.text('MAP'), findsOneWidget);
      expect(find.text('QUEST'), findsOneWidget);

      // Verify required loading message
      expect(find.text('Please w8....loading core assets'), findsOneWidget);

      // Verify progress bar is rendered
      expect(find.byType(FractionallySizedBox), findsWidgets);
      expect(find.textContaining('%'), findsOneWidget);

      // Pump through progress duration
      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
