import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Confirme la remise en main propre d'un article via le code QR affiché
/// par le vendeur et scanné par l'acheteur. Débloque le paiement côté
/// serveur (pendingAmount → availableAmount du vendeur).
class DeliveryConfirmationService {
  static const String _confirmUrl = 'https://us-central1-ablony-a5db9.cloudfunctions.net/confirmDelivery';

  /// [qrCodeId] est l'id opaque scanné dans le QR (collection `qrcodes`),
  /// jamais la référence de transaction directement — c'est le serveur qui
  /// résout ce lien. En secours, [transactionRef] (la référence affichée sur
  /// le reçu) peut être fourni à la place lorsque l'acheteur saisit la
  /// référence manuellement plutôt que de scanner le code.
  Future<void> confirmDelivery({String? qrCodeId, String? transactionRef}) async {
    assert(qrCodeId != null || transactionRef != null);

    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await http.post(
      Uri.parse(_confirmUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        if (qrCodeId != null) 'qrCodeId': qrCodeId,
        if (transactionRef != null) 'transactionRef': transactionRef,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error']?['message'] ?? 'Échec de la confirmation de réception');
    }
  }
}

final deliveryConfirmationServiceProvider = Provider<DeliveryConfirmationService>((ref) {
  return DeliveryConfirmationService();
});
