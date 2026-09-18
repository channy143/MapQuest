import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/game_mission.dart';
import '../services/audio_manager.dart';
import '../services/coordinate_quest_storage.dart';
import '../services/map_point_storage.dart';
import 'mode_selection_screen.dart';

/// Grade 4 Araling Panlipunan geographical classifications relative to the Philippines.
enum GeoCategory {
  bisinal, // Land-based neighbors in mainland Asia
  insular, // Surrounding bodies of water and maritime/archipelagic neighbors
  pilipinas, // Philippine main islands and archipelago
}

/// Game Mode sub-mode specification.
enum GameSubMode {
  level,
  coordinates,
}

/// Category filter options for interactive map highlighting.
enum CategoryFilter {
  lahat('LAHAT', 'Lahat ng Lokasyon', Icons.public_rounded, Color(0xFF64B5F6)),
  bisinal('BISINAL', 'Karatig-Bansa sa Kalupaan', Icons.terrain_rounded, Color(0xFF00E676)),
  insular('INSULAR', 'Anyong Tubig at Kapuluan', Icons.waves_rounded, Color(0xFF00E5FF)),
  pilipinas('PILIPINAS', 'Mga Pulo ng Bansa', Icons.flag_rounded, Color(0xFFFFD54F));

  const CategoryFilter(this.label, this.description, this.icon, this.accentColor);
  final String label;
  final String description;
  final IconData icon;
  final Color accentColor;
}

/// Geographic location model representing an interactive point on the map.
class MapLocation {
  final String id;
  final String title;
  final String category;
  final GeoCategory geoCategory;
  final String description;
  final String funFact;
  final String coordinates;
  final double normalizedX;
  final double normalizedY;
  final Color color;

  const MapLocation({
    required this.id,
    required this.title,
    required this.category,
    required this.geoCategory,
    required this.description,
    required this.funFact,
    required this.coordinates,
    required this.normalizedX,
    required this.normalizedY,
    required this.color,
  });
}

