import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Service pour uploader les images de produits vers Firebase Storage.
///
/// Gère l'upload, la compression et la suppression des images.
/// Structure de stockage : `products/{userId}/{productId}/image_{index}.jpg`
class ImageUploadService {
  final FirebaseStorage _storage;

  ImageUploadService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Upload les images d'un produit et retourne les URLs de téléchargement.
  ///
  /// **Paramètres :**
  /// - [images] : Liste des fichiers images (1-6)
  /// - [userId] : ID de l'utilisateur
  /// - [productId] : ID du produit (peut être temporaire avant création)
  ///
  /// **Retourne :**
  /// - Liste des URLs de téléchargement dans l'ordre
  ///
  /// **Exemple :**
  /// ```dart
  /// final urls = await imageUploadService.uploadProductImages(
  ///   images,
  ///   'user_123',
  ///   'product_456',
  /// );
  /// ```
  Future<List<String>> uploadProductImages(
    List<XFile> images,
    String userId,
    String productId,
  ) async {
    if (images.isEmpty) {
      throw Exception('Aucune image à uploader');
    }

    if (images.length > 6) {
      throw Exception('Maximum 6 images autorisées');
    }

    final urls = <String>[];

    try {
      debugPrint(
        '🔄 ImageUploadService: Début upload de ${images.length} images',
      );
      debugPrint('   Bucket: ${_storage.bucket}');

      for (int i = 0; i < images.length; i++) {
        final file = images[i];

        // Chemin dans Storage : products/{userId}/{productId}/image_{i}.jpg
        final path = 'products/$userId/$productId/image_$i.jpg';
        final ref = _storage.ref().child(path);

        debugPrint('   📤 Upload image $i vers: $path');

        // Métadonnées
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'productId': productId,
            'index': i.toString(),
          },
        );

        // Upload
        try {
          final bytes = await file.readAsBytes();
          final uploadTask = ref.putData(bytes, metadata);
          final snapshot = await uploadTask;

          // Récupérer l'URL de téléchargement
          final downloadUrl = await snapshot.ref.getDownloadURL();
          urls.add(downloadUrl);

          debugPrint(
            '   ✅ Image $i uploadée: ${downloadUrl.substring(0, 50)}...',
          );
        } catch (uploadError) {
          debugPrint('   ❌ Erreur upload image $i: $uploadError');

          // Si c'est une erreur Firebase, donner plus de détails
          if (uploadError is FirebaseException) {
            debugPrint('      Code: ${uploadError.code}');
            debugPrint('      Message: ${uploadError.message}');
            debugPrint('      Plugin: ${uploadError.plugin}');
          }

          throw Exception(
            'Erreur lors de l\'upload de l\'image $i: $uploadError',
          );
        }
      }

      debugPrint('✅ Tous les uploads terminés: ${urls.length} URLs');
      return urls;
    } catch (e) {
      debugPrint('❌ Erreur générale upload: $e');
      // En cas d'erreur, supprimer les images déjà uploadées
      await _cleanupPartialUpload(userId, productId, urls.length);
      rethrow;
    }
  }

  /// Supprime toutes les images d'un produit.
  ///
  /// **Paramètres :**
  /// - [userId] : ID de l'utilisateur
  /// - [productId] : ID du produit
  ///
  /// **Exemple :**
  /// ```dart
  /// await imageUploadService.deleteProductImages('user_123', 'product_456');
  /// ```
  Future<void> deleteProductImages(String userId, String productId) async {
    try {
      final folderRef = _storage.ref().child('products/$userId/$productId');

      // Lister tous les fichiers dans le dossier
      final listResult = await folderRef.listAll();

      // Supprimer chaque fichier
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // Ignorer les erreurs si le dossier n'existe pas
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      rethrow;
    }
  }

  /// Nettoie un upload partiel en cas d'erreur.
  ///
  /// Supprime les images déjà uploadées si l'upload complet échoue.
  Future<void> _cleanupPartialUpload(
    String userId,
    String productId,
    int uploadedCount,
  ) async {
    try {
      for (int i = 0; i < uploadedCount; i++) {
        final path = 'products/$userId/$productId/image_$i.jpg';
        final ref = _storage.ref().child(path);
        await ref.delete();
      }
    } catch (e) {
      // Ignorer les erreurs de nettoyage
      if (kDebugMode) {
        print('Erreur lors du nettoyage : $e');
      }
    }
  }

  /// Remplace une image spécifique d'un produit.
  ///
  /// **Paramètres :**
  /// - [newImage] : Nouvelle image
  /// - [userId] : ID de l'utilisateur
  /// - [productId] : ID du produit
  /// - [index] : Index de l'image à remplacer (0-5)
  ///
  /// **Retourne :**
  /// - URL de téléchargement de la nouvelle image
  Future<String> replaceProductImage(
    XFile newImage,
    String userId,
    String productId,
    int index,
  ) async {
    if (index < 0 || index > 5) {
      throw Exception('Index invalide (doit être entre 0 et 5)');
    }

    final path = 'products/$userId/$productId/image_$index.jpg';
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uploadedBy': userId,
        'productId': productId,
        'index': index.toString(),
      },
    );

    final bytes = await newImage.readAsBytes();
    final uploadTask = ref.putData(bytes, metadata);
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }
}

/// Provider Riverpod pour ImageUploadService
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});
