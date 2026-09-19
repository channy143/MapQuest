import 'dart:math' as math;

/// Model for a 3-choice geography question used in Classic Quiz Mode.
class ClassicQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const ClassicQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  String get correctAnswer => options[correctIndex];

  bool isCorrect(int index) => index == correctIndex;

  /// Returns a copy of the question with shuffled options and an updated correctIndex.
  ClassicQuestion withShuffledOptions([math.Random? random]) {
    final rand = random ?? math.Random();
    final pairs = options.asMap().entries.toList()..shuffle(rand);
    final newOptions = pairs.map((e) => e.value).toList();
    final newCorrectIndex = pairs.indexWhere((e) => e.key == correctIndex);
    return ClassicQuestion(
      id: id,
      prompt: prompt,
      options: newOptions,
      correctIndex: newCorrectIndex,
      explanation: explanation,
    );
  }
}

/// Registry of curated Grade 4 Araling Panlipunan geography questions for Classic Mode.
class ClassicQuestionRegistry {
  static const List<ClassicQuestion> questions = [
    ClassicQuestion(
      id: 'cq_1',
      prompt: 'Aling bansa ang pinakamalapit na karatig-bansa sa hilaga ng Pilipinas, patawid sa Kipot ng Bashi?',
      options: ['Taiwan', 'Hapon', 'Vietnam'],
      correctIndex: 0,
      explanation: 'Ang Taiwan ang pinakamalapit na karatig-bansa sa hilaga ng Pilipinas, pinaghihiwalay lamang ng Kipot ng Bashi mula sa lalawigan ng Batanes.',
    ),
    ClassicQuestion(
      id: 'cq_2',
      prompt: 'Anong anyong tubig ang matatagpuan sa buong silangang hangganan ng kapuluan ng Pilipinas?',
      options: ['Karagatang Pasipiko', 'Dagat Kanlurang Pilipinas', 'Dagat Celebes'],
      correctIndex: 0,
      explanation: 'Ang Karagatang Pasipiko ang pinakamalaking karagatan sa daigdig na sumasaklaw sa silangang bahagi ng Pilipinas.',
    ),
    ClassicQuestion(
      id: 'cq_3',
      prompt: 'Aling bansa sa Timog-Silangang Asya ang matatagpuan sa timog ng Pilipinas, patawid sa Dagat Celebes?',
      options: ['Malaysia', 'Indonesia', 'Singgapur'],
      correctIndex: 1,
      explanation: 'Ang Indonesia ang pinakamalaking kapuluang bansa sa daigdig at matatagpuan sa direktang timog ng Mindanao.',
    ),
    ClassicQuestion(
      id: 'cq_4',
      prompt: 'Anong anyong tubig ang nasa kanlurang baybayin ng Pilipinas na sakop ng Exclusive Economic Zone (EEZ) ng bansa?',
      options: ['Dagat Sulu', 'Dagat Celebes', 'Dagat Kanlurang Pilipinas'],
      correctIndex: 2,
      explanation: 'Ang Dagat Kanlurang Pilipinas (West Philippine Sea) ang opisyal na tawag sa katubigan sa kanluran ng Luzon at Palawan.',
    ),
    ClassicQuestion(
      id: 'cq_5',
      prompt: 'Ano ang tiyak na lokasyon (absolute location) ng Pilipinas sa grid ng mundo gamit ang latitud at longhitud?',
      options: [
        '4° hanggang 21° Hilagang Latitud at 116° hanggang 127° Silangang Longhitud',
        '10° hanggang 30° Timog Latitud at 100° hanggang 115° Silangang Longhitud',
        '0° hanggang 15° Hilagang Latitud at 130° hanggang 145° Kanlurang Longhitud',
      ],
      correctIndex: 0,
      explanation: 'Matatagpuan ang Pilipinas sa pagitan ng 4° hanggang 21° Hilagang Latitud at 116° hanggang 127° Silangang Longhitud.',
    ),
    ClassicQuestion(
      id: 'cq_6',
      prompt: 'Aling bansa ang matatagpuan sa kanluran ng Pilipinas na may mahabang baybaying hugis titik "S"?',
      options: ['Vietnam', 'Thailand', 'Kambodya'],
      correctIndex: 0,
      explanation: 'Ang Vietnam ay matatagpuan sa silangang baybayin ng Tangway ng Indochina sa kanluran ng Pilipinas at may hugis titik "S".',
    ),
    ClassicQuestion(
      id: 'cq_7',
      prompt: 'Kung ikaw ay maglalakbay mula sa Pilipinas patungong Hapon (Japan), saang direksyon ka tutungo?',
      options: ['Timog-Kanluran', 'Hilagang-Silangan', 'Hilagang-Kanluran'],
      correctIndex: 1,
      explanation: 'Ang Hapon ay matatagpuan sa hilagang-silangan (northeast) ng Pilipinas sa Karagatang Pasipiko.',
    ),
    ClassicQuestion(
      id: 'cq_8',
      prompt: 'Aling bansa sa timog-kanluran ng Pilipinas ang binubuo ng Peninsular Malaysia at Silangang Malaysia sa Borneo?',
      options: ['Singgapur', 'Brunei', 'Malaysia'],
      correctIndex: 2,
      explanation: 'Ang Malaysia ay nahahati sa dalawang pangunahing bahagi: Peninsular Malaysia at Sabah/Sarawak sa isla ng Borneo.',
    ),
    ClassicQuestion(
      id: 'cq_9',
      prompt: 'Ano ang tawag sa pagtukoy ng lokasyon ng isang lugar batay sa mga nakapaligid na kalupaan o karatig-bansa?',
      options: ['Bisinal na Lokasyon', 'Insular na Lokasyon', 'Tiyak na Lokasyon'],
      correctIndex: 0,
      explanation: 'Ang Bisinal na lokasyon ay ang pagtukoy ng kinaroroonan ng isang bansa batay sa mga lupang nakapaligid dito (mga karatig-bansa).',
    ),
    ClassicQuestion(
      id: 'cq_10',
      prompt: 'Ano naman ang tawag sa pagtukoy ng lokasyon batay sa mga nakapaligid na anyong tubig?',
      options: ['Bisinal na Lokasyon', 'Insular na Lokasyon', 'Absolútong Lokasyon'],
      correctIndex: 1,
      explanation: 'Ang Insular na lokasyon (maritima) ay ang pagtukoy ng kinaroroonan ng isang lugar gamit ang mga nakapaligid na dagat at karagatan.',
    ),
    ClassicQuestion(
      id: 'cq_11',
      prompt: 'Aling bansa ang tahanan ng tanyag na Angkor Wat at Lawa ng Tonle Sap, na nasa kanluran ng Pilipinas?',
      options: ['Laos', 'Kambodya', 'Myanmar'],
      correctIndex: 1,
      explanation: 'Ang Kambodya (Cambodia) sa Indochina Peninsula ay tahanan ng Angkor Wat at Lawa ng Tonle Sap.',
    ),
    ClassicQuestion(
      id: 'cq_12',
      prompt: 'Anong anyong tubig ang naghihiwalay sa Mindanao at sa isla ng Sulawesi sa Indonesia?',
      options: ['Dagat Celebes', 'Dagat Sulu', 'Dagat Pilipinas'],
      correctIndex: 0,
      explanation: 'Ang Dagat Celebes ay matatagpuan sa katimugan ng Pilipinas sa pagitan ng Mindanao at Sulawesi, Indonesia.',
    ),
    ClassicQuestion(
      id: 'cq_13',
      prompt: 'Aling dambuhalang kontinente at bansa ang matatagpuan sa timog ng kapuluan ng Indonesia?',
      options: ['India', 'Antartika', 'Australya'],
      correctIndex: 2,
      explanation: 'Ang Australya ay isang kontinente at bansa na matatagpuan sa katimugan ng Pilipinas, lampas sa Indonesia.',
    ),
    ClassicQuestion(
      id: 'cq_14',
      prompt: 'Bakit tinatawag na "Kapuluan" o "Archipelago" ang bansang Pilipinas?',
      options: [
        'Dahil binubuo ito ng mahigit 7,641 na mga pulo na napaliligiran ng katubigan',
        'Dahil ito ay nakadikit sa kontinente ng Asya',
        'Dahil mayroon itong isang malaking bundok sa gitna',
      ],
      correctIndex: 0,
      explanation: 'Ang kapuluan ay isang pangkat o grupo ng mga pulo. May mahigit 7,641 pulo ang Pilipinas na pinalilibutan ng dagat.',
    ),
    ClassicQuestion(
      id: 'cq_15',
      prompt: 'Aling bansa sa mainland Asya ang dating tinawag na "Siam" at hindi kailanman nasakop ng mga Kanluranin?',
      options: ['Tsina', 'Thailand', 'Vietnam'],
      correctIndex: 1,
      explanation: 'Ang Thailand (dating Siam) ang nag-iisang bansa sa Timog-Silangang Asya na hindi nasakop ng mga bansang Europeo.',
    ),
    ClassicQuestion(
      id: 'cq_16',
      prompt: 'Kung ihahambing ang Taiwan at Hapon, alin sa dalawa ang mas malapit sa lalawigan ng Batanes sa Pilipinas?',
      options: ['Taiwan', 'Hapon', 'Magkasinglayo'],
      correctIndex: 0,
      explanation: 'Ang Taiwan ang pinakamalapit sa Batanes, may distansya lamang na humigit-kumulang 350 kilometro patawid sa Bashi Channel.',
    ),
    ClassicQuestion(
      id: 'cq_17',
      prompt: 'Anong malaking panloob na dagat ang napaliligiran ng Palawan, Visayas, at Zamboanga Peninsula?',
      options: ['Dagat Celebes', 'Dagat Sulu', 'Dagat Bohol'],
      correctIndex: 1,
      explanation: 'Ang Dagat Sulu ay matatagpuan sa timog-kanluran ng Pilipinas, sa pagitan ng Palawan, Kabisayaan, at Mindanao.',
    ),
    ClassicQuestion(
      id: 'cq_18',
      prompt: 'Aling city-state sa dulo ng Tangway ng Malay ang kilala sa pagiging isa sa pinakamaunlad na bansa sa Timog-Silangang Asya?',
      options: ['Brunei', 'Singgapur', 'Timor-Leste'],
      correctIndex: 1,
      explanation: 'Ang Singgapur ay isang maunlad na pulong-bansa at sentro ng kalakalan sa timog ng Malaysia.',
    ),
    ClassicQuestion(
      id: 'cq_19',
      prompt: 'Ano ang tawag sa guhit na pahalang sa gitna ng globo na may 0° latitud at naghahati sa hilaga at timog hating-globo?',
      options: ['Ekwador (Equator)', 'Prime Meridian', 'Tropiko ng Kanser'],
      correctIndex: 0,
      explanation: 'Ang Ekwador ay ang 0° latitud na naghahati sa daigdig sa Hilaga at Timog Hating-globo. Ang Pilipinas ay nasa itaas (hilaga) nito.',
    ),
    ClassicQuestion(
      id: 'cq_20',
      prompt: 'Dahil ang Pilipinas ay malapit sa Ekwador sa pagitan ng Tropiko ng Kanser at Ekwador, anong uri ng klima mayroon ang bansa?',
      options: ['Klimang Polar', 'Klimang Tropikal', 'Klimang Katamtaman (Temperate)'],
      correctIndex: 1,
      explanation: 'Nasa sonang tropikal ang Pilipinas kaya mayroon itong klimang tropikal na may dalawang pangunahing panahon: tag-araw at tag-ulan.',
    ),
    ClassicQuestion(
      id: 'cq_21',
      prompt: 'Aling dambuhalang bansa ang nasa hilagang-kanluran ng Pilipinas patawid sa Dagat Kanlurang Pilipinas?',
      options: ['Tsina (China)', 'Rusya', 'India'],
      correctIndex: 0,
      explanation: 'Ang Tsina ay matatagpuan sa hilagang-kanluran ng Pilipinas sa mainland Asya.',
    ),
  ];

