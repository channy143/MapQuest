import 'dart:math' as math;

/// Model for a treasure hunt challenge with an image clue.
class TreasureHuntQuestion {
  final int id;
  final String prompt;
  final String correctAnswer;
  final List<String> acceptableAnswers;
  final String imageAsset;
  final List<String> options;
  final bool isTypingQuestion;
  final String explanation;

  const TreasureHuntQuestion({
    required this.id,
    required this.prompt,
    required this.correctAnswer,
    required this.acceptableAnswers,
    required this.imageAsset,
    required this.options,
    required this.isTypingQuestion,
    required this.explanation,
  });

  /// Returns a copy of the question with shuffled options so choices are randomized.
  TreasureHuntQuestion withShuffledOptions([math.Random? random]) {
    final rand = random ?? math.Random();
    final shuffled = List<String>.from(options)..shuffle(rand);
    return TreasureHuntQuestion(
      id: id,
      prompt: prompt,
      correctAnswer: correctAnswer,
      acceptableAnswers: acceptableAnswers,
      imageAsset: imageAsset,
      options: shuffled,
      isTypingQuestion: isTypingQuestion,
      explanation: explanation,
    );
  }

  /// Check if an answer string matches the correct answer (case-insensitive & trimmed).
  bool isAnswerCorrect(String input) {
    final cleaned = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return false;
    if (cleaned == correctAnswer.trim().toLowerCase()) return true;
    for (final alt in acceptableAnswers) {
      if (cleaned == alt.trim().toLowerCase()) return true;
    }
    return false;
  }
}

/// Registry of the 10 Grade 4 treasure hunt missions in MapQuest.
class TreasureHuntRegistry {
  static const String modeInstruction =
      'Basahin nang mabuti ang bawat pahiwatig upang malaman kung saan nakatago ang kayamanan. Piliin o i-type ang tamang sagot. Bawat tamang sagot ay may puntos! Handa ka na? Hanapin ang kayamanan!';

