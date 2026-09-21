import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../domain/models/withdrawal.dart';

/// Les demandes de retrait de la personne connectée.
///
/// Lues directement dans Firestore et non par une Cloud Function : les règles
/// donnent accès aux siennes, et un flux tient l'écran à jour quand
/// l'administration verse — sans que le vendeur ait à revenir.
final withdrawalsProvider = StreamProvider<List<Withdrawal>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection('withdrawals')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Withdrawal.fromFirestore).toList());
});

/// Y a-t-il une demande en cours ?
///
/// Sert à prévenir plutôt qu'à interdire : rien n'empêche d'en demander deux,
/// mais le dire évite la relance inquiète après quelques heures d'attente.
final hasPendingWithdrawalProvider = Provider<bool>((ref) {
  final demandes = ref.watch(withdrawalsProvider).value ?? const [];
  return demandes.any((d) => d.status == WithdrawalStatus.requested);
});
