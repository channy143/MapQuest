import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// Service that manages ambient background music across the entire app.
class AudioManager with WidgetsBindingObserver {
  AudioManager._() {
    _initAudioContext();
    WidgetsBinding.instance.addObserver(this);
  }

  static AudioManager instance = AudioManager._();

  static final AudioContext _sfxAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  static final AudioContext _musicAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  void _initAudioContext() {
    try {
      AudioPlayer.global.setAudioContext(_musicAudioContext);
    } catch (e) {
      debugPrint('AudioManager global context init error: $e');
    }
  }

  bool _wasPlayingBeforePause = false;
  bool _isAppInBackground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _isAppInBackground = true;
      if (_isPlaying) {
        _wasPlayingBeforePause = true;
        _player?.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      _isAppInBackground = false;
      if (_wasPlayingBeforePause && !_isMuted) {
        _wasPlayingBeforePause = false;
        _player?.resume();
      }
    }
  }

  AudioPlayer? _player;
  AudioPlayer get player {
    if (_player == null) {
      final p = AudioPlayer();
      p.setAudioContext(_musicAudioContext);
      _player = p;
    }
    return _player!;
  }

  AudioPlayer? _clickPlayer;
  AudioPlayer get clickPlayer {
    if (_clickPlayer == null) {
      final p = AudioPlayer();
      p.setAudioContext(_sfxAudioContext);
      _clickPlayer = p;
    }
    return _clickPlayer!;
  }

  AudioPlayer? _correctPlayer;
  AudioPlayer get correctPlayer {
    if (_correctPlayer == null) {
      final p = AudioPlayer();
      p.setAudioContext(_sfxAudioContext);
      _correctPlayer = p;
    }
    return _correctPlayer!;
  }

  AudioPlayer? _wrongPlayer;
  AudioPlayer get wrongPlayer {
    if (_wrongPlayer == null) {
      final p = AudioPlayer();
      p.setAudioContext(_sfxAudioContext);
      _wrongPlayer = p;
    }
    return _wrongPlayer!;
  }

  bool _isMuted = false;
  bool _isPlaying = false;
  double _musicVolume = 0.4;
  double _soundVolume = 0.8;

  final ValueNotifier<bool> isMutedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> musicVolumeNotifier = ValueNotifier<double>(0.4);
  final ValueNotifier<double> soundVolumeNotifier = ValueNotifier<double>(0.8);

  bool get isMuted => _isMuted;
  bool get isPlaying => _isPlaying;
  double get musicVolume => _musicVolume;
  double get soundVolume => _soundVolume;
  double get volume => _musicVolume;

  /// Starts background music looping continuously.
  Future<void> startBackgroundMusic() async {
    if (_isPlaying) return;

    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_isMuted ? 0.0 : _musicVolume);
      await player.play(AssetSource('music/bg-music.mp3'));
      _isPlaying = true;
    } catch (e) {
      debugPrint('AudioManager: Auto-play might be restricted by browser until user gesture: $e');
    }
  }

  /// Called on user gesture (tap/click) to trigger audio if web autoplay was prevented.
  Future<void> handleUserInteraction() async {
    if (!_isPlaying && !_isMuted) {
      await startBackgroundMusic();
    }
  }

  /// Plays button click sound effect.
  Future<void> playClick() async {
    if (_isMuted || _isAppInBackground) return;
    try {
      final p = clickPlayer;
      await p.stop();
      await p.setVolume(_soundVolume);
      await p.play(AssetSource('music/click.wav'));
    } catch (e) {
      debugPrint('AudioManager playClick error: $e');
    }
  }

  /// Plays correct answer sound effect or victory celebration.
  Future<void> playCorrect() async {
    if (_isMuted || _isAppInBackground) return;
    try {
      final p = correctPlayer;
      await p.stop();
      await p.setVolume(_soundVolume);
      await p.play(AssetSource('music/correct.mp3'));
    } catch (e) {
      debugPrint('AudioManager playCorrect error: $e');
    }
  }

  /// Plays wrong answer sound effect or game failure cue.
  Future<void> playWrong() async {
    if (_isMuted || _isAppInBackground) return;
    try {
      final p = wrongPlayer;
      await p.stop();
      await p.setVolume(_soundVolume);
      await p.play(AssetSource('music/wrong.mp3'));
    } catch (e) {
      debugPrint('AudioManager playWrong error: $e');
    }
  }

  /// Toggles mute state of background music and sound effects.
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    isMutedNotifier.value = _isMuted;

    try {
      if (_isMuted) {
        await _player?.setVolume(0.0);
        await _clickPlayer?.stop();
        await _correctPlayer?.stop();
        await _wrongPlayer?.stop();
      } else {
        await _player?.setVolume(_musicVolume);
        if (!_isPlaying) {
          await startBackgroundMusic();
        }
      }
    } catch (e) {
      debugPrint('AudioManager toggleMute error: $e');
    }
  }

  /// Sets music volume (0.0 to 1.0).
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    musicVolumeNotifier.value = _musicVolume;
    if (!_isMuted) {
      await _player?.setVolume(_musicVolume);
    }
  }

  /// Sets sound effects volume (0.0 to 1.0).
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    soundVolumeNotifier.value = _soundVolume;
  }

  /// Sets audio volume (backward compatibility, sets music volume).
  Future<void> setVolume(double volume) async {
    await setMusicVolume(volume);
  }

  /// Pauses the background music.
  Future<void> pause() async {
    try {
      await _player?.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('AudioManager pause error: $e');
    }
  }

  /// Resumes the background music.
  Future<void> resume() async {
    if (_isMuted) return;
    try {
      await _player?.resume();
      _isPlaying = true;
    } catch (e) {
      debugPrint('AudioManager resume error: $e');
    }
  }

  /// Disposes of all audio players.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player?.dispose();
    _player = null;
    _clickPlayer?.dispose();
    _clickPlayer = null;
    _correctPlayer?.dispose();
    _correctPlayer = null;
    _wrongPlayer?.dispose();
    _wrongPlayer = null;
  }
}
