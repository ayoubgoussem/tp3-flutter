import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tp3_flutter/data/models/question_model.dart';
import 'package:tp3_flutter/data/repositories/quiz_repository.dart';

class QuizProvider extends ChangeNotifier {
  final QuizRepository _repository = QuizRepository();

  List<QuestionModel> _questions = [];
  final List<bool> _userResults = [];
  List<String> _themes = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _error;
  String _selectedTheme = '';

  // Getters
  List<QuestionModel> get questions => _questions;
  List<bool> get userResults => _userResults;
  List<String> get themes => _themes;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedTheme => _selectedTheme;

  QuestionModel? get currentQuestion {
    if (_currentIndex < _questions.length) {
      return _questions[_currentIndex];
    }
    return null;
  }

  int get correctAnswersCount => _userResults.where((r) => r).length;
  bool get isQuizComplete => _currentIndex >= _questions.length && _questions.isNotEmpty;

  // Load questions for a specific theme
  Future<void> loadQuestionsByTheme(String theme) async {
    _isLoading = true;
    _error = null;
    _selectedTheme = theme;
    notifyListeners();

    try {
      _questions = await _repository.getQuestionsByTheme(theme);
      _questions.shuffle(); // Randomize question order
      _currentIndex = 0;
      _userResults.clear();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load random questions from all themes
  Future<void> loadRandomQuestions(int count) async {
    _isLoading = true;
    _error = null;
    _selectedTheme = 'Mix Aléatoire';
    notifyListeners();

    try {
      _questions = await _repository.getRandomQuestions(count);
      _currentIndex = 0;
      _userResults.clear();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Answer current question
  void answerQuestion(bool userChoice) {
    if (currentQuestion == null) return;

    final isCorrect = userChoice == currentQuestion!.isCorrect;
    _userResults.add(isCorrect);

    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
    } else {
      _currentIndex = _questions.length; // Mark as complete
    }
    notifyListeners();
  }

  // Reset quiz
  void resetQuiz() {
    _currentIndex = 0;
    _userResults.clear();
    notifyListeners();
  }

  // Get all themes
  Future<List<String>> getAllThemes() async {
    try {
      _themes = await _repository.getAllThemes();
      notifyListeners();
      return _themes;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Add a new question
  Future<bool> addQuestion(QuestionModel question) async {
    try {
      await _repository.addQuestion(question);
      // Reload questions if we're on the same theme
      if (_selectedTheme == question.theme) {
        await loadQuestionsByTheme(_selectedTheme);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateQuestion(QuestionModel question) async {
    try {
      await _repository.updateQuestion(question);
      // Reload questions if we're on the same theme
      if (_selectedTheme == question.theme) {
        await loadQuestionsByTheme(_selectedTheme);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Precache all question images for better UX
  Future<void> precacheAllQuestionImages(BuildContext? context) async {
    try {
      debugPrint('Starting to precache question images...');
      
      // Get all questions (increased limit to ensure we get all)
      final allQuestions = await _repository.getRandomQuestions(10000);
      
      debugPrint('Total questions in database: ${allQuestions.length}');
      
      // Filter questions with network images
      final questionsWithImages = allQuestions
          .where((q) => q.imagePath.isNotEmpty && q.imagePath.startsWith('http'))
          .toList();
      
      debugPrint('Found ${questionsWithImages.length} questions with network images');
      
      // Precache each image using a more robust method
      int successCount = 0;
      for (var i = 0; i < questionsWithImages.length; i++) {
        final question = questionsWithImages[i];
        try {
          // Use ImageProvider to cache without needing a valid context
          final imageProvider = NetworkImage(question.imagePath);
          final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
          
          // Wait for first frame to ensure it's cached
          final completer = Completer<void>();
          late ImageStreamListener listener;
          
          listener = ImageStreamListener(
            (ImageInfo info, bool synchronousCall) {
              if (!completer.isCompleted) {
                successCount++;
                debugPrint('Cached image ${successCount}/${questionsWithImages.length}');
                completer.complete();
              }
              stream.removeListener(listener);
            },
            onError: (dynamic exception, StackTrace? stackTrace) {
              debugPrint('Failed to cache image ${i + 1}/${questionsWithImages.length}: ${question.imagePath}');
              if (!completer.isCompleted) {
                completer.complete();
              }
              stream.removeListener(listener);
            },
          );
          
          stream.addListener(listener);
          await completer.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱ Timeout caching image ${i + 1}/${questionsWithImages.length}');
              stream.removeListener(listener);
            },
          );
        } catch (e) {
          debugPrint('Error precaching ${question.imagePath}: $e');
        }
      }
      
      debugPrint('✅ Successfully precached $successCount/${questionsWithImages.length} images');
    } catch (e) {
      debugPrint('❌ Error in precacheAllQuestionImages: $e');
    }
  }
}
