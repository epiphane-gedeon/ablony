import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/parcel.dart';

/// Accès aux colis. Lecture seule côté application : les règles Firestore
/// interdisent l'écriture, et pour une bonne raison — un vendeur capable
/// d'écrire ici déclarerait son colis remis et se ferait payer sans avoir
/// rien envoyé.
class ParcelRepository {
  ParcelRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Suit un colis par le code imprimé sur son étiquette.
  ///
  /// En flux, et non en lecture ponctuelle : le statut change au fil des
  /// scans de nos agents, et c'est précisément ce que l'acheteur regarde.
  Stream<Parcel?> watchByCode(String code) {
    return _firestore
        .collection('parcels')
        .doc(code)
        .snapshots()
        .map((doc) => doc.exists ? Parcel.fromFirestore(doc) : null);
  }
}

final parcelRepositoryProvider = Provider<ParcelRepository>((ref) {
  return ParcelRepository();
});

/// Le colis d'une vente, suivi en continu.
final parcelByCodeProvider = StreamProvider.family<Parcel?, String>((ref, code) {
  return ref.watch(parcelRepositoryProvider).watchByCode(code);
});
