/// Types of gameplay interactions available across game missions.
enum MissionType {
  /// Player must click/tap the correct target pin on the interactive map.
  tapMap,

  /// Player must choose the correct answer among options based on the map.
  choice,

  /// Player is given progressive clues and must tap the correct location on the map.
  cluesMap,
}

/// Model representing a badge or achievement earned in Game Mode.
class GameBadge {
  final String id;
  final String title;
  final String subtitle;
  final String icon;

  const GameBadge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Model representing an individual challenge/mission in MapQuest Game Mode.
class GameMission {
  final int missionNumber;
  final String title;
  final String prompt;
  final String instruction;
  final MissionType type;
  final List<String> targetLocationIds;
  final List<String> clues;
  final List<String> choices;
  final int correctChoiceIndex;
  final int pointsReward;
  final int coinsReward;
  final String successMessage;
  final String failureMessage;

  const GameMission({
    required this.missionNumber,
    required this.title,
    required this.prompt,
    required this.instruction,
    required this.type,
    this.targetLocationIds = const [],
    this.clues = const [],
    this.choices = const [],
    this.correctChoiceIndex = -1,
    required this.pointsReward,
    required this.coinsReward,
    required this.successMessage,
    required this.failureMessage,
  });

  /// Check if a tapped location matches the target(s) for tapMap or cluesMap missions.
  bool isTargetLocation(String locationId) {
    return targetLocationIds.contains(locationId.toLowerCase());
  }

  /// Check if selected choice index is correct.
  bool isCorrectChoice(int index) {
    return index == correctChoiceIndex;
  }
}

/// Registry of the 10 Grade 4 geography missions in MapQuest Game Mode.
class GameMissionRegistry {
  static const List<GameBadge> availableBadges = [
    GameBadge(
      id: 'first_discovery',
      title: 'First Discovery',
      subtitle: 'Unang Misyon Natapos',
      icon: '⭐',
    ),
    GameBadge(
      id: 'direction_master',
      title: 'Direction Master',
      subtitle: 'Dalubhasa sa mga Direksyon',
      icon: '🧭',
    ),
    GameBadge(
      id: 'map_detective',
      title: 'Map Detective',
      subtitle: 'Nalutas ang mga Pahiwatig',
      icon: '🔍',
    ),
    GameBadge(
      id: 'asia_explorer',
      title: 'Asia Explorer',
      subtitle: 'Tuklas ang Timog-Silangang Asya',
      icon: '🌏',
    ),
    GameBadge(
      id: 'ultimate_explorer',
      title: 'Ultimate Explorer',
      subtitle: 'Nakumpleto ang Lahat ng 10 Misyon',
      icon: '🏆',
    ),
  ];

