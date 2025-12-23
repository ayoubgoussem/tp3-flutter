import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String? id;
  final String text;
  final bool isCorrect;
  final String imagePath;
  final String theme;
  final DateTime createdAt;

  QuestionModel({
    this.id,
    required this.text,
    required this.isCorrect,
    required this.imagePath,
    required this.theme,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Firestore document to QuestionModel
  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      text: data['text'] ?? '',
      isCorrect: data['isCorrect'] ?? false,
      imagePath: data['imagePath'] ?? '',
      theme: data['theme'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert QuestionModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'isCorrect': isCorrect,
      'imagePath': imagePath,
      'theme': theme,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method for creating modified copies
  QuestionModel copyWith({
    String? id,
    String? text,
    bool? isCorrect,
    String? imagePath,
    String? theme,
    DateTime? createdAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
      imagePath: imagePath ?? this.imagePath,
      theme: theme ?? this.theme,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
