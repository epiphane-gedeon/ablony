/// Énumération représentant les pays où l'application Ablony est disponible.
///
/// Pour la phase initiale de lancement, Ablony est uniquement disponible dans
/// deux pays d'Afrique de l'Ouest : le Togo et le Bénin.
///
/// Cette énumération permet de :
/// - Limiter les choix de pays lors de l'inscription
/// - Gérer les paramètres régionaux (devise, fuseau horaire, langue)
/// - Filtrer les produits et services par pays
/// - Adapter le contenu selon la localisation de l'utilisateur
///
/// Chaque pays dispose de :
/// - Un code ISO 3166-1 alpha-2 (TG, BJ)
/// - Un nom en français
/// - Un emoji de drapeau pour l'affichage
/// - Une devise (Franc CFA - XOF)
enum Country {
  /// République Togolaise
  ///
  /// Code ISO : TG
  /// Capitale : Lomé
  /// Devise : Franc CFA (XOF)
  /// Langue officielle : Français
  /// Fuseau horaire : GMT+0
  ///
  /// Villes principales pour la marketplace :
  /// - Lomé
  /// - Sokodé
  /// - Kara
  /// - Atakpamé
  togo('TG', 'Togo', '🇹🇬', 'Lomé', 'XOF'),

  /// République du Bénin
  ///
  /// Code ISO : BJ
  /// Capitale : Porto-Novo (capitale constitutionnelle)
  /// Capitale économique : Cotonou
  /// Devise : Franc CFA (XOF)
  /// Langue officielle : Français
  /// Fuseau horaire : GMT+1
  ///
  /// Villes principales pour la marketplace :
  /// - Cotonou
  /// - Porto-Novo
  /// - Parakou
  /// - Abomey-Calavi
  benin('BJ', 'Bénin', '🇧🇯', 'Cotonou', 'XOF');

  // ============================================================
  // PROPRIÉTÉS DE L'ÉNUMÉRATION
  // ============================================================

  /// Code ISO 3166-1 alpha-2 du pays
  ///
  /// Ce code à 2 lettres est le standard international pour identifier les pays.
  /// Il est utilisé pour :
  /// - Les requêtes API
  /// - Le stockage dans Firestore
  /// - Les filtres de recherche
  ///
  /// Exemples : 'TG', 'BJ'
  final String code;

  /// Nom complet du pays en français
  ///
  /// Ce nom est affiché dans l'interface utilisateur lors de la sélection
  /// du pays pendant l'inscription.
  ///
  /// Exemples : 'Togo', 'Bénin'
  final String name;

  /// Emoji du drapeau du pays
  ///
  /// Utilisé pour un affichage visuel rapide dans l'interface.
  /// Compatible avec tous les systèmes d'exploitation modernes.
  ///
  /// Exemples : '🇹🇬', '🇧🇯'
  final String flag;

  /// Nom de la ville principale / capitale économique
  ///
  /// Cette ville est utilisée comme ville par défaut lors de l'inscription
  /// et pour les filtres de recherche de produits.
  ///
  /// Exemples : 'Lomé', 'Cotonou'
  final String mainCity;

  /// Code de la devise utilisée dans le pays
  ///
  /// Code ISO 4217 de la devise.
  /// Pour le Togo et le Bénin : 'XOF' (Franc CFA de l'Afrique de l'Ouest)
  ///
  /// Le Franc CFA (XOF) est la monnaie commune de l'Union Économique et
  /// Monétaire Ouest Africaine (UEMOA).
  final String currencyCode;

  /// Constructeur constant pour les valeurs de l'énumération
  ///
  /// Les valeurs sont définies de manière constante pour éviter les allocations
  /// mémoire inutiles et permettre l'utilisation dans des contextes const.
  const Country(
    this.code,
    this.name,
    this.flag,
    this.mainCity,
    this.currencyCode,
  );

  // ============================================================
  // MÉTHODES UTILITAIRES
  // ============================================================

  /// Retourne l'affichage complet du pays : drapeau + nom
  ///
  /// Format : "🇹🇬 Togo"
  ///
  /// Utilisé dans les listes déroulantes et les sélecteurs de pays.
  ///
  /// Exemple :
  /// ```dart
  /// Country.togo.displayName // "🇹🇬 Togo"
  /// Country.benin.displayName // "🇧🇯 Bénin"
  /// ```
  String get displayName => '$flag $name';

  /// Convertit un code ISO en instance de Country
  ///
  /// Cette méthode est utilisée pour la désérialisation depuis Firestore.
  /// Le code doit être en majuscules (TG, BJ).
  ///
  /// Exemple :
  /// ```dart
  /// Country.fromCode('TG') // Country.togo
  /// Country.fromCode('BJ') // Country.benin
  /// ```
  ///
  /// Lance une exception [ArgumentError] si le code pays n'est pas reconnu.
  /// Cela permet de détecter les erreurs de données en production.
  static Country fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'TG':
        return Country.togo;
      case 'BJ':
        return Country.benin;
      default:
        throw ArgumentError(
          'Code pays non supporté : $code. '
          'Les pays supportés sont : TG (Togo), BJ (Bénin)',
        );
    }
  }

  /// Convertit le Country en code ISO pour Firestore
  ///
  /// Cette méthode est utilisée pour la sérialisation vers Firestore.
  /// Elle retourne le code ISO à 2 lettres.
  ///
  /// Exemple :
  /// ```dart
  /// Country.togo.toFirestore() // "TG"
  /// Country.benin.toFirestore() // "BJ"
  /// ```
  String toFirestore() {
    return code;
  }

  /// Retourne la liste de toutes les valeurs disponibles
  ///
  /// Utilisé pour générer dynamiquement la liste des pays dans
  /// l'écran de sélection pendant l'inscription.
  ///
  /// Exemple :
  /// ```dart
  /// Country.all // [Country.togo, Country.benin]
  /// ```
  static List<Country> get all => Country.values;

  /// Vérifie si deux pays partagent la même devise
  ///
  /// Utile pour les conversions de prix et les transactions.
  ///
  /// Exemple :
  /// ```dart
  /// Country.togo.hasSameCurrency(Country.benin) // true (tous deux XOF)
  /// ```
  bool hasSameCurrency(Country other) {
    return currencyCode == other.currencyCode;
  }
}