/// The game screen that opens after mode selection.
///
/// Features:
/// 1. Smooth modal entrance and exit.
/// 2. 3-second fade-in of the SVG map as the permanent main map.
/// 3. Interactive pulsing circle points across the Philippines, neighboring
///    Asian nations, and surrounding bodies of water.
/// 4. Smooth camera zoom-in to any selected location upon click, paired with
///    an educational glassy location info card.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.selectedMode,
    this.gameSubMode = GameSubMode.level,
    this.enableCalibration = false,
    this.onBack,
  });

  final String selectedMode;
  final GameSubMode gameSubMode;
  final bool enableCalibration;
  final VoidCallback? onBack;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  // Modal controllers
  late final AnimationController _modalController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    reverseDuration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _slideProgress;

  // Map fade controller (3 seconds)
  late final AnimationController _mapFadeController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final Animation<double> _mapFadeAnimation;

  // Interactive zoom & camera controllers
  late final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _zoomController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Animation<Matrix4>? _matrixAnimation;

  // Pulse animation for pins
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  static final Cubic _customBezier = Cubic(0.25, 0.1, 0.25, 1.0);

  bool _isModalOpen = true;
  bool _renderMap = false;
  MapLocation? _selectedLocation;
  CategoryFilter _selectedCategory = CategoryFilter.lahat;
  bool _showMapGrid = true;

  // Coordinate Quest Mode state
  Set<String> _unlockedLocationIds = {};
  bool get _isCoordinateMode => widget.gameSubMode == GameSubMode.coordinates;

  // Calibration & Interactive Moving Mode state
  bool _isCalibrationMode = false;
  Map<String, Offset> _customOffsets = {};
  String? _draggingPinId;

  /// Returns custom calibrated position if saved/active, else original normalized coordinates.
  Offset _getLocationPosition(MapLocation loc) {
    return _customOffsets[loc.id] ?? Offset(loc.normalizedX, loc.normalizedY);
  }

  // Game Mode state
  int _currentMissionIndex = 0;
  int _score = 100;
  int _lives = 3;
  int _coins = 0;
  int _revealedCluesCount = 1;
  final Set<String> _unlockedBadgeIds = {};
  bool _isGameOver = false;
  bool _isGameCompleted = false;

  GameMission get _currentMission =>
      GameMissionRegistry.missions[_currentMissionIndex];

  // Curated Grade 4 geography locations on map.svg (1024 x 1536)
  static const List<MapLocation> _locations = [
    // --- Mga Pulo at Anyong Tubig ng Pilipinas ---
    MapLocation(
      id: 'luzon',
      title: 'Luzon',
      category: 'PANGUNAHING PULO NG PILIPINAS',
      geoCategory: GeoCategory.pilipinas,
      description:
          'Ang Luzon ang pinakamalaki at pinakamataong pulo sa Pilipinas, matatagpuan sa hilagang bahagi ng kapuluan. Dito natatagpuan ang Maynila (pambansang kabisera o capital).',
      funFact:
          'Alam mo ba? Dito matatagpuan ang Bulkang Taal na isa sa pinakamaliliit na aktibong bulkan sa buong mundo!',
      coordinates: '16.6° H Latitud, 121.3° S Longhitud',
      normalizedX: 0.615,
      normalizedY: 0.398,
      color: Color(0xFFFFCA28),
    ),
    MapLocation(
      id: 'visayas',
      title: 'Visayas',
      category: 'PANGUNAHING PULO NG PILIPINAS',
      geoCategory: GeoCategory.pilipinas,
      description:
          'Ang Visayas ang gitnang bahagi ng Pilipinas na binubuo ng magagandang isla. Napaliligiran ito ng malinaw na dagat at mayamang yamang-tubig.',
      funFact:
          'Alam mo ba? Sa Bohol makikita ang mahigit isang libong burol na nagiging kulay tsokolate kung tag-araw!',
      coordinates: '11.0° H Latitud, 123.4° S Longhitud',
      normalizedX: 0.676,
      normalizedY: 0.486,
      color: Color(0xFF26C6DA),
    ),
    MapLocation(
      id: 'mindanao',
      title: 'Mindanao',
      category: 'PANGUNAHING PULO NG PILIPINAS',
      geoCategory: GeoCategory.pilipinas,
      description:
          'Ang Mindanao sa pinakamalaking kapuluan sa Pilipinas na matatagpuan sa Timog na bahagi ng bansa.',
      funFact:
          'Alam mo ba? Tinatawag na "Kamalig ng Pilipinas" ang Mindanao dahil sa masaganang ani ng pagkain at prutas. Dito rin matatagpuan ang Philippine Eagle na pambansang ibon at isa sa pinakamalaking agila sa mundo!',
      coordinates: '7.9° H Latitud, 125.1° S Longhitud',
      normalizedX: 0.694,
      normalizedY: 0.554,
      color: Color(0xFFFFA726),
    ),
    MapLocation(
      id: 'palawan',
      title: 'Palawan',
      category: 'PULO SA KANLURANG PILIPINAS',
      geoCategory: GeoCategory.pilipinas,
      description:
          'Ang Palawan ay isang mahabang isla sa kanluran ng Pilipinas. Tanyag ito sa malinis na dagat at luntiang kagubatan.',
      funFact:
          'Alam mo ba? May mahabang ilog sa Palawan na dumadaloy sa loob ng isang madilim na kuweba!',
      coordinates: '9.8° H Latitud, 118.7° S Longhitud',
      normalizedX: 0.540,
      normalizedY: 0.510,
      color: Color(0xFF66BB6A),
    ),
    MapLocation(
      id: 'sulu_sea',
      title: 'Dagat Sulu',
      category: 'ANYONG TUBIG SA TIMOG-KANLURAN',
      geoCategory: GeoCategory.insular,
      description:
          'Ang Dagat Sulu ay isang malaking anyong tubig sa timog-kanluran ng bansa. Matatagpuan ito sa pagitan ng Palawan, Visayas, at Mindanao.',
      funFact:
          'Alam mo ba? Sa gitna ng dagat na ito matatagpuan ang Tubbataha Reef na tirahan ng napakaraming makukulay na isda at korales!',
      coordinates: '8.0° H Latitud, 120.0° S Longhitud',
      normalizedX: 0.436,
      normalizedY: 0.567,
      color: Color(0xFF00ACC1),
    ),

    // --- Mga Karatig-Bansa sa Asya at Karatig-Kontinente ---
    MapLocation(
      id: 'taiwan',
      title: 'Taiwan',
      category: 'KARATIG-BANSA SA HILAGA (BISINAL)',
      geoCategory: GeoCategory.bisinal,
      description:
          'Ang Taiwan ay ang pinakamalapit na karatig-bansa na matatagpuan sa Hilaga ng Pilipinas.',
      funFact:
          'Alam mo ba na tumutugtog ng classical music ang mga truck ng basura para malaman ng mga tao na oras na para magtapon ng basura. Ang hugis ng Taiwan sa mapa ay parang isang kamote!',
      coordinates: '23.7° H Latitud, 121.0° S Longhitud',
      normalizedX: 0.643,
      normalizedY: 0.241,
      color: Color(0xFFAB47BC),
    ),
    MapLocation(
      id: 'china',
      title: 'China',
      category: 'KARATIG-BANSA SA HILAGANG-KANLURAN (BISINAL)',
      geoCategory: GeoCategory.bisinal,
      description:
          'Ang China ay isang napakalaking bansa sa hilagang-kanluran ng Pilipinas na may pinakamalaking populasyon sa Asya.',
      funFact:
          'Alam mo ba na mga Giant Panda ay matatagpuan lamang sa kagubatan ng China sa ligaw na kalikasan (wild). Lahat ng mga panda sa iba\'t ibang bansa ay hiram lamang mula sa pamahalaan ng China upang alagaan at protektahan. Sobra silang mahilig kumain na kaya nilang umubos ng bamboo sa loob ng 12 oras kada araw.',
      coordinates: '35.9° H Latitud, 104.2° S Longhitud',
      normalizedX: 0.340,
      normalizedY: 0.160,
      color: Color(0xFFFF7043),
    ),
    MapLocation(
      id: 'japan',
      title: 'Japan',
      category: 'KARATIG-BANSA SA HILAGANG-SILANGAN (INSULAR)',
      geoCategory: GeoCategory.insular,
      description:
          'Ang Japan ay matatagpuan sa hilagang-silangan ng Pilipinas, sa rehiyon ng Silangang Asya.',
      funFact:
          'Alam mo ba na ang Japan ay kilala bilang "Land of the Rising Sun". Kung titingnan mo ang kanilang bandila, ang pulang bilog sa gitna ay sumisimbolo sa araw.',
      coordinates: '36.2° H Latitud, 138.3° S Longhitud',
      normalizedX: 0.853,
      normalizedY: 0.130,
      color: Color(0xFFEC407A),
    ),
    MapLocation(
      id: 'vietnam',
      title: 'Vietnam',
      category: 'KARATIG-BANSA SA KANLURAN (BISINAL)',
      geoCategory: GeoCategory.bisinal,
      description:
          'Ang Vietnam ay matatagpuan sa Kanluran ng Pilipinas. Hugis titik “S” ang mapa nito na may mahabang baybaying nakaharap sa ating kapuluan.',
      funFact:
          'Alam mo ba? Sa Vietnam matatagpuan ang pinakamalaking kuweba sa buong mundo na may sariling gubat sa loob!',
      coordinates: '14.1° H Latitud, 108.3° S Longhitud',
      normalizedX: 0.286,
      normalizedY: 0.325,
      color: Color(0xFFEF5350),
    ),
    MapLocation(
      id: 'thailand',
      title: 'Thailand',
      category: 'KARATIG-BANSA SA KANLURAN (BISINAL)',
      geoCategory: GeoCategory.bisinal,
      description:
          'Ang Thailand ay matatagpuan sa Kanluran ng Pilipinas. Pinapalibutan ito ng Vietnam, Cambodia, Laos, at Myanmar. Sentro ito ng agrikultura at Budismo (Buddhism) na relihiyon.',
      funFact:
          'Alam mo ba na ang ibig sabihin ng salitang Thailand ay "Land of the Free" o Lupain ng mga Malaya. Sa lahat ng mga bansa sa Timog-Silangang Asya (tulad ng Pilipinas na sinakop ng Espanya at Amerika), ang Thailand lamang ang tanging bansa na hindi kailanman sinakop ng mga bansa mula sa Europa!',
      coordinates: '15.9° H Latitud, 101.0° S Longhitud',
      normalizedX: 0.159,
      normalizedY: 0.384,
      color: Color(0xFFFB8C00),
    ),
    MapLocation(
      id: 'cambodia',
      title: 'Cambodia',
      category: 'KARATIG-BANSA SA KANLURAN (BISINAL)',
      geoCategory: GeoCategory.bisinal,
      description:
          'Ang Cambodia ay matatagpuan sa Timog-Silangang Asya na diretsong Kanluran ng Pilipinas. Napapaligiran ito ng Thailand, Laos, at Vietnam.',
      funFact:
          'Alam mo ba na ang watawat ng Cambodia ang tanging bandila sa buong mundo na may larawan ng isang gusali. Ang gusaling ito ay ang sikat na templong Angkor Wat, na kinikilala bilang pinakamalaking panrelihiyong monumento o templo sa buong mundo.',
      coordinates: '12.6° H Latitud, 105.0° S Longhitud',
      normalizedX: 0.244,
      normalizedY: 0.445,
      color: Color(0xFF8E24AA),
    ),
    MapLocation(
      id: 'myanmar',
      title: 'Myanmar',
      category: 'KARATIG-BANSA SA KANLURAN (BISINAL)',
      geoCategory: GeoCategory.bisinal,
      description:
          'Ang Myanmar ay isang bansa sa kanluran ng Asya na kapitbahay ng Thailand. Kilala ito sa mga gintong templo at luntiang kabundukan.',
      funFact:
          'Alam mo ba? May libu-libong sinaunang templo na kulay ginto sa kapatagan ng Myanmar!',
      coordinates: '21.9° H Latitud, 95.9° S Longhitud',
      normalizedX: 0.095,
      normalizedY: 0.275,
      color: Color(0xFFFFB300),
    ),
    MapLocation(
      id: 'malaysia',
      title: 'Malaysia',
      category: 'KARATIG-BANSA SA TIMOG-KANLURAN (BISINAL)',
      geoCategory: GeoCategory.bisinal,
      description:
          'Ang Malaysia ay matatagpuan sa Timog-Kanluran ng Pilipinas. Nahahati ang bansang ito sa dalawang bahagi: ang Peninsular Malaysia (sa Tangway ng Malaya) at ang East Malaysia (sa isla ng Borneo).',
      funFact:
          'Alam mo ba na sa Malaysia matatagpuan ang Rafflesia, ang pinakamalaking bulaklak sa buong mundo. Kaya nitong lumaki nang hanggang tatlong talampakan (3 feet) at kasingbigat ng isang maliit na aso! Ang nakakatuwa (at medyo nakakadiri), mabaho ang amoy nito na parang bulok na karne, kaya tinatawag din itong "corpse flower".',
      coordinates: '4.2° H Latitud, 102.0° S Longhitud',
      normalizedX: 0.445,
      normalizedY: 0.635,
      color: Color(0xFF26A69A),
    ),
    MapLocation(
      id: 'singapore',
      title: 'Singapore',
      category: 'KARATIG-BANSA SA TIMOG-KANLURAN (BISINAL)',
      geoCategory: GeoCategory.bisinal,
      description:
          'Ang Singapore ay isang maunlad na pulong-bansa sa timog ng Tangway ng Malaya. Kilala ito bilang isa sa pinakamalinis at pinakaligtas na bansa sa buong mundo.',
      funFact:
          'Alam mo ba na tinatawag na "Lion City" ang Singapore? Ang sikat na estatwa ng Merlion dito ay may ulo ng leon at katawan ng isda!',
      coordinates: '1.3° H Latitud, 103.8° S Longhitud',
      normalizedX: 0.246,
      normalizedY: 0.635,
      color: Color(0xFFE91E63),
    ),
    MapLocation(
      id: 'brunei',
      title: 'Brunei',
      category: 'KARATIG-BANSA SA TIMOG-KANLURAN (BISINAL)',
      geoCategory: GeoCategory.bisinal,
      description:
          'Ang Brunei ay matatagpuan sa Timog-Kanluran ng Pilipinas. Ito ay matatagpuan sa hilagang baybayin ng isla ng Borneo. Napapaligiran ito ng Malaysia at ng South China Sea.',
      funFact:
          'Alam mo ba na ang Brunei ay isa sa pinakamayamang bansa sa Asya dahil sa langis? Libre ang edukasyon at pagpapagamot para sa lahat ng kanilang mamamayan!',
      coordinates: '4.5° H Latitud, 114.7° S Longhitud',
      normalizedX: 0.495,
      normalizedY: 0.588,
      color: Color(0xFFFDD835),
    ),
    MapLocation(
      id: 'indonesia',
      title: 'Indonesia',
      category: 'KARATIG-BANSA SA TIMOG (INSULAR)',
      geoCategory: GeoCategory.insular,
      description:
          'Ang Indonesia ay matatagpuan sa Timog ng Pilipinas. Ito ang pinakamalapit na karatig-bansa mula sa Mindanao. Ito ang pinakamalaking kapuluang bansa sa buong daigdig.',
      funFact:
          'Alam mo ba? Dito lamang nakatira ang Komodo Dragon na pinakamalaking buhay na bayawak sa mundo!',
      coordinates: '0.8° T Latitud, 113.9° S Longhitud',
      normalizedX: 0.463,
      normalizedY: 0.753,
      color: Color(0xFF00897B),
    ),
    MapLocation(
      id: 'palau',
      title: 'Palau',
      category: 'KARATIG-BANSA SA SILANGAN (INSULAR)',
      geoCategory: GeoCategory.insular,
      description:
          'Ang Palau ay matatagpuan sa Timog-Silangan (southeast) o silangan (east) ng Pilipinas. Matatagpuan ito sa direksyong silangan ng Mindanao at timog-silangan ng Visayas. Ito ay nasa rehiyon ng Micronesia sa Karagatang Pasipiko. Ang pinakamalapit na pangunahing isla ng Pilipinas dito ay ang Mindanao.',
      funFact:
          'Alam mo ba na mayroong sikat na lawa sa Palau kung saan milyun-milyong kulay-rosas at gintong dikya (jellyfish) ang lumalangoy. Hindi sila nakakatusok o nakalalason, kaya pwedeng-pwede silang makasabay sa paglangoy ng mga tao! Sa buong bansa rin ng Palau, walang kahit isang traffic light.',
      coordinates: '7.5° H Latitud, 134.6° S Longhitud',
      normalizedX: 0.840,
      normalizedY: 0.585,
      color: Color(0xFF00E5FF),
    ),
    MapLocation(
      id: 'guam',
      title: 'Guam',
      category: 'TERITORYO SA SILANGAN (INSULAR)',
      geoCategory: GeoCategory.insular,
      description:
          'Ang Guam ay matatagpuan sa Silangan ng Pilipinas. Ito ay teritoryo ng Estados Unidos sa Kanlurang Pasipiko na maituturing na "malapit na kamag-anak" ng Pilipinas dahil sa ating magkatulad na pinasasamang kasaysayan, lahi, at kultura.',
      funFact:
          'Alam mo ba na napakaliit ng Guam? Ang haba nito ay parang distansya lang mula Cebu City hanggang Carcar City kaya madali itong ikutin sa loob ng isang araw. Ang mga katutubong tao rito ay tinatawag na Chamorro.',
      coordinates: '13.4° H Latitud, 144.8° S Longhitud',
      normalizedX: 0.948,
      normalizedY: 0.470,
      color: Color(0xFF26A69A),
    ),
    MapLocation(
      id: 'australia',
      title: 'Australia',
      category: 'KARATIG-KONTINENTE SA TIMOG (INSULAR)',
      geoCategory: GeoCategory.insular,
      description:
          'Ang Australia ay isang malaking bansa at kontinente sa malayong timog ng Pilipinas. Napaliligiran ito ng malawak na karagatan.',
      funFact:
          'Alam mo ba? Dito lamang makikita ang mga Kangaroo at Koala na may bulsa sa kanilang tiyan para sa mga sanggol!',
      coordinates: '25.3° T Latitud, 133.8° S Longhitud',
      normalizedX: 0.239,
      normalizedY: 0.925,
      color: Color(0xFFE65100),
    ),

    // --- Mga Nakapaligid na Anyong Tubig ---
    MapLocation(
      id: 'pacific_ocean',
      title: 'Karagatang Pasipiko',
      category: 'ANYONG TUBIG SA SILANGAN (INSULAR)',
      geoCategory: GeoCategory.insular,
      description:
          'Ang Karagatang Pasipiko ang pinakamalaking karagatan sa buong mundo. Matatagpuan ito sa buong silangang bahagi ng Pilipinas.',
      funFact:
          'Alam mo ba? Dito matatagpuan ang pinakamalalim na bahagi ng dagat sa mundo kung saan kasya ang buong Bundok Everest!',
      coordinates: '20.0° H Latitud, 135.0° S Longhitud',
      normalizedX: 0.845,
      normalizedY: 0.350,
      color: Color(0xFF42A5F5),
    ),
    MapLocation(
      id: 'west_ph_sea',
      title: 'Dagat Kanlurang Pilipinas',
      category: 'ANYONG TUBIG SA KANLURAN (INSULAR)',
      geoCategory: GeoCategory.insular,
      description:
          'Ito ang dagat na nasa kanlurang bahagi ng Pilipinas. Mahalaga itong daanan ng mga barko at pinagkukunan ng maraming isda.',
      funFact:
          'Alam mo ba? Napakaraming barko mula sa iba\'t ibang bansa ang naglalayag dito araw-araw!',
      coordinates: '14.0° H Latitud, 116.0° S Longhitud',
      normalizedX: 0.460,
      normalizedY: 0.430,
      color: Color(0xFF29B6F6),
    ),
    MapLocation(
      id: 'celebes_sea',
      title: 'Dagat Celebes',
      category: 'ANYONG TUBIG SA TIMOG (INSULAR)',
      geoCategory: GeoCategory.insular,
      description:
          'Ang Dagat Celebes ay isang malalim na dagat sa timog ng Mindanao. Naghihiwalay ito sa Pilipinas at sa bansang Indonesia.',
      funFact:
          'Alam mo ba? May mga pambihirang isda sa ilalim ng dagat na ito na may sariling natural na ilaw sa katawan!',
      coordinates: '4.0° H Latitud, 122.0° S Longhitud',
      normalizedX: 0.709,
      normalizedY: 0.643,
      color: Color(0xFF5C6BC0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Enforce full-screen immersive mode to hide Android status/notification bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _slideProgress = CurvedAnimation(
      parent: _modalController,
      curve: _customBezier,
      reverseCurve: Curves.easeInOutCubic,
    );

    _mapFadeAnimation = CurvedAnimation(
      parent: _mapFadeController,
      curve: Curves.easeInOut,
    );

    _zoomController.addListener(() {
      if (_matrixAnimation != null) {
        _transformationController.value = _matrixAnimation!.value;
      }
    });

    // Step 1: Start modal entrance animation after initial frame paints
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _modalController.forward();
      }
    });

    // Load saved unlocked locations in Coordinate Quest mode
    if (_isCoordinateMode) {
      CoordinateQuestStorage.getUnlockedLocations().then((ids) {
        if (mounted) {
          setState(() {
            _unlockedLocationIds = ids;
          });
        }
      });
    }

    // Load saved custom coordinates for map pins from persistent storage
    MapPointStorage.loadCustomPositions().then((loaded) {
      if (mounted && loaded.isNotEmpty) {
        setState(() {
          _customOffsets = loaded;
        });
      }
    });

    // Step 2: Defer mounting and fading in SVG map to keep initial frame silky smooth
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _renderMap = true;
        });
        _mapFadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _modalController.dispose();
    _mapFadeController.dispose();
    _zoomController.dispose();
    _pulseController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _dismissModal() {
    if (!_isModalOpen) return;
    setState(() {
      _isModalOpen = false;
    });

    // Plays close animation: slides from current position to bottom outside of screen
    _modalController.reverse().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  static const double _canvasWidth = 1024.0;
  static const double _canvasHeight = 1536.0;

  Matrix4 _getBaseMatrix(double viewportWidth, double viewportHeight) {
    final scaleX = viewportWidth / _canvasWidth;
    final scaleY = viewportHeight / _canvasHeight;
    // On portrait screens (scaleX < scaleY, such as mobile phones), scale by scaleY so
    // the map fills the vertical height of the screen naturally without excessive letterbox
    // ocean borders that make it feel overly zoomed out.
    // On landscape screens, fit to height/width smoothly.
    final baseScale = (scaleX < scaleY) ? scaleY : math.min(scaleX, scaleY);
    final tx = (viewportWidth - _canvasWidth * baseScale) / 2;
    final ty = (viewportHeight - _canvasHeight * baseScale) / 2;
    return _createMatrix(scale: baseScale, tx: tx, ty: ty);
  }

  void _zoomToLocation(
    MapLocation location,
    double viewportWidth,
    double viewportHeight,
  ) {
    setState(() {
      _selectedLocation = location;
    });

    final scaleX = viewportWidth / _canvasWidth;
    final scaleY = viewportHeight / _canvasHeight;
    final baseScale = (scaleX < scaleY) ? scaleY : math.min(scaleX, scaleY);
    final targetScale = (baseScale * 2.5).clamp(1.2, 5.0);

    final pos = _getLocationPosition(location);
    final pinX = pos.dx * _canvasWidth;
    final pinY = pos.dy * _canvasHeight;

    // Offset camera matrix so target point lands in the UPPER portion of the screen
    // (around 28% from the top on mobile) instead of dead-center. This keeps the location and its
    // territory prominently visible above the educational info modal at the bottom.
    final isCompact = viewportWidth < 600;
    final targetScreenY =
        isCompact ? viewportHeight * 0.28 : viewportHeight * 0.32;

    final newX = (viewportWidth / 2) - (pinX * targetScale);
    final newY = targetScreenY - (pinY * targetScale);

    _animateToMatrix(_createMatrix(scale: targetScale, tx: newX, ty: newY));
  }

  void _enterCalibrationMode() {
    AudioManager.instance.playClick();
    setState(() {
      _isCalibrationMode = true;
      _selectedLocation = null;
    });
  }

  Future<void> _acceptAndLockPositions() async {
    AudioManager.instance.playClick();
    await MapPointStorage.saveCustomPositions(_customOffsets);
    if (!mounted) return;
    setState(() {
      _isCalibrationMode = false;
      _draggingPinId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nai-save at naka-lock na ang mga posisyon ng mga punto sa mapa!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0B1E28),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _resetPositionsToDefault() async {
    AudioManager.instance.playClick();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2534),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF26C6DA), width: 1.5),
        ),
        title: const Text(
          'I-reset ang mga Punto?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Ibabalik ba ang lahat ng mga punto sa kanilang orihinal (default) na posisyon sa mapa?',
          style: TextStyle(color: Color(0xFFB0BEC5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('HINDI', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OO, I-RESET'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await MapPointStorage.clearCustomPositions();
      if (!mounted) return;
      setState(() {
        _customOffsets.clear();
      });
    }
  }

  Future<void> _cancelCalibration() async {
    AudioManager.instance.playClick();
    final saved = await MapPointStorage.loadCustomPositions();
    if (!mounted) return;
    setState(() {
      _customOffsets = saved;
      _isCalibrationMode = false;
      _draggingPinId = null;
    });
  }

  void _showCopyCodeDialog() {
    AudioManager.instance.playClick();
    final currentMap = <String, Offset>{};
    for (final loc in _locations) {
      currentMap[loc.id] = _getLocationPosition(loc);
    }
    final code = MapPointStorage.generateDartCode(currentMap);
    MapPointStorage.copyToClipboard(code);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2534),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.code_rounded, color: Color(0xFFFFD54F)),
            SizedBox(width: 8),
            Text(
              'Kodigo ng mga Punto',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Na-kopya na sa clipboard ang kodigo! Maaari mo itong gamitin sa pag-update ng coordinates:',
                style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF81D4FA),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.check_rounded),
            label: const Text('OK'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _handlePinDrag(String locId, DragUpdateDetails details) {
    final current = _getLocationPosition(
      _locations.firstWhere((l) => l.id == locId),
    );
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final effectiveScale = currentScale > 0 ? currentScale : 1.0;
    final dxNorm = (details.delta.dx / effectiveScale) / _canvasWidth;
    final dyNorm = (details.delta.dy / effectiveScale) / _canvasHeight;

    final newX = (current.dx + dxNorm).clamp(0.01, 0.99);
    final newY = (current.dy + dyNorm).clamp(0.01, 0.99);

    setState(() {
      _customOffsets[locId] = Offset(newX, newY);
    });
  }

  void _handlePinDelta(String locId, Offset delta) {
    final current = _getLocationPosition(
      _locations.firstWhere((l) => l.id == locId),
    );
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final effectiveScale = currentScale > 0 ? currentScale : 1.0;
    final dxNorm = (delta.dx / effectiveScale) / _canvasWidth;
    final dyNorm = (delta.dy / effectiveScale) / _canvasHeight;

    final newX = (current.dx + dxNorm).clamp(0.01, 0.99);
    final newY = (current.dy + dyNorm).clamp(0.01, 0.99);

    setState(() {
      _customOffsets[locId] = Offset(newX, newY);
    });
  }

  Matrix4 _createMatrix({
    required double scale,
    required double tx,
    required double ty,
  }) {
    final m = Matrix4.identity();
    m.storage[0] = scale;
    m.storage[5] = scale;
    m.storage[12] = tx;
    m.storage[13] = ty;
    return m;
  }

  void _resetZoom(double viewportWidth, double viewportHeight) {
    setState(() {
      _selectedLocation = null;
    });
    _animateToMatrix(_getBaseMatrix(viewportWidth, viewportHeight));
  }

  void _handleInteractionEnd(
    ScaleEndDetails details,
    double viewportWidth,
    double viewportHeight,
  ) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final baseMatrix = _getBaseMatrix(viewportWidth, viewportHeight);
    final baseScale = baseMatrix.storage[0];

    // Limit zoom out: when the user pinches out past the fitted screen scale and releases,
    // smoothly animate back to the fitted map view!
    if (currentScale < baseScale * 0.98) {
      _animateToMatrix(baseMatrix);
    }
  }

  void _animateToMatrix(Matrix4 target) {
    _matrixAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _zoomController.forward(from: 0.0);
  }

  void _goBackToModeSelection() {
    if (widget.onBack != null) {
      try {
        widget.onBack!();
        return;
      } catch (_) {}
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ModeSelectionScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  bool get _isLearningMode =>
      !widget.selectedMode.toLowerCase().contains('laro') &&
      !widget.selectedMode.toLowerCase().contains('game');

  bool _isPinVisible(MapLocation loc) {
    if (!_isCoordinateMode) return true;
    return _unlockedLocationIds.contains(loc.id);
  }

  void _onPinTapped(
    MapLocation location,
    double viewportWidth,
    double viewportHeight,
  ) {
    AudioManager.instance.playClick();
    if (_isLearningMode || _isCoordinateMode) {
      _zoomToLocation(location, viewportWidth, viewportHeight);
      return;
    }

    if (_isGameOver || _isGameCompleted) return;

    final mission = _currentMission;
    _zoomToLocation(location, viewportWidth, viewportHeight);

    if (mission.type == MissionType.tapMap ||
        mission.type == MissionType.cluesMap) {
      if (mission.isTargetLocation(location.id)) {
        _handleCorrectAnswer(viewportWidth, viewportHeight);
      } else {
        _handleWrongAnswer(mission.failureMessage, viewportWidth, viewportHeight);
      }
    }
  }

  void _handleCoordinateUnlock(
    MapLocation location,
    double viewportWidth,
    double viewportHeight,
  ) {
    setState(() {
      _unlockedLocationIds.add(location.id);
      _selectedLocation = location;
    });
    CoordinateQuestStorage.saveUnlockedLocation(location.id);
    _zoomToLocation(location, viewportWidth, viewportHeight);
  }

  void _handleResetCoordinateProgress(
    double viewportWidth,
    double viewportHeight,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF07123A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.amber, width: 1.4),
        ),
        title: const Text(
          'Simulan Muli ang Paghahanap?',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Mabubura ang iyong mga nabuksang punto sa mapa. Nais mo bang magsimula muli mula sa simula?',
          style: TextStyle(color: Colors.white, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.of(ctx).pop();
            },
            child: const Text('Kanselahin', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: const Color(0xFF07123A),
            ),
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.of(ctx).pop();
              CoordinateQuestStorage.resetProgress();
              setState(() {
                _unlockedLocationIds.clear();
                _selectedLocation = null;
              });
              _resetZoom(viewportWidth, viewportHeight);
            },
            child: const Text('Oo, Simulan Muli',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleChoiceAnswer(
    int choiceIndex,
    double viewportWidth,
    double viewportHeight,
  ) {
    if (_isGameOver || _isGameCompleted) return;

    final mission = _currentMission;
    if (mission.isCorrectChoice(choiceIndex)) {
      _handleCorrectAnswer(viewportWidth, viewportHeight);
    } else {
      _handleWrongAnswer(mission.failureMessage, viewportWidth, viewportHeight);
    }
  }

  void _handleCorrectAnswer(
    double viewportWidth,
    double viewportHeight,
  ) {
    AudioManager.instance.playCorrect();
    final mission = _currentMission;
    final pointsWon = mission.pointsReward;
    final coinsWon = mission.coinsReward;

    setState(() {
      _score += pointsWon;
      _coins += coinsWon;
    });

    final List<GameBadge> newlyUnlockedBadges = [];
    void checkBadge(String id) {
      if (!_unlockedBadgeIds.contains(id)) {
        _unlockedBadgeIds.add(id);
        final badge = GameMissionRegistry.availableBadges
            .firstWhere((b) => b.id == id);
        newlyUnlockedBadges.add(badge);
      }
    }

    if (mission.missionNumber == 1) checkBadge('first_discovery');
    if (mission.missionNumber == 4 || mission.missionNumber == 7) {
      checkBadge('direction_master');
    }
    if (mission.missionNumber == 6 || mission.missionNumber == 9) {
      checkBadge('map_detective');
    }
    if (mission.missionNumber == 8) checkBadge('asia_explorer');
    if (mission.missionNumber == 10) {
      checkBadge('asia_explorer');
      checkBadge('ultimate_explorer');
    }

    final isLastMission =
        _currentMissionIndex >= GameMissionRegistry.missions.length - 1;

    if (isLastMission) {
      setState(() {
        _isGameCompleted = true;
      });
      _showGameCompleteDialog(viewportWidth, viewportHeight);
    } else {
      _showMissionSuccessDialog(
        mission: mission,
        pointsWon: pointsWon,
        coinsWon: coinsWon,
        newBadges: newlyUnlockedBadges,
        onNext: () {
          Navigator.of(context, rootNavigator: true).pop();
          setState(() {
            _currentMissionIndex++;
            _revealedCluesCount = 1;
            _selectedLocation = null;
          });
          _resetZoom(viewportWidth, viewportHeight);
        },
      );
    }
  }

  void _handleWrongAnswer(
    String failureMessage,
    double viewportWidth,
    double viewportHeight,
  ) {
    AudioManager.instance.playWrong();
    setState(() {
      _lives = math.max(0, _lives - 1);
    });

    if (_lives <= 0) {
      setState(() {
        _isGameOver = true;
      });
      _showGameOverDialog(viewportWidth, viewportHeight);
    } else {
      _showFailureDialog(failureMessage);
    }
  }

  void _restartGame(double viewportWidth, double viewportHeight) {
    setState(() {
      _currentMissionIndex = 0;
      _score = 100;
      _lives = 3;
      _coins = 0;
      _revealedCluesCount = 1;
      _unlockedBadgeIds.clear();
      _isGameOver = false;
      _isGameCompleted = false;
      _selectedLocation = null;
    });
    _resetZoom(viewportWidth, viewportHeight);
  }

  void _showMissionSuccessDialog({
    required GameMission mission,
    required int pointsWon,
    required int coinsWon,
    required List<GameBadge> newBadges,
    required VoidCallback onNext,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _MissionFeedbackDialog(
        isSuccess: true,
        title: mission.missionNumber == 9
            ? '🎉 MYSTERY SOLVED!'
            : (mission.missionNumber == 3 ? '🌊 MAGALING!' : '⭐ TAMANG SAGOT!'),
        message: mission.successMessage,
        pointsReward: pointsWon,
        coinsReward: coinsWon,
        newBadges: newBadges,
        buttonText: 'SUSUNOD NA MISYON',
        onButtonPressed: onNext,
      ),
    );
  }

  void _showFailureDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _MissionFeedbackDialog(
        isSuccess: false,
        title: 'Hindi Iyan Ang Tamang Sagot',
        message: message,
        remainingLives: _lives,
        buttonText: 'SUBUKAN MULI',
        onButtonPressed: () => Navigator.of(dialogCtx).pop(),
      ),
    );
  }

  void _showGameOverDialog(double viewportWidth, double viewportHeight) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _GameOverDialog(
        score: _score,
        onRetry: () {
          Navigator.of(dialogCtx).pop();
          _restartGame(viewportWidth, viewportHeight);
        },
        onExitToMenu: () {
          Navigator.of(dialogCtx).pop();
          _goBackToModeSelection();
        },
      ),
    );
  }

  void _showGameCompleteDialog(double viewportWidth, double viewportHeight) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _MissionCompleteDialog(
        score: _score,
        coins: _coins,
        completedMissions: GameMissionRegistry.missions.length,
        totalMissions: GameMissionRegistry.missions.length,
        onReplay: () {
          Navigator.of(dialogCtx).pop();
          _restartGame(viewportWidth, viewportHeight);
        },
        onViewMap: () {
          Navigator.of(dialogCtx).pop();
          _resetZoom(viewportWidth, viewportHeight);
        },
        onExitToMenu: () {
          Navigator.of(dialogCtx).pop();
          _goBackToModeSelection();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackToModeSelection();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0373C0),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = constraints.maxWidth;
            final viewportHeight = constraints.maxHeight;

            final baseMatrix = _getBaseMatrix(viewportWidth, viewportHeight);
            final baseScale = baseMatrix.storage[0];

            if (_transformationController.value.isIdentity()) {
              _transformationController.value = baseMatrix;
            }

            // Allow user to pinch-zoom out slightly beyond screen fit (down to 80%),
            // with boundary margins allowing that extra range before snapping back.
            final allowedMinScale = baseScale * 0.80;
            final extraMarginW =
                math.max(0.0, (viewportWidth / allowedMinScale - _canvasWidth) / 2);
            final extraMarginH =
                math.max(0.0, (viewportHeight / allowedMinScale - _canvasHeight) / 2);

            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                // 1. Interactive Map with Circle Points
                if (_renderMap)
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _mapFadeAnimation,
                      child: InteractiveViewer(
                        constrained: false,
                        transformationController: _transformationController,
                        panEnabled: !_isCalibrationMode || _draggingPinId == null,
                        scaleEnabled: true,
                        trackpadScrollCausesScale: true,
                        minScale: allowedMinScale,
                        maxScale: baseScale * 5.0,
                        boundaryMargin: EdgeInsets.symmetric(
                          horizontal: extraMarginW,
                          vertical: extraMarginH,
                        ),
                        clipBehavior: Clip.none,
                        onInteractionEnd: (details) => _handleInteractionEnd(
                          details,
                          viewportWidth,
                          viewportHeight,
                        ),
                        child: SizedBox(
                          width: _canvasWidth,
                          height: _canvasHeight,
                          child: Stack(
                            children: [
                              // Full SVG Map
                              Positioned.fill(
                                child: SvgPicture.asset(
                                  'assets/images/map.svg',
                                  fit: BoxFit.fill,
                                  alignment: Alignment.center,
                                ),
                              ),

                              // Soft Edge Fade-Out Overlay (dissolves static rectangular borders)
                              const Positioned.fill(
                                child: _MapEdgeFadeOverlay(),
                              ),

                              // Longitude & Latitude Coordinate Grid Layer (Educational Grid)
                              if (_showMapGrid)
                                const Positioned.fill(
                                  child: IgnorePointer(
                                    child: _MapCoordinateGridLayer(),
                                  ),
                                ),

                              // Interactive Pulsing Circle Points
                              for (final loc in _locations)
                                if (_isPinVisible(loc))
                                  Builder(
                                    builder: (context) {
                                      final pos = _getLocationPosition(loc);
                                      return Positioned(
                                        left: pos.dx * _canvasWidth - 28,
                                        top: pos.dy * _canvasHeight - 28,
                                        child: MapPointPin(
                                          key: ValueKey('pin_${loc.id}'),
                                          location: loc,
                                          currentOffset: pos,
                                          isCalibrationMode: _isCalibrationMode,
                                          isDragging: _draggingPinId == loc.id,
                                          isSelected: _selectedLocation?.id == loc.id,
                                          pulseController: _pulseController,
                                          activeCategory: _selectedCategory,
                                          onTap: () {
                                            if (!_isCalibrationMode) {
                                              _onPinTapped(
                                                loc,
                                                viewportWidth,
                                                viewportHeight,
                                              );
                                            }
                                          },
                                          onPointerDown: _isCalibrationMode
                                              ? () => setState(() => _draggingPinId = loc.id)
                                              : null,
                                          onPointerMove: _isCalibrationMode
                                              ? (delta) => _handlePinDelta(loc.id, delta)
                                              : null,
                                          onPointerUp: _isCalibrationMode
                                              ? () => setState(() => _draggingPinId = null)
                                              : null,
                                          onPanStart: _isCalibrationMode
                                              ? (_) => setState(() => _draggingPinId = loc.id)
                                              : null,
                                          onPanUpdate: _isCalibrationMode
                                              ? (details) => _handlePinDrag(loc.id, details)
                                              : null,
                                          onPanEnd: _isCalibrationMode
                                              ? (_) => setState(() => _draggingPinId = null)
                                              : null,
                                        ),
                                      );
                                    },
                                  ),

                              // In-Map Drifting Clouds with soft shadows and pin-proximity 50% transparency
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _MapDriftingCloudsLayer(
                                    canvasWidth: _canvasWidth,
                                    canvasHeight: _canvasHeight,
                                    pinPositions: [
                                      for (final loc in _locations)
                                        if (_isPinVisible(loc))
                                          Offset(
                                            _getLocationPosition(loc).dx * _canvasWidth,
                                            _getLocationPosition(loc).dy * _canvasHeight,
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2. Softened Vignette Overlay (fades in alongside map)
                if (_renderMap)
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _mapFadeAnimation,
                      child: const _DarkVignetteOverlay(),
                    ),
                  ),

                // Screen-fixed Coordinate Badges Overlay (Latitude & Longitude edge numbers)
                if (_renderMap && _showMapGrid && !_isModalOpen)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _ScreenCoordinateBadgesOverlay(
                        transformationController: _transformationController,
                        viewportWidth: viewportWidth,
                        viewportHeight: viewportHeight,
                        hasBottomCard: _selectedLocation != null,
                        isLevelMode: !_isLearningMode && !_isCoordinateMode,
                      ),
                    ),
                  ),

                // 3. Top-left Back Button (hidden in calibration mode)
                if (!_isCalibrationMode)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _BackButton(onTap: _goBackToModeSelection),
                  ),

                // 4. Top-center Header: Category Filter (Learning Mode) or Game HUD / Coordinate HUD
                if (_renderMap && !_isModalOpen && !_isCalibrationMode)
                  Positioned(
                    top: 16,
                    left: isCompact ? 56 : 72,
                    right: isCompact ? 56 : 72,
                    child: Center(
                      child: _isLearningMode
                          ? _CategoryFilterButton(
                              key: const ValueKey('category_filter_button'),
                              selectedCategory: _selectedCategory,
                              isCompact: isCompact,
                              onCategoryChanged: (cat) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                            )
                          : _isCoordinateMode
                              ? _CoordinateQuestHudHeader(
                                  key: const ValueKey('coordinate_hud_header'),
                                  unlockedCount: _unlockedLocationIds.length,
                                  totalCount: _locations.length,
                                  isCompact: isCompact,
                                  onReset: () => _handleResetCoordinateProgress(
                                      viewportWidth, viewportHeight),
                                )
                              : _GameHudHeader(
                                  key: const ValueKey('game_hud_header'),
                                  missionNumber: _currentMissionIndex + 1,
                                  totalMissions: GameMissionRegistry.missions.length,
                                  score: _score,
                                  lives: _lives,
                                  coins: _coins,
                                  isCompact: isCompact,
                                ),
                    ),
                  ),

                // Top-right Grid Toggle Button (Latitud at Longhitud)
                if (_renderMap && !_isModalOpen && !_isCalibrationMode)
                  Positioned(
                    top: 16,
                    right: widget.enableCalibration ? (isCompact ? 60 : 70) : 16,
                    child: _GridToggleButton(
                      isGridOn: _showMapGrid,
                      isCompact: isCompact,
                      onTap: () {
                        setState(() {
                          _showMapGrid = !_showMapGrid;
                        });
                      },
                    ),
                  ),

                // Top-right Calibrate Points Button (hidden by default unless enableCalibration is true)
                if (widget.enableCalibration && _renderMap && !_isModalOpen && !_isCalibrationMode)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _CalibratePointsButton(
                      isCompact: isCompact,
                      onTap: _enterCalibrationMode,
                    ),
                  ),

                // Full-width Calibration Toolbar (shown when in calibration mode)
                if (widget.enableCalibration && _renderMap && !_isModalOpen && _isCalibrationMode)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _CalibrationControlBar(
                      isCompact: isCompact,
                      onAccept: _acceptAndLockPositions,
                      onCopyCode: _showCopyCodeDialog,
                      onReset: _resetPositionsToDefault,
                      onCancel: _cancelCalibration,
                    ),
                  ),

                // 5. Selected Location Info Card (Learning Mode & Coordinate Mode review)
                if ((_isLearningMode || _isCoordinateMode) &&
                    _selectedLocation != null &&
                    !_isModalOpen &&
                    !_isCalibrationMode)
                  Positioned(
                    bottom: isCompact
                        ? math.max(
                            MediaQuery.paddingOf(context).bottom + 12.0, 14.0)
                        : 20.0,
                    left: isCompact ? 12.0 : 24.0,
                    right: isCompact ? 12.0 : 24.0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_selectedLocation?.id),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 18 * (1.0 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: _LocationInfoCard(
                          location: _selectedLocation!,
                          isCompact: isCompact,
                          onClose: () {
                            setState(() => _selectedLocation = null);
                            _resetZoom(viewportWidth, viewportHeight);
                          },
                          onResetZoom: () =>
                              _resetZoom(viewportWidth, viewportHeight),
                        ),
                      ),
                    ),
                  ),

                // 6. Game Mission Panel (Level Mode only - elevated position)
                if (!_isLearningMode && !_isCoordinateMode && !_isModalOpen && !_isCalibrationMode)
                  Positioned(
                    bottom: isCompact
                        ? math.max(
                            MediaQuery.paddingOf(context).bottom + 36, 52.0)
                        : 48.0,
                    left: isCompact ? 12.0 : 24.0,
                    right: isCompact ? 12.0 : 24.0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _GameMissionPanel(
                        key: ValueKey('mission_panel_$_currentMissionIndex'),
                        mission: _currentMission,
                        revealedCluesCount: _revealedCluesCount,
                        isCompact: isCompact,
                        onRevealNextClue: () {
                          setState(() {
                            _revealedCluesCount++;
                          });
                        },
                        onSelectChoice: (choiceIndex) => _handleChoiceAnswer(
                          choiceIndex,
                          viewportWidth,
                          viewportHeight,
                        ),
                      ),
                    ),
                  ),

                // 7. Coordinate Quest Panel (Coordinate Mode only - elevated position)
                if (_isCoordinateMode && !_isModalOpen && _selectedLocation == null && !_isCalibrationMode)
                  Positioned(
                    bottom: isCompact
                        ? math.max(
                            MediaQuery.paddingOf(context).bottom + 36, 52.0)
                        : 48.0,
                    left: isCompact ? 12.0 : 24.0,
                    right: isCompact ? 12.0 : 24.0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _CoordinateQuestPanel(
                        key: ValueKey('coord_panel_${_unlockedLocationIds.length}'),
                        unlockedIds: _unlockedLocationIds,
                        allLocations: _locations,
                        isCompact: isCompact,
                        onCorrectAnswer: (loc) => _handleCoordinateUnlock(
                          loc,
                          viewportWidth,
                          viewportHeight,
                        ),
                        onResetProgress: () => _handleResetCoordinateProgress(
                          viewportWidth,
                          viewportHeight,
                        ),
                      ),
                    ),
                  ),

                // 8. Center Welcome Modal: slides in from bottom, slides out on continue
                if (_isModalOpen || _modalController.isAnimating)
                  IgnorePointer(
                    ignoring: !_isModalOpen,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _modalController,
                        builder: (context, child) {
                          final dy = (1.0 - _slideProgress.value) *
                              (screen.height * 1.1);
                          return Transform.translate(
                            offset: Offset(0, dy),
                            child: child,
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 20 : 48,
                          ),
                          child: _GlassWelcomeModal(
                            isLearningMode: _isLearningMode,
                            isCoordinateMode: _isCoordinateMode,
                            onContinue: _dismissModal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
  }
}

/// An interactive, pulsing circle point on the map.
class MapPointPin extends StatefulWidget {
  const MapPointPin({
    super.key,
    required this.location,
    required this.currentOffset,
    required this.isCalibrationMode,
    required this.isDragging,
    required this.isSelected,
    required this.pulseController,
    required this.activeCategory,
    required this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
  });

  final MapLocation location;
  final Offset currentOffset;
  final bool isCalibrationMode;
  final bool isDragging;
  final bool isSelected;
  final AnimationController pulseController;
  final CategoryFilter activeCategory;
  final VoidCallback onTap;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final VoidCallback? onPointerDown;
  final ValueChanged<Offset>? onPointerMove;
  final VoidCallback? onPointerUp;

  @override
  State<MapPointPin> createState() => _MapPointPinState();
}

class _MapPointPinState extends State<MapPointPin> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isBisinal = widget.location.geoCategory == GeoCategory.bisinal;
    final isInsular = widget.location.geoCategory == GeoCategory.insular;
    final isPilipinas = widget.location.geoCategory == GeoCategory.pilipinas;

    final bool isMatching;
    final Color color;

    if (widget.isCalibrationMode) {
      isMatching = true;
      color = widget.isDragging
          ? const Color(0xFFFFD54F)
          : widget.location.color;
    } else {
      switch (widget.activeCategory) {
        case CategoryFilter.bisinal:
          isMatching = isBisinal;
          color = isBisinal ? const Color(0xFF00E676) : widget.location.color;
          break;
        case CategoryFilter.insular:
          isMatching = isInsular;
          color = isInsular ? const Color(0xFF00E5FF) : widget.location.color;
          break;
        case CategoryFilter.pilipinas:
          isMatching = isPilipinas;
          color = isPilipinas ? const Color(0xFFFFD54F) : widget.location.color;
          break;
        case CategoryFilter.lahat:
          isMatching = true;
          color = widget.location.color;
          break;
      }
    }

    final showTooltip = widget.isCalibrationMode || _hovered || widget.isSelected;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 280),
      opacity: isMatching ? 1.0 : 0.25,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.isCalibrationMode
            ? SystemMouseCursors.move
            : SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: widget.isCalibrationMode
              ? (_) => widget.onPointerDown?.call()
              : null,
          onPointerMove: widget.isCalibrationMode
              ? (event) => widget.onPointerMove?.call(event.localDelta)
              : null,
          onPointerUp: widget.isCalibrationMode
              ? (_) => widget.onPointerUp?.call()
              : null,
          onPointerCancel: widget.isCalibrationMode
              ? (_) => widget.onPointerUp?.call()
              : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onPanStart: widget.onPanStart,
            onPanUpdate: widget.onPanUpdate,
            onPanEnd: widget.onPanEnd,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Outer pulsing ripple ring (or calibration halo)
                if (widget.isCalibrationMode)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: widget.isDragging ? 42 : 32,
                    height: widget.isDragging ? 42 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isDragging
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF00E5FF).withValues(alpha: 0.8),
                        width: widget.isDragging ? 2.5 : 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isDragging
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFF00E5FF))
                              .withValues(alpha: widget.isDragging ? 0.6 : 0.3),
                          blurRadius: widget.isDragging ? 14 : 8,
                          spreadRadius: widget.isDragging ? 3 : 1,
                        ),
                      ],
                    ),
                  )
                else if (isMatching)
                  AnimatedBuilder(
                    animation: widget.pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (widget.pulseController.value * 0.55);
                      final opacity =
                          (1.0 - widget.pulseController.value).clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: widget.isSelected ? 1.65 : scale,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: opacity * 0.85),
                              width: 2.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Inner glowing pin circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: widget.isDragging
                      ? 26
                      : (_hovered || widget.isSelected || widget.isCalibrationMode ? 22 : 18),
                  height: widget.isDragging
                      ? 26
                      : (_hovered || widget.isSelected || widget.isCalibrationMode ? 22 : 18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: Colors.white,
                      width: widget.isDragging ? 2.8 : 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: isMatching ? 0.75 : 0.20),
                        blurRadius: _hovered || widget.isSelected || widget.isDragging ? 18 : 10,
                        spreadRadius: _hovered || widget.isSelected || widget.isDragging ? 4 : 1.5,
                      ),
                    ],
                  ),
                  child: widget.isCalibrationMode
                      ? Center(
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: widget.isDragging ? 14 : 12,
                            color: Colors.black.withValues(alpha: 0.8),
                          ),
                        )
                      : null,
                ),

                // Tooltip badge showing territory name and coordinates
                if (showTooltip)
                  Positioned(
                    top: widget.isCalibrationMode ? -34 : -26,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: widget.isCalibrationMode ? 3.5 : 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: color.withValues(alpha: 0.85),
                          width: widget.isCalibrationMode ? 1.4 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: widget.isCalibrationMode
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.location.title,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  'X: ${widget.currentOffset.dx.toStringAsFixed(3)}  Y: ${widget.currentOffset.dy.toStringAsFixed(3)}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF80D8FF),
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.activeCategory == CategoryFilter.bisinal &&
                                    isBisinal) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00E676),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                Text(
                                  widget.activeCategory == CategoryFilter.bisinal &&
                                          isBisinal
                                      ? '${widget.location.title} (Bisinal)'
                                      : widget.location.title,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Top-right toggle button to open Calibration / Move Points Mode.
class _CalibratePointsButton extends StatelessWidget {
  const _CalibratePointsButton({
    required this.onTap,
    this.isCompact = false,
  });

  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xDD0D2534),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFFFFD54F),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 8),
                const Text(
                  'AYUSIN ANG MGA PUNTO',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width floating control toolbar displayed while in Calibration Mode.
class _CalibrationControlBar extends StatelessWidget {
  const _CalibrationControlBar({
    required this.onAccept,
    required this.onCopyCode,
    required this.onReset,
    required this.onCancel,
    this.isCompact = false,
  });

  final VoidCallback onAccept;
  final VoidCallback onCopyCode;
  final VoidCallback onReset;
  final VoidCallback onCancel;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF2081721),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.open_with_rounded,
                      color: Color(0xFFFFD54F),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'PAG-AAYOS: I-drag ang mga bilog sa mapa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    _buildCancelBtn(),
                    _buildResetBtn(),
                    _buildCodeBtn(),
                    _buildAcceptBtn(),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                const Icon(
                  Icons.open_with_rounded,
                  color: Color(0xFFFFD54F),
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAG-AAYOS NG MGA PUNTO SA MAPA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'I-drag ang mga bilog sa kanilang tamang lokasyon. Pindutin ang TANGGAPIN kapag tapos na upang i-lock.',
                        style: TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildCancelBtn(),
                const SizedBox(width: 6),
                _buildResetBtn(),
                const SizedBox(width: 6),
                _buildCodeBtn(),
                const SizedBox(width: 8),
                _buildAcceptBtn(),
              ],
            ),
    );
  }

  Widget _buildAcceptBtn() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.check_circle_rounded, size: 16),
      label: const Text(
        'TANGGAPIN / I-SAVE',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
      onPressed: onAccept,
    );
  }

  Widget _buildCodeBtn() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00E5FF),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.code_rounded, size: 15),
      label: const Text(
        'KODIGO',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      onPressed: onCopyCode,
    );
  }

  Widget _buildResetBtn() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFFB74D),
        side: const BorderSide(color: Color(0xFFFFB74D), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.restore_rounded, size: 15),
      label: const Text(
        'I-RESET',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      onPressed: onReset,
    );
  }

  Widget _buildCancelBtn() {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFFF5252),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      icon: const Icon(Icons.close_rounded, size: 15),
      label: const Text(
        'KANSELA',
        style: TextStyle(fontSize: 11),
      ),
      onPressed: onCancel,
    );
  }
}

