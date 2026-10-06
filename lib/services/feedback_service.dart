import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Sends signed-in users' app feedback to the admin moderation queue.
class FeedbackService {
  static const collection = 'feedback';

  static String? validationError({
    required String category,
    required int rating,
    required String message,
  }) {
    if (!['Bug report', 'Idea', 'Other'].contains(category)) {
      return 'Choose a feedback type.';
    }
    if (rating < 1 || rating > 5) return 'Choose a rating from 1 to 5.';
    final trimmed = message.trim();
    if (trimmed.length < 8) return 'Please add a little more detail.';
    if (trimmed.length > 2000) return 'Feedback must be under 2,000 characters.';
    return null;
  }

  static Future<void> submit({
    required String category,
    required int rating,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to send feedback.');
    final problem = validationError(
      category: category,
      rating: rating,
      message: message,
    );
    if (problem != null) throw StateError(problem);

    await FirebaseFirestore.instance.collection(collection).add({
      'userId': user.uid,
      'email': user.email ?? '',
      'category': category,
      'rating': rating,
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
