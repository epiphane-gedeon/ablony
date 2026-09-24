import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Actions du VENDEUR sur son colis (auto-expédition).
class ParcelSellerService {
  ParcelSellerService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const String _base =
      'https://us-central1-ablony-a5db9.cloudfunctions.net';

  Future<String> _token() async =>
      (await FirebaseAuth.instance.currentUser?.getIdToken()) ?? '';

  /// Déclare le colis expédié, avec sa preuve (URL déjà uploadée). Le serveur
  /// met la preuve en modération.
  Future<void> markShipped({
    required String parcelCode,
    required String proofUrl,
  }) async {
    final r = await _client.post(
      Uri.parse('$_base/markParcelShipped'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      },
      body: jsonEncode({'parcelCode': parcelCode, 'proofUrl': proofUrl}),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['error']?['message'] ?? 'Échec de la déclaration d\'expédition',
      );
    }
  }
}

final parcelSellerServiceProvider = Provider<ParcelSellerService>((ref) {
  return ParcelSellerService();
});
