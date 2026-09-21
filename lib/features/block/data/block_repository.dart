import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le blocage entre membres.
///
/// Écriture Firestore directe, sans Cloud Function : il n'y a rien à valider
/// côté serveur que les règles ne valident déjà, et l'identifiant composite
/// `{bloqueur}_{bloqué}` rend le doublon impossible — bloquer deux fois la
/// même personne écrit deux fois le même document.
class BlockRepository {
  BlockRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _moi {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Utilisateur non authentifié');
    return uid;
  }

  /// L'identifiant du document : c'est lui qui garantit l'unicité, et c'est
  /// lui que les règles de la messagerie vont chercher.
  static String idBlocage(String bloqueur, String bloque) =>
      '${bloqueur}_$bloque';

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _db.collection('blocks');

  Future<void> block(String autre) async {
    if (autre == _moi) throw ArgumentError('On ne se bloque pas soi-même');
    await _blocks.doc(idBlocage(_moi, autre)).set({
      'blockerId': _moi,
      'blockedId': autre,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblock(String autre) async {
    await _blocks.doc(idBlocage(_moi, autre)).delete();
  }

  /// Les personnes que j'ai bloquées.
  ///
  /// Je ne peux pas savoir qui m'a bloqué : les règles me l'interdisent, et
  /// le savoir n'apporterait rien sinon l'envie de répliquer.
  Stream<List<String>> watchBlocked() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _blocks
        .where('blockerId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['blockedId'] as String).toList());
  }

  Future<bool> isBlocked(String autre) async {
    final doc = await _blocks.doc(idBlocage(_moi, autre)).get();
    return doc.exists;
  }
}

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository();
});
