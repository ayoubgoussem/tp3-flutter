import 'package:flutter/material.dart';
import 'package:tp3_flutter/data/models/question_model.dart';
import 'package:tp3_flutter/data/repositories/quiz_repository.dart';
import 'add_question_screen.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  final _repository = QuizRepository();
  String? _selectedThemeFilter;
  List<String> _themes = [];
  bool _isLoadingThemes = true;

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    try {
      final themes = await _repository.getAllThemes();
      setState(() {
        _themes = ['Toutes', ...themes];
        _selectedThemeFilter = _themes.first;
        _isLoadingThemes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingThemes = false;
      });
    }
  }

  Future<void> _deleteQuestion(QuestionModel question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cette question ?\n\n"${question.text}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final id = question.id;
      if (id == null || id.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : ID de question invalide'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      try {
        await _repository.deleteQuestion(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editQuestion(QuestionModel question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuestionScreen(questionToEdit: question),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les Questions'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
        children: [
          // Filter dropdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoadingThemes
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    initialValue: _selectedThemeFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filtrer par thématique',
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: _themes.map((theme) {
                      return DropdownMenuItem(
                        value: theme,
                        child: Text(theme),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedThemeFilter = value;
                      });
                    },
                  ),
          ),

          // Questions list
          Expanded(
            child: StreamBuilder<List<QuestionModel>>(
              stream: _selectedThemeFilter == 'Toutes'
                  ? _repository.streamQuestionsByTheme('')
                  : _repository.streamQuestionsByTheme(_selectedThemeFilter ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur de chargement',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final questions = snapshot.data ?? [];
                
                // Filter questions
                final filteredQuestions = _selectedThemeFilter == 'Toutes'
                    ? questions
                    : questions.where((q) => q.theme == _selectedThemeFilter).toList();

                if (filteredQuestions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune question',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedThemeFilter == 'Toutes'
                              ? 'Ajoutez votre première question'
                              : 'Aucune question dans cette thématique',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredQuestions.length,
                  itemBuilder: (context, index) {
                    final question = filteredQuestions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: question.isCorrect
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            question.isCorrect ? Icons.check : Icons.close,
                            color: question.isCorrect
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                        title: Text(
                          question.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(question.theme),
                            if (question.imagePath.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.image,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: theme.colorScheme.primary,
                              onPressed: () => _editQuestion(question),
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: theme.colorScheme.error,
                              onPressed: () => _deleteQuestion(question),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
