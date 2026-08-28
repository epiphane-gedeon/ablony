import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/exceptions/exceptions.dart';

/// Gère les relations d'abonnement (follow) entre utilisateurs.
///
/// Stockage : collection `follows`, un document par paire
/// (followerId, followedId), id = `{followerId}_{followedId}`.
/// Les compteurs `followersCount`/`followingCount` sont dénormalisés sur
/// `users/{uid}` et maintenus à jour via transaction à chaque toggle.
class FollowRepository {
  FollowRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
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

  CollectionReference<Map<String, dynamic>> get _followsRef {
    return _firestore.collection('follows');
  }

  String _followDocId(String followerId, String followedId) {
    return '${followerId}_$followedId';
  }

  Future<bool> isFollowing(String targetUserId) async {
    try {
      final uid = _uid;
      final doc = await _followsRef.doc(_followDocId(uid, targetUserId)).get();
      return doc.exists;
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la vérification de l\'abonnement',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setFollowing(String targetUserId, bool value) async {
    try {
      final uid = _uid;
      if (uid == targetUserId) {
        throw CannotFollowSelfException();
      }

      final followDoc = _followsRef.doc(_followDocId(uid, targetUserId));
      final followerUserDoc = _firestore.collection('users').doc(uid);
      final followedUserDoc = _firestore.collection('users').doc(targetUserId);

      await _firestore.runTransaction((transaction) async {
        final followSnap = await transaction.get(followDoc);
        final alreadyFollowing = followSnap.exists;
        if (value == alreadyFollowing) {
          return;
        }

        if (value) {
          transaction.set(followDoc, {
            'followerId': uid,
            'followedId': targetUserId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(followerUserDoc, {
            'followingCount': FieldValue.increment(1),
          });
          transaction.update(followedUserDoc, {
            'followersCount': FieldValue.increment(1),
          });
        } else {
          transaction.delete(followDoc);
          transaction.update(followerUserDoc, {
            'followingCount': FieldValue.increment(-1),
          });
          transaction.update(followedUserDoc, {
            'followersCount': FieldValue.increment(-1),
          });
        }
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la mise à jour de l\'abonnement',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> toggleFollow(String targetUserId) async {
    final value = !(await isFollowing(targetUserId));
    await setFollowing(targetUserId, value);
  }

  /// UIDs des utilisateurs qui suivent [userId], du plus récent au plus ancien.
  Future<List<String>> getFollowerIds(String userId) async {
    try {
      final query = await _followsRef
          .where('followedId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return query.docs
          .map((doc) => doc.data()['followerId'])
          .whereType<String>()
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des abonnés',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  /// UIDs des utilisateurs suivis par [userId], du plus récent au plus ancien.
  Future<List<String>> getFollowingIds(String userId) async {
    try {
      final query = await _followsRef
          .where('followerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return query.docs
          .map((doc) => doc.data()['followedId'])
          .whereType<String>()
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des abonnements',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }
}
