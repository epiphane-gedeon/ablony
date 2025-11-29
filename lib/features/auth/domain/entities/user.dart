import 'package:equatable/equatable.dart';
import 'auth_provider.dart';
import 'country.dart';

/// Entité représentant un utilisateur dans l'application Ablony.
///
/// Cette classe est une entité du domaine (Domain Layer) et représente
/// le concept d'utilisateur de manière pure, indépendamment de la couche
/// de données ou de présentation.
///
/// L'entité User contient toutes les informations essentielles d'un utilisateur :
/// - Identifiants (UID, email, username)
/// - Informations de profil (nom, photo, téléphone)
/// - Méthode d'authentification utilisée
/// - Localisation (pays, ville)
/// - Préférences et consentements
/// - Métadonnées (dates de création/modification)
/// - Statut du compte
///
/// Note : Cette classe utilise [Equatable] pour faciliter les comparaisons
/// d'instances et est immuable (tous les champs sont final).
class User extends Equatable {
  // ============================================================
  // IDENTIFIANTS UNIQUES
  // ============================================================

  /// Identifiant unique de l'utilisateur dans Firebase Auth
  ///
  /// Cet ID est généré automatiquement par Firebase lors de la création
  /// du compte et ne change jamais. Il est utilisé comme clé primaire
  /// dans Firestore et pour toutes les relations.
  ///
  /// Exemple : "xK7mP3nQ8dRsT2vY4wZ1"
  final String uid;

  /// Adresse email de l'utilisateur
  ///
  /// Email utilisé pour :
  /// - L'authentification (si connexion par email)
  /// - Les communications (newsletters, notifications)
  /// - La récupération de compte
  ///
  /// Important : Cet email peut être masqué si l'utilisateur s'est connecté
  /// avec Apple et a choisi de masquer son adresse réelle.
  ///
  /// Exemple : "user@example.com" ou "privaterelay.appleid.com"
  final String email;

  /// Nom d'utilisateur unique (identifiant public)
  ///
  /// Ce nom d'utilisateur est :
  /// - Unique dans toute l'application (vérifié lors de l'inscription)
  /// - Utilisé pour les profils publics (@username)
  /// - Visible par les autres utilisateurs
  /// - Modifiable (mais avec vérification d'unicité)
  ///
  /// Format : alphanumérique + tirets/underscores, 3-30 caractères
  /// Exemple : "epiphane-gedeon", "marie_kouassi"
  final String username;

  // ============================================================
  // INFORMATIONS DE PROFIL
  // ============================================================

  /// Nom complet de l'utilisateur (optionnel)
  ///
  /// Ce nom est récupéré automatiquement lors de la connexion sociale
  /// (Google, Facebook, Apple) mais reste optionnel.
  ///
  /// Il peut être modifié par l'utilisateur dans les paramètres de profil.
  ///
  /// Exemple : "Épiphane Gédéon", "Marie Kouassi"
  final String? displayName;

  /// URL de la photo de profil (optionnel)
  ///
  /// Cette URL pointe vers :
  /// - La photo de profil du compte social (Google, Facebook, Apple)
  /// - Une photo uploadée par l'utilisateur
  /// - null si aucune photo n'est définie
  ///
  /// Note : Pour les photos uploadées, utiliser Firebase Storage
  /// et stocker l'URL de téléchargement ici.
  ///
  /// Exemple : "https://lh3.googleusercontent.com/..."
  final String? photoUrl;

  /// Numéro de téléphone (optionnel)
  ///
  /// Format international recommandé : +[code pays][numéro]
  ///
  /// Utilisé pour :
  /// - Vérification d'identité supplémentaire
  /// - Contact pour les transactions
  /// - Notifications SMS (futures fonctionnalités)
  ///
  /// Exemple : "+22890123456" (Togo), "+22961234567" (Bénin)
  final String? phoneNumber;

  // ============================================================
  // MÉTHODE D'AUTHENTIFICATION
  // ============================================================

  /// Fournisseur d'authentification utilisé lors de l'inscription
  ///
  /// Indique comment l'utilisateur s'est inscrit :
  /// - [AuthProvider.google] : Via Google Sign-In
  /// - [AuthProvider.facebook] : Via Facebook Login
  /// - [AuthProvider.apple] : Via Apple Sign-In
  /// - [AuthProvider.email] : Via email/mot de passe
  ///
  /// Cette information permet de :
  /// - Afficher le bon bouton de connexion
  /// - Gérer les reconnexions
  /// - Personnaliser l'expérience utilisateur
  final AuthProvider authProvider;

  /// Identifiant du compte chez le provider social (optionnel)
  ///
  /// Stocke l'ID du compte Google/Facebook/Apple pour référence.
  /// Null si l'utilisateur s'est inscrit par email.
  ///
  /// Exemple : "112345678901234567890" (Google ID)
  final String? providerId;

  // ============================================================
  // LOCALISATION
  // ============================================================

  /// Pays de résidence de l'utilisateur
  ///
  /// Obligatoire lors de l'inscription. Permet de :
  /// - Filtrer les produits disponibles dans le même pays
  /// - Gérer les règles de livraison
  /// - Adapter le contenu (langue, devise, etc.)
  ///
  /// Valeurs possibles : [Country.togo] ou [Country.benin]
  final Country country;

  /// Ville de résidence (optionnel)
  ///
  /// Permet une localisation plus précise pour :
  /// - Les recherches de proximité
  /// - Les frais de livraison
  /// - Les annonces locales
  ///
  /// Exemple : "Lomé", "Cotonou", "Sokodé"
  final String? city;

  // ============================================================
  // PRÉFÉRENCES ET CONSENTEMENTS
  // ============================================================

