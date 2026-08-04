import 'package:audioplayers/audioplayers.dart';

/// Service for playing calming background audio.
///
/// Uses the `audioplayers` package to toggle a looping ambient track.
/// The audio file should be placed at `assets/audio/calm.mp3`.
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Toggles the calming audio on/off.
  Future<void> toggle() async {
    if (_isPlaying) {
      await stop();
    } else {
      await play();
    }
  }

  /// Starts playing the calming track on loop.
  Future<void> play() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.5);
      await _player.play(AssetSource('audio/calm.mp3'));
      _isPlaying = true;
    } catch (e) {
      // Audio playback failure should never crash the app.
      _isPlaying = false;
    }
  }

  /// Stops playback.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
  }

  /// Releases resources. Call on app dispose.
  Future<void> dispose() async {
    await _player.dispose();
  }
}
