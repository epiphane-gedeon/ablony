import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/delivery/domain/models/delivery_choice.dart';

/// Service gérant les appels API pour les paiements via Firebase Cloud Functions
class PaymentService {
  // URLs des Cloud Functions déployées (2nd Gen Cloud Run)
  static const String _initiateUrl = 'https://initiatepayment-mahukqtfea-uc.a.run.app';
  static const String _confirmUrl = 'https://confirmpayment-mahukqtfea-uc.a.run.app';
  static const String _applyBoostUrl =
      'https://us-central1-ablony-a5db9.cloudfunctions.net/applyBoost';

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
    int? quantity,
    String? parcelCode,
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
          // Nombre de boosts à créditer pour un achat de lot (type 'boostpack').
          if (quantity != null) 'quantity': quantity,
          // Ramassage à domicile : le colis à venir chercher (type 'pickup').
          if (parcelCode != null) 'parcelCode': parcelCode,
          // Le maillon qui manquait : le mode de livraison, le point relais
          // et l'adresse étaient choisis à l'écran puis jetés avant l'appel.
          // L'article était vendu et attendu nulle part. Pour un ramassage,
          // ce même objet porte l'adresse + le contact du VENDEUR.
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

  /// Dépense un boost de la réserve pour mettre un produit en avant, sans
  /// paiement. Le serveur (`applyBoost`) vérifie le solde, décrémente d'un
  /// crédit et marque le produit boosté — tout dans une seule transaction.
  ///
  /// Renvoie le nombre de boosts restants après l'opération, quand le serveur
  /// le fournit (`null` sinon).
  Future<void> applyBoost({required String productId}) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await http.post(
      Uri.parse(_applyBoostUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'productId': productId}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['error']?['message'] ?? 'Impossible d\'appliquer le boost',
      );
    }
  }
}

/// Provider pour injecter le PaymentService dans l'application
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});
