/// Script pour importer les catégories directement dans Firestore
///
/// **Utilisation :**
/// ```bash
/// # Importer vers l'émulateur (par défaut)
/// dart run tools/seed_to_firestore.dart
///
/// # Importer vers l'émulateur explicitement
/// dart run tools/seed_to_firestore.dart --emulator
///
/// # Importer vers la production
/// dart run tools/seed_to_firestore.dart --prod
/// ```

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  print('🚀 Ablony - Import direct vers Firestore\n');

  // Déterminer la cible (émulateur ou production)
  final bool useEmulator = !arguments.contains('--prod');
  final String target = useEmulator ? '🧪 ÉMULATEUR' : '🔴 PRODUCTION';

  print('🎯 Cible: $target');
  if (useEmulator) {
    print('   Host: localhost:8080\n');
  } else {
    print('   ⚠️  ATTENTION: Utilisez le script Node.js pour la production!\n');
    print('   Commande: node tools/import_to_firestore.js\n');
    exit(1);
  }

  try {
    final projectId = 'ablony-dev';
    final baseUrl =
        'http://localhost:8080/v1/projects/$projectId/databases/(default)/documents';

    // 1. Charger les fichiers JSON
    print('📂 Chargement des fichiers JSON...');
    final categories = await _loadJsonFile('tools/seed_data/categories.json');
    final subcategories = await _loadJsonFile(
      'tools/seed_data/subcategories.json',
    );
    final attributes = await _loadJsonFile('tools/seed_data/attributes.json');

    print('   ✅ ${categories.length} catégories chargées');
    print('   ✅ ${subcategories.length} sous-catégories chargées');
    print('   ✅ ${attributes.length} attributs chargés\n');

    // 2. Importer les catégories
    print('📁 Import des catégories...');
    for (final category in categories) {
      final id = category['id'] as String;
      final data = _prepareFirestoreData(category);

      await _createDocument(baseUrl, 'config/categories/items', id, data);

      print('   ✅ Catégorie: ${category['name']}');
    }

    // 3. Importer les sous-catégories
    print('\n📁 Import des sous-catégories...');
    int withCondition = 0;
    for (final subcategory in subcategories) {
      final id = subcategory['id'] as String;
      final data = _prepareFirestoreData(subcategory);

      await _createDocument(baseUrl, 'config/subcategories/items', id, data);

      final attrs = subcategory['attributes'] as List?;
      if (attrs != null && attrs.contains('condition')) {
        withCondition++;
      }

      print('   ✅ Sous-catégorie: ${subcategory['name']}');
    }

    // 4. Importer les attributs
    print('\n📁 Import des attributs...');
    for (final attribute in attributes) {
      final id = attribute['id'] as String;
      final data = _prepareFirestoreData(attribute);

      await _createDocument(baseUrl, 'config/attributes/items', id, data);

      print('   ✅ Attribut: ${attribute['name']}');
    }

    // 6. Résumé
    print('\n' + '=' * 80);
    print('✅ IMPORT TERMINÉ AVEC SUCCÈS !');
    print('=' * 80);
    print('\n📊 Résumé:');
    print('   - ${categories.length} catégories importées');
    print('   - ${subcategories.length} sous-catégories importées');
    print('   - $withCondition sous-catégories avec attribut "condition"');
    print('   - ${attributes.length} attributs importés');
    print('\n🎯 Cible: $target');
    print('\n💡 Pour voir les données:');
    print('   Interface: http://localhost:4000/firestore');
    print('   API: http://localhost:8080');
    print(
      '\n💡 Relancez votre app Flutter avec hot reload (r) pour voir les catégories\n',
    );

    exit(0);
  } catch (e, stackTrace) {
    print('\n❌ ERREUR: $e');
    print('\n📋 Stack trace:');
    print(stackTrace);
    exit(1);
  }
}

/// Crée un document dans Firestore via l'API REST
Future<void> _createDocument(
  String baseUrl,
  String collectionPath,
  String documentId,
  Map<String, dynamic> data,
) async {
  final url = '$baseUrl/$collectionPath/$documentId';

  // Convertir les données au format Firestore REST API
  final firestoreData = _convertToFirestoreFormat(data);

  final response = await http.patch(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'fields': firestoreData}),
  );

  if (response.statusCode != 200) {
    throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
  }
}

/// Convertit une map Dart au format Firestore REST API
Map<String, dynamic> _convertToFirestoreFormat(Map<String, dynamic> data) {
  final result = <String, dynamic>{};

  for (final entry in data.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value == null) {
      result[key] = {'nullValue': null};
    } else if (value is String) {
      result[key] = {'stringValue': value};
    } else if (value is int) {
      result[key] = {'integerValue': value.toString()};
    } else if (value is double) {
      result[key] = {'doubleValue': value};
    } else if (value is bool) {
      result[key] = {'booleanValue': value};
    } else if (value is List) {
      result[key] = {
        'arrayValue': {
          'values': value
              .map((item) => _convertValueToFirestore(item))
              .toList(),
        },
      };
    } else if (value is Map) {
      result[key] = {
        'mapValue': {
          'fields': _convertToFirestoreFormat(Map<String, dynamic>.from(value)),
        },
      };
    }
  }

  return result;
}

/// Convertit une valeur individuelle au format Firestore
dynamic _convertValueToFirestore(dynamic value) {
  if (value == null) {
    return {'nullValue': null};
  } else if (value is String) {
    return {'stringValue': value};
  } else if (value is int) {
    return {'integerValue': value.toString()};
  } else if (value is double) {
    return {'doubleValue': value};
  } else if (value is bool) {
    return {'booleanValue': value};
  } else if (value is List) {
    return {
      'arrayValue': {
        'values': value.map((item) => _convertValueToFirestore(item)).toList(),
      },
    };
  } else if (value is Map) {
    return {
      'mapValue': {
        'fields': _convertToFirestoreFormat(Map<String, dynamic>.from(value)),
      },
    };
  }
  return {'stringValue': value.toString()};
}

/// Charge un fichier JSON et retourne une liste de maps
Future<List<Map<String, dynamic>>> _loadJsonFile(String path) async {
  final file = File(path);

  if (!await file.exists()) {
    throw Exception('Fichier non trouvé : $path');
  }

  final content = await file.readAsString();
  final List<dynamic> data = jsonDecode(content);

  return data.cast<Map<String, dynamic>>();
}

/// Prépare les données pour Firestore
Map<String, dynamic> _prepareFirestoreData(Map<String, dynamic> data) {
  final result = Map<String, dynamic>.from(data);

  // Retirer l'ID (utilisé comme document ID)
  result.remove('id');

  // Ajouter les timestamps (format ISO pour l'émulateur)
  final now = DateTime.now().toIso8601String();
  result['createdAt'] = now;
  result['updatedAt'] = now;

  return result;
}
