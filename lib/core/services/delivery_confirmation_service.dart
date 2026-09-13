import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// L'acheteur confirme avoir reçu son colis, ce qui débloque le paiement du
/// vendeur (pendingAmount → availableAmount).
///
/// Il n'y a rien à scanner. La version précédente faisait scanner à l'acheteur
/// un QR affiché sur l'écran du vendeur — un geste de remise en main propre,
/// alors qu'Ablony achemine lui-même les colis : les deux personnes ne se
/// rencontrent jamais.
class DeliveryConfirmationService {
  static const String _confirmUrl = 'https://us-central1-ablony-a5db9.cloudfunctions.net/confirmDelivery';

  /// [transactionRef] est la référence affichée sur le reçu. Le serveur
  /// vérifie que l'appelant en est bien l'acheteur : c'est là que tient la
  /// protection, et non dans un code quelconque.
  Future<void> confirmDelivery({required String transactionRef}) async {
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
      body: jsonEncode({'transactionRef': transactionRef}),
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
