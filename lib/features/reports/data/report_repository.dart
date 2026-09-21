import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/exceptions/exceptions.dart';
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
      throw NotAuthenticatedException();
    }
    return uid;
  }

  /// Signale un membre.
  ///
  /// Apple comme Google exigent, pour toute application à contenu produit par
  /// les utilisateurs, de pouvoir signaler **et** bloquer quelqu'un. Les deux
  /// gestes sont distincts : bloquer règle mon problème, signaler porte le
  /// problème à Ablony.
  ///
  /// Même collection que les signalements d'annonce, avec `productId` à null :
  /// une seule file à relire, et le vendeur visé est le même champ.
  Future<void> submitUserReport({
    required String reportedUserId,
    required ReportReason reason,
    String? comment,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'productId': null,
        'sellerId': reportedUserId,
        'reporterId': _uid,
        'reason': reason.value,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de l\'envoi du signalement',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> submitReport({
    required String productId,
    required String productTitle,
    required String sellerId,
    required ReportReason reason,
    String? comment,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'productId': productId,
        'productTitle': productTitle,
        'sellerId': sellerId,
        'reporterId': _uid,
        'reason': reason.value,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
        // La file de modération filtre sur `status == "open"`. Omettre le
        // champ, c'est déposer un signalement que personne ne verra jamais :
        // une égalité Firestore ne retrouve pas un document où il manque.
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de l\'envoi du signalement',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }
}
