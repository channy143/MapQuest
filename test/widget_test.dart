import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoquest_philippines/app.dart';

void main() {
  testWidgets('Home screen shows MapQuest branding and buttons',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GeoQuestApp());

    await tester.pump();
    // Splash screen loads core assets (~2400ms) + fade transition (~600ms)
    await tester.pump(const Duration(milliseconds: 3200));
    // Intro animations on HomeScreen take ~1400ms
    await tester.pump(const Duration(milliseconds: 1400));

    expect(find.text('MAP'), findsOneWidget);
    expect(find.text('QUEST'), findsOneWidget);
    expect(find.text('MAGLARO'), findsOneWidget);
    expect(find.text('MGA SETTING'), findsOneWidget);
    expect(find.text('ISARA ANG APP'), findsOneWidget);
  });
}
