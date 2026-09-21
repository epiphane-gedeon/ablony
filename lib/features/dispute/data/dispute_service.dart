import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/models/dispute.dart';

/// Les appels liés aux litiges.
///
/// Une seule route depuis l'application : l'ouverture. Trancher est réservé à
/// l'administration, qui travaille dans `ablony_admin` — un rôle qui voyage
/// dans un client décompilable est une mauvaise idée.
class DisputeService {
  DisputeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _base =
      'https://us-central1-ablony-a5db9.cloudfunctions.net';

  Future<String> _token() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw DisputeException('Utilisateur non authentifié');
    return token;
  }

  /// Dépose les photos et renvoie leurs adresses.
  ///
  /// L'identifiant de qui dépose est dans le chemin : c'est ce que les règles
  /// de stockage vérifient.
  ///
  /// Dépôt par `putData` et non `putFile` : `putFile` s'appuie sur `dart:io`,
  /// indisponible sur le web.
  Future<List<String>> uploadPhotos({
    required String transactionRef,
    required List<XFile> fichiers,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw DisputeException('Utilisateur non authentifié');

    final urls = <String>[];
    for (var i = 0; i < fichiers.length; i++) {
      final ref = FirebaseStorage.instance
          .ref('disputes/$transactionRef/$uid/${DateTime.now()
              .millisecondsSinceEpoch}_$i.jpg');
      await ref.putData(
        await fichiers[i].readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  /// Ouvre le litige.
  Future<void> open({
    required String transactionRef,
    required DisputeReason reason,
    required String description,
    required List<String> photoUrls,
  }) async {
    final response = await _client.post(
      Uri.parse('$_base/openDispute'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      },
      body: jsonEncode({
        'transactionRef': transactionRef,
        'reason': reason.wireValue,
        'description': description,
        'photoUrls': photoUrls,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      final erreur = data['error'] as Map<String, dynamic>?;
      throw DisputeException(
        erreur?['message'] as String? ?? "L'ouverture a échoué",
        code: erreur?['code'] as String?,
      );
    }
  }
}

class DisputeException implements Exception {
  DisputeException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

final disputeServiceProvider = Provider<DisputeService>((ref) {
  return DisputeService();
});
