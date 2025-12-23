import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/add_question_screen.dart';
import '../screens/manage_questions_screen.dart';
import '../screens/manage_themes_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/quiz_screen.dart';
import '../../business_logic/providers/auth_provider.dart';
import '../../business_logic/providers/quiz_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load themes when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().getAllThemes();
      
      // Precache all question images after login for better UX
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        _precacheImages();
      }
    });
  }

  // Precache images in background (doesn't block UI)
  void _precacheImages() {
    final quizProvider = context.read<QuizProvider>();
    // Fire and forget - runs in background
    quizProvider.precacheAllQuestionImages(context).then((_) {
      debugPrint('Image precaching complete');
    }).catchError((e) {
      debugPrint('Image precaching error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz App'),
        actions: [
          if (user != null) ...[
            // Favorite theme selector
            Consumer<QuizProvider>(
              builder: (context, quizProvider, _) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.favorite),
                  tooltip: 'Choisir mon thème favori',
                  onSelected: (theme) async {
                    if (theme == '__REMOVE__') {
                      // Remove favorite theme
                      await context.read<AuthProvider>().updatePreferredTheme('');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thème favori retiré'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      // Set favorite theme
                      await context.read<AuthProvider>().updatePreferredTheme(theme);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Thème favori: $theme'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final themes = quizProvider.themes;
                    if (themes.isEmpty) {
                      return [const PopupMenuItem(child: Text('Chargement...'))];
                    }
                    final items = themes.map((themeOption) {
                      final isSelected = user.preferredTheme == themeOption;
                      return PopupMenuItem(
                        value: themeOption,
                        child: Row(
                          children: [
                            if (isSelected)
                              Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
                            if (isSelected) const SizedBox(width: 8),
                            Expanded(child: Text(themeOption)),
                          ],
                        ),
                      );
                    }).toList();
                    
                    // Add "Remove favorite" option if a theme is selected
                    if (user.preferredTheme != null && user.preferredTheme!.isNotEmpty) {
                      items.insert(0, const PopupMenuItem(
                        value: '__REMOVE__',
                        child: Row(
                          children: [
                            Icon(Icons.close, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Retirer le favori', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ));
                      items.insert(1, const PopupMenuItem(
                        enabled: false,
                        child: Divider(height: 1),
                      ));
                    }
                    
                    return items;
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserProfileScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null || user.photoURL!.isEmpty
                        ? Text(
                            user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authProvider.signOut(),
              tooltip: 'Déconnexion',
            ),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.quiz,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user != null)
                        Text(
                          'Bienvenue, ${user.displayName ?? user.email.split('@')[0]}!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        Text(
                          "Bienvenue au Quiz!",
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        "TP3 - Flutter & Firebase",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Testez vos connaissances avec des questions stockées sur Firestore",
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final quizProvider = context.read<QuizProvider>();
                  await quizProvider.loadRandomQuestions(10);
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QuizScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Commencer le Quiz (10 questions)'),
              ),
            ),
            const SizedBox(height: 24),
            
            // Admin-only buttons
            if (user?.isAdmin == true) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddQuestionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une Question'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageQuestionsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Gérer les Questions'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageThemesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.category),
                  label: const Text('Gérer les Thématiques'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                  ),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Tableau de Bord'),
                ),
              ),
            ],
          ],
        ),
          ),
        ),
      ),
      floatingActionButton: user != null ? Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final currentUser = auth.currentUser;
          final hasPreferredTheme = currentUser?.preferredTheme != null && 
                                     currentUser!.preferredTheme!.isNotEmpty;
          
          return FloatingActionButton.extended(
            onPressed: hasPreferredTheme ? () async {
              // Unlocked: Launch quiz with favorite theme
              final quizProvider = context.read<QuizProvider>();
              await quizProvider.loadQuestionsByTheme(currentUser.preferredTheme!);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                );
              }
            } : () {
              // Locked: Show message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Choisissez d\'abord votre thème favori pour débloquer le Mode SHOOT'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: Icon(hasPreferredTheme ? Icons.rocket_launch : Icons.lock),
            label: Text(hasPreferredTheme ? 'Mode SHOOT' : 'Verrouillé'),
            backgroundColor: hasPreferredTheme 
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            foregroundColor: hasPreferredTheme
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurfaceVariant,
            tooltip: hasPreferredTheme 
                ? 'Quiz rapide: ${currentUser.preferredTheme}'
                : 'Débloquez en choisissant un thème favori',
          );
        },
      ) : null,
    );
  }
}
