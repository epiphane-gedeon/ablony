import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/delivery/domain/models/delivery_choice.dart';

/// Service gérant les appels API pour les paiements via Firebase Cloud Functions
class PaymentService {
  // URLs des Cloud Functions déployées (2nd Gen Cloud Run)
  static const String _initiateUrl = 'https://initiatepayment-mahukqtfea-uc.a.run.app';
  static const String _confirmUrl = 'https://confirmpayment-mahukqtfea-uc.a.run.app';

  /// Initie un paiement auprès de GeniusPay via la Cloud Function.
  ///
  /// [delivery] est obligatoire pour un achat : le serveur refuse une commande
  /// sans destination exploitable, et vérifie le point relais **avant** tout
  /// débit — le découvrir après coup laisserait un achat payé et un colis que
  /// personne ne sait où livrer.
  Future<Map<String, dynamic>> initiatePayment({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? phone,
    String? name,
    String? email,
    String? description,
    String? type,
    String? productId,
    String? sellerId,
    double? productPrice,
    double? walletDeduction,
    DeliveryChoice? delivery,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_initiateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'phone': phone,
          'name': name,
          'email': email,
          'description': description,
          'type': type ?? 'recharge',
          'productId': productId,
          'sellerId': sellerId,
          'productPrice': productPrice,
          'walletDeduction': walletDeduction,
          // Le maillon qui manquait : le mode de livraison, le point relais
          // et l'adresse étaient choisis à l'écran puis jetés avant l'appel.
          // L'article était vendu et attendu nulle part.
          if (delivery != null) 'delivery': delivery.toJson(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['error']?['message'] ?? 'Échec de l\'initiation du paiement');
        }
      } else {
        throw Exception(data['error']?['message'] ?? 'Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête de paiement : $e');
    }
  }

  /// Confirme un paiement après retour de la WebView.
  /// Vérifie le statut auprès de GeniusPay et finalise la transaction
  /// (débit wallet, crédit pendingAmount vendeur, produit marqué vendu).
  Future<Map<String, dynamic>> confirmPayment({
    required String reference,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_confirmUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reference': reference,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['error']?['message'] ?? 'Échec de la confirmation du paiement');
        }
      } else {
        throw Exception(data['error']?['message'] ?? 'Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors de la confirmation du paiement : $e');
    }
  }
}

/// Provider pour injecter le PaymentService dans l'application
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});
