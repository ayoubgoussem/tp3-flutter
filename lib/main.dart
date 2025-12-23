import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'business_logic/providers/quiz_provider.dart';
import 'business_logic/providers/auth_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/sign_in_screen.dart';
import 'firebase_options.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'TP3 - Quiz Firebase',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // Show loading screen while checking auth state
            if (auth.isInitializing) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Navigate based on auth state
            if (auth.isAuthenticated) {
              return const HomeScreen();
            } else {
              return const SignInScreen();
            }
          },
        ),
      ),
    );
  }
}
