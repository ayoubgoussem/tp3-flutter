import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tp3_flutter/data/models/question_model.dart';

class QuizRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _questionsCollection = 'questions';

  // Get all questions for a specific theme
  Future<List<QuestionModel>> getQuestionsByTheme(String theme) async {
    try {
      final querySnapshot = await _firestore
          .collection(_questionsCollection)
          .where('theme', isEqualTo: theme)
          .get();

      return querySnapshot.docs
          .map((doc) => QuestionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  // Get random questions from all themes
  Future<List<QuestionModel>> getRandomQuestions(int count) async {
    try {
      // Get all questions
      final querySnapshot = await _firestore
          .collection(_questionsCollection)
          .get();

      // Convert to list and shuffle
      final allQuestions = querySnapshot.docs
          .map((doc) => QuestionModel.fromFirestore(doc))
          .toList();

      allQuestions.shuffle();

      // Return requested count or all if less available
      return allQuestions.take(count).toList();
    } catch (e) {
      throw Exception('Failed to load random questions: $e');
    }
  }

  // Get all available themes
  Future<List<String>> getAllThemes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_questionsCollection)
          .get();

      // Extract unique themes
      final themes = <String>{};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['theme'] != null) {
          themes.add(data['theme'] as String);
        }
      }

      return themes.toList()..sort();
    } catch (e) {
      throw Exception('Failed to load themes: $e');
    }
  }

  // Add a new question
  Future<void> addQuestion(QuestionModel question) async {
    try {
      await _firestore
          .collection(_questionsCollection)
          .add(question.toFirestore());
    } catch (e) {
      throw Exception('Failed to add question: $e');
    }
  }

  // Update an existing question
  Future<void> updateQuestion(QuestionModel question) async {
    if (question.id == null) {
      throw Exception('Question ID is required for update');
    }

    try {
      await _firestore
          .collection(_questionsCollection)
          .doc(question.id)
          .update(question.toFirestore());
    } catch (e) {
      throw Exception('Failed to update question: $e');
    }
  }

  // Delete a question
  Future<void> deleteQuestion(String id) async {
    try {
      await _firestore
          .collection(_questionsCollection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  // Stream of questions for real-time updates
  Stream<List<QuestionModel>> streamQuestionsByTheme(String theme) {
    return _firestore
        .collection(_questionsCollection)
        .where('theme', isEqualTo: theme)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuestionModel.fromFirestore(doc))
            .toList());
  }

  // Upload question image to Firebase Storage
  Future<String?> uploadQuestionImage(List<int> imageBytes, String fileName) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('question_images/$fileName');
      
      await imageRef.putData(
        Uint8List.fromList(imageBytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      return await imageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Rename theme (updates all questions with this theme)
  Future<void> renameTheme(String oldName, String newName) async {
    try {
      final snapshot = await _firestore
          .collection(_questionsCollection)
          .where('theme', isEqualTo: oldName)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'theme': newName});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error renaming theme: $e');
      rethrow;
    }
  }

  // Delete theme (deletes all questions with this theme)
  Future<void> deleteTheme(String themeName) async {
    try {
      final snapshot = await _firestore
          .collection(_questionsCollection)
          .where('theme', isEqualTo: themeName)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting theme: $e');
      rethrow;
    }
  }

  // Count questions by theme
  Future<int> countQuestionsByTheme(String theme) async {
    try {
      final snapshot = await _firestore
          .collection(_questionsCollection)
          .where('theme', isEqualTo: theme)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error counting questions: $e');
      return 0;
    }
  }

  // Stream themes with question counts
  Stream<Map<String, int>> streamThemesWithCount() {
    return _firestore
        .collection(_questionsCollection)
        .snapshots()
        .asyncMap((snapshot) async {
      final Map<String, int> themeCount = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final theme = data['theme'] as String?;
        if (theme != null && theme.isNotEmpty) {
          themeCount[theme] = (themeCount[theme] ?? 0) + 1;
        }
      }
      return themeCount;
    });
  }
}
