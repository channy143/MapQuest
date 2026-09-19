import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoquest_philippines/models/classic_question.dart';
import 'package:geoquest_philippines/models/game_mission.dart';
import 'package:geoquest_philippines/models/treasure_hunt_question.dart';
import 'package:geoquest_philippines/screens/classic_quiz_screen.dart';
import 'package:geoquest_philippines/screens/treasure_hunt_screen.dart';
import 'package:geoquest_philippines/services/game_progress_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Treasure Hunt Registry & Question Model Tests', () {
    test('Registry contains exactly 10 questions with valid fields and assets', () {
      expect(TreasureHuntRegistry.questions.length, 10);
      for (final q in TreasureHuntRegistry.questions) {
        expect(q.id, inInclusiveRange(1, 10));
        expect(q.prompt.isNotEmpty, isTrue);
        expect(q.correctAnswer.isNotEmpty, isTrue);
        expect(q.imageAsset.startsWith('assets/images/treasure_hunt/'), isTrue);
        expect(q.options.length, greaterThanOrEqualTo(3));
        expect(q.options.contains(q.correctAnswer), isTrue);
        expect(q.explanation.isNotEmpty, isTrue);
      }
    });

    test('isAnswerCorrect handles exact matches, aliases, casing, and spaces', () {
      final q1 = TreasureHuntRegistry.questions[0]; // Taiwan
      expect(q1.isAnswerCorrect('Taiwan'), isTrue);
      expect(q1.isAnswerCorrect('taiwan'), isTrue);
      expect(q1.isAnswerCorrect('  TAIWAN  '), isTrue);
      expect(q1.isAnswerCorrect('republic of china'), isTrue);
      expect(q1.isAnswerCorrect('Japan'), isFalse);

      final q2 = TreasureHuntRegistry.questions[1]; // Sulu Sea
      expect(q2.isAnswerCorrect('Sulu Sea'), isTrue);
      expect(q2.isAnswerCorrect('sulu sea'), isTrue);
      expect(q2.isAnswerCorrect('dagat sulu'), isTrue);
      expect(q2.isAnswerCorrect('Pacific Ocean'), isFalse);

      final q4 = TreasureHuntRegistry.questions[3]; // Indonesia
      expect(q4.isAnswerCorrect('Indonesia'), isTrue);
      expect(q4.isAnswerCorrect('indonesya'), isTrue);
      expect(q4.isAnswerCorrect('Malaysia'), isFalse);
    });
  });

  group('Subukin ang Kaalaman Registry Tests', () {
    test('Registry contains exactly 14 official questions', () {
      expect(SubukinKaalamanRegistry.questions.length, 14);
      for (final q in SubukinKaalamanRegistry.questions) {
        expect(q.prompt.isNotEmpty, isTrue);
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
        expect(q.explanation.isNotEmpty, isTrue);
      }
    });

    test('Question 4 has exactly two choices: Taiwan and Japan, with Taiwan as correct answer', () {
      final q4 = SubukinKaalamanRegistry.questions[3];
      expect(q4.options.length, 2);
      expect(q4.options, containsAll(['Taiwan', 'Japan']));
      expect(q4.correctAnswer, 'Taiwan');
    });

    test('Question 1 to 3 have correct English terms and answers', () {
      final q1 = SubukinKaalamanRegistry.questions[0];
      expect(q1.correctAnswer, 'Pacific Ocean');

      final q2 = SubukinKaalamanRegistry.questions[1];
      expect(q2.correctAnswer, 'West Philippine Sea');

      final q3 = SubukinKaalamanRegistry.questions[2];
      expect(q3.correctAnswer, 'China');
    });
  });

  group('Game Progress & Badges Tests', () {
    setUp(() async {
      await GameProgressStorage.resetProgress();
    });

    test('Map Detective and Ultimate Explorer badges are registered with empty subtitle', () {
      final mapDetective = GameMissionRegistry.availableBadges.firstWhere(
        (b) => b.id == 'map_detective',
      );
      expect(mapDetective.title, 'Map Detective');
      expect(mapDetective.subtitle, isEmpty);

      final ultimateExplorer = GameMissionRegistry.availableBadges.firstWhere(
        (b) => b.id == 'ultimate_explorer',
      );
      expect(ultimateExplorer.title, 'Ultimate Explorer');
      expect(ultimateExplorer.subtitle, isEmpty);
    });

    test('Completing all 3 games unlocks Ultimate Explorer badge', () async {
      // Complete game 1: Hanapin ang Lokasyon
      var earnedUltimate = await GameProgressStorage.recordGameCompleted(
        GameProgressStorage.gameHanapinLokasyon,
      );
      expect(earnedUltimate, isFalse);
      expect(await GameProgressStorage.isBadgeUnlocked('direction_master'), isTrue);
      expect(await GameProgressStorage.isBadgeUnlocked('ultimate_explorer'), isFalse);

      // Complete game 2: Hanapin ang Kayamanan
      earnedUltimate = await GameProgressStorage.recordGameCompleted(
        GameProgressStorage.gameHanapinKayamanan,
      );
      expect(earnedUltimate, isFalse);
      expect(await GameProgressStorage.isBadgeUnlocked('map_detective'), isTrue);
      expect(await GameProgressStorage.isBadgeUnlocked('ultimate_explorer'), isFalse);

      // Complete game 3: Subukin ang Kaalaman -> Unlocks Ultimate Explorer!
      earnedUltimate = await GameProgressStorage.recordGameCompleted(
        GameProgressStorage.gameSubukinKaalaman,
      );
      expect(earnedUltimate, isTrue);
      expect(await GameProgressStorage.isBadgeUnlocked('ultimate_explorer'), isTrue);
    });
  });

  group('Treasure Hunt Screen Widget Tests', () {
    testWidgets('Renders instructions, can start hunt, answers question, and progresses',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TreasureHuntScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify instruction modal is shown first
      expect(find.text('HANAPIN ANG KAYAMANAN!'), findsWidgets);
      expect(find.text('SIMULAN ANG PAGHAHANAP 🧭'), findsOneWidget);

      // Tap start button
      await tester.tap(find.text('SIMULAN ANG PAGHAHANAP 🧭'));
      await tester.pumpAndSettle();

      // Instruction modal dismissed, Question 1 is visible
      expect(find.textContaining('KATANUNGAN 1 NG 10'), findsOneWidget);
      expect(find.textContaining('Taiwan'), findsOneWidget);

      // Tap Taiwan option
      await tester.tap(find.text('Taiwan'));
      await tester.pumpAndSettle();

      // Next button appears
      final nextBtn = find.text('SUSUNOD NA PAHIWATIG ➔');
      expect(nextBtn, findsOneWidget);
      await tester.ensureVisible(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Now at question 2 (which supports typing!)
      expect(find.textContaining('KATANUNGAN 2 NG 10'), findsOneWidget);
      expect(find.text('I-type ang sagot dito...'), findsOneWidget);
    });
  });

  group('Subukin ang Kaalaman Screen Widget Tests', () {
    testWidgets('Renders with 14 questions, can answer and show progress',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassicQuizScreen(
              title: 'SUBUKIN ANG KAALAMAN!',
              subtitle: '14 na Tanong • Araling Panlipunan',
              questions: SubukinKaalamanRegistry.questions,
              showInstructions: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header has title and 14 questions count
      expect(find.text('SUBUKIN ANG KAALAMAN!'), findsOneWidget);
      expect(find.textContaining('TANONG 1 NG 14'), findsOneWidget);

      // Verify Option A is available and answer it
      expect(find.text('Pacific Ocean'), findsOneWidget);
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(find.text('SUSUNOD NA TANONG ➔'), findsOneWidget);
      await tester.tap(find.text('SUSUNOD NA TANONG ➔'));
      await tester.pumpAndSettle();

      // Question 2 is shown
      expect(find.textContaining('TANONG 2 NG 14'), findsOneWidget);
    });
  });
}
