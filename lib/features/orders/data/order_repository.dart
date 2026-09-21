import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/order_summary.dart';

/// Les commandes, des deux côtés.
///
/// Aucune collection nouvelle : les reçus portent l'argent, les colis portent
/// l'acheminement. On les croise ici plutôt que de recopier l'état du colis
/// sur le reçu — une donnée dupliquée est une donnée qui se désynchronise, et
/// c'est justement l'état d'un colis qui change le plus souvent.
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const int pageSize = 20;

  Stream<List<OrderSummary>> watch(OrderSide side, {int limit = pageSize}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    final champ = side == OrderSide.purchase ? 'buyerId' : 'sellerId';
    return _db
        .collection('receipts')
        .where(champ, isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snap) => _joindreColis(snap.docs, side));
  }

  /// Joint le colis à chaque reçu.
  ///
  /// **Par leur code, en lecture directe** — pas par une requête
  /// `where transactionRef in [...]`. La règle de sécurité de `parcels`
  /// autorise un document si l'appelant en est l'acheteur ou le vendeur ;
  /// c'est une règle par document. Une requête, elle, doit se restreindre
  /// elle-même aux documents autorisés : comme celle-ci filtre sur
  /// `transactionRef` et non sur `buyerId`/`sellerId`, Firestore ne peut pas
  /// prouver qu'elle ne renverra que des colis permis, et la refuse en entier.
  ///
  /// Le code du colis est déjà sur le reçu, et c'est l'identifiant du document
  /// `parcels`. On lit donc chaque colis par son id, en parallèle : autant de
  /// lectures que de lignes, mais chacune passe la règle par document — et
  /// c'est exactement ce que le design prévoyait.
  Future<List<OrderSummary>> _joindreColis(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> recus,
    OrderSide side,
  ) async {
    if (recus.isEmpty) return const [];

    // Les codes présents : un reçu antérieur à la livraison par colis n'en a
    // pas, et n'a alors aucun colis à joindre.
    final codes = <String>{
      for (final d in recus)
        if (d.data()['parcelCode'] is String) d.data()['parcelCode'] as String,
    };

    final lus = await Future.wait(
      codes.map((code) => _db.collection('parcels').doc(code).get()),
    );

    final colis = <String, Map<String, dynamic>>{};
    for (final doc in lus) {
      final d = doc.data();
      // Un colis peut avoir disparu, ou être illisible : on l'ignore plutôt
      // que de faire échouer toute la liste pour une ligne.
      if (doc.exists && d != null) {
        colis[d['transactionRef'] as String? ?? doc.id] = d;
      }
    }

    return recus
        .map((d) => OrderSummary.fromReceipt(
              d,
              side,
              parcel: colis[d.data()['transactionRef'] as String? ?? d.id],
            ))
        .toList();
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});
