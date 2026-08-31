import 'package:flutter_test/flutter_test.dart';

import 'package:geoquest_philippines/app.dart';

void main() {
  testWidgets('Home screen shows title, subtitle, and both mode cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GeoQuestApp());

    expect(find.text('GeoQuest Philippines'), findsOneWidget);
    expect(find.text('Explore. Learn. Play.'), findsOneWidget);
    expect(find.text('Learning Mode'), findsOneWidget);
    expect(find.text('Game Mode'), findsOneWidget);
  });

  testWidgets('Tapping Learning Mode shows coming soon message',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GeoQuestApp());

    await tester.tap(find.text('Learning Mode'));
    await tester.pump();

    expect(find.text('Learning Mode coming soon'), findsOneWidget);
  });

  testWidgets('Tapping Game Mode shows coming soon message',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GeoQuestApp());

    await tester.tap(find.text('Game Mode'));
    await tester.pump();

    expect(find.text('Game Mode coming soon'), findsOneWidget);
  });
}
