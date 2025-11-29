import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// Modèle de données pour l'utilisateur avec sérialisation Firestore.
///
/// Cette classe étend l'entité [User] et ajoute les fonctionnalités de
/// sérialisation/désérialisation nécessaires pour communiquer avec
/// Cloud Firestore (base de données Firebase).
///
/// **Différence entre Entity et Model :**
/// - **Entity** (domain/entities/user.dart) : Représentation pure du concept
///   métier, indépendante de toute technologie ou framework
/// - **Model** (data/models/user_model.dart) : Adaptation de l'entity pour
///   les besoins techniques (JSON, Firestore, API, etc.)
///
/// **Responsabilités de UserModel :**
/// - Convertir un document Firestore en instance de User (fromFirestore)
/// - Convertir une instance de User en document Firestore (toFirestore)
/// - Gérer les conversions de types (Timestamp ↔ DateTime, enum ↔ String)
/// - Valider les données lors de la désérialisation
/// - Gérer les champs optionnels et les valeurs par défaut
///
/// **Exemple d'utilisation :**
/// ```dart
/// // Lire depuis Firestore
/// final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
/// final user = UserModel.fromFirestore(doc, null);
///
/// // Écrire dans Firestore
/// await FirebaseFirestore.instance
///     .collection('users')
///     .doc(user.uid)
///     .set(UserModel.fromEntity(user).toFirestore());
/// ```
class UserModel extends User {
  /// Constructeur du modèle UserModel
  ///
  /// Utilise le constructeur de la classe parente [User] avec tous les
  /// mêmes paramètres. Ce constructeur est principalement utilisé en interne
  /// pour créer des instances après désérialisation.
  const UserModel({
    required super.uid,
    required super.email,
    required super.username,
    super.displayName,
    super.photoUrl,
    super.phoneNumber,
    required super.authProvider,
    super.providerId,
    required super.country,
    super.city,
    required super.acceptedTerms,
    required super.acceptedTermsDate,
    required super.marketingEmailsEnabled,
    required super.createdAt,
    required super.updatedAt,
    required super.isVerified,
    required super.isActive,
    super.productsCount,
    super.salesCount,
    super.rating,
    super.reviewsCount,
  });

  // ============================================================
  // FACTORY CONSTRUCTORS - Création depuis différentes sources
  // ============================================================

