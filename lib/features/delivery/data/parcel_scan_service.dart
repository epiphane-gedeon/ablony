import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/models/scanned_parcel.dart';

/// Ce que l'application peut faire d'un code scanné.
///
/// Le code est imprimé sur le carton : n'importe qui peut le lire, le
/// photographier, le recopier. Ce n'est donc jamais lui qui autorise — c'est
/// **celui qui scanne**. Chaque appel porte le jeton de la personne, et le
/// serveur relit son rôle en base avant d'agir. Un client trafiqué n'obtient
/// rien de plus qu'un client honnête.
class ParcelScanService {
  ParcelScanService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _base = 'https://us-central1-ablony-a5db9.cloudfunctions.net';

  Future<String> _token() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('Utilisateur non authentifié');
    return token;
  }

  Future<Map<String, dynamic>> _post(String fonction, Map<String, dynamic> corps) async {
    final response = await _client.post(
      Uri.parse('$_base/$fonction'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      },
      body: jsonEncode(corps),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw ParcelScanException(
        (data['error'] as Map<String, dynamic>?)?['message'] as String? ??
            'Le scan a échoué',
        statusCode: response.statusCode,
      );
    }
    return (data['data'] as Map<String, dynamic>?) ?? const {};
  }

  /// Résout un code scanné, pour le personnel.
  ///
  /// La vue renvoyée est réduite : de quoi acheminer le colis, rien de plus.
  /// Ni prix, ni identité — un agent n'a pas à savoir combien vaut ce qu'il
  /// transporte.
  Future<ScannedParcel> resolve(String code) async =>
      ScannedParcel.fromJson(await _post('resolveParcel', {'code': code}));

  /// Enregistre une étape constatée.
  Future<void> recordCheckpoint({
    required String code,
    required String kind,
    String? relayPointId,
    String? note,
  }) => _post('recordParcelCheckpoint', {
    'code': code,
    'kind': kind,
    if (relayPointId != null) 'relayPointId': relayPointId,
    if (note != null) 'note': note,
  });

  /// Rend son argent à l'acheteur, et remet l'article en vente.
  ///
  /// Réservé à l'administration. Aucune horloge ne tourne au lancement et
  /// aucun agent ne constate les remises : la décision est donc prise par
  /// quelqu'un qui a regardé le dossier, ce qui est le bon niveau d'exigence
  /// quand personne ne peut prouver ce qui s'est passé.
  Future<void> refund({
    required String transactionRef,
    required String reason,
  }) => _post('refundPurchase', {
    'transactionRef': transactionRef,
    'reason': reason,
  });

  /// Verse au vendeur une vente que l'acheteur n'a jamais confirmée.
  ///
  /// L'autre moitié de la porte de sortie : sans agent et sans horloge, la
  /// confirmation de l'acheteur est le seul signal, et celui qui reçoit son
  /// colis puis n'y revient jamais laisse le vendeur attendre indéfiniment.
  Future<void> release({
    required String transactionRef,
    required String reason,
  }) => _post('releasePurchase', {
    'transactionRef': transactionRef,
    'reason': reason,
  });

  /// L'acheteur atteste avoir le colis en main.
  ///
  /// Ne libère rien : c'est une attestation, datée et indépendante de celle de
  /// l'agent. La libération reste un geste explicite, pris sur l'écran de la
  /// commande, après avoir ouvert le carton.
  Future<AttestedParcel> attestReceipt(String code) async =>
      AttestedParcel.fromJson(await _post('attestParcelReceipt', {'code': code}));
}

class ParcelScanException implements Exception {
  ParcelScanException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Le serveur répond « introuvable » aussi bien pour un code inconnu que
  /// pour un colis qui ne concerne pas l'appelant : dire « interdit »
  /// confirmerait l'existence de la vente à qui n'a rien à en savoir.
  bool get isNotFound => statusCode == 404;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}

final parcelScanServiceProvider = Provider<ParcelScanService>((ref) {
  return ParcelScanService();
});
