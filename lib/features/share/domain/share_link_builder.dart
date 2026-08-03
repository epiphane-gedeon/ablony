import 'models/shareable_content.dart';

/// Construit l'URL publique d'un contenu partagé. Cette URL pointe vers
/// l'app web (Firebase Hosting) déployée sur le même domaine que les routes
/// go_router (`/product/:id`, ...) — l'ouvrir dans un navigateur affiche
/// directement le contenu partagé, sans passerelle serveur dédiée.
class ShareLinkBuilder {
  const ShareLinkBuilder._();

  /// Domaine Firebase Hosting par défaut du projet `ablony-a5db9`.
  /// À remplacer ici si un nom de domaine personnalisé est configuré.
  static const String baseUrl = 'https://ablony-a5db9.web.app';

  static String build(ShareableContent content) {
    switch (content.type) {
      case ShareableType.product:
        return '$baseUrl/product/${content.id}';
    }
  }
}
