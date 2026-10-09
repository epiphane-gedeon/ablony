import '../../../core/config/app_urls.dart';
import 'models/shareable_content.dart';

/// Construit l'URL publique d'un contenu partagé. Cette URL pointe vers
/// l'app web (Firebase Hosting) déployée sur le même domaine que les routes
/// go_router (`/product/:id`, ...) — l'ouvrir dans un navigateur affiche
/// directement le contenu partagé, sans passerelle serveur dédiée.
class ShareLinkBuilder {
  const ShareLinkBuilder._();

  static String build(ShareableContent content) {
    switch (content.type) {
      // L'adresse vient d'AppUrls : un lien d'annonce est ce qui circule le
      // plus loin d'Ablony, et il ne doit pas pointer vers un domaine qu'on
      // aurait oublié de mettre à jour ici.
      case ShareableType.product:
        return '${AppUrls.productShareBase}/${content.id}';
    }
  }
}
