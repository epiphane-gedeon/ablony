import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/exceptions/exceptions.dart';

class ProductFavRepository {
  ProductFavRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
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

  CollectionReference<Map<String, dynamic>> get _favRef {
    return _firestore.collection('fav');
  }

  String _favDocId(String uid, String productId) {
    return '${uid}_$productId';
  }

  Future<Set<String>> loadFavorites() async {
    try {
      final uid = _uid;
      final query = await _favRef.where('userId', isEqualTo: uid).get();
      return query.docs
          .map((doc) => doc.data()['productId'])
          .whereType<String>()
          .toSet();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des favoris',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> isFavorite(String productId) async {
    try {
      final uid = _uid;
      final doc = await _favRef.doc(_favDocId(uid, productId)).get();
      return doc.exists;
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la vérification du favori',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setFavorite(String productId, bool value) async {
    try {
      final uid = _uid;
      final favDoc = _favRef.doc(_favDocId(uid, productId));
      final productDoc = _firestore.collection('products').doc(productId);

      await _firestore.runTransaction((transaction) async {
        final favSnap = await transaction.get(favDoc);
        final productSnap = await transaction.get(productDoc);

        if (!productSnap.exists) {
          throw ProductNotFoundException(productId: productId);
        }

        final alreadyFavorite = favSnap.exists;
        if (value == alreadyFavorite) {
          return;
        }

        if (value) {
          transaction.set(favDoc, {
            'productId': productId,
            'userId': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(productDoc, {
            'favoritesCount': FieldValue.increment(1),
          });
        } else {
          transaction.delete(favDoc);
          transaction.update(productDoc, {
            'favoritesCount': FieldValue.increment(-1),
          });
        }
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la mise à jour du favori',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> toggleFavorite(String productId) async {
    final value = !(await isFavorite(productId));
    await setFavorite(productId, value);
  }
}