  /// Crée un UserModel depuis une entité User existante
  ///
  /// Cette méthode est utile pour convertir une entité du domaine en modèle
  /// avant de la sauvegarder dans Firestore.
  ///
  /// **Exemple :**
  /// ```dart
  /// // On a une entité User du domaine
  /// User domainUser = User(...);
  ///
  /// // On la convertit en UserModel pour la sauvegarder
  /// UserModel model = UserModel.fromEntity(domainUser);
  /// await firestore.collection('users').doc(model.uid).set(model.toFirestore());
  /// ```
  factory UserModel.fromEntity(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      phoneNumber: user.phoneNumber,
      authProvider: user.authProvider,
      providerId: user.providerId,
      country: user.country,
      city: user.city,
      acceptedTerms: user.acceptedTerms,
      acceptedTermsDate: user.acceptedTermsDate,
      marketingEmailsEnabled: user.marketingEmailsEnabled,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isVerified: user.isVerified,
      isActive: user.isActive,
      productsCount: user.productsCount,
      salesCount: user.salesCount,
      rating: user.rating,
      reviewsCount: user.reviewsCount,
    );
  }

  /// Crée un UserModel depuis un document Firestore
  ///
  /// Cette méthode est appelée automatiquement par Firestore lors de la
  /// lecture d'un document avec `.withConverter()`.
  ///
  /// **Paramètres :**
  /// - [snapshot] : Le document Firestore contenant les données
  /// - [options] : Options de sérialisation (rarement utilisées)
  ///
  /// **Gestion des erreurs :**
  /// - Lance [ArgumentError] si un champ obligatoire est manquant
  /// - Lance [FormatException] si un format de données est invalide
  /// - Retourne des valeurs par défaut pour les champs optionnels
  ///
  /// **Exemple :**
  /// ```dart
  /// final userRef = FirebaseFirestore.instance
  ///     .collection('users')
  ///     .doc(uid)
  ///     .withConverter<UserModel>(
  ///       fromFirestore: UserModel.fromFirestore,
  ///       toFirestore: (user, _) => user.toFirestore(),
  ///     );
  ///
  /// final doc = await userRef.get();
  /// final user = doc.data(); // UserModel
  /// ```
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    // Récupérer les données du document
    // Si le document n'existe pas, data() retourne null
    final data = snapshot.data();

    if (data == null) {
      throw ArgumentError(
        'Le document Firestore est vide ou n\'existe pas : ${snapshot.id}',
      );
    }

    // Fonction helper pour récupérer un champ obligatoire
    // Lance une exception si le champ est absent
    T getRequiredField<T>(String fieldName) {
      if (!data.containsKey(fieldName) || data[fieldName] == null) {
        throw ArgumentError(
          'Le champ obligatoire "$fieldName" est manquant dans le document ${snapshot.id}',
        );
      }
      return data[fieldName] as T;
    }

    // Fonction helper pour récupérer un champ optionnel
    // Retourne null si le champ est absent ou null
    T? getOptionalField<T>(String fieldName) {
      if (!data.containsKey(fieldName) || data[fieldName] == null) {
        return null;
      }
      return data[fieldName] as T;
    }

    // Conversion des Timestamps Firestore en DateTime
    // Firestore stocke les dates sous forme de Timestamp
    DateTime timestampToDateTime(dynamic value, String fieldName) {
      if (value == null) {
        throw ArgumentError('Le timestamp "$fieldName" est null');
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is int) {
        // Timestamp Unix en millisecondes
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      throw FormatException(
        'Format de date invalide pour le champ "$fieldName": $value',
      );
    }

    try {
      return UserModel(
        // IDENTIFIANTS
        uid: getRequiredField<String>('uid'),
        email: getRequiredField<String>('email'),
        username: getRequiredField<String>('username'),

        // PROFIL (optionnels)
        displayName: getOptionalField<String>('displayName'),
        photoUrl: getOptionalField<String>('photoUrl'),
        phoneNumber: getOptionalField<String>('phoneNumber'),

        // AUTHENTIFICATION
        authProvider: AuthProvider.fromString(
          getRequiredField<String>('authProvider'),
        ),
        providerId: getOptionalField<String>('providerId'),

        // LOCALISATION
        country: Country.fromCode(getRequiredField<String>('country')),
        city: getOptionalField<String>('city'),

        // CONSENTEMENTS
        acceptedTerms: getRequiredField<bool>('acceptedTerms'),
        acceptedTermsDate: timestampToDateTime(
          data['acceptedTermsDate'],
          'acceptedTermsDate',
        ),
        marketingEmailsEnabled: getRequiredField<bool>(
          'marketingEmailsEnabled',
        ),

        // MÉTADONNÉES
        createdAt: timestampToDateTime(data['createdAt'], 'createdAt'),
        updatedAt: timestampToDateTime(data['updatedAt'], 'updatedAt'),
        isVerified: getRequiredField<bool>('isVerified'),
        isActive: getRequiredField<bool>('isActive'),

        // STATISTIQUES (avec valeurs par défaut si absentes)
        productsCount: data['productsCount'] as int? ?? 0,
        salesCount: data['salesCount'] as int? ?? 0,
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        reviewsCount: data['reviewsCount'] as int? ?? 0,
      );
    } catch (e) {
      // Capturer et enrichir l'erreur avec le contexte
      throw FormatException(
        'Erreur lors de la désérialisation du document ${snapshot.id}: $e',
      );
    }
  }

  /// Crée un UserModel depuis un Map<String, dynamic> (JSON-like)
  ///
  /// Cette méthode est utile pour créer un utilisateur depuis :
  /// - Des données JSON d'une API
  /// - Des tests unitaires
  /// - Des imports de données
  ///
  /// **Différence avec fromFirestore :**
  /// - fromFirestore gère les types Firestore spécifiques (Timestamp)
  /// - fromJson gère les types standard (String, int, Map, etc.)
  ///
  /// **Exemple :**
  /// ```dart
  /// final json = {
  ///   'uid': 'abc123',
  ///   'email': 'test@example.com',
  ///   'username': 'testuser',
  ///   // ... autres champs
  /// };
  /// final user = UserModel.fromJson(json);
  /// ```
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      authProvider: AuthProvider.fromString(json['authProvider'] as String),
      providerId: json['providerId'] as String?,
      country: Country.fromCode(json['country'] as String),
      city: json['city'] as String?,
      acceptedTerms: json['acceptedTerms'] as bool,
      acceptedTermsDate: DateTime.parse(json['acceptedTermsDate'] as String),
      marketingEmailsEnabled: json['marketingEmailsEnabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isVerified: json['isVerified'] as bool,
      isActive: json['isActive'] as bool,
      productsCount: json['productsCount'] as int? ?? 0,
      salesCount: json['salesCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviewsCount'] as int? ?? 0,
    );
  }

  // ============================================================
  // MÉTHODES DE SÉRIALISATION
  // ============================================================

  /// Convertit le UserModel en Map pour Firestore
  ///
  /// Cette méthode transforme l'objet UserModel en un Map<String, dynamic>
  /// compatible avec Firestore. Elle effectue les conversions nécessaires :
  /// - DateTime → Timestamp
  /// - Enum → String
  /// - null → champ absent (pour économiser l'espace de stockage)
  ///
  /// **Utilisation :**
  /// ```dart
  /// final user = UserModel(...);
  ///
  /// // Sauvegarder dans Firestore
  /// await FirebaseFirestore.instance
  ///     .collection('users')
  ///     .doc(user.uid)
  ///     .set(user.toFirestore());
  ///
  /// // Mettre à jour des champs spécifiques
  /// await FirebaseFirestore.instance
  ///     .collection('users')
  ///     .doc(user.uid)
  ///     .update(user.toFirestore());
  /// ```
  ///
  /// **Optimisations :**
  /// - Les champs null ne sont pas inclus (économie d'espace)
  /// - Les dates sont converties en Timestamp pour les requêtes temporelles
  /// - Les enums sont sérialisées en minuscules pour cohérence
  Map<String, dynamic> toFirestore() {
    // Map de base avec tous les champs obligatoires
    final Map<String, dynamic> data = {
      'uid': uid,
      'email': email,
      'username': username,
      'authProvider': authProvider.toFirestore(),
      'country': country.toFirestore(),
      'acceptedTerms': acceptedTerms,
      'acceptedTermsDate': Timestamp.fromDate(acceptedTermsDate),
      'marketingEmailsEnabled': marketingEmailsEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'isActive': isActive,
      'productsCount': productsCount,
      'salesCount': salesCount,
      'rating': rating,
      'reviewsCount': reviewsCount,
    };

    // Ajouter les champs optionnels seulement s'ils ne sont pas null
    // Cela réduit la taille du document Firestore et économise des coûts
    if (displayName != null) {
      data['displayName'] = displayName;
    }
    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }
    if (phoneNumber != null) {
      data['phoneNumber'] = phoneNumber;
    }
    if (providerId != null) {
      data['providerId'] = providerId;
    }
    if (city != null) {
      data['city'] = city;
    }

    return data;
  }

  /// Convertit le UserModel en Map JSON standard
  ///
  /// Contrairement à toFirestore(), cette méthode retourne un JSON standard
  /// avec des types basiques (String, int, double, bool) sans types Firestore.
  ///
  /// **Utilisation :**
  /// - Envoi de données vers une API REST
  /// - Stockage local (SharedPreferences, SQLite)
  /// - Logs et debugging
  /// - Tests unitaires
  ///
  /// **Exemple :**
  /// ```dart
  /// final user = UserModel(...);
  /// final json = user.toJson();
  /// print(json); // Map standard sans Timestamp
  ///
  /// // Sérialiser en String JSON
  /// String jsonString = jsonEncode(user.toJson());
  /// ```
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'uid': uid,
      'email': email,
      'username': username,
      'authProvider': authProvider.toFirestore(),
      'country': country.toFirestore(),
      'acceptedTerms': acceptedTerms,
      'acceptedTermsDate': acceptedTermsDate.toIso8601String(),
      'marketingEmailsEnabled': marketingEmailsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVerified': isVerified,
      'isActive': isActive,
      'productsCount': productsCount,
      'salesCount': salesCount,
      'rating': rating,
      'reviewsCount': reviewsCount,
    };

    // Ajouter les champs optionnels
    if (displayName != null) {
      json['displayName'] = displayName;
    }
    if (photoUrl != null) {
      json['photoUrl'] = photoUrl;
    }
    if (phoneNumber != null) {
      json['phoneNumber'] = phoneNumber;
    }
    if (providerId != null) {
      json['providerId'] = providerId;
    }
    if (city != null) {
      json['city'] = city;
    }

    return json;
  }

  // ============================================================
  // MÉTHODES UTILITAIRES SPÉCIFIQUES AU MODÈLE
  // ============================================================

  /// Crée une référence Firestore pour ce document utilisateur
  ///
  /// Retourne une référence typée vers le document Firestore de cet utilisateur
  /// avec les converters configurés automatiquement.
  ///
  /// **Avantages :**
  /// - Sérialisation/désérialisation automatique
  /// - Type safety (retourne UserModel au lieu de Map)
  /// - Code plus propre et moins répétitif
  ///
  /// **Exemple :**
  /// ```dart
  /// final user = UserModel(...);
  /// final ref = user.getDocumentReference();
  ///
  /// // Mise à jour typée
  /// await ref.update({...});
  ///
  /// // Lecture typée
  /// final snapshot = await ref.get();
  /// final userData = snapshot.data(); // UserModel
  /// ```
  DocumentReference<UserModel> getDocumentReference() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .withConverter<UserModel>(
          fromFirestore: (snapshot, options) =>
              UserModel.fromFirestore(snapshot, options),
          toFirestore: (user, options) => user.toFirestore(),
        );
  }

  /// Copie le UserModel avec mise à jour automatique de `updatedAt`
  ///
  /// Similaire à User.copyWith() mais met à jour automatiquement le champ
  /// `updatedAt` à DateTime.now() pour garantir la cohérence des dates.
  ///
  /// **Exemple :**
  /// ```dart
  /// final updatedUser = user.copyWithTimestamp(
  ///   username: 'nouveau_username',
  ///   city: 'Lomé',
  /// );
  /// // updatedUser.updatedAt contient automatiquement DateTime.now()
  /// ```
  UserModel copyWithTimestamp({
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
    bool? isVerified,
    bool? isActive,
    int? productsCount,
    int? salesCount,
    double? rating,
    int? reviewsCount,
  }) {
    return UserModel(
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
      // ⚠️ updatedAt est toujours mis à jour à la date actuelle
      updatedAt: DateTime.now(),
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      productsCount: productsCount ?? this.productsCount,
      salesCount: salesCount ?? this.salesCount,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }
}
