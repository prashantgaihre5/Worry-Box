import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Service for playing calming background audio.
///
/// Uses the `audioplayers` package to toggle a looping ambient track.
class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentTrackId;

  bool get isPlaying => _isPlaying;
  String? get currentTrackId => _currentTrackId;

  /// Starts playing a specific track by its URL.
  Future<void> playTrack(String trackId, String url) async {
    try {
      if (_isPlaying && _currentTrackId == trackId) {
        // Just resume if paused, but it should already be playing.
        return;
      }
      
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.5);
      
      // Use AssetSource for local bundle files
      await _player.play(AssetSource(url));
      
      _isPlaying = true;
      _currentTrackId = trackId;
      notifyListeners();
    } catch (e) {
      // Audio playback failure should never crash the app.
      _isPlaying = false;
      _currentTrackId = null;
      notifyListeners();
    }
  }

  /// Stops playback.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
    _currentTrackId = null;
    notifyListeners();
  }

  /// Toggles playback for a specific track.
  Future<void> toggleTrack(String trackId, String url) async {
    if (_isPlaying && _currentTrackId == trackId) {
      await stop();
    } else {
      await playTrack(trackId, url);
    }
  }

  /// Releases resources. Call on app dispose.
  Future<void> dispose() async {
    await _player.dispose();
  }
}
