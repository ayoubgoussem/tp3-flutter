import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload user avatar to Storage
  /// Returns the download URL
  Future<String> uploadAvatar(String userId, Uint8List imageBytes) async {
    try {
      final ref = _storage.ref().child('avatars/$userId.jpg');
      
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('Avatar uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      throw 'Erreur lors de l\'upload de l\'avatar: $e';
    }
  }

  /// Get avatar URL for a user
  Future<String?> getAvatarUrl(String userId) async {
    try {
      final ref = _storage.ref().child('avatars/$userId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Avatar not found for user $userId');
      return null;
    }
  }

  /// Delete user avatar
  Future<void> deleteAvatar(String userId) async {
    try {
      final ref = _storage.ref().child('avatars/$userId.jpg');
      await ref.delete();
      debugPrint('Avatar deleted for user $userId');
    } catch (e) {
      debugPrint('Error deleting avatar: $e');
      throw 'Erreur lors de la suppression de l\'avatar: $e';
    }
  }

  /// Get sound URL from Storage
  Future<String> getSoundUrl(String soundName) async {
    try {
      final ref = _storage.ref().child('sounds/$soundName');
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Sound not found: $soundName');
      throw 'Son introuvable: $soundName';
    }
  }

  /// Upload sound file (admin only - use Firebase Console instead)
  Future<String> uploadSound(String soundName, Uint8List audioBytes) async {
    try {
      final ref = _storage.ref().child('sounds/$soundName');
      
      final uploadTask = await ref.putData(
        audioBytes,
        SettableMetadata(contentType: 'audio/mpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('Sound uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading sound: $e');
      throw 'Erreur lors de l\'upload du son: $e';
    }
  }
}
