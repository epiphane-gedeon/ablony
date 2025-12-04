/// Type d'attribut produit
enum AttributeType {
  /// Sélection unique (dropdown)
  select,

  /// Sélection multiple (checkboxes)
  multiSelect,

  /// Texte libre
  text,

  /// Nombre
  number,

  /// Booléen (oui/non)
  boolean,
}

/// Entité représentant un attribut produit.
///
/// Un attribut définit une caractéristique que peut avoir un produit.
/// 
/// Exemples :
/// - brand (type: select, values: [Nike, Zara, Adidas...])
/// - size_haut (type: select, values: [XS, S, M, L, XL, XXL])
/// - color (type: select, values: [Bleu, Rouge, Noir...])
/// - material (type: select, values: [Coton, Polyester, Laine...])
/// - dressLength (type: select, values: [Court, Mi-long, Long])
class ProductAttribute {
  /// Identifiant unique de l'attribut
  final String id;

  /// Nom affiché de l'attribut
  final String name;

  /// Type d'attribut (select, multiSelect, text, number, boolean)
  final AttributeType type;

  /// Liste des valeurs possibles (pour type select/multiSelect)
  /// 
  /// Exemples :
  /// - brand: ['Nike', 'Zara', 'Adidas', 'H&M', 'Gucci']
  /// - color: ['Bleu', 'Rouge', 'Noir', 'Blanc', 'Rose']
  final List<String> values;

  /// Indique si l'attribut est obligatoire
  final bool isRequired;

  /// Texte d'aide/description (optionnel)
  final String? helpText;

  /// Ordre d'affichage (optionnel)
  final int? order;

  /// Indique si l'attribut est actif
  final bool isActive;

  /// Date de création
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime updatedAt;

  const ProductAttribute({
    required this.id,
    required this.name,
    required this.type,
    this.values = const [],
    this.isRequired = false,
    this.helpText,
    this.order,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée une copie avec certains champs modifiés
  ProductAttribute copyWith({
    String? id,
    String? name,
    AttributeType? type,
    List<String>? values,
    bool? isRequired,
    String? helpText,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductAttribute(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      values: values ?? this.values,
      isRequired: isRequired ?? this.isRequired,
      helpText: helpText ?? this.helpText,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ProductAttribute(id: $id, name: $name, type: $type, values: ${values.length})';
}
