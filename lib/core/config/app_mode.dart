import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode global de fonctionnement de l'app, piloté depuis l'admin
/// (`config/app.mode`).
///
/// - [def] : l'app complète (relais + livraison Ablony partout).
/// - [beg] : mode de lancement (opération manuelle sur Lomé + auto-expédition
///   ailleurs).
///
/// **Le mode ne modifie QUE les fonctionnalités qui diffèrent** ; tout le reste
/// (ville, vente, chat, paiement…) est indépendant du mode.
enum AppMode {
  beg('beg'),
  def('def');

  const AppMode(this.wire);
  final String wire;

  static AppMode fromWire(String? value) =>
      value == 'beg' ? AppMode.beg : AppMode.def;

  bool get isBeg => this == AppMode.beg;
}

/// Mode courant, lu en temps réel depuis `config/app`. Repli sur [AppMode.def]
/// tant que rien n'est configuré (comportement actuel).
final appModeProvider = StreamProvider<AppMode>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('app')
      .snapshots()
      .map((doc) => AppMode.fromWire(doc.data()?['mode'] as String?));
});

/// Le mode courant en valeur simple (repli [AppMode.def] pendant le chargement).
final currentAppModeProvider = Provider<AppMode>((ref) {
  return ref.watch(appModeProvider).value ?? AppMode.def;
});

/// Faut-il montrer la preuve d'expédition à l'acheteur (auto-expédition) ?
/// Réglable en admin (`config/app.shipmentProofToBuyer`). Défaut : oui.
final shipmentProofVisibleProvider = Provider<bool>((ref) {
  return ref.watch(_appConfigProvider).value?['shipmentProofToBuyer']
          as bool? ??
      true;
});

/// Stream brut du document `config/app` (mode + réglages annexes).
final _appConfigProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('app')
      .snapshots()
      .map((doc) => doc.data());
});
