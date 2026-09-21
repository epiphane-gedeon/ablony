import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/stuck_parcel.dart';

/// Les colis qui n'avancent plus.
///
/// Sans agent pour constater une remise, rien ne se libère : l'argent reste en
/// séquestre, ce qui est sûr mais bloque le vendeur. Cette file est la porte
/// de sortie — elle montre ce qui attend une décision humaine, plutôt que de
/// laisser le silence durer.
final stuckParcelsProvider = FutureProvider.autoDispose<List<StuckParcel>>((
  ref,
) async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (token == null) return const [];

  final response = await http.get(
    Uri.parse('https://us-central1-ablony-a5db9.cloudfunctions.net/stuckParcels'),
    headers: {'Authorization': 'Bearer $token'},
  );

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  if (response.statusCode != 200 || body['success'] != true) {
    throw Exception(
      (body['error'] as Map<String, dynamic>?)?['message'] ??
          'Impossible de charger la file',
    );
  }

  // `data.items`, comme toutes les autres files : le contrat est le même
  // pour l'application et pour la console d'administration.
  final data = body['data'] as Map<String, dynamic>;
  return (data['items'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(StuckParcel.fromJson)
      .toList();
});
