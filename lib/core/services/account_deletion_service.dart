import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../exceptions/exceptions.dart';

/// Supprime le compte de l'utilisateur connecté, côté serveur.
///
/// Ce n'est pas une suppression du document `users/{uid}` : le serveur
/// anonymise à la place toutes les informations personnelles (email,
/// username, nom, photo, téléphone, wallet...) puis supprime pour de bon le
/// compte Firebase Auth — voir `functions/index.js#deleteAccount` pour le
/// détail de ce qui est anonymisé et de ce qui est volontairement préservé.
class AccountDeletionService {
  static const String _deleteUrl =
      'https://us-central1-ablony-a5db9.cloudfunctions.net/deleteAccount';

  Future<void> deleteAccount() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw NotAuthenticatedException();
    }

    final response = await http.post(
      Uri.parse(_deleteUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw UnknownException(
        message:
            data['error']?['message'] ??
            'Échec de la suppression du compte',
      );
    }
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService();
});