  static const List<TreasureHuntQuestion> questions = [
    // Question 1: School in country north of Philippines -> Taiwan (Option B)
    TreasureHuntQuestion(
      id: 1,
      prompt:
          'Ang kayamanan ay nasa paaralan sa bansang nasa hilaga ng Pilipinas. Sa anong bansa ito matatagpuan?',
      correctAnswer: 'Taiwan',
      acceptableAnswers: ['taiwan', 'republic of china', 'roc'],
      imageAsset: 'assets/images/treasure_hunt/q1_school.png',
      options: ['Japan', 'Taiwan', 'South Korea'],
      isTypingQuestion: false,
      explanation:
          'Ang Taiwan ang pinakamalapit na karatig-bansa sa hilaga ng Pilipinas patawid sa Bashi Channel.',
    ),

    // Question 2: Ship sailing southwest -> Sulu Sea (Option C)
    TreasureHuntQuestion(
      id: 2,
      prompt:
          'Ang kayamanan ay nasa barkong naglalayag sa timog-kanluran ng Pilipinas. Saang karagatan ito matatagpuan?',
      correctAnswer: 'Sulu Sea',
      acceptableAnswers: ['sulu sea', 'dagat sulu', 'sulu'],
      imageAsset: 'assets/images/treasure_hunt/q2_ship_sulu.png',
      options: ['Celebes Sea', 'Philippine Sea', 'Sulu Sea'],
      isTypingQuestion: true,
      explanation:
          'Ang Sulu Sea ay matatagpuan sa timog-kanluran ng Pilipinas, napalilibutan ng Palawan, Visayas, at Sulu Archipelago.',
    ),

    // Question 3: City building in country northeast/northwest -> China (Option A)
    TreasureHuntQuestion(
      id: 3,
      prompt:
          'Ang kayamanan ay nasa siyudad sa bansang sa hilagang-silangan ng Pilipinas. Saang bansa ito matatagpuan?',
      correctAnswer: 'China',
      acceptableAnswers: ['china', 'tsina', 'prc'],
      imageAsset: 'assets/images/treasure_hunt/q3_city_china.png',
      options: ['China', 'Mongolia', 'Russia'],
      isTypingQuestion: false,
      explanation:
          'Ang China ay malaking bansa sa kontinente ng Asya sa hilaga ng Pilipinas.',
    ),

    // Question 4: Cave in country south -> Indonesia (Option B)
    TreasureHuntQuestion(
      id: 4,
      prompt:
          'Ang kayamanan ay nakatago sa kuweba sa bansang nasa timog ng Pilipinas. Saang bansa ito mahahanap?',
      correctAnswer: 'Indonesia',
      acceptableAnswers: ['indonesia', 'indonesya'],
      imageAsset: 'assets/images/treasure_hunt/q4_cave_indonesia.png',
      options: ['Malaysia', 'Indonesia', 'East Timor'],
      isTypingQuestion: true,
      explanation:
          'Ang Indonesia ay ang pinakamalaking kapuluang bansa na nasa direktang timog ng Pilipinas.',
    ),

    // Question 5: Playground in country west -> Vietnam (Option C)
    TreasureHuntQuestion(
      id: 5,
      prompt:
          'Ang kayamanan ay nasa palaruan (playground) sa bansang nasa kanluran ng Pilipinas. Saang bansa ito matatagpuan?',
      correctAnswer: 'Vietnam',
      acceptableAnswers: ['vietnam', 'biyetnam'],
      imageAsset: 'assets/images/treasure_hunt/q5_playground_vietnam.png',
      options: ['Laos', 'Cambodia', 'Vietnam'],
      isTypingQuestion: false,
      explanation:
          'Ang Vietnam ay may baybaying hugis titik "S" sa kanluran ng Pilipinas patawid sa West Philippine Sea.',
    ),

    // Question 6: Island southeast -> Palau (Option A)
    TreasureHuntQuestion(
      id: 6,
      prompt:
          'Ang kayamanan ay nasa isla na nasa timog-silangan ng Pilipinas. Saang bansa ito makikita?',
      correctAnswer: 'Palau',
      acceptableAnswers: ['palau', 'belau'],
      imageAsset: 'assets/images/treasure_hunt/q6_island_palau.png',
      options: ['Palau', 'Guam', 'Micronesia'],
      isTypingQuestion: true,
      explanation:
          'Ang bansang Palau ay matatagpuan sa Karagatang Pasipiko sa timog-silangan ng Mindanao.',
    ),

    // Question 7: Country west of Philippines -> Thailand (Option B)
    TreasureHuntQuestion(
      id: 7,
      prompt:
          'Ang kayamanan ay matatagpuan sa bansang nasa kanluran ng Pilipinas. Saang bansang ito makikita?',
      correctAnswer: 'Thailand',
      acceptableAnswers: ['thailand', 'taylandiya', 'siam'],
      imageAsset: 'assets/images/treasure_hunt/q7_forest_thailand.png',
      options: ['Myanmar', 'Thailand', 'Singapore'],
      isTypingQuestion: false,
      explanation:
          'Ang Thailand ay matatagpuan sa kanluran ng Pilipinas sa Indochina Peninsula sa Timog-Silangang Asya.',
    ),

    // Question 8: Big ocean east of Philippines -> Pacific Ocean (Option C)
    TreasureHuntQuestion(
      id: 8,
      prompt:
          'Ang kayamanan ay nakatago sa malaking karagatang nasa silangan ng Pilipinas. Saan ito matatagpuan?',
      correctAnswer: 'Pacific Ocean',
      acceptableAnswers: [
        'pacific ocean',
        'pacific',
        'karagatang pasipiko',
        'pasipiko'
      ],
      imageAsset: 'assets/images/treasure_hunt/q8_ocean_pacific.png',
      options: ['Indian Ocean', 'Atlantic Ocean', 'Pacific Ocean'],
      isTypingQuestion: true,
      explanation:
          'Ang Pacific Ocean ang pinakamalaking karagatan sa buong daigdig na sumasakop sa silangang bahagi ng Pilipinas.',
    ),

    // Question 9: Ship sailing in west sea -> West Philippine Sea (Option A)
    TreasureHuntQuestion(
      id: 9,
      prompt:
          'Ang kayamanan ay nasa barkong naglalayag sa kanluran na karagatan ng Pilipinas. Saang dagat ito matatagpuan?',
      correctAnswer: 'West Philippine Sea',
      acceptableAnswers: [
        'west philippine sea',
        'dagat kanlurang pilipinas',
        'wps'
      ],
      imageAsset: 'assets/images/treasure_hunt/q9_ship_wps.png',
      options: ['West Philippine Sea', 'Celebes Sea', 'Indian Ocean'],
      isTypingQuestion: false,
      explanation:
          'Ang West Philippine Sea ang katubigan sa kanlurang baybayin ng Pilipinas na sakop ng Exclusive Economic Zone (EEZ).',
    ),

    // Question 10: Ocean ship northeast -> Philippine Sea (Option B)
    TreasureHuntQuestion(
      id: 10,
      prompt:
          'Ang kayamanan ay nakatago sa karagatan sa barkong nasa hilagang-silangan ng Pilipinas. Saang karagatan ito matatagpuan?',
      correctAnswer: 'Philippine Sea',
      acceptableAnswers: ['philippine sea', 'dagat pilipinas'],
      imageAsset: 'assets/images/treasure_hunt/q10_helm_phsea.png',
      options: ['Sulu Sea', 'Philippine Sea', 'Celebes Sea'],
      isTypingQuestion: true,
      explanation:
          'Ang Philippine Sea ay bahagi ng Karagatang Pasipiko na nasa silangan at hilagang-silangan ng Pilipinas.',
    ),
  ];
}