  /// Indique si l'utilisateur a accepté les Conditions Générales d'Utilisation
  ///
  /// Obligatoire = true pour créer un compte.
  /// Stocké avec la date d'acceptation pour conformité légale (RGPD).
  final bool acceptedTerms;

  /// Date et heure d'acceptation des CGU
  ///
  /// Enregistrée pour des raisons légales et de traçabilité.
  /// Permet de savoir quelle version des CGU l'utilisateur a acceptée.
  final DateTime acceptedTermsDate;

  /// Consentement pour recevoir des emails marketing
  ///
  /// - true : L'utilisateur accepte de recevoir newsletters et offres
  /// - false : L'utilisateur refuse les communications marketing
  ///
  /// Modifiable à tout moment dans les paramètres.
  /// Respecte les réglementations anti-spam.
  final bool marketingEmailsEnabled;

  // ============================================================
  // MÉTADONNÉES
  // ============================================================

  /// Date et heure de création du compte
  ///
  /// Timestamp enregistré lors de l'inscription.
  /// Utilisé pour :
  /// - L'ordre chronologique des utilisateurs
  /// - Les statistiques d'inscription
  /// - Les badges "nouveau membre"
  final DateTime createdAt;

  /// Date et heure de dernière modification du profil
  ///
  /// Mise à jour automatiquement à chaque modification des données.
  /// Permet de synchroniser les données entre appareils.
  final DateTime updatedAt;

  /// Indique si l'email ou le téléphone a été vérifié
  ///
  /// - true : Email vérifié (via lien de vérification)
  /// - false : Email non vérifié
  ///
  /// Les utilisateurs avec email vérifié peuvent avoir accès à plus de
  /// fonctionnalités (vente de produits, messagerie, etc.)
  final bool isVerified;

  /// Indique si le compte est actif
  ///
  /// - true : Compte normal et actif
  /// - false : Compte suspendu ou banni
  ///
  /// Un compte inactif ne peut pas :
  /// - Se connecter à l'application
  /// - Publier des annonces
  /// - Contacter d'autres utilisateurs
  final bool isActive;

  // ============================================================
  // STATISTIQUES UTILISATEUR (pour la marketplace)
  // ============================================================

  /// Nombre de produits actuellement en vente par cet utilisateur
  ///
  /// Mis à jour automatiquement lors de la publication/suppression d'annonces.
  /// Affiché sur le profil public.
  final int productsCount;

  /// Nombre total de ventes réalisées
  ///
  /// Compteur incrémenté à chaque vente confirmée.
  /// Indicateur de fiabilité du vendeur.
  final int salesCount;

  /// Note moyenne du vendeur (0.0 à 5.0)
  ///
  /// Calculée à partir des avis laissés par les acheteurs.
  /// - 0.0 : Aucun avis ou note très basse
  /// - 5.0 : Note maximale
  ///
  /// Format : 1 décimale (ex: 4.5)
  final double rating;

  /// Nombre d'avis reçus
  ///
  /// Nombre total d'évaluations laissées par les acheteurs.
  /// Plus ce nombre est élevé, plus la note moyenne est fiable.
  final int reviewsCount;

  // ============================================================
  // CONSTRUCTEUR
  // ============================================================

  /// Constructeur de l'entité User
  ///
  /// Tous les champs obligatoires doivent être fournis.
  /// Les champs optionnels peuvent être null.
  const User({
    required this.uid,
    required this.email,
    required this.username,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.authProvider,
    this.providerId,
    required this.country,
    this.city,
    required this.acceptedTerms,
    required this.acceptedTermsDate,
    required this.marketingEmailsEnabled,
    required this.createdAt,
    required this.updatedAt,
    required this.isVerified,
    required this.isActive,
    this.productsCount = 0,
    this.salesCount = 0,
    this.rating = 0.0,
    this.reviewsCount = 0,
  });

  // ============================================================
  // MÉTHODES UTILITAIRES
  // ============================================================

  /// Crée une copie de l'utilisateur avec certains champs modifiés
  ///
  /// Utilisé pour mettre à jour les informations de l'utilisateur de manière
  /// immuable. Seuls les champs fournis seront modifiés.
  ///
  /// Exemple :
  /// ```dart
  /// final updatedUser = user.copyWith(
  ///   username: 'nouveau_username',
  ///   city: 'Lomé',
  /// );
  /// ```
  User copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    AuthProvider? authProvider,
    String? providerId,
    Country? country,
    String? city,
    bool? acceptedTerms,
    DateTime? acceptedTermsDate,
    bool? marketingEmailsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isActive,
    int? productsCount,
    int? salesCount,
    double? rating,
    int? reviewsCount,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authProvider: authProvider ?? this.authProvider,
      providerId: providerId ?? this.providerId,
      country: country ?? this.country,
      city: city ?? this.city,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedTermsDate: acceptedTermsDate ?? this.acceptedTermsDate,
      marketingEmailsEnabled:
          marketingEmailsEnabled ?? this.marketingEmailsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      productsCount: productsCount ?? this.productsCount,
      salesCount: salesCount ?? this.salesCount,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }

  // ============================================================
  // EQUATABLE - Comparaison d'instances
  // ============================================================

  /// Liste des propriétés utilisées pour la comparaison d'égalité
  ///
  /// Deux instances de User sont considérées égales si elles ont le même UID.
  /// Les autres propriétés ne sont pas prises en compte pour l'égalité car
  /// l'UID est l'identifiant unique et immuable.
  @override
  List<Object?> get props => [uid];

  /// Retourne une représentation textuelle de l'utilisateur
  ///
  /// Utile pour le debugging et les logs.
  ///
  /// Exemple : "User(uid: abc123, username: john_doe, email: john@example.com)"
  @override
  String toString() {
    return 'User(uid: $uid, username: $username, email: $email, country: ${country.name})';
  }
}
