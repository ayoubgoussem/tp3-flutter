import 'package:flutter/material.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/audio_service.dart';
import '../../data/repositories/score_repository.dart';
import '../../data/models/score_model.dart';
import 'package:provider/provider.dart';
import '../../business_logic/providers/quiz_provider.dart';
import '../../business_logic/providers/auth_provider.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _playResultSound();
    
    // Log the score to Analytics and save to Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final quizProvider = context.read<QuizProvider>();
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      
      // Log to Analytics
      AnalyticsService.logScore(
        quizProvider.correctAnswersCount,
        quizProvider.selectedTheme,
      );
      
      // Save score to Firestore if user is logged in
      if (user != null) {
        try {
          final score = ScoreModel(
            id: '',
            userId: user.uid,
            userName: user.displayName ?? user.email.split('@')[0],
            theme: quizProvider.selectedTheme,
            correctAnswers: quizProvider.correctAnswersCount,
            totalQuestions: quizProvider.questions.length,
            completedAt: DateTime.now(),
          );
          
          await ScoreRepository().saveScore(score);
        } catch (e) {
          // Silent fail - don't interrupt user experience
          debugPrint('Failed to save score: $e');
        }
      }
    });
  }

  void _playResultSound() async {
    // Get quiz results from provider
    final provider = context.read<QuizProvider>();
    final correctCount = provider.correctAnswersCount;
    final totalQuestions = provider.questions.length;
    
    if (totalQuestions == 0) return;

    // Preload sounds
    await _audioService.preloadSounds();

    // Calculate score percentage
    final scorePercentage = (correctCount / totalQuestions) * 100;

    // Play victory or defeat sound
    if (scorePercentage >= 50) {
      _audioService.playVictory();
    } else {
      _audioService.playDefeat();
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        final questions = provider.questions;
        final results = provider.userResults;
        final correctCount = provider.correctAnswersCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Récapitulatif"),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       // Score Card avec fond coloré
                      Card(
                        color: colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          child: Column(
                            children: [
                              Text(
                                "Score Final",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$correctCount / ${questions.length}",
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Titre détail des réponses
                      Text(
                        "Détail des réponses",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Liste des réponses
                      if (questions.isNotEmpty && results.isNotEmpty)
                        ...List.generate(questions.length, (i) {
                          if (i >= results.length) return const SizedBox.shrink();
                          final isGood = results[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isGood 
                                    ? Colors.green.shade100 
                                    : Colors.red.shade100,
                                child: Icon(
                                  isGood ? Icons.check : Icons.close,
                                  color: isGood 
                                      ? Colors.green.shade800 
                                      : Colors.red.shade800,
                                ),
                              ),
                              title: Text(
                                questions[i].text,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                        }),
                      
                      const SizedBox(height: 24),
                      
                      // Bouton retour à l'accueil
                      FilledButton.icon(
                        onPressed: () {
                          provider.resetQuiz();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.home),
                        label: const Text("Retour à l'accueil"),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Bouton recommencer
                      OutlinedButton.icon(
                        onPressed: () {
                          provider.resetQuiz();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Recommencer"),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
