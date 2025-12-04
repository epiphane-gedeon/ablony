/// Entité représentant une catégorie de niveau 1 (racine).
///
/// Exemples : Femme, Homme, Enfant, Maison, Électronique...
/// 
/// Une catégorie peut avoir des sous-catégories (children).
class Category {
  /// Identifiant unique de la catégorie
  final String id;

  /// Nom affiché de la catégorie
  final String name;

  /// Liste des IDs des sous-catégories directes
  final List<String> children;

  /// Ordre d'affichage (optionnel)
  final int? order;

  /// URL de l'icône/image (optionnel)
  final String? iconUrl;

  /// Indique si la catégorie est active
  final bool isActive;

  /// Date de création
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.children = const [],
    this.order,
    this.iconUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée une copie avec certains champs modifiés
  Category copyWith({
    String? id,
    String? name,
    List<String>? children,
    int? order,
    String? iconUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      children: children ?? this.children,
      order: order ?? this.order,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, children: ${children.length})';
}
