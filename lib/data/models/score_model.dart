import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreModel {
  final String id;
  final String userId;
  final String userName;
  final String theme;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime completedAt;

  ScoreModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.theme,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.completedAt,
  });

  // Helper getters
  String get scoreDisplay => '$correctAnswers/$totalQuestions';
  double get percentage => (correctAnswers / totalQuestions) * 100;

  // From Firestore
  factory ScoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScoreModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      theme: data['theme'] ?? '',
      correctAnswers: data['correctAnswers'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'theme': theme,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}