/// Information card displayed when a user taps a map location.
/// Designed for Grade 4 learners: light high-contrast background, dark readable text,
/// half-screen height, and close button that zooms out back to the full map.
class _LocationInfoCard extends StatefulWidget {
  const _LocationInfoCard({
    required this.location,
    required this.onClose,
    required this.onResetZoom,
    this.isCompact = false,
  });

  final MapLocation location;
  final VoidCallback onClose;
  final VoidCallback onResetZoom;
  final bool isCompact;

  @override
  State<_LocationInfoCard> createState() => _LocationInfoCardState();
}

class _LocationInfoCardState extends State<_LocationInfoCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final isCompact = widget.isCompact;
    final onClose = widget.onClose;

    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width > 680 ? 560.0 : screen.width * 0.94;
    // Mobile modal takes about half the phone height (0.52) comfortably
    final maxHeight = screen.height * (isCompact ? 0.52 : 0.46);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: location.color.withValues(alpha: 0.85),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 20,
            isCompact ? 12 : 16,
            isCompact ? 16 : 20,
            isCompact ? 12 : 14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Row: Category Pill & Close / Zoom-out Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category Pill
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 10,
                        vertical: isCompact ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: location.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: location.color,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        location.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: isCompact ? 10.5 : 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Close Button (Tapping this closes card and zooms out to full map)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF475569),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Isara at Mag-zoom out',
                    onPressed: () {
                      AudioManager.instance.playClick();
                      onClose();
                    },
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 4 : 8),

              // Title in Jomhuria Typography (High-contrast dark text)
              Text(
                location.title,
                style: TextStyle(
                  fontFamily: 'Jomhuria',
                  fontSize: isCompact ? 40 : 48,
                  color: const Color(0xFF0F172A),
                  height: 0.88,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isCompact ? 6 : 10),

              // Scrollable Description & Fun Fact Box (Dark text on light background)
              Flexible(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.unknown,
                    },
                  ),
                  child: RawScrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thickness: 4.0,
                    radius: const Radius.circular(4),
                    thumbColor: const Color(0xFF94A3B8),
                    interactive: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Educational Description with high contrast black/dark slate text
                          Text(
                            location.description,
                            style: TextStyle(
                              fontSize: isCompact ? 16.0 : 17.5,
                              color: const Color(0xFF1E293B),
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Fun Fact Box with warm light amber background & black text
                          Container(
                            padding: EdgeInsets.all(isCompact ? 12 : 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFF59E0B),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lightbulb_rounded,
                                      color: Color(0xFFD97706),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'ALAM MO BA? (FUN FACT)',
                                        style: TextStyle(
                                          fontSize:
                                              isCompact ? 11.5 : 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFB45309),
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  location.funFact,
                                  style: TextStyle(
                                    fontSize:
                                        isCompact ? 14.5 : 15.5,
                                    color: const Color(0xFF1E293B),
                                    height: 1.42,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 10 : 12),

              // Bottom Action: Reset Zoom / Return to Full Map
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 14 : 18,
                      vertical: isCompact ? 8 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    AudioManager.instance.playClick();
                    onClose();
                  },
                  icon: Icon(
                    Icons.zoom_out_map_rounded,
                    size: isCompact ? 15 : 17,
                  ),
                  label: Text(
                    'BUMALIK SA BUONG MAPA',
                    style: TextStyle(
                      fontSize: isCompact ? 11.5 : 12.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-center frosted glassy category filter button.
/// Allows toggling and highlighting between categories (Lahat, Bisinal, Insular, Pilipinas).
class _CategoryFilterButton extends StatelessWidget {
  const _CategoryFilterButton({
    super.key,
    required this.selectedCategory,
    required this.isCompact,
    required this.onCategoryChanged,
  });

  final CategoryFilter selectedCategory;
  final bool isCompact;
  final ValueChanged<CategoryFilter> onCategoryChanged;

  void _cycleNext() {
    final nextIndex =
        (selectedCategory.index + 1) % CategoryFilter.values.length;
    onCategoryChanged(CategoryFilter.values[nextIndex]);
  }

  void _openCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryPickerSheet(
        selectedCategory: selectedCategory,
        onSelect: (cat) {
          Navigator.of(context).pop();
          onCategoryChanged(cat);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = selectedCategory.accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A1950).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.65),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                AudioManager.instance.playClick();
                _cycleNext();
              },
              onLongPress: () => _openCategoryPicker(context),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 14,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category Icon with glow
                    Icon(
                      selectedCategory.icon,
                      color: accentColor,
                      size: isCompact ? 15 : 18,
                    ),
                    const SizedBox(width: 6),

                    // Label: "KATEGORYA: [LABEL]"
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KATEGORYA',
                          style: TextStyle(
                            fontSize: isCompact ? 8 : 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.70),
                            letterSpacing: 0.8,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          selectedCategory.label,
                          style: TextStyle(
                            fontSize: isCompact ? 11.5 : 13,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 0.6,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),

                    // Switch icon
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white.withValues(alpha: 0.60),
                      size: isCompact ? 14 : 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted glassy bottom sheet to easily select any category with descriptive details.
class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.selectedCategory,
    required this.onSelect,
  });

  final CategoryFilter selectedCategory;
  final ValueChanged<CategoryFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1950).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'PUMILI NG KATEGORYA',
                style: TextStyle(
                  fontFamily: 'Jomhuria',
                  fontSize: 32,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 12),
              for (final cat in CategoryFilter.values)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selectedCategory == cat
                        ? cat.accentColor.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        AudioManager.instance.playClick();
                        onSelect(cat);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(cat.icon, color: cat.accentColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      color: cat.accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    cat.description,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedCategory == cat)
                              Icon(Icons.check_circle_rounded,
                                  color: cat.accentColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


/// A softened dark vignette overlay with reduced size and subtle opacity
/// that delicately frames all sides (top, bottom, left, right) and corners
/// without overpowering or darkening the map.
class _DarkVignetteOverlay extends StatelessWidget {
  const _DarkVignetteOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Soft radial vignette from center out to corners
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.35,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.40),
                  ],
                  stops: const [0.0, 0.65, 0.88, 1.0],
                ),
              ),
            ),
          ),

          // Top edge subtle vignette
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom edge subtle vignette
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Left edge subtle vignette
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Right edge subtle vignette
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft gradient fade-outs on each of the four outer boundaries of the map canvas
/// so the edges seamlessly dissolve into the ocean background without static hard lines.
class _MapEdgeFadeOverlay extends StatelessWidget {
  const _MapEdgeFadeOverlay();

