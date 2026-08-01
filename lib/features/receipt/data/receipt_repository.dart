import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/receipt.dart';

class ReceiptRepository {
  ReceiptRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Receipt> getReceiptById(String receiptId) async {
    final doc = await _firestore.collection('receipts').doc(receiptId).get();
    if (!doc.exists) {
      throw Exception('Reçu introuvable');
    }
    return Receipt.fromFirestore(doc);
  }

  /// Écoute en temps réel le reçu d'un produit, côté vendeur.
  ///
  /// Filtre explicitement par `sellerId` (et pas seulement `productId`) :
  /// les règles de sécurité Firestore ne peuvent valider une requête que si
  /// ses clauses `where` correspondent aux champs vérifiés par la règle
  /// (`resource.data.sellerId == request.auth.uid`). Une requête filtrée
  /// uniquement par `productId` est rejetée dans son ensemble, même quand le
  /// document trouvé appartient bien à l'utilisateur — Firestore ne peut pas
  /// le prouver statiquement à partir de la requête seule.
  Stream<Receipt?> watchReceiptAsSeller(String productId, String sellerId) {
    return _firestore
        .collection('receipts')
        .where('productId', isEqualTo: productId)
        .where('sellerId', isEqualTo: sellerId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty ? null : Receipt.fromFirestore(snapshot.docs.first));
  }

  /// Écoute en temps réel le reçu d'un produit, côté acheteur.
  /// Émet `null` si l'utilisateur courant n'est pas l'acheteur de ce produit
  /// (règle identique à [watchReceiptAsSeller], filtrée sur `buyerId`).
  Stream<Receipt?> watchReceiptAsBuyer(String productId, String buyerId) {
    return _firestore
        .collection('receipts')
        .where('productId', isEqualTo: productId)
        .where('buyerId', isEqualTo: buyerId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty ? null : Receipt.fromFirestore(snapshot.docs.first));
  }
}
