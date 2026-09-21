import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Les appels liés aux retraits.
///
/// Une seule route côté vendeur : la demande. Le versement se fait à la main
/// depuis l'administration, et le vendeur suit l'avancement par la collection
/// `withdrawals`, qu'il lit directement — les règles Firestore lui donnent
/// accès aux siennes, et à elles seules.
class WithdrawalService {
  WithdrawalService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _base =
      'https://us-central1-ablony-a5db9.cloudfunctions.net';

  Future<String> _token() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw WithdrawalException('Utilisateur non authentifié');
    return token;
  }

  /// Demande un retrait.
  ///
  /// La somme quitte le solde disponible immédiatement, côté serveur : c'est
  /// ce qui empêche deux demandes lancées coup sur coup de retirer le même
  /// argent.
  Future<WithdrawalReceipt> request({
    required int amountXof,
    required String method,
    required String destination,
  }) async {
    final response = await _client.post(
      Uri.parse('$_base/requestWithdrawal'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      },
      body: jsonEncode({
        'amountXof': amountXof,
        'method': method,
        'destination': destination,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      final erreur = data['error'] as Map<String, dynamic>?;
      throw WithdrawalException(
        erreur?['message'] as String? ?? 'La demande a échoué',
        code: erreur?['code'] as String?,
      );
    }

    final corps = data['data'] as Map<String, dynamic>;
    return WithdrawalReceipt(
      id: corps['id'] as String,
      amountXof: (corps['amountXof'] as num?)?.round() ?? amountXof,
      feeXof: (corps['feeXof'] as num?)?.round() ?? 0,
      netAmountXof: (corps['netAmountXof'] as num?)?.round() ?? amountXof,
    );
  }
}

/// Ce que le serveur confirme après une demande.
class WithdrawalReceipt {
  const WithdrawalReceipt({
    required this.id,
    required this.amountXof,
    required this.feeXof,
    required this.netAmountXof,
  });

  final String id;
  final int amountXof;
  final int feeXof;
  final int netAmountXof;
}

class WithdrawalException implements Exception {
  WithdrawalException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

final withdrawalServiceProvider = Provider<WithdrawalService>((ref) {
  return WithdrawalService();
});
