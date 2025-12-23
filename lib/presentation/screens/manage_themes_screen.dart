import 'package:flutter/material.dart';
import 'package:tp3_flutter/data/repositories/quiz_repository.dart';

class ManageThemesScreen extends StatefulWidget {
  const ManageThemesScreen({super.key});

  @override
  State<ManageThemesScreen> createState() => _ManageThemesScreenState();
}

class _ManageThemesScreenState extends State<ManageThemesScreen> {
  final _repository = QuizRepository();

  Future<void> _renameTheme(String oldName, int questionCount) async {
    final controller = TextEditingController(text: oldName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer la thématique'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nouveau nom',
            hintText: 'Entrez le nouveau nom',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && text != oldName) {
                Navigator.pop(context, text);
              }
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );

    // Dispose controller after dialog closes
    controller.dispose();

    if (newName != null) {
      try {
        await _repository.renameTheme(oldName, newName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thématique renommée : "$oldName" → "$newName"'),
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

  Future<void> _deleteTheme(String themeName, int questionCount) async {
    if (questionCount > 0) {
      // Block deletion if questions exist
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.warning_amber, size: 64, color: Colors.orange.shade600),
          title: const Text('Impossible de supprimer'),
          content: Text(
            'Cette thématique contient $questionCount question(s).\n\n'
            'Veuillez d\'abord supprimer toutes les questions de cette thématique.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la thématique "$themeName" ?'),
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
      try {
        await _repository.deleteTheme(themeName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thématique supprimée avec succès'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les Thématiques'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<Map<String, int>>(
        stream: _repository.streamThemesWithCount(),
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

          final themesWithCount = snapshot.data ?? {};

          if (themesWithCount.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune thématique',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des questions pour créer des thématiques',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final sortedThemes = themesWithCount.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedThemes.length,
            itemBuilder: (context, index) {
              final entry = sortedThemes[index];
              final themeName = entry.key;
              final questionCount = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.category,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(themeName),
                  subtitle: Text(
                    '$questionCount question${questionCount > 1 ? 's' : ''}',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: theme.colorScheme.primary,
                        onPressed: () => _renameTheme(themeName, questionCount),
                        tooltip: 'Renommer',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: questionCount > 0
                            ? theme.colorScheme.outline
                            : theme.colorScheme.error,
                        onPressed: () => _deleteTheme(themeName, questionCount),
                        tooltip: questionCount > 0
                            ? 'Impossible (contient des questions)'
                            : 'Supprimer',
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
      ),
    );
  }
}
