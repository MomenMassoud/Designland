import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SearchHistoryService {
  static Future<void> saveSearchHistory(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      if (userId == null) {
        await FirebaseFirestore.instance.collection('search_history').doc().set({
          'query': trimmedQuery,
          'createdAt': FieldValue.serverTimestamp(),
          'userID': 'Gust',
          'gust': true,
        });
        return;
      }

      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('search_history')
          .add({
        'query': trimmedQuery,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('search_history').doc().set({
        'query': trimmedQuery,
        'createdAt': FieldValue.serverTimestamp(),
        'userID': userId,
        'gust': false,
      });
    } catch (e) {
      debugPrint("Error saving search history: $e");
    }
  }
}