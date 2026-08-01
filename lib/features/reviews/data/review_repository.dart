import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/models/review.dart';

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Utilisateur non authentifié');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _reviewsRef {
    return _firestore.collection('reviews');
  }

  /// Soumet l'avis d'achat. L'id du document = [transactionRef] : Firestore
  /// refuse toute écriture d'un 2e avis pour le même achat (règles de
  /// sécurité, cf. firestore.rules).
  Future<void> submitReview({
    required String transactionRef,
    required String sellerId,
    required String productId,
    required String productTitle,
    required int rating,
    String? comment,
  }) async {
    await _reviewsRef.doc(transactionRef).set({
      'buyerId': _uid,
      'sellerId': sellerId,
      'productId': productId,
      'productTitle': productTitle,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      'transactionRef': transactionRef,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasReviewed(String transactionRef) async {
    final doc = await _reviewsRef.doc(transactionRef).get();
    return doc.exists;
  }

  Stream<List<Review>> watchReviewsForSeller(String sellerId) {
    return _reviewsRef
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Review.fromFirestore).toList());
  }
}
