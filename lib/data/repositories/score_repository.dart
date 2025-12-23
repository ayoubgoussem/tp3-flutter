import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/score_model.dart';

class ScoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Save a quiz score
  Future<void> saveScore(ScoreModel score) async {
    try {
      await _firestore.collection('scores').add(score.toMap());
    } catch (e) {
      throw Exception('Failed to save score: $e');
    }
  }
  
  // Get all scores (admin only)
  Future<List<ScoreModel>> getAllScores({int? limit}) async {
    try {
      Query query = _firestore
          .collection('scores')
          .orderBy('completedAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ScoreModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch scores: $e');
    }
  }
  
  // Get scores by theme
  Future<List<ScoreModel>> getScoresByTheme(String theme) async {
    try {
      final snapshot = await _firestore
          .collection('scores')
          .where('theme', isEqualTo: theme)
          .orderBy('completedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ScoreModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch scores by theme: $e');
    }
  }
  
  // Get top scores (leaderboard)
  Future<List<ScoreModel>> getTopScores({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('scores')
          .orderBy('correctAnswers', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => ScoreModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top scores: $e');
    }
  }
  
  // Stream all scores (for real-time updates)
  Stream<List<ScoreModel>> streamAllScores({int? limit}) {
    Query query = _firestore
        .collection('scores')
        .orderBy('completedAt', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ScoreModel.fromFirestore(doc))
          .toList();
    });
  }
  
  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final snapshot = await _firestore.collection('scores').get();
      final scores = snapshot.docs
          .map((doc) => ScoreModel.fromFirestore(doc))
          .toList();
      
      if (scores.isEmpty) {
        return {
          'totalQuizzes': 0,
          'averageScore': 0.0,
          'uniqueUsers': 0,
          'scoresByTheme': <String, List<ScoreModel>>{},
        };
      }
      
      // Calculate statistics
      final totalQuizzes = scores.length;
      final averagePercentage = scores
          .map((s) => s.percentage)
          .reduce((a, b) => a + b) / totalQuizzes;
      final uniqueUsers = scores.map((s) => s.userId).toSet().length;
      
      // Group by theme
      final scoresByTheme = <String, List<ScoreModel>>{};
      for (var score in scores) {
        scoresByTheme.putIfAbsent(score.theme, () => []).add(score);
      }
      
      return {
        'totalQuizzes': totalQuizzes,
        'averageScore': averagePercentage,
        'uniqueUsers': uniqueUsers,
        'scoresByTheme': scoresByTheme,
      };
    } catch (e) {
      throw Exception('Failed to calculate statistics: $e');
    }
  }
  
  // Get most popular favorite theme
  Future<Map<String, dynamic>> getMostPopularFavoriteTheme() async {
    try {
      // First, get all valid themes from the questions collection
      final questionsSnapshot = await _firestore.collection('questions').get();
      final validThemes = <String>{};
      
      for (var doc in questionsSnapshot.docs) {
        final data = doc.data();
        final theme = data['theme'] as String?;
        if (theme != null && theme.isNotEmpty) {
          validThemes.add(theme);
        }
      }
      
      if (validThemes.isEmpty) {
        return {'theme': 'Aucun', 'count': 0};
      }
      
      // Get all users with preferred themes
      final snapshot = await _firestore
          .collection('users')
          .where('preferredTheme', isNull: false)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return {'theme': 'Aucun', 'count': 0};
      }
      
      // Count occurrences of each theme, but only for VALID themes
      final themeCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final theme = data['preferredTheme'] as String?;
        
        // Only count if theme is valid (exists in questions collection)
        if (theme != null && theme.isNotEmpty && validThemes.contains(theme)) {
          themeCounts[theme] = (themeCounts[theme] ?? 0) + 1;
        }
      }
      
      if (themeCounts.isEmpty) {
        return {'theme': 'Aucun', 'count': 0};
      }
      
      // Find the most popular valid theme
      final mostPopular = themeCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      return {'theme': mostPopular.key, 'count': mostPopular.value};
    } catch (e) {
      return {'theme': 'Erreur', 'count': 0};
    }
  }
}
