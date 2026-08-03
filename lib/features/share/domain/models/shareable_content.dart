/// Types de contenu que la fonctionnalité de partage sait gérer.
///
/// Ajouter un nouveau type ici (ex. profil vendeur) puis lui donner un
/// chemin dans [ShareLinkBuilder] suffit à le rendre partageable partout
/// dans l'app, sans dupliquer la logique de partage à chaque endroit.
enum ShareableType { product }

/// Contenu générique à partager : un produit aujourd'hui, potentiellement
/// autre chose demain (profil, collection...). Le texte affiché (titre,
/// sous-titre) est déjà localisé par l'appelant — ce module reste agnostique
/// des traductions.
class ShareableContent {
  final ShareableType type;
  final String id;
  final String title;
  final String? subtitle;

  const ShareableContent({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
  });

  factory ShareableContent.product({
    required String id,
    required String title,
    String? subtitle,
  }) {
    return ShareableContent(type: ShareableType.product, id: id, title: title, subtitle: subtitle);
  }
}
