import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final StorageService _storageService = StorageService();
  
  String? _victoryUrl;
  String? _defeatUrl;

  /// Preload sound URLs from Firebase Storage
  Future<void> preloadSounds() async {
    try {
      _victoryUrl = await _storageService.getSoundUrl('victoire.mp3');
      _defeatUrl = await _storageService.getSoundUrl('perte.mp3');
      debugPrint('Sounds preloaded successfully');
    } catch (e) {
      debugPrint('Warning: Could not preload sounds: $e');
      // Non-blocking: app continues without sounds
    }
  }

  /// Play victory sound
  Future<void> playVictory() async {
    if (_victoryUrl == null) {
      debugPrint('Victory sound URL not loaded');
      return;
    }

    try {
      await _player.play(UrlSource(_victoryUrl!));
      debugPrint('Playing victory sound');
    } catch (e) {
      debugPrint('Error playing victory sound: $e');
    }
  }

  /// Play defeat sound
  Future<void> playDefeat() async {
    if (_defeatUrl == null) {
      debugPrint('Defeat sound URL not loaded');
      return;
    }

    try {
      await _player.play(UrlSource(_defeatUrl!));
      debugPrint('Playing defeat sound');
    } catch (e) {
      debugPrint('Error playing defeat sound: $e');
    }
  }

  /// Stop any currently playing sound
  Future<void> stop() async {
    await _player.stop();
  }

  /// Dispose audio resources
  void dispose() {
    _player.dispose();
  }
}