  @override
  Widget build(BuildContext context) {
    const fadeColor = Color(0xFF0373C0);
    const double edgeSize = 48.0;

    return IgnorePointer(
      child: Stack(
        children: [
          // Top edge fade
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: edgeSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    fadeColor,
                    fadeColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Bottom edge fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: edgeSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    fadeColor,
                    fadeColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Left edge fade
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: edgeSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    fadeColor,
                    fadeColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Right edge fade
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: edgeSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    fadeColor,
                    fadeColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Educational Coordinate Grid Layer displaying Latitudes (Parallels) and
/// Longitudes (Meridians) with distinct 0° Equator line and edge badges.
class _MapCoordinateGridLayer extends StatelessWidget {
  const _MapCoordinateGridLayer();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _CoordinateGridPainter(),
      size: Size(1024.0, 1536.0),
    );
  }
}

class _CoordinateGridPainter extends CustomPainter {
  const _CoordinateGridPainter();

  // Parallels (Latitud - horizontal lines)
  static const List<_GridLineData> latitudes = [
    _GridLineData(label: '30° H', pos: 338.0),
    _GridLineData(label: '20° H', pos: 530.0),
    _GridLineData(label: '10° H', pos: 783.0),
    _GridLineData(label: '0° Ekwador', pos: 1105.0, isEquator: true),
    _GridLineData(label: '10° T', pos: 1275.0),
    _GridLineData(label: '20° T', pos: 1428.0),
  ];

  // Meridians (Longhitud - vertical lines)
  static const List<_GridLineData> longitudes = [
    _GridLineData(label: '95° S', pos: 82.0),
    _GridLineData(label: '100° S', pos: 195.0),
    _GridLineData(label: '110° S', pos: 389.0),
    _GridLineData(label: '120° S', pos: 635.0),
    _GridLineData(label: '130° S', pos: 799.0),
    _GridLineData(label: '140° S', pos: 932.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final regularLinePaint = Paint()
      ..color = const Color(0xFF81D4FA).withValues(alpha: 0.38)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final equatorLinePaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.80)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw Parallels (Horizontal Latitude Lines)
    for (final lat in latitudes) {
      final y = lat.pos;
      if (y < 0 || y > size.height) continue;

      if (lat.isEquator) {
        _drawDashedLine(
          canvas,
          Offset(0, y),
          Offset(size.width, y),
          equatorLinePaint,
          dash: 14.0,
          gap: 6.0,
        );
        // Center equator badge across ocean
        _drawBadge(
          canvas,
          '0° EKWADOR (EQUATOR)',
          Offset(size.width * 0.50, y),
          isEquator: true,
        );
      } else {
        _drawDashedLine(
          canvas,
          Offset(0, y),
          Offset(size.width, y),
          regularLinePaint,
          dash: 8.0,
          gap: 6.0,
        );
      }
    }

    // Draw Meridians (Vertical Longitude Lines)
    for (final lon in longitudes) {
      final x = lon.pos;
      if (x < 0 || x > size.width) continue;

      _drawDashedLine(
        canvas,
        Offset(x, 0),
        Offset(x, size.height),
        regularLinePaint,
        dash: 8.0,
        gap: 6.0,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dash = 8.0,
    double gap = 6.0,
  }) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;
    final unitX = dx / distance;
    final unitY = dy / distance;
    double current = 0.0;
    while (current < distance) {
      final start = Offset(p1.dx + unitX * current, p1.dy + unitY * current);
      final nextLen = math.min(dash, distance - current);
      final end = Offset(start.dx + unitX * nextLen, start.dy + unitY * nextLen);
      canvas.drawLine(start, end, paint);
      current += dash + gap;
    }
  }

  void _drawBadge(
    Canvas canvas,
    String text,
    Offset center, {
    bool isEquator = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: isEquator ? 12.0 : 10.5,
          fontWeight: FontWeight.bold,
          color: isEquator ? const Color(0xFFFFD54F) : const Color(0xFFE0F7FA),
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final paddingH = isEquator ? 8.0 : 6.0;
    final paddingV = isEquator ? 4.0 : 3.0;
    final w = textPainter.width + paddingH * 2;
    final h = textPainter.height + paddingV * 2;
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    final bgPaint = Paint()
      ..color = const Color(0xDD071B2B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = isEquator
          ? const Color(0xFFFFD54F).withValues(alpha: 0.85)
          : const Color(0xFF00E5FF).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridLineData {
  const _GridLineData({
    required this.label,
    required this.pos,
    this.isEquator = false,
  });

  final String label;
  final double pos;
  final bool isEquator;
}

/// Screen-fixed coordinate badges overlay.
/// Keeps latitude labels pinned to the left and right screen borders
/// and longitude labels pinned to the top and bottom screen borders,
/// tracking the grid lines dynamically across all zoom levels and pan positions.
class _ScreenCoordinateBadgesOverlay extends StatelessWidget {
  const _ScreenCoordinateBadgesOverlay({
    required this.transformationController,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.hasBottomCard,
    this.isLevelMode = false,
  });

  final TransformationController transformationController;
  final double viewportWidth;
  final double viewportHeight;
  final bool hasBottomCard;
  final bool isLevelMode;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: transformationController,
      builder: (context, _) {
        return CustomPaint(
          size: Size(viewportWidth, viewportHeight),
          painter: _ScreenBadgesPainter(
            matrix: transformationController.value,
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight,
            hasBottomCard: hasBottomCard,
            isLevelMode: isLevelMode,
          ),
        );
      },
    );
  }
}

class _ScreenBadgesPainter extends CustomPainter {
  const _ScreenBadgesPainter({
    required this.matrix,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.hasBottomCard,
    required this.isLevelMode,
  });

  final Matrix4 matrix;
  final double viewportWidth;
  final double viewportHeight;
  final bool hasBottomCard;
  final bool isLevelMode;

  @override
  void paint(Canvas canvas, Size size) {
    final storage = matrix.storage;
    final scaleX = storage[0];
    final scaleY = storage[5];
    final transX = storage[12];
    final transY = storage[13];

    const canvasWidth = 1024.0;
    const canvasHeight = 1536.0;

    final mapLeft = transX;
    final mapRight = canvasWidth * scaleX + transX;
    final mapTop = transY;
    final mapBottom = canvasHeight * scaleY + transY;

    // 1. Latitude numbers (Horizontal Parallels - on Left and Right sides of screen)
    final topLimit = 60.0;
    final bottomLimit = hasBottomCard
        ? viewportHeight * 0.44
        : (isLevelMode ? viewportHeight - 120.0 : viewportHeight - 24.0);

    for (final lat in _CoordinateGridPainter.latitudes) {
      final sy = lat.pos * scaleY + transY;
      if (sy < topLimit || sy > bottomLimit) continue;
      // If line is completely outside screen horizontally
      if (mapRight < 24.0 || mapLeft > viewportWidth - 24.0) continue;

      // Left screen side badge
      final leftX = (mapLeft > 0)
          ? math.min(mapLeft + 26.0, viewportWidth - 26.0)
          : 26.0;
      _drawBadge(canvas, lat.label, Offset(leftX, sy), isEquator: lat.isEquator);

      // Right screen side badge
      final rightX = (mapRight < viewportWidth)
          ? math.max(26.0, mapRight - 26.0)
          : viewportWidth - 26.0;
      if (rightX > leftX + 54.0) {
        _drawBadge(canvas, lat.label, Offset(rightX, sy), isEquator: lat.isEquator);
      }
    }

    // 2. Longitude numbers (Vertical Meridians - on Top and Bottom sides of screen)
    final leftLimit = 52.0;
    final rightLimit = viewportWidth - 52.0;

    for (final lon in _CoordinateGridPainter.longitudes) {
      final sx = lon.pos * scaleX + transX;
      if (sx < leftLimit || sx > rightLimit) continue;
      // If line is completely outside screen vertically
      if (mapBottom < 50.0 || mapTop > viewportHeight - 50.0) continue;

      // Top screen side badge (docked just below top bar)
      final topY = (mapTop > 62.0)
          ? math.min(mapTop + 20.0, viewportHeight - 20.0)
          : 62.0;
      _drawBadge(canvas, lon.label, Offset(sx, topY));

      // Bottom screen side badge (only when no bottom card)
      if (!hasBottomCard) {
        final bottomTarget =
            isLevelMode ? viewportHeight - 120.0 : viewportHeight - 16.0;
        final bottomY = (mapBottom < bottomTarget)
            ? math.max(topY + 36.0, mapBottom - 16.0)
            : bottomTarget;
        if (bottomY > topY + 36.0) {
          _drawBadge(canvas, lon.label, Offset(sx, bottomY));
        }
      }
    }
  }

  void _drawBadge(
    Canvas canvas,
    String text,
    Offset center, {
    bool isEquator = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: isEquator ? 12.0 : 10.5,
          fontWeight: FontWeight.bold,
          color: isEquator ? const Color(0xFFFFD54F) : const Color(0xFFE0F7FA),
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final paddingH = isEquator ? 8.0 : 6.0;
    final paddingV = isEquator ? 4.0 : 3.0;
    final w = textPainter.width + paddingH * 2;
    final h = textPainter.height + paddingV * 2;
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Shadow for clear contrast against any terrain
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(rrect.shift(const Offset(0, 1.5)), shadowPaint);

    final bgPaint = Paint()
      ..color = const Color(0xF0071B2B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = isEquator
          ? const Color(0xFFFFD54F).withValues(alpha: 0.90)
          : const Color(0xFF00E5FF).withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ScreenBadgesPainter oldDelegate) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.hasBottomCard != hasBottomCard ||
        oldDelegate.isLevelMode != isLevelMode;
  }
}

/// Floating glass button to toggle the coordinate grid layer on or off.
class _GridToggleButton extends StatelessWidget {
  const _GridToggleButton({
    required this.isGridOn,
    required this.isCompact,
    required this.onTap,
  });

  final bool isGridOn;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () {
            AudioManager.instance.playClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 13,
              vertical: isCompact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: isGridOn
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.24)
                  : Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isGridOn
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.80)
                    : Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isGridOn ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                  color: isGridOn ? const Color(0xFF00E5FF) : Colors.white70,
                  size: isCompact ? 16 : 18,
                ),
                SizedBox(width: isCompact ? 5 : 6),
                Text(
                  isGridOn ? 'GRID' : 'GRID (OFF)',
                  style: TextStyle(
                    fontSize: isCompact ? 11.0 : 12.0,
                    fontWeight: FontWeight.bold,
                    color: isGridOn ? Colors.white : Colors.white70,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A glassy modal card with rounded corners, frosted blur, and hoverable button.
/// The title is simply "MALIGAYANG PAGDATING" while the body content teaches
/// the context of "Mapa ng Pilipinas sa Asya".
class _GlassWelcomeModal extends StatelessWidget {
  const _GlassWelcomeModal({
    required this.isLearningMode,
    this.isCoordinateMode = false,
    required this.onContinue,
  });

  final bool isLearningMode;
  final bool isCoordinateMode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600;
    final maxWidth = screen.width > 700 ? 580.0 : screen.width * 0.90;
    final maxHeight = screen.height * 0.86;

    String title = 'MAPQUEST EXPLORER';
    Color titleColor = Colors.amber;
    String tag = '🎮 ANTAS NG MISYON';
    Color tagColor = Colors.amber;

    if (isCoordinateMode) {
      title = 'COORDINATE QUEST';
      titleColor = const Color(0xFF00E676);
      tag = '🧭 TIYAK NA LOKASYON';
      tagColor = const Color(0xFF00E676);
    } else if (isLearningMode) {
      title = 'MALIGAYANG PAGDATING!';
      titleColor = Colors.white;
      tag = 'MODE NG PAGKATUTO';
      tagColor = Colors.white;
    }

    String welcomeText;
    if (isCoordinateMode) {
      welcomeText =
          '“Handa ka na bang tuklasin ang mapa gamit ang mga koordinada?”\n\n“Nakatago ang lahat ng punto sa mapa. Kailangan mong suriin ang ibinigay na latitud at longhitud upang matukoy ang tamang lugar.”\n\n“Bawat tamang sagot ay magbubukas ng punto sa mapa. Naitatala ang iyong progreso kahit pansamantala kang umalis!”';
    } else if (isLearningMode) {
      welcomeText =
          'Handa ka na bang tuklasin ang kinalalagyan ng Pilipinas sa mapa ng Asya?\n\nSa araling ito, aalamin natin kung nasaan ang Pilipinas, ang mga karatig-bansa nito, at ang mga anyong tubig na nakapaligid dito. Handa ka na ba?\n\nPindutin ang “Magsimula” kung ikaw ay handa na sa pagtuklas!';
    } else {
      welcomeText =
          '“Handa ka na bang maging isang MapQuest Explorer?”\n\n“Gamitin ang iyong mapa upang tuklasin ang lokasyon ng Pilipinas sa Asya, hanapin ang mga karatig-bansa, tukuyin ang mga anyong tubig, at lutasin ang mga hamon!”\n\n“Bawat tamang sagot ay magbibigay sa iyo ng puntos at gantimpala.”';
    }

    String buttonLabel;
    if (isCoordinateMode) {
      buttonLabel = 'SIMULAN ANG PAGHAHANAP';
    } else if (isLearningMode) {
      buttonLabel = 'MAGSIMULA';
    } else {
      buttonLabel = 'SIMULAN ANG MISYON';
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 16 : 28,
              isCompact ? 14 : 24,
              isCompact ? 16 : 28,
              isCompact ? 14 : 26,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.40),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 4,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Title in Jomhuria Typography
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Jomhuria',
                      fontSize: isCompact ? 40 : 64,
                      color: titleColor,
                      height: 0.85,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: isCompact ? 3 : 6),

                  // Mode Indicator Tag
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: isCompact ? 8 : 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tagColor.withValues(alpha: 0.60),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontFamily: 'Jomhuria',
                        fontSize: isCompact ? 18 : 26,
                        color: tagColor,
                        height: 0.9,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 6 : 14),

                  // Decorative Divider Line
                  Container(
                    width: isCompact ? 60 : 80,
                    height: 2,
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 16),

                  // Welcome Message Content
                  Text(
                    welcomeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 12.5 : 15.5,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: isCompact ? 1.32 : 1.45,
                      fontWeight: FontWeight.w400,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 24),

                  // Hoverable Continue Button
                  _HoverContinueButton(
                    label: buttonLabel,
                    isCompact: isCompact,
                    onTap: onContinue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A hoverable continue button with animated highlight styling.
class _HoverContinueButton extends StatefulWidget {
  const _HoverContinueButton({
    required this.label,
    required this.onTap,
    this.isCompact = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  State<_HoverContinueButton> createState() => _HoverContinueButtonState();
}

class _HoverContinueButtonState extends State<_HoverContinueButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AudioManager.instance.playClick();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 22 : 38,
            vertical: widget.isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white
                : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.65),
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Jomhuria',
              fontSize: widget.isCompact ? 26 : 36,
              color: _hovered ? const Color(0xFF0C27DA) : Colors.white,
              height: 0.9,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Top-left back button.
class _BackButton extends StatefulWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AudioManager.instance.playClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _hovered ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.40),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// Top Game HUD Header displaying Mission number, Points, Lives, and Coins.
class _GameHudHeader extends StatelessWidget {
  const _GameHudHeader({
    super.key,
    required this.missionNumber,
    required this.totalMissions,
    required this.score,
    required this.lives,
    required this.coins,
    required this.isCompact,
  });

  final int missionNumber;
  final int totalMissions;
  final int score;
  final int lives;
  final int coins;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 18,
            vertical: isCompact ? 5 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1950).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.70),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo (shown on larger screens)
              if (!isCompact) ...[
                const Text(
                  'MAPQUEST',
                  style: TextStyle(
                    fontFamily: 'Jomhuria',
                    fontSize: 28,
                    color: Colors.amber,
                    height: 0.9,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 18,
                  color: Colors.white24,
                ),
              ],
              // Misyon counter
              Text(
                isCompact ? 'M$missionNumber/$totalMissions' : 'Misyon $missionNumber / $totalMissions',
                style: TextStyle(
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: isCompact ? 4 : 12),
              // Points
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 5 : 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isCompact ? 4 : 6),
              // Lives
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 5 : 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('❤️', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '$lives',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isCompact ? 4 : 6),
              // Coins
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 5 : 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '$coins',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating bottom panel presenting the active mission, instructions, progressive clues,
/// and interactive choice options.
class _GameMissionPanel extends StatelessWidget {
  const _GameMissionPanel({
    super.key,
    required this.mission,
    required this.revealedCluesCount,
    required this.isCompact,
    required this.onRevealNextClue,
    required this.onSelectChoice,
  });

  final GameMission mission;
  final int revealedCluesCount;
  final bool isCompact;
  final VoidCallback onRevealNextClue;
  final ValueChanged<int> onSelectChoice;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width > 700 ? 630.0 : screen.width * 0.94;
    final maxHeight = screen.height * (isCompact ? 0.48 : 0.44);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 16 : 22,
              isCompact ? 14 : 18,
              isCompact ? 16 : 22,
              isCompact ? 14 : 18,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF07123A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.75),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  blurRadius: 26,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.60),
                  blurRadius: 30,
                  spreadRadius: 3,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mission Title Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 9 : 11,
                          vertical: isCompact ? 3.5 : 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.60),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'HAMON ${mission.missionNumber}',
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E5FF),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mission.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 15 : 17.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Mission Prompt
                  Text(
                    mission.prompt,
                    style: TextStyle(
                      fontSize: isCompact ? 14.5 : 16.5,
                      color: Colors.white.withValues(alpha: 0.98),
                      height: 1.38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Mission Instruction
                  Text(
                    mission.instruction,
                    style: TextStyle(
                      fontSize: isCompact ? 12.5 : 14.0,
                      color: const Color(0xFFFFD54F),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 11),

                  // Progressive Clues (for cluesMap missions)
                  if (mission.type == MissionType.cluesMap) ...[
                    for (int i = 0; i < revealedCluesCount && i < mission.clues.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 14,
                          vertical: isCompact ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔎 ', style: TextStyle(fontSize: isCompact ? 14 : 16)),
                            Expanded(
                              child: Text(
                                mission.clues[i],
                                style: TextStyle(
                                  fontSize: isCompact ? 13 : 14.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (revealedCluesCount < mission.clues.length)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            AudioManager.instance.playClick();
                            onRevealNextClue();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            foregroundColor: const Color(0xFF64B5F6),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 17),
                          label: Text(
                            'Ipakita ang susunod na pahiwatig (${mission.clues.length - revealedCluesCount} natitira)',
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],

                  // Choices (for choice missions)
                  if (mission.type == MissionType.choice) ...[
                    const SizedBox(height: 6),
                    for (int idx = 0; idx < mission.choices.length; idx++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _MissionChoiceButton(
                          label: mission.choices[idx],
                          isCompact: isCompact,
                          onTap: () => onSelectChoice(idx),
                        ),
                      ),
                  ],

                  // Map tap prompt hint for tapMap
                  if (mission.type == MissionType.tapMap ||
                      mission.type == MissionType.cluesMap) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 14,
                        vertical: isCompact ? 7 : 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            size: 18,
                            color: Color(0xFF00E5FF),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Pumili at i-tap ang tamang bilog o bansa sa mapa sa itaas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 13.5,
                                color: const Color(0xFF00E5FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A button representing an individual choice in a multiple-choice mission.
class _MissionChoiceButton extends StatefulWidget {
  const _MissionChoiceButton({
    required this.label,
    required this.isCompact,
    required this.onTap,
  });

  final String label;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  State<_MissionChoiceButton> createState() => _MissionChoiceButtonState();
}

class _MissionChoiceButtonState extends State<_MissionChoiceButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          AudioManager.instance.playClick();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 14 : 18,
            vertical: widget.isCompact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF1976D2).withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF64B5F6)
                  : Colors.white.withValues(alpha: 0.28),
              width: 1.4,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.isCompact ? 13.5 : 15.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: _hovered ? Colors.amberAccent : Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted modal dialog displaying feedback after an answer (success or retry).
class _MissionFeedbackDialog extends StatelessWidget {
  const _MissionFeedbackDialog({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.pointsReward,
    this.coinsReward,
    this.newBadges = const [],
    this.remainingLives,
    required this.buttonText,
    required this.onButtonPressed,
  });

  final bool isSuccess;
  final String title;
  final String message;
  final int? pointsReward;
  final int? coinsReward;
  final List<GameBadge> newBadges;
  final int? remainingLives;
  final String buttonText;
  final VoidCallback onButtonPressed;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600;
    final accentColor = isSuccess ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isCompact ? 20 : 36),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 20 : 28,
              isCompact ? 20 : 24,
              isCompact ? 20 : 28,
              isCompact ? 18 : 22,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF071238).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.70),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.30),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.60),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isSuccess ? '⭐' : '❌',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Jomhuria',
                    fontSize: isCompact ? 40 : 48,
                    color: accentColor,
                    height: 0.9,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Feedback Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCompact ? 13.5 : 15,
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Rewards row if success
                if (isSuccess && (pointsReward != null || coinsReward != null)) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.40),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pointsReward != null) ...[
                          const Text('⭐', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '+$pointsReward Puntos',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ],
                        if (pointsReward != null && coinsReward != null)
                          const SizedBox(width: 14),
                        if (coinsReward != null) ...[
                          const Text('🪙', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '+$coinsReward Barya',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Newly unlocked badges
                if (newBadges.isNotEmpty) ...[
                  for (final badge in newBadges)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.60),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(badge.icon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BAGONG BADGE: ${badge.title}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amberAccent,
                                ),
                              ),
                              Text(
                                badge.subtitle,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                ],

                // Remaining lives if failure
                if (!isSuccess && remainingLives != null) ...[
                  Text(
                    '❤️ Natitirang Buhay: $remainingLives',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action button
                _HoverContinueButton(
                  label: buttonText,
                  onTap: onButtonPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Game Over dialog when lives reach zero.
class _GameOverDialog extends StatelessWidget {
  const _GameOverDialog({
    required this.score,
    required this.onRetry,
    required this.onExitToMenu,
  });

  final int score;
  final VoidCallback onRetry;
  final VoidCallback onExitToMenu;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isCompact ? 20 : 36),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 20 : 28,
              isCompact ? 22 : 28,
              isCompact ? 20 : 28,
              isCompact ? 20 : 24,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1E0A16).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.70),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💔', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  'NAUBOS ANG BUHAY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Jomhuria',
                    fontSize: isCompact ? 42 : 52,
                    color: Colors.redAccent,
                    height: 0.9,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Huwag sumuko, Explorer! Gamitin muli ang iyong mapa ng Pilipinas sa Asya upang matutuhan ang mga direksyon at karatig-lugar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 14.5,
                    color: Colors.white.withValues(alpha: 0.90),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '⭐ Naipong Puntos: $score',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                  ),
                ),
                const SizedBox(height: 18),
                _HoverContinueButton(
                  label: 'ULITIN ANG HAMON',
                  onTap: onRetry,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    AudioManager.instance.playClick();
                    onExitToMenu();
                  },
                  child: Text(
                    'BUMALIK SA MENU',
                    style: TextStyle(
                      fontFamily: 'Jomhuria',
                      fontSize: isCompact ? 24 : 28,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mission Complete celebration dialog matching Section 15 of user specification.
class _MissionCompleteDialog extends StatelessWidget {
  const _MissionCompleteDialog({
    required this.score,
    required this.coins,
    required this.completedMissions,
    required this.totalMissions,
    required this.onReplay,
    required this.onViewMap,
    required this.onExitToMenu,
  });

  final int score;
  final int coins;
  final int completedMissions;
  final int totalMissions;
  final VoidCallback onReplay;
  final VoidCallback onViewMap;
  final VoidCallback onExitToMenu;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 32,
        vertical: 24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 580,
              maxHeight: screen.height * 0.90,
            ),
            padding: EdgeInsets.fromLTRB(
              isCompact ? 18 : 28,
              isCompact ? 18 : 24,
              isCompact ? 18 : 28,
              isCompact ? 16 : 22,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF091742).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.85),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 4),
                  Text(
                    'MISSION COMPLETE!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Jomhuria',
                      fontSize: isCompact ? 46 : 58,
                      color: Colors.amberAccent,
                      height: 0.85,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'CONGRATULATIONS, EXPLORER!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“Nagamit mo ang iyong kaalaman sa mapa upang matukoy ang lokasyon ng Pilipinas sa Asya.”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 12.5 : 14,
                      color: Colors.white.withValues(alpha: 0.90),
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Results Summary Grid
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ResultStat(
                          icon: '🏆',
                          title: 'SCORE',
                          value: '$score Puntos',
                          color: Colors.amberAccent,
                          isCompact: isCompact,
                        ),
                        Container(width: 1, height: 36, color: Colors.white24),
                        _ResultStat(
                          icon: '⭐',
                          title: 'PERFORMANCE',
                          value: '$completedMissions / $totalMissions',
                          color: const Color(0xFF64B5F6),
                          isCompact: isCompact,
                        ),
                        Container(width: 1, height: 36, color: Colors.white24),
                        _ResultStat(
                          icon: '🪙',
                          title: 'REWARDS',
                          value: '+$coins Barya',
                          color: Colors.orangeAccent,
                          isCompact: isCompact,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Badges Earned Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '🏅 MGA NAKAMIT NA BADGE:',
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final badge in GameMissionRegistry.availableBadges)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.60),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(badge.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    badge.title,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    badge.subtitle,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: Colors.white.withValues(alpha: 0.70),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  _HoverContinueButton(
                    label: 'ULITIN ANG HAMON',
                    onTap: onReplay,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          AudioManager.instance.playClick();
                          onViewMap();
                        },
                        child: Text(
                          'BUMALIK SA GAME MAP',
                          style: TextStyle(
                            fontFamily: 'Jomhuria',
                            fontSize: isCompact ? 22 : 26,
                            color: const Color(0xFF64B5F6),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {
                          AudioManager.instance.playClick();
                          onExitToMenu();
                        },
                        child: Text(
                          'BUMALIK SA MENU',
                          style: TextStyle(
                            fontFamily: 'Jomhuria',
                            fontSize: isCompact ? 22 : 26,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isCompact,
  });

  final String icon;
  final String title;
  final String value;
  final Color color;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: isCompact ? 16 : 18)),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: isCompact ? 9 : 10,
            color: Colors.white60,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isCompact ? 11.5 : 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Top HUD Header for Coordinate Quest Mode.
class _CoordinateQuestHudHeader extends StatelessWidget {
  const _CoordinateQuestHudHeader({
    super.key,
    required this.unlockedCount,
    required this.totalCount,
    required this.isCompact,
    required this.onReset,
  });

  final int unlockedCount;
  final int totalCount;
  final bool isCompact;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 18,
            vertical: isCompact ? 5 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1950).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.70),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompact) ...[
                const Text(
                  'COORDINATE QUEST',
                  style: TextStyle(
                    fontFamily: 'Jomhuria',
                    fontSize: 28,
                    color: Color(0xFF00E5FF),
                    height: 0.9,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 18,
                  color: Colors.white24,
                ),
              ],
              Text(
                'Punto: $unlockedCount / $totalCount',
                style: TextStyle(
                  fontSize: isCompact ? 11.5 : 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Simulan Muli',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    AudioManager.instance.playClick();
                    onReset();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom glassmorphic panel for Coordinate Quest mode asking latitude & longitude questions.
class _CoordinateQuestPanel extends StatefulWidget {
  const _CoordinateQuestPanel({
    super.key,
    required this.unlockedIds,
    required this.allLocations,
    required this.isCompact,
    required this.onCorrectAnswer,
    required this.onResetProgress,
  });

  final Set<String> unlockedIds;
  final List<MapLocation> allLocations;
  final bool isCompact;
  final ValueChanged<MapLocation> onCorrectAnswer;
  final VoidCallback onResetProgress;

  @override
  State<_CoordinateQuestPanel> createState() => _CoordinateQuestPanelState();
}

class _CoordinateQuestPanelState extends State<_CoordinateQuestPanel> {
  int? _selectedOptionIndex;
  bool? _isCorrect;
  String? _feedbackMessage;

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.isCompact;
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width > 700 ? 630.0 : screen.width * 0.94;
    final maxHeight = screen.height * (isCompact ? 0.48 : 0.44);

    final lockedLocations = widget.allLocations
        .where((loc) => !widget.unlockedIds.contains(loc.id))
        .toList();

    // If all locations unlocked, show completion celebration
    if (lockedLocations.isEmpty) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.all(isCompact ? 16 : 22),
              decoration: BoxDecoration(
                color: const Color(0xFF07123A).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.75),
                  width: 1.8,
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 4),
                    Text(
                      'NABUKSAN ANG LAHAT NG PUNTO!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Jomhuria',
                        fontSize: isCompact ? 30 : 38,
                        color: const Color(0xFF00E676),
                        height: 0.85,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tagumpay mong natukoy ang lahat ng mga lokasyon gamit ang latitud at longhitud! Malaya mo nang magagalugad ang buong mapa o simulan muli ang paghahanap.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 13.5,
                        color: Colors.white.withValues(alpha: 0.90),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        widget.onResetProgress();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xFF07123A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'SIMULAN MULI ANG PAGHAHANAP',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final targetLocation = lockedLocations.first;

    // Generate 3 choices (1 target + 2 distractors deterministic by target.id)
    final otherLocations = widget.allLocations
        .where((l) => l.id != targetLocation.id)
        .toList();
    otherLocations.shuffle(math.Random(targetLocation.id.hashCode));
    final options = [
      targetLocation,
      otherLocations[0],
      otherLocations[1],
    ];
    options.shuffle(math.Random(targetLocation.id.hashCode + 1));

    final isWater = targetLocation.geoCategory == GeoCategory.insular &&
        (targetLocation.id.contains('sea') || targetLocation.id.contains('ocean'));
    final questionPrompt = isWater
        ? 'Anong anyong tubig ang matatagpuan sa koordinadang:'
        : 'Aling bansa o pulo ang matatagpuan sa koordinadang:';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 16 : 22,
              isCompact ? 12 : 16,
              isCompact ? 16 : 22,
              isCompact ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF07123A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.75),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.25),
                  blurRadius: 26,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.60),
                  blurRadius: 30,
                  spreadRadius: 3,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Row: Mode tag & Unlocked count
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 9 : 11,
                          vertical: isCompact ? 3.5 : 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: const Color(0xFF00E676).withValues(alpha: 0.60),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'COORDINATE QUEST',
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E676),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Punto: ${widget.unlockedIds.length} / ${widget.allLocations.length} Nabuksan',
                          style: TextStyle(
                            fontSize: isCompact ? 12 : 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Prompt
                  Text(
                    questionPrompt,
                    style: TextStyle(
                      fontSize: isCompact ? 13.5 : 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Big Glowing Coordinates Banner
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 16,
                      vertical: isCompact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.60),
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_searching_rounded,
                          color: Color(0xFF00E5FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            targetLocation.coordinates,
                            style: TextStyle(
                              fontSize: isCompact ? 14.5 : 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00E5FF),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3 Choice Buttons
                  for (int i = 0; i < options.length; i++) ...[
                    Builder(builder: (context) {
                      final optionLoc = options[i];
                      final isSelected = _selectedOptionIndex == i;
                      final isTarget = optionLoc.id == targetLocation.id;

                      Color btnBorder = Colors.white24;
                      Color btnBg = Colors.white.withValues(alpha: 0.08);
                      Color btnText = Colors.white;

                      if (isSelected && _isCorrect == true) {
                        btnBorder = const Color(0xFF00E676);
                        btnBg = const Color(0xFF00E676).withValues(alpha: 0.25);
                      } else if (isSelected && _isCorrect == false) {
                        btnBorder = const Color(0xFFFF5252);
                        btnBg = const Color(0xFFFF5252).withValues(alpha: 0.25);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        child: Material(
                          color: btnBg,
                          borderRadius: BorderRadius.circular(11),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(11),
                            onTap: () {
                              AudioManager.instance.playClick();
                              setState(() {
                                _selectedOptionIndex = i;
                                _isCorrect = isTarget;
                                if (isTarget) {
                                  _feedbackMessage = 'Tumpak! Nabuksan mo ang ${targetLocation.title}!';
                                } else {
                                  _feedbackMessage =
                                      'Maling sagot! Subukang muli. Pahiwatig: Ito ay matatagpuan sa ${targetLocation.category}.';
                                }
                              });
                              if (isTarget) {
                                AudioManager.instance.playCorrect();
                                widget.onCorrectAnswer(targetLocation);
                                Future.delayed(const Duration(milliseconds: 1400), () {
                                  if (mounted) {
                                    setState(() {
                                      _selectedOptionIndex = null;
                                      _isCorrect = null;
                                      _feedbackMessage = null;
                                    });
                                  }
                                });
                              } else {
                                AudioManager.instance.playWrong();
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 12 : 16,
                                vertical: isCompact ? 9 : 11,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: btnBorder, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${String.fromCharCode(65 + i)}.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: btnText,
                                      fontSize: isCompact ? 13 : 14.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      optionLoc.title,
                                      style: TextStyle(
                                        color: btnText,
                                        fontSize: isCompact ? 13 : 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isSelected && _isCorrect == true)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF00E676), size: 18)
                                  else if (isSelected && _isCorrect == false)
                                    const Icon(Icons.cancel_rounded,
                                        color: Color(0xFFFF5252), size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  // Feedback Message
                  if (_feedbackMessage != null) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCorrect == true
                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
                            : const Color(0xFFFF5252).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _feedbackMessage!,
                        style: TextStyle(
                          fontSize: isCompact ? 11.5 : 12.5,
                          fontWeight: FontWeight.w600,
                          color: _isCorrect == true
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFF8A80),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// In-map drifting clouds layer with directional soft shadows and pin-proximity 50% transparency.
class _MapDriftingCloudsLayer extends StatefulWidget {
  const _MapDriftingCloudsLayer({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.pinPositions,
  });

  final double canvasWidth;
  final double canvasHeight;
  final List<Offset> pinPositions;

  @override
  State<_MapDriftingCloudsLayer> createState() => _MapDriftingCloudsLayerState();
}

class _MapDriftingCloudsLayerState extends State<_MapDriftingCloudsLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cloudController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 70),
  )..repeat();

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cloudController,
      builder: (context, _) {
        final t = _cloudController.value;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Render all cloud shadows first (so shadows always sit below clouds)
            for (final cloud in _mapClouds)
              _buildSingleCloudShadow(cloud, t),

            // Render all clouds on top of shadows and map
            for (final cloud in _mapClouds)
              _buildSingleCloud(cloud, t),
          ],
        );
      },
    );
  }

  bool _isCloudOverPin(double x, double y, double width) {
    final height = width * 0.55;
    // Bounding box with generous buffer so the fade triggers smoothly
    final cloudRect = Rect.fromLTWH(x - 14, y - 14, width + 28, height + 28);
    for (final pin in widget.pinPositions) {
      if (cloudRect.contains(pin)) return true;
    }
    return false;
  }

  Widget _buildSingleCloudShadow(_MapCloudData cloud, double t) {
    final progress = (cloud.initialProgress + t * cloud.loopsPerCycle) % 1.0;
    final totalDistance = widget.canvasWidth + cloud.width;
    final x = -cloud.width + progress * totalDistance;

    final bob = math.sin(t * 2 * math.pi * cloud.bobSpeed + cloud.bobPhase) *
        cloud.bobAmplitude;
    final y = (widget.canvasHeight * cloud.yFraction) + bob;

    final isOverPin = _isCloudOverPin(x, y, cloud.width);
    final shadowOpacity = isOverPin ? 0.20 : 0.40;

    return Positioned(
      left: x + 10,
      top: y + 14,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: shadowOpacity,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
          child: Transform.scale(
            scaleX: cloud.flipX ? -1.0 : 1.0,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0x55000000),
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/images/clouds',
                width: cloud.width,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/clouds.png',
                  width: cloud.width,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleCloud(_MapCloudData cloud, double t) {
    final progress = (cloud.initialProgress + t * cloud.loopsPerCycle) % 1.0;
    final totalDistance = widget.canvasWidth + cloud.width;
    final x = -cloud.width + progress * totalDistance;

    final bob = math.sin(t * 2 * math.pi * cloud.bobSpeed + cloud.bobPhase) *
        cloud.bobAmplitude;
    final y = (widget.canvasHeight * cloud.yFraction) + bob;

    final isOverPin = _isCloudOverPin(x, y, cloud.width);
    // 50% opacity when passing through a pin, 100% solid opacity otherwise
    final cloudOpacity = isOverPin ? 0.50 : 1.0;

    return Positioned(
      left: x,
      top: y,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: cloudOpacity,
        child: Transform.scale(
          scaleX: cloud.flipX ? -1.0 : 1.0,
          child: Image.asset(
            'assets/images/clouds',
            width: cloud.width,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/clouds.png',
              width: cloud.width,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// Specifications for an individual in-map drifting cloud.
class _MapCloudData {
  final double initialProgress;
  final int loopsPerCycle;
  final double yFraction;
  final double width;
  final double bobAmplitude;
  final double bobSpeed;
  final double bobPhase;
  final bool flipX;

  const _MapCloudData({
    required this.initialProgress,
    required this.loopsPerCycle,
    required this.yFraction,
    required this.width,
    this.bobAmplitude = 4.5,
    this.bobSpeed = 1.8,
    this.bobPhase = 0.0,
    this.flipX = false,
  });
}

/// 5 small, proportionate drifting clouds across the 1024 x 1536 map canvas.
const List<_MapCloudData> _mapClouds = [
  _MapCloudData(
    initialProgress: 0.12,
    loopsPerCycle: 2,
    yFraction: 0.14,
    width: 85.0,
    bobAmplitude: 4.0,
    bobSpeed: 1.8,
    bobPhase: 0.5,
    flipX: false,
  ),
  _MapCloudData(
    initialProgress: 0.68,
    loopsPerCycle: 1,
    yFraction: 0.32,
    width: 105.0,
    bobAmplitude: 5.0,
    bobSpeed: 1.4,
    bobPhase: 1.8,
    flipX: true,
  ),
  _MapCloudData(
    initialProgress: 0.34,
    loopsPerCycle: 2,
    yFraction: 0.52,
    width: 90.0,
    bobAmplitude: 4.5,
    bobSpeed: 2.1,
    bobPhase: 3.2,
    flipX: false,
  ),
  _MapCloudData(
    initialProgress: 0.84,
    loopsPerCycle: 1,
    yFraction: 0.70,
    width: 110.0,
    bobAmplitude: 5.5,
    bobSpeed: 1.2,
    bobPhase: 4.5,
    flipX: true,
  ),
  _MapCloudData(
    initialProgress: 0.48,
    loopsPerCycle: 2,
    yFraction: 0.86,
    width: 80.0,
    bobAmplitude: 4.0,
    bobSpeed: 1.9,
    bobPhase: 2.0,
    flipX: false,
  ),
];
