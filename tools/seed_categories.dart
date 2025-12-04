/// Script pour générer les commandes d'import Firestore.
///
/// Ce script lit les fichiers JSON dans tools/seed_data/ et génère
/// un fichier JavaScript contenant toutes les commandes Firebase Admin SDK
/// pour importer les données dans Firestore.
///
/// **Utilisation :**
/// ```bash
/// dart run tools/seed_categories.dart
/// ```
///
/// **Sortie :**
/// - Fichier généré : tools/import_to_firestore.js
/// - Exécuter avec : node tools/import_to_firestore.js

import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) async {
  print(r'🚀 Ablony - Génération du script d''import Firestore' + '\n');

  try {
    // 1. Charger les fichiers JSON
    print('📂 Chargement des fichiers JSON...');
    final categories = await _loadJsonFile('tools/seed_data/categories.json');
    final subcategories =
        await _loadJsonFile('tools/seed_data/subcategories.json');
    final attributes = await _loadJsonFile('tools/seed_data/attributes.json');

    print('   ✅ ${categories.length} catégories chargées');
    print('   ✅ ${subcategories.length} sous-catégories chargées');
    print('   ✅ ${attributes.length} attributs chargés\n');

    // 2. Générer le script JavaScript
    print('📝 Génération du script Firebase Admin SDK...');
    final script = _generateFirebaseScript(
      categories,
      subcategories,
      attributes,
    );

    // 3. Sauvegarder le script
    final outputFile = File('tools/import_to_firestore.js');
    await outputFile.writeAsString(script);

    print('   ✅ Script généré : ${outputFile.path}\n');

    // 4. Afficher les instructions
    print('=' * 80);
    print('✅ SCRIPT GÉNÉRÉ AVEC SUCCÈS !');
    print('=' * 80);
    print(r'\n📋 INSTRUCTIONS D''UTILISATION :\n');
    print('1. Installez les dépendances Node.js :');
    print('   cd tools && npm install firebase-admin\n');
    print('2. Téléchargez votre service account key depuis Firebase Console');
    print('   et sauvegardez-le dans tools/service-account.json\n');
    print(r'3. Exécutez le script d''import :');
    print('   node tools/import_to_firestore.js\n');
    print('=' * 80);
    print('\n💡 Le script importera :');
    print('   - ${categories.length} catégories');
    print('   - ${subcategories.length} sous-catégories');
    print('   - ${attributes.length} attributs\n');
  } catch (e) {
    print('❌ Erreur : $e');
    exit(1);
  }
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

/// Génère le script JavaScript Firebase Admin SDK
String _generateFirebaseScript(
  List<Map<String, dynamic>> categories,
  List<Map<String, dynamic>> subcategories,
  List<Map<String, dynamic>> attributes,
) {
  final lines = <String>[];

  // En-tête
  lines.add('/**');
  lines.add(' * Script d\'import des catégories Ablony dans Firestore');
  lines.add(' * Généré automatiquement par tools/seed_categories.dart');
  lines.add(' * Date: ${DateTime.now().toIso8601String()}');
  lines.add(' */');
  lines.add('');
  lines.add('const admin = require(\'firebase-admin\');');
  lines.add('');
  lines.add('// Initialiser Firebase Admin SDK');
  lines.add(
    'const serviceAccount = require(\'./service-account.json\');',
  );
  lines.add('');
  lines.add('admin.initializeApp({');
  lines.add('  credential: admin.credential.cert(serviceAccount)');
  lines.add('});');
  lines.add('');
  lines.add('const db = admin.firestore();');
  lines.add('');
  lines.add('async function importData() {');
  lines.add('  console.log(\'🚀 Début de l\\\'import...\\n\');');
  lines.add('');

  // Catégories
  lines.add('  // Catégories (Niveau 1)');
  lines.add('  console.log(\'📁 Import des catégories...\');');
  for (final category in categories) {
    final id = category['id'];
    final data = _prepareFirestoreData(category);
    final jsonData = _formatJsonForJs(data);
    lines.add('  await db.collection(\'config\').doc(\'categories\')');
    lines.add('    .collection(\'items\').doc(\'$id\').set($jsonData);');
    lines.add('  console.log(\'   ✅ Catégorie: ${category['name']}\');');
  }
  lines.add('');

  // Sous-catégories
  lines.add('  // Sous-catégories');
  lines.add('  console.log(\'\\n📁 Import des sous-catégories...\');');
  for (final subcategory in subcategories) {
    final id = subcategory['id'];
    final data = _prepareFirestoreData(subcategory);
    final jsonData = _formatJsonForJs(data);
    lines.add('  await db.collection(\'config\').doc(\'subcategories\')');
    lines.add('    .collection(\'items\').doc(\'$id\').set($jsonData);');
    lines.add('  console.log(\'   ✅ Sous-catégorie: ${subcategory['name']}\');');
  }
  lines.add('');

  // Attributs
  lines.add('  // Attributs');
  lines.add('  console.log(\'\\n📁 Import des attributs...\');');
  for (final attribute in attributes) {
    final id = attribute['id'];
    final data = _prepareFirestoreData(attribute);
    final jsonData = _formatJsonForJs(data);
    lines.add('  await db.collection(\'config\').doc(\'attributes\')');
    lines.add('    .collection(\'items\').doc(\'$id\').set($jsonData);');
    lines.add('  console.log(\'   ✅ Attribut: ${attribute['name']}\');');
  }
  lines.add('');

  // Fin
  lines.add('  console.log(\'\\n✅ Import terminé avec succès !\');');
  lines.add('  process.exit(0);');
  lines.add('}');
  lines.add('');
  lines.add('// Exécuter l\'import');
  lines.add('importData().catch((error) => {');
  lines.add('  console.error(\'❌ Erreur lors de l\\\'import:\', error);');
  lines.add('  process.exit(1);');
  lines.add('});');

  return lines.join('\n');
}

/// Prépare les données pour Firestore
Map<String, dynamic> _prepareFirestoreData(Map<String, dynamic> data) {
  final result = Map<String, dynamic>.from(data);
  result.remove('id');
  result['createdAt'] = 'TIMESTAMP';
  result['updatedAt'] = 'TIMESTAMP';
  return result;
}

/// Formate un objet JSON pour JavaScript
String _formatJsonForJs(Map<String, dynamic> data) {
  final jsonStr = jsonEncode(data);
  return jsonStr.replaceAll(
    '"TIMESTAMP"',
    'admin.firestore.FieldValue.serverTimestamp()',
  );
}
