import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/wallet_entry.dart';

/// Lit le relevé du porte-monnaie.
///
/// Deux collections, parce que l'argent y est écrit depuis deux points de vue :
/// `transactions` pour ce qui a été payé, `receipts` pour ce qui a été vendu.
/// Elles sont fusionnées ici plutôt qu'en base : Firestore ne sait pas joindre,
/// et à l'échelle d'un relevé personnel, trier en mémoire ne coûte rien.
///
/// Les deux collections sont en lecture seule côté client — all y est écrit
/// par les Cloud Functions.
class WalletEntryRepository {
  WalletEntryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Nombre de mouvements chargés par collection.
  ///
  /// Un relevé se consulte de haut en bas et rarement au-delà des dernières
  /// semaines. Tout charger ferait payer des lectures pour des écrans que
  /// personne n'atteint.
  static const int pageSize = 50;

  Stream<List<WalletEntry>> watchEntries(String userId) {
    final purchases = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(pageSize)
        .snapshots();

    final sales = _firestore
        .collection('receipts')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(pageSize)
        .snapshots();

    return _merge(purchases, sales);
  }

  /// Fusionne les deux flux en une seule liste ordonnée.
  ///
  /// Chaque flux émet de son côté ; on garde le dernier état de l'autre pour
  /// ne pas vider la liste à chaque mise à jour partielle.
  Stream<List<WalletEntry>> _merge(
    Stream<QuerySnapshot<Map<String, dynamic>>> purchases,
    Stream<QuerySnapshot<Map<String, dynamic>>> sales,
  ) async* {
    List<WalletEntry> lastPurchases = const [];
    List<WalletEntry> lastSales = const [];
    var purchasesSeen = false;
    var salesSeen = false;

    await for (final event in _interleave(purchases, sales)) {
      if (event.$1 == _Source.purchases) {
        lastPurchases = event.$2.docs
            .map(WalletEntry.fromTransaction)
            .whereType<WalletEntry>()
            .toList();
        purchasesSeen = true;
      } else {
        lastSales = event.$2.docs
            .map(WalletEntry.fromReceipt)
            .whereType<WalletEntry>()
            .toList();
        salesSeen = true;
      }

      // Attendre les deux premières émissions évite un affichage qui montre
      // les purchases seuls pendant un instant, puis se réordonne sous les yeux.
      if (!purchasesSeen || !salesSeen) continue;

      final all = [...lastPurchases, ...lastSales]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield all;
    }
  }

  Stream<(_Source, QuerySnapshot<Map<String, dynamic>>)> _interleave(
    Stream<QuerySnapshot<Map<String, dynamic>>> purchases,
    Stream<QuerySnapshot<Map<String, dynamic>>> sales,
  ) {
    final controller =
        StreamController<(_Source, QuerySnapshot<Map<String, dynamic>>)>();
    final subscriptions = [
      purchases.listen(
        (s) => controller.add((_Source.purchases, s)),
        onError: controller.addError,
      ),
      sales.listen(
        (s) => controller.add((_Source.sales, s)),
        onError: controller.addError,
      ),
    ];
    controller.onCancel = () async {
      for (final a in subscriptions) {
        await a.cancel();
      }
    };
    return controller.stream;
  }
}

enum _Source { purchases, sales }
