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
  final bool requireAllTargets;
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
    this.requireAllTargets = false,
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
      id: 'direction_master',
      title: 'Direction Master',
      subtitle: '',
      icon: '🧭',
    ),
  ];

  static const List<GameMission> missions = [
    // Mission 1: Luzon, Visayas, Mindanao (tap all 3)
    GameMission(
      missionNumber: 1,
      title: 'MISYON 1',
      prompt:
          'Nagsimula na ang iyong paglalakbay! Sa unang misyon, hanapin ang Pilipinas sa mapa ng Timog-Silangang Asya. Nasaan ang Luzon, Visayas, at Mindanao?',
      instruction:
          'Pindutin ang Luzon, Visayas, at Mindanao sa mapa upang magpatuloy.',
      type: MissionType.tapMap,
      targetLocationIds: ['luzon', 'visayas', 'mindanao'],
      requireAllTargets: true,
      pointsReward: 15,
      coinsReward: 5,
      successMessage:
          'Magaling! Nahanap mo ang tatlong pangunahing kapuluan ng Pilipinas: Luzon, Visayas, at Mindanao!',
      failureMessage:
          'Hindi iyan bahagi ng tatlong pulo. Pindutin ang Luzon, Visayas, o Mindanao.',
    ),

    // Mission 2: Taiwan (Hilaga)
    GameMission(
      missionNumber: 2,
      title: 'MISYON 2',
      prompt:
          'Hanapin ang karatig-bansa na matatagpuan sa hilaga ng Pilipinas.',
      instruction: 'Pindutin ito sa mapa.',
      type: MissionType.tapMap,
      targetLocationIds: ['taiwan'],
      pointsReward: 15,
      coinsReward: 5,
      successMessage:
          'TAMA! Ang Taiwan ang karatig-bansa na matatagpuan sa hilaga ng Pilipinas.',
      failureMessage:
          'Hindi iyan ang bansa sa hilaga ng Pilipinas. Tumingin sa dakong itaas mula sa Luzon.',
    ),

    // Mission 3: West Philippine Sea (Kanluran)
    GameMission(
      missionNumber: 3,
      title: 'MISYON 3',
      prompt:
          'Hanapin ang anyong tubig na matatagpuan sa kanluran ng Pilipinas.',
      instruction: 'Pindutin kung saan ito sa mapa.',
      type: MissionType.tapMap,
      targetLocationIds: ['west_ph_sea'],
      pointsReward: 15,
      coinsReward: 5,
      successMessage:
          'MAGALING! Ang Dagat Kanlurang Pilipinas (West Philippine Sea) ay matatagpuan sa kanluran ng Pilipinas.',
      failureMessage:
          'Hindi iyan ang anyong tubig sa kanluran. Tumingin sa gawing kaliwa ng kapuluan.',
    ),

    // Mission 4: Vietnam Direction (Kanluran)
    GameMission(
      missionNumber: 4,
      title: 'MISYON 4',
      prompt:
          'Mula sa Pilipinas, alamin kung anong pangunahing direksyon matatagpuan ang bansang Vietnam.',
      instruction: 'Piliin ang tamang direksyon batay sa mapa:',
      type: MissionType.choice,
      choices: [
        'A. Hilaga (North)',
        'B. Kanluran (West)',
        'C. Timog (South)',
        'D. Silangan (East)',
      ],
      correctChoiceIndex: 1,
      pointsReward: 20,
      coinsReward: 5,
      successMessage:
          'TAMA! Ang bansang Vietnam ay matatagpuan sa dakong KANLURAN mula sa Pilipinas.',
      failureMessage:
          'Mali ang direksyon. Tingnan ang mapa: ang Vietnam ay nasa gawing kaliwa o kanluran ng Pilipinas.',
    ),

    // Mission 5: Indonesia (Timog)
    GameMission(
      missionNumber: 5,
      title: 'MISYON 5',
      prompt:
          'May kailangan kang puntahan! Ang iyong destinasyon ay papuntang timog ng Pilipinas. Anong bansa ang iyong patutunguhan?',
      instruction: 'Pindutin ang bansa sa timog ng Pilipinas sa mapa.',
      type: MissionType.tapMap,
      targetLocationIds: ['indonesia'],
      pointsReward: 20,
      coinsReward: 5,
      successMessage:
          'TAMA! Ang Indonesia ang bansang iyong patutunguhan sa timog ng Pilipinas.',
      failureMessage:
          'Hindi iyan ang bansa sa timog ng Pilipinas. Tumingin sa ibaba ng Mindanao at Dagat Celebes.',
    ),

    // Mission 6: China (Progressive Clues)
    GameMission(
      missionNumber: 6,
      title: 'MISYON 6',
      prompt:
          'Nawawala ang ibang MapQuest Explorer! Gamitin ang mga pahiwatig upang matukoy kung saang lugar siya naroroon.',
      instruction:
          'Basahin ang mga pahiwatig at pindutin ang tamang lugar sa mapa:',
      type: MissionType.cluesMap,
      clues: [
        'Pahiwatig 1: Ako ay nasa hilagang-kanluran ng Pilipinas',
        'Pahiwatig 2: Napakalaki ng bansang ito',
        'Pahiwatig 3: Isa ito sa pinakalumang bansa na may mahabang kasaysayan',
      ],
      targetLocationIds: ['china'],
      pointsReward: 25,
      coinsReward: 10,
      successMessage:
          'MAGALING! Natukoy mo ang bansang China gamit ang mga pahiwatig!',
      failureMessage:
          'Hindi iyan ang lugar na inilalarawan ng mga pahiwatig. Suriin ang malaking bansa sa hilagang-kanluran.',
    ),

    // Mission 7: Journey to Palau (Timog-silangan)
    GameMission(
      missionNumber: 7,
      title: 'MISYON 7',
      prompt:
          'Nasa Pilipinas ka at kailangan mong maglayag patungong Palau. Sa anong direksyon ka dapat magtungo?',
      instruction: 'Piliin ang tamang direksyon batay sa mapa:',
      type: MissionType.choice,
      choices: [
        'A. Hilagang-kanluran (Northwest)',
        'B. Hilagang-silangan (Northeast)',
        'C. Timog-silangan (Southeast)',
        'D. Timog-kanluran (Southwest)',
      ],
      correctChoiceIndex: 2,
      pointsReward: 20,
      coinsReward: 5,
      successMessage:
          'TAMA! Ang Palau ay matatagpuan sa Timog-Silangan ng Pilipinas sa Karagatang Pasipiko.',
      failureMessage:
          'Maling direksyon! Ang Palau ay nasa dakong timog-silangan mula sa Visayas at Mindanao.',
    ),

    // Mission 8: Basi Channel
    GameMission(
      missionNumber: 8,
      title: 'MISYON 8',
      prompt:
          'Alamin kung anong karagatan o anyong tubig ang nasa hilagang bahagi ng Pilipinas.',
      instruction: 'Piliin ang tamang anyong tubig:',
      type: MissionType.choice,
      choices: [
        'A. Basi Channel',
        'B. Dagat Celebes',
        'C. Dagat Sulu',
        'D. Karagatang Pasipiko',
      ],
      correctChoiceIndex: 0,
      pointsReward: 25,
      coinsReward: 5,
      successMessage:
          'TAMA! Ang Basi Channel ang anyong tubig sa hilagang bahagi ng Pilipinas na naghihiwalay sa Pilipinas at Taiwan.',
      failureMessage:
          'Mali ang sagot. Ang Basi Channel ang anyong tubig sa dakong hilaga ng Pilipinas.',
    ),

    // Mission 9: Thailand
    GameMission(
      missionNumber: 9,
      title: 'MISYON 9',
      prompt:
          'Anong bansa ang pinapalibutan ng Vietnam, Myanmar, Cambodia, at Laos?',
      instruction: 'Pindutin ang bansang ito sa mapa:',
      type: MissionType.tapMap,
      targetLocationIds: ['thailand'],
      pointsReward: 25,
      coinsReward: 5,
      successMessage:
          'TAMA! Ang Thailand ang bansang napalilibutan ng Vietnam, Myanmar, Cambodia, at Laos!',
      failureMessage:
          'Hindi iyan ang bansa. Suriin ang bansa sa gitnang bahagi ng Tangway ng Indochina.',
    ),

    // Mission 10: Absolute Location of Philippines
    GameMission(
      missionNumber: 10,
      title: 'MISYON 10',
      prompt:
          'Sa iyong panghuling misyon, tukuyin kung ano ang tiyak na lokasyon ng Pilipinas sa mapa.',
      instruction:
          'Piliin ang tamang tiyak na lokasyon (absolute location) ng Pilipinas:',
      type: MissionType.choice,
      choices: [
        'A. 4° hanggang 21° Hilagang Latitud (H), 116° hanggang 127° Silangang Longhitud (S)',
        'B. 40° hanggang 55° Hilagang Latitud (H), 90° hanggang 105° Kanlurang Longhitud (K)',
        'C. 30° hanggang 45° Timog Latitud (T), 130° hanggang 150° Silangang Longhitud (S)',
      ],
      correctChoiceIndex: 0,
      pointsReward: 35,
      coinsReward: 15,
      successMessage:
          'NAPAKAHUSAY! Natukoy mo ang tiyak na lokasyon ng Pilipinas (4°-21° H Latitud, 116°-127° S Longhitud) at napagtagumpayan ang lahat ng 10 misyon!',
      failureMessage:
          'Hindi iyan ang tamang tiyak na lokasyon. Ang Pilipinas ay nasa 4°-21° Hilagang Latitud at 116°-127° Silangang Longhitud.',
    ),
  ];
}
