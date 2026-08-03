import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/models/report_reason.dart';

class ReportRepository {
  ReportRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
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

  Future<void> submitReport({
    required String productId,
    required String productTitle,
    required String sellerId,
    required ReportReason reason,
    String? comment,
  }) async {
    await _firestore.collection('reports').add({
      'productId': productId,
      'productTitle': productTitle,
      'sellerId': sellerId,
      'reporterId': _uid,
      'reason': reason.value,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
