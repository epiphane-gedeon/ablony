import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      throw Exception('Utilisateur non authentifié');
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
    final uid = _uid;
    final doc = await _followsRef.doc(_followDocId(uid, targetUserId)).get();
    return doc.exists;
  }

  Future<void> setFollowing(String targetUserId, bool value) async {
    final uid = _uid;
    if (uid == targetUserId) {
      throw Exception('Impossible de se suivre soi-même');
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
  }

  Future<void> toggleFollow(String targetUserId) async {
    final value = !(await isFollowing(targetUserId));
    await setFollowing(targetUserId, value);
  }

  /// UIDs des utilisateurs qui suivent [userId], du plus récent au plus ancien.
  Future<List<String>> getFollowerIds(String userId) async {
    final query = await _followsRef
        .where('followedId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs
        .map((doc) => doc.data()['followerId'])
        .whereType<String>()
        .toList();
  }

  /// UIDs des utilisateurs suivis par [userId], du plus récent au plus ancien.
  Future<List<String>> getFollowingIds(String userId) async {
    final query = await _followsRef
        .where('followerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs
        .map((doc) => doc.data()['followedId'])
        .whereType<String>()
        .toList();
  }
}
