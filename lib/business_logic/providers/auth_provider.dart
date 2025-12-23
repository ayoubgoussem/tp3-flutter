import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/admin_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((UserModel? user) async {
      if (user != null) {
        debugPrint('User authenticated: ${user.uid}');
        
        // Load complete user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          // Merge Firestore data with Firebase Auth data
          final firestoreData = userDoc.data() as Map<String, dynamic>;
          debugPrint('Firestore data: $firestoreData');
          
          _currentUser = UserModel(
            uid: user.uid, // Always use Firebase Auth uid
            email: user.email, // Always use Firebase Auth email
            displayName: firestoreData['displayName'] ?? user.displayName,
            photoURL: firestoreData['photoURL'] ?? user.photoURL,
            isAdmin: firestoreData['isAdmin'] ?? false,
            preferredTheme: firestoreData['preferredTheme'],
          );
          debugPrint('User loaded from Firestore: ${_currentUser!.email}, isAdmin: ${_currentUser!.isAdmin}, preferredTheme: ${_currentUser!.preferredTheme}');
        } else {
          // Fallback: check admin status manually if no Firestore doc exists yet
          debugPrint('No Firestore doc found, checking admin status for user: ${user.uid}');
          final isAdmin = await _adminService.isAdmin(user.uid);
          _currentUser = UserModel(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            isAdmin: isAdmin,
          );
          debugPrint('User created from Firebase Auth: ${user.email}, isAdmin: $isAdmin');
        }
        
        // Sync analytics
        AnalyticsService.setPreferredTheme(_currentUser?.preferredTheme);
      } else {
        _currentUser = null;
        debugPrint('User signed out');
      }
      _isInitializing = false;
      _isLoading = false;
      notifyListeners(); // IMPORTANT: notify UI to rebuild
    });
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(email, password);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _error = null;
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  Future<void> updatePreferredTheme(String? theme) async {
    if (_currentUser == null) return;
    try {
      await _authService.updateUserPreferredTheme(_currentUser!.uid, theme);
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        displayName: _currentUser!.displayName,
        photoURL: _currentUser!.photoURL,
        isAdmin: _currentUser!.isAdmin,
        preferredTheme: theme,
      );
      await AnalyticsService.setPreferredTheme(theme);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }


  Future<void> refreshCurrentUser() async {
    try {
      final firebaseUser = _authService.currentFirebaseUser;
      if (firebaseUser != null) {
        await firebaseUser.reload();
        
        // Load complete user data from Firestore (including isAdmin)
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        
        if (userDoc.exists) {
          _currentUser = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        } else {
          _currentUser = UserModel.fromFirebaseUser(_authService.currentFirebaseUser!);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }
}
