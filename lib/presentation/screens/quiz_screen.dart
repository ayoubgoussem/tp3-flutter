import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business_logic/providers/quiz_provider.dart';
import 'summary_screen.dart';

class QuizScreen extends StatefulWidget {
  final String? theme;
  const QuizScreen({super.key, this.theme});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.theme != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<QuizProvider>().loadQuestionsByTheme(widget.theme!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.isQuizComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const SummaryScreen(),
              ),
            );
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final question = provider.currentQuestion;
        if (question == null) {
          return const Scaffold(
            body: Center(
              child: Text('Aucune question disponible'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(provider.selectedTheme),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Question ${provider.currentIndex + 1}/${provider.questions.length}",
                          style: themeData.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (question.imagePath.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: question.imagePath.startsWith('http')
                                ? Image.network(
                                    question.imagePath,
                                    height: 150,
                                    fit: BoxFit.contain,
                                    cacheWidth: 300,
                                    cacheHeight: 300,
                                    // No loadingBuilder since images are precached on login
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_not_supported,
                                        size: 150,
                                        color: themeData.colorScheme.error,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    question.imagePath,
                                    height: 150,
                                    fit: BoxFit.contain,
                                    cacheWidth: 300,
                                    cacheHeight: 300,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_not_supported,
                                        size: 150,
                                        color: themeData.colorScheme.secondary,
                                      );
                                    },
                                  ),
                          ),
                        Text(
                          question.text,
                          textAlign: TextAlign.center,
                          style: themeData.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => provider.answerQuestion(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  elevation: 2,
                                  shadowColor: Colors.black.withValues(alpha: 0.25),
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('VRAI'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => provider.answerQuestion(false),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  elevation: 2,
                                  shadowColor: Colors.black.withValues(alpha: 0.25),
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text('FAUX'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
