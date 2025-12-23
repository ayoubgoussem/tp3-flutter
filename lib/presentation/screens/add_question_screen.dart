import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../business_logic/providers/quiz_provider.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/quiz_repository.dart';

class AddQuestionScreen extends StatefulWidget {
  final QuestionModel? questionToEdit;
  
  const AddQuestionScreen({super.key, this.questionToEdit});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _newThemeController = TextEditingController();
  
  bool _isCorrect = true;
  bool _isSubmitting = false;
  
  List<String> _existingThemes = [];
  String? _selectedTheme;
  bool _isLoadingThemes = true;
  
  // Special value for "Add new theme" option
  static const String _addNewThemeValue = '__ADD_NEW__';
  
  // Image upload
  Uint8List? _imageBytes;
  String? _imageFileName;

  @override
  void initState() {
    super.initState();
    _loadExistingThemes();
    
    // If editing existing question, pre-fill form
    if (widget.questionToEdit != null) {
      final question = widget.questionToEdit!;
      _questionController.text = question.text;
      _isCorrect = question.isCorrect;
      _selectedTheme = question.theme;
      // Note: image path from Firebase will be displayed as existing
      if (question.imagePath.isNotEmpty) {
        // We could optionally download and show the existing image
      }
    }
  }

  Future<void> _loadExistingThemes() async {
    final provider = context.read<QuizProvider>();
    try {
      final themes = await provider.getAllThemes();
      setState(() {
        _existingThemes = themes;
        _isLoadingThemes = false;
        // Only set default theme if not already set (e.g., when editing)
        if (_selectedTheme == null && themes.isNotEmpty) {
          _selectedTheme = themes.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingThemes = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _imageBytes = file.bytes;
          _imageFileName = file.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de sélection d\'image: $e')),
      );
    }
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate theme selection
    String? themeName;
    if (_selectedTheme == _addNewThemeValue) {
      themeName = _newThemeController.text.trim();
      if (themeName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer un nom de thématique')),
        );
        return;
      }
    } else {
      themeName = _selectedTheme;
      if (themeName == null || themeName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une thématique')),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    String? imageUrl;

    // Upload image if selected
    if (_imageBytes != null && _imageFileName != null) {
      final repository = QuizRepository();
      final uploadedUrl = await repository.uploadQuestionImage(
        _imageBytes!,
        '${DateTime.now().millisecondsSinceEpoch}_$_imageFileName',
      );

      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'upload de l\'image'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    final question = QuestionModel(
      id: widget.questionToEdit?.id ?? '',
      text: _questionController.text.trim(),
      isCorrect: _isCorrect,
      imagePath: imageUrl ?? widget.questionToEdit?.imagePath ?? '',
      theme: themeName,
    );

    final provider = context.read<QuizProvider>();
    final bool success;
    
    if (widget.questionToEdit != null) {
      // Update existing question
      success = await provider.updateQuestion(question);
    } else {
      // Add new question
      success = await provider.addQuestion(question);
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.questionToEdit != null
              ? 'Question modifiée avec succès!'
              : 'Question ajoutée avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // If editing, go back after success
      if (widget.questionToEdit != null) {
        Navigator.pop(context);
        return;
      }
      
      // Clear form
      _questionController.clear();
      _newThemeController.clear();
      setState(() {
        _isCorrect = true;
        _imageBytes = null;
        _imageFileName = null;
        // Reset to first theme after successful add
        if (_existingThemes.isNotEmpty) {
          _selectedTheme = _existingThemes.first;
        }
      });
      
      // TOUJOURS recharger les thèmes pour voir les nouveaux
      await _loadExistingThemes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _newThemeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter une Question"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.questionToEdit != null
                        ? 'Modifier la Question'
                        : 'Nouvelle Question',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Question text
                  TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      labelText: 'Question',
                      hintText: 'Entrez votre question ici',
                      prefixIcon: Icon(Icons.question_answer),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer une question';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Theme selection
                  Text(
                    'Thématique',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  if (_isLoadingThemes)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTheme,
                      decoration: const InputDecoration(
                        labelText: 'Sélectionner une thématique',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: [
                        // First option: Add new theme
                        const DropdownMenuItem(
                          value: _addNewThemeValue,
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Ajouter nouvelle thématique...'),
                            ],
                          ),
                        ),
                        // Then existing themes
                        ..._existingThemes.map((theme) {
                          return DropdownMenuItem(
                            value: theme,
                            child: Text(theme),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTheme = value;
                        });
                      },
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Show text field if "Add new" is selected
                  if (_selectedTheme == _addNewThemeValue) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newThemeController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la nouvelle thématique',
                        hintText: 'Ex: histoire, sciences...',
                        prefixIcon: Icon(Icons.new_label),
                      ),
                      validator: (value) {
                        if (_selectedTheme == _addNewThemeValue && (value == null || value.trim().isEmpty)) {
                          return 'Veuillez entrer le nom de la thématique';
                        }
                        return null;
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Image picker
                  Text(
                    'Image (optionnel)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_imageFileName ?? 'Choisir une image'),
                  ),
                  
                  if (_imageBytes != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageBytes = null;
                          _imageFileName = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Retirer l\'image'),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Correct answer selector
                  Text(
                    'Réponse correcte',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _isCorrect = true;
                            });
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _isCorrect 
                                ? Colors.green.shade600 
                                : theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: _isCorrect 
                                ? Colors.white 
                                : theme.colorScheme.onSurface,
                          ),
                          icon: Icon(_isCorrect ? Icons.check_circle : Icons.check),
                          label: const Text('VRAI'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _isCorrect = false;
                            });
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: !_isCorrect 
                                ? Colors.red.shade600 
                                : theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: !_isCorrect 
                                ? Colors.white 
                                : theme.colorScheme.onSurface,
                          ),
                          icon: Icon(!_isCorrect ? Icons.cancel : Icons.close),
                          label: const Text('FAUX'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit button
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submitQuestion,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Ajouter la Question',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }
}
