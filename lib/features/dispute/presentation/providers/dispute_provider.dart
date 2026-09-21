import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/dispute.dart';

/// Le litige d'une vente, s'il existe.
///
/// Lu directement dans Firestore et non par un appel : les règles donnent
/// l'accès aux deux parties et à elles seules, et le reçu doit savoir
/// immédiatement s'il faut masquer le bouton de confirmation.
///
/// En flux plutôt qu'en lecture unique : quand l'administration tranche, le
/// reçu ouvert change tout seul.
final disputeForTransactionProvider =
    StreamProvider.autoDispose.family<Dispute?, String>((ref, transactionRef) {
  return FirebaseFirestore.instance
      .collection('disputes')
      .doc(transactionRef)
      .snapshots()
      .map((doc) => doc.exists ? Dispute.fromFirestore(doc) : null);
});
