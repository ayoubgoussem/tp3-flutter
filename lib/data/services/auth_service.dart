import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentFirebaseUser => _auth.currentUser;

  // Auth state changes stream
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map((User? user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user != null
          ? UserModel.fromFirebaseUser(result.user!)
          : null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw 'Une erreur est survenue lors de la connexion';
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await result.user?.updateDisplayName(displayName);
        await result.user?.reload();
      }

      return result.user != null
          ? UserModel.fromFirebaseUser(_auth.currentUser!)
          : null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign up error: $e');
      throw 'Une erreur est survenue lors de l\'inscription';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw 'Erreur lors de la déconnexion';
    }
  }

  // Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'invalid-email':
        return 'Email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'operation-not-allowed':
        return 'Opération non autorisée.';
      default:
        return 'Une erreur est survenue : ${e.message ?? "Erreur inconnue"}';
    }
  }

  Future<void> updateUserPreferredTheme(String uid, String? theme) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await docRef.set({
        'preferredTheme': theme,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating preferred theme: $e');
      rethrow;
    }
  }
}
