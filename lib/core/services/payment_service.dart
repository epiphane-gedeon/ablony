import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Service gérant les appels API pour les paiements via Firebase Cloud Functions
class PaymentService {
  // URL de la Cloud Function de paiement déployée (2nd Gen Cloud Run)
  static const String _functionUrl = 'https://initiatepayment-mahukqtfea-uc.a.run.app';

  /// Initie un paiement auprès de GeniusPay via la Cloud Function
  Future<Map<String, dynamic>> initiatePayment({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? phone,
    String? name,
    String? email,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'phone': phone,
          'name': name,
          'email': email,
          'description': description,
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
}

/// Provider pour injecter le PaymentService dans l'application
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});