  /// Returns [count] randomly selected questions shuffled for a fresh quiz experience.
  static List<ClassicQuestion> getRandomQuestions([int count = 10]) {
    final list = List<ClassicQuestion>.from(questions);
    list.shuffle(math.Random());
    return list.take(count).toList();
  }
}

/// Registry containing the 14 official revised Araling Panlipunan questions
/// for the "Subukin ang Kaalaman!" game mode.
class SubukinKaalamanRegistry {
  static const String instruction =
      'Handa ka na bang subukin ang iyong kaalaman? Sagutin ang bawat tanong. Basahin ng mabuti bago pumili ng tamang sagot sa mga pagpipilian. Bawat tamang sagot ay may puntos at gantimpala.';

  static const List<ClassicQuestion> questions = [
    // Tanong 1: Anong anyong tubig ang matatagpuan sa buong silangan ng Pilipinas? -> Pacific Ocean (Option B)
    ClassicQuestion(
      id: 'sk_1',
      prompt: 'Anong anyong tubig ang matatagpuan sa buong silangan ng Pilipinas?',
      options: ['Celebes Sea', 'Pacific Ocean', 'South China Sea'],
      correctIndex: 1,
      explanation:
          'Ang Pacific Ocean ang pinakamalaking karagatan sa daigdig na sumasaklaw sa buong silangang bahagi ng Pilipinas.',
    ),

    // Tanong 2: Kanlurang baybayin EEZ -> West Philippine Sea (Option C)
    ClassicQuestion(
      id: 'sk_2',
      prompt:
          'Anong anyong tubig ang nasa kanlurang baybayin ng Pilipinas na sakop ng Exclusive Economic Zone (EEZ) ng bansa?',
      options: ['Sulu Sea', 'Celebes Sea', 'West Philippine Sea'],
      correctIndex: 2,
      explanation:
          'Ang West Philippine Sea ang katubigan sa kanlurang baybayin ng Pilipinas na sakop ng Exclusive Economic Zone (EEZ).',
    ),

    // Tanong 3: Hilagang-kanluran patawid sa West Philippine Sea -> China (Option C)
    ClassicQuestion(
      id: 'sk_3',
      prompt:
          'Ano ang malaking bansa na nasa hilagang-kanluran ng Pilipinas patawid sa West Philippine Sea?',
      options: ['Indonesia', 'Japan', 'China'],
      correctIndex: 2,
      explanation:
          'Ang China ang malaking bansa sa kontinente ng Asya na nasa hilagang-kanluran ng Pilipinas.',
    ),

    // Tanong 4: Mas malapit (Taiwan vs Japan) -> Taiwan (Option B)
    ClassicQuestion(
      id: 'sk_4',
      prompt: 'Aling bansa ang mas malapit sa Pilipinas?',
      options: ['Japan', 'Taiwan'],
      correctIndex: 1,
      explanation:
          'Ang Taiwan ang pinakamalapit na karatig-bansa sa hilaga ng Pilipinas, humigit-kumulang 350 km lamang ang layo mula sa Batanes.',
    ),

    // Tanong 5: Kanluran ng Pilipinas, baybaying hugis "S" -> Vietnam (Option A)
    ClassicQuestion(
      id: 'sk_5',
      prompt:
          'Anong bansa ang matatagpuan sa kanluran ng Pilipinas na may baybaying hugis titik "S"?',
      options: ['Vietnam', 'Thailand', 'Cambodia'],
      correctIndex: 0,
      explanation:
          'Ang Vietnam ay may mahabang baybaying hugis titik "S" sa silangang baybayin ng Indochina Peninsula.',
    ),

    // Tanong 6: Timog-kanluran ng Pilipinas -> Brunei (Option B)
    ClassicQuestion(
      id: 'sk_6',
      prompt: 'Anong bansa ang nasa timog-kanluran ng Pilipinas?',
      options: ['Taiwan', 'Brunei', 'Japan'],
      correctIndex: 1,
      explanation:
          'Ang Brunei ay matatagpuan sa hilagang bahagi ng isla ng Borneo sa timog-kanluran ng Pilipinas.',
    ),

    // Tanong 7: Silangan ng Pilipinas -> Guam (Option C)
    ClassicQuestion(
      id: 'sk_7',
      prompt: 'Anong bansa ang nasa silangan ng Pilipinas?',
      options: ['Vietnam', 'Thailand', 'Guam'],
      correctIndex: 2,
      explanation:
          'Ang Guam ay matatagpuan sa Karagatang Pasipiko sa silangan ng Pilipinas.',
    ),

    // Tanong 8: Kanluran ng Pilipinas -> Cambodia (Option B)
    ClassicQuestion(
      id: 'sk_8',
      prompt: 'Anong bansa ang nasa kanluran ng Pilipinas?',
      options: ['Palau', 'Cambodia', 'Japan'],
      correctIndex: 1,
      explanation:
          'Ang Cambodia ay matatagpuan sa kanluran ng Pilipinas sa Timog-Silangang Asya.',
    ),

    // Tanong 9: Nahati sa dalawa, Peninsular at Silangang Malaysia -> Malaysia (Option B)
    ClassicQuestion(
      id: 'sk_9',
      prompt:
          'Anong bansa ang nahati sa dalawa, ang Peninsular Malaysia at Silangang Malaysia?',
      options: ['Indonesia', 'Malaysia', 'Singapore'],
      correctIndex: 1,
      explanation:
          'Ang Malaysia ay nahahati sa dalawang pangunahing bahagi: Peninsular Malaysia at Silangang Malaysia (Sabah at Sarawak).',
    ),

    // Tanong 10: Lokasyon batay sa nakapaligid na anyong tubig -> Lokasyong Insular (Option C)
    ClassicQuestion(
      id: 'sk_10',
      prompt:
          'Ano ang tawag sa pagtukoy ng lokasyon batay sa mga nakapaligid na anyong tubig?',
      options: ['Lokasyong Bisinal', 'Tiyak na Lokasyon', 'Lokasyong Insular'],
      correctIndex: 2,
      explanation:
          'Ang Lokasyong Insular ay ang pagtukoy ng lokasyon batay sa mga nakapaligid na dagat at karagatan.',
    ),

    // Tanong 11: Lokasyon batay sa nakapaligid na bansa o anyong lupa -> Lokasyong Bisinal (Option A)
    ClassicQuestion(
      id: 'sk_11',
      prompt:
          'Ano ang tawag sa pagtukoy ng lokasyon batay sa mga nakapaligid na bansa o anyong lupa?',
      options: ['Lokasyong Bisinal', 'Lokasyong Insular', 'Relatibong Lokasyon'],
      correctIndex: 0,
      explanation:
          'Ang Lokasyong Bisinal ay ang pagtukoy ng lokasyon batay sa mga karatig-bansa o kalupaan sa paligid.',
    ),

    // Tanong 12: Eksakto at ispesipikong kinalalagyan gamit latitud at longhitud -> Tiyak na Lokasyon (Option B)
    ClassicQuestion(
      id: 'sk_12',
      prompt:
          'Ano ang tumutukoy sa eksakto at ispesipikong kinalalagyan ng isang lugar gamit ang latitud at longhitud?',
      options: ['Relatibong Lokasyon', 'Tiyak na Lokasyon', 'Lokasyong Bisinal'],
      correctIndex: 1,
      explanation:
          'Ang Tiyak na Lokasyon (Absolute Location) ay tinutukoy gamit ang mga degree ng latitud at longhitud.',
    ),

    // Tanong 13: Patayong guhit sa mapa o globo -> Longhitud (Option C)
    ClassicQuestion(
      id: 'sk_13',
      prompt: 'Ano ang mga patayong guhit sa mapa o globo?',
      options: ['Latitud', 'Ekwador', 'Longhitud'],
      correctIndex: 2,
      explanation:
          'Ang mga linyang Longhitud (meridians) ay ang mga patayong guhit na tumatakbo mula Hilagang Polo patungong Timog Polo.',
    ),

    // Tanong 14: Kinalalagyan batay sa direksyon at karatig na bansa/katubigan -> Relatibong Lokasyon (Option B)
    ClassicQuestion(
      id: 'sk_14',
      prompt:
          'Tumutukoy sa kinalalagyan ng isang bansa batay sa direksyon at mga bansa o katubigang nakapaligid nito.',
      options: ['Tiyak na Lokasyon', 'Relatibong Lokasyon', 'Absolute Location'],
      correctIndex: 1,
      explanation:
          'Ang Relatibong Lokasyon ay tumutukoy sa kinaroroonan ng lugar batay sa mga nakapaligid ditong mga anyong lupa at tubig.',
    ),
  ];
}

