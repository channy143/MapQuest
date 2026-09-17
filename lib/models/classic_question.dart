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