  static const List<GameMission> missions = [
    // Mission 1 – Hanapin ang Pilipinas
    GameMission(
      missionNumber: 1,
      title: 'MISYON 1 – HANAPIN ANG PILIPINAS',
      prompt: 'Nagsisimula ang iyong paglalakbay! Hanapin ang Pilipinas sa mapa ng Asya.',
      instruction: 'I-tap ang alinman sa mga pulo ng Pilipinas (Luzon, Visayas, Mindanao, o Palawan) upang magpatuloy.',
      type: MissionType.tapMap,
      targetLocationIds: ['luzon', 'visayas', 'mindanao', 'palawan'],
      pointsReward: 10,
      coinsReward: 5,
      successMessage: 'Magaling! Nahanap mo ang kapuluan ng Pilipinas sa gitna ng Timog-Silangang Asya.',
      failureMessage: 'Hindi iyan ang Pilipinas. Tingnan muli ang kapuluan sa silangang bahagi ng Dagat Kanlurang Pilipinas.',
    ),

    // Mission 2 – Hanapin ang Karatig-Bansa (Bisinal)
    GameMission(
      missionNumber: 2,
      title: 'MISYON 2 – HANAPIN ANG KARATIG-BANSA',
      prompt: 'May isang bansa na matatagpuan sa hilaga ng Pilipinas. Hanapin ito sa mapa.',
      instruction: 'Tingnan ang itaas (hilaga) ng Pilipinas at i-tap ang tamang bansa o pulo.',
      type: MissionType.tapMap,
      targetLocationIds: ['taiwan', 'china'],
      pointsReward: 15,
      coinsReward: 5,
      successMessage: 'TAMA! Ang Taiwan ay matatagpuan sa hilaga ng Pilipinas bilang isa sa mga pinakamalapit na karatig-lugar nito.',
      failureMessage: 'Hindi iyan ang nasa hilaga ng Pilipinas. Tumingin sa dakong itaas mula sa Luzon.',
    ),

    // Mission 3 – Hanapin ang Anyong Tubig (Insular)
    GameMission(
      missionNumber: 3,
      title: 'MISYON 3 – HANAPIN ANG ANYONG TUBIG',
      prompt: 'Hanapin ang anyong tubig na matatagpuan sa kanluran ng Pilipinas.',
      instruction: 'I-tap ang dagat o karagatan sa kanlurang bahagi ng ating bansa.',
      type: MissionType.tapMap,
      targetLocationIds: ['west_ph_sea'],
      pointsReward: 15,
      coinsReward: 5,
      successMessage: 'MAGALING! Ang Dagat Kanlurang Pilipinas (West Philippine Sea) ay nasa kanluran ng ating kapuluan.',
      failureMessage: 'Hindi iyan ang anyong tubig sa kanluran. Tumingin sa gawing kaliwa ng Luzon at Palawan.',
    ),

    // Mission 4 – Direction Challenge
    GameMission(
      missionNumber: 4,
      title: 'MISYON 4 – DIRECTION CHALLENGE',
      prompt: 'Mula sa Pilipinas, sa anong pangunahing direksyon matatagpuan ang bansang Taiwan?',
      instruction: 'Suriin ang posisyon ng Taiwan gamit ang mapa bago pumili ng sagot:',
      type: MissionType.choice,
      choices: [
        'A. Hilaga (North)',
        'B. Timog (South)',
        'C. Silangan (East)',
        'D. Kanluran (West)',
      ],
      correctChoiceIndex: 0,
      pointsReward: 20,
      coinsReward: 5,
      successMessage: 'TAMA! Ang Taiwan ay matatagpuan sa dakong HILAGA mula sa kapuluan ng Pilipinas.',
      failureMessage: 'Mali ang napiling direksyon. Tandaan: ang itaas sa mapa ay Hilaga.',
    ),

    // Mission 5 – Hanapin ang Lokasyon
    GameMission(
      missionNumber: 5,
      title: 'MISYON 5 – HANAPIN ANG LOKASYON',
      prompt: 'May kailangan kang puntahan! Ang iyong destinasyon ay isang bansang matatagpuan sa timog ng Pilipinas. Hanapin ang tamang lokasyon sa mapa.',
      instruction: 'Suriin ang timog ng Pilipinas (sa gawing ibaba ng Mindanao at Dagat Celebes) at i-tap ito.',
      type: MissionType.tapMap,
      targetLocationIds: ['indonesia'],
      pointsReward: 20,
      coinsReward: 5,
      successMessage: 'TAMA! Ang Indonesia ay ang dambuhalang kapuluang bansa sa timog ng Pilipinas.',
      failureMessage: 'Hindi iyan ang bansa sa timog ng Pilipinas. Tumingin sa gawing ibaba ng Dagat Celebes.',
    ),

    // Mission 6 – Lost Explorer (Progressive Clues)
    GameMission(
      missionNumber: 6,
      title: 'MISYON 6 – LOST EXPLORER',
      prompt: 'Nawawala ang MapQuest Explorer! Gamitin ang mga pahiwatig upang matukoy kung saang lugar siya naroroon.',
      instruction: 'Basahin ang mga pahiwatig at i-tap ang tamang lugar sa mapa:',
      type: MissionType.cluesMap,
      clues: [
        'Pahiwatig 1: Ako ay nasa hilaga ng Pilipinas.',
        'Pahiwatig 2: Ako ay isang isla.',
        'Pahiwatig 3: Ako ay malapit sa mainland China.',
      ],
      targetLocationIds: ['taiwan'],
      pointsReward: 25,
      coinsReward: 10,
      successMessage: 'MAGALING! Natukoy mo ang Taiwan gamit ang tatlong pahiwatig ng Lost Explorer!',
      failureMessage: 'Hindi iyan ang lugar na inilalarawan ng mga pahiwatig. Suriing mabuti ang isla sa hilaga.',
    ),

    // Mission 7 – Plan Your Journey
    GameMission(
      missionNumber: 7,
      title: 'MISYON 7 – PLAN YOUR JOURNEY',
      prompt: 'Nasa Pilipinas ka at kailangan mong maglayag patungong Taiwan. Sa anong direksyon ka dapat magtungo?',
      instruction: 'Gamitin ang mapa at compass upang itakda ang direksyon ng barko:',
      type: MissionType.choice,
      choices: [
        '🧭 Hilaga (North)',
        '🧭 Timog (South)',
        '🧭 Silangan (East)',
        '🧭 Kanluran (West)',
      ],
      correctChoiceIndex: 0,
      pointsReward: 20,
      coinsReward: 5,
      successMessage: 'TAMA! Naglayag ka patungong Hilaga at ligtas na nakarating sa daungan ng Taiwan!',
      failureMessage: 'Maling ruta! Kung doon ka maglalayag, hindi ka makararating sa Taiwan.',
    ),

    // Mission 8 – Map Comparison
    GameMission(
      missionNumber: 8,
      title: 'MISYON 8 – MAP COMPARISON',
      prompt: 'Alin sa dalawang bansang ito ang mas malapit sa Pilipinas batay sa mapa?',
      instruction: 'Ihambing ang agwat at distansya ng bawat isa mula sa Pilipinas:',
      type: MissionType.choice,
      choices: [
        '🇹🇼 Taiwan',
        '🇯🇵 Hapon (Japan)',
      ],
      correctChoiceIndex: 0,
      pointsReward: 25,
      coinsReward: 5,
      successMessage: 'TAMA! Ang Taiwan ang pinakamalapit na karatig-lugar sa hilaga, higit na mas malapit kaysa sa Hapon.',
      failureMessage: 'Hindi iyon. Mas malayo ang Hapon; ang Taiwan ang mas malapit na bansa sa hilaga.',
    ),

    // Mission 9 – Geography Detective
    GameMission(
      missionNumber: 9,
      title: 'MISYON 9 – GEOGRAPHY DETECTIVE',
      prompt: 'May nawawalang lokasyon sa mapa! Tulungan ang MapQuest Explorer na hanapin ito gamit ang mga pahiwatig.',
      instruction: 'Suriin ang mga detalyadong pahiwatig at i-tap ang tamang bansa sa mapa:',
      type: MissionType.cluesMap,
      clues: [
        'Clue 1: Ako ay nasa katimugang bahagi ng Tangway ng Indochina sa kanluran ng Pilipinas.',
        'Clue 2: Dito matatagpuan ang tanyag na Angkor Wat at ang Lawa ng Tonle Sap.',
        'Clue 3: Karatig-bansa ako ng Thailand at Vietnam.',
      ],
      targetLocationIds: ['cambodia'],
      pointsReward: 30,
      coinsReward: 10,
      successMessage: '🎉 MYSTERY SOLVED! Magaling, Explorer! Natukoy mo ang Kambodya (Cambodia) gamit ang mga heograpikal na pahiwatig.',
      failureMessage: 'Hindi iyan ang hinahanap. Tandaan: tahanan ito ng Angkor Wat at Tonle Sap.',
    ),

    // Mission 10 – Absolute Location
    GameMission(
      missionNumber: 10,
      title: 'MISYON 10 – ABSOLUTE LOCATION',
      prompt: 'Ang isang lugar ay maaaring matukoy gamit ang latitude at longitude. Ano ang absolute location ng Pilipinas sa globo?',
      instruction: 'Piliin ang wastong coordinate ng Pilipinas:',
      type: MissionType.choice,
      choices: [
        'A. 4° hanggang 21° Hilagang Latitud (N), 116° hanggang 127° Silangang Longhitud (E)',
        'B. 40° hanggang 55° Hilagang Latitud (N), 90° hanggang 105° Kanlurang Longhitud (W)',
        'C. 30° hanggang 45° Timog Latitud (S), 130° hanggang 150° Silangang Longhitud (E)',
      ],
      correctChoiceIndex: 0,
      pointsReward: 35,
      coinsReward: 15,
      successMessage: 'NAPAKAHUSAY! Natukoy mo ang eksaktong absolute coordinates ng Pilipinas sa buong daigdig!',
      failureMessage: 'Hindi iyan ang tamang coordinate. Ang Pilipinas ay nasa pagitan ng 4°-21° N latitud at 116°-127° E longhitud.',
    ),
  ];
}
