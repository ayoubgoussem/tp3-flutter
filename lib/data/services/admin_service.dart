import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user is admin
  Future<bool> isAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('admins').doc(userId).get();
      return doc.exists && doc.data()?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Stream to listen to admin status changes
  Stream<bool> adminStatusStream(String userId) {
    return _firestore.collection('admins').doc(userId).snapshots().map(
      (doc) => doc.exists && doc.data()?['isAdmin'] == true,
    );
  }
}
