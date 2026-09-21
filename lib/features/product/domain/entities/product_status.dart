/// Le cycle de vie d'une annonce.
///
/// Remplace les trois booléens `isSold`, `isReserved` et `isHidden`, qui
/// permettaient huit combinaisons dont plusieurs n'ont aucun sens — vendu
/// *et* réservé, masqué *et* vendu — sans que rien ne les empêche.
///
/// Une seule valeur à la fois, et la base le garantit.
enum ProductStatus {
  /// En vente.
  active,

  /// Réservée le temps d'un paiement.
  reserved,

  /// Vendue. Définitif : un achat ne se défait pas.
  sold,

  /// Retirée par son auteur, qui peut la remettre en ligne d'un geste.
  hidden,

  /// Supprimée par son auteur, ou rejetée puis périmée.
  ///
  /// Le document reste : transactions, reçus et colis y référent, et un reçu
  /// d'acheteur qui pointe dans le vide est pire qu'un document de trop.
  archived;

  static ProductStatus fromWire(String? value) => switch (value) {
    'active' => ProductStatus.active,
    'reserved' => ProductStatus.reserved,
    'sold' => ProductStatus.sold,
    'hidden' => ProductStatus.hidden,
    'archived' => ProductStatus.archived,
    // Une valeur inconnue est traitée comme masquée, jamais comme visible :
    // mieux vaut cacher une annonce à tort que montrer ce qu'on ne comprend
    // pas.
    _ => ProductStatus.hidden,
  };

  String get wireValue => name;

  /// Déduit l'état depuis les trois booléens d'une version ancienne.
  ///
  /// L'ordre porte la priorité : une annonce marquée vendue *et* masquée —
  /// ce que l'ancien modèle n'empêchait pas — reste vendue.
  static ProductStatus fromLegacy({
    required bool isSold,
    required bool isReserved,
    required bool isHidden,
  }) {
    if (isSold) return ProductStatus.sold;
    if (isReserved) return ProductStatus.reserved;
    if (isHidden) return ProductStatus.hidden;
    return ProductStatus.active;
  }

  /// Une annonce vendue ne se modifie plus, et ne se supprime pas.
  bool get isFinal => this == ProductStatus.sold;
}

/// Ce que la modération a décidé d'une annonce.
///
/// Orthogonal au cycle de vie : une annonce peut être vendue **et**
/// approuvée. Les mélanger dans un seul champ ferait perdre l'un des deux à
/// chaque changement de l'autre.
enum ModerationStatus {
  /// Jamais examinée. **L'annonce est en ligne malgré tout** — bloquer la
  /// publication le temps d'un examen tarirait l'offre au démarrage.
  pending,

  /// Examinée et conforme.
  approved,

  /// Non conforme. Retirée de la vente, archivée au bout de dix jours.
  rejected;

  static ModerationStatus fromWire(String? value) => switch (value) {
    'approved' => ModerationStatus.approved,
    'rejected' => ModerationStatus.rejected,
    // `pending` par défaut, y compris pour une valeur inconnue : c'est l'état
    // le plus honnête quand on ne sait pas.
    _ => ModerationStatus.pending,
  };

  String get wireValue => name;
}
