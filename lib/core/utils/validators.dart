/// Fichier: validators.dart
/// Description: Fonctions de validation réutilisables pour les formulaires.
///
/// Ce fichier contient toutes les fonctions de validation des champs de saisie
/// utilisées dans l'application. Chaque validateur retourne null si la validation
/// réussit, ou un message d'erreur si elle échoue.
///
/// **Utilisation :**
/// ```dart
/// TextFormField(
///   validator: Validators.email,
///   // ou
///   validator: (value) => Validators.required(value, 'Email requis'),
/// )
/// ```
///
/// **Convention de nommage :**
/// - Les validateurs simples sont des fonctions statiques
/// - Les validateurs paramétrables retournent une fonction de validation
///
/// **Exemple de composition :**
/// ```dart
/// validator: (value) {
///   // Vérifier d'abord que le champ n'est pas vide
///   final requiredError = Validators.required(value);
///   if (requiredError != null) return requiredError;
///
///   // Puis vérifier le format
///   return Validators.email(value);
/// }
/// ```

class Validators {
  // Constructeur privé pour empêcher l'instanciation
  Validators._();

  // ============================================================
  // VALIDATEURS DE BASE
  // ============================================================

  /// Vérifie qu'un champ n'est pas vide.
  ///
  /// **Paramètres :**
  /// - [value] : La valeur à valider
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si le champ est rempli
  /// - Message d'erreur si le champ est vide
  ///
  /// **Exemple :**
  /// ```dart
  /// validator: (value) => Validators.required(value, 'Le nom est obligatoire')
  /// ```
  static String? required(String? value, [String? errorMessage]) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'Ce champ est obligatoire';
    }
    return null;
  }

  /// Vérifie la longueur minimale d'un champ.
  ///
  /// **Paramètres :**
  /// - [value] : La valeur à valider
  /// - [minLength] : Longueur minimale requise
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si la longueur est suffisante
  /// - Message d'erreur si trop court
  ///
  /// **Exemple :**
  /// ```dart
  /// validator: (value) => Validators.minLength(value, 8, 'Minimum 8 caractères')
  /// ```
  static String? minLength(
    String? value,
    int minLength, [
    String? errorMessage,
  ]) {
    if (value == null || value.length < minLength) {
      return errorMessage ?? 'Minimum $minLength caractères requis';
    }
    return null;
  }

  /// Vérifie la longueur maximale d'un champ.
  ///
  /// **Paramètres :**
  /// - [value] : La valeur à valider
  /// - [maxLength] : Longueur maximale autorisée
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si la longueur est acceptable
  /// - Message d'erreur si trop long
  static String? maxLength(
    String? value,
    int maxLength, [
    String? errorMessage,
  ]) {
    if (value != null && value.length > maxLength) {
      return errorMessage ?? 'Maximum $maxLength caractères autorisés';
    }
    return null;
  }

  // ============================================================
  // VALIDATEURS D'EMAIL
  // ============================================================

  /// Vérifie le format d'une adresse email.
  ///
  /// Utilise une regex standard pour valider le format :
  /// - Au moins un caractère avant le @
  /// - Un @ obligatoire
  /// - Un nom de domaine valide après le @
  /// - Une extension de domaine (.com, .fr, etc.)
  ///
  /// **Exemples valides :**
  /// - john.doe@example.com
  /// - test+alias@domain.co.uk
  /// - user123@subdomain.domain.fr
  ///
  /// **Exemples invalides :**
  /// - @example.com (pas de partie locale)
  /// - john@com (pas d'extension)
  /// - john.doe@ (pas de domaine)
  ///
  /// **Paramètres :**
  /// - [value] : L'email à valider
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si l'email est valide
  /// - Message d'erreur si le format est invalide
  static String? email(String? value, [String? errorMessage]) {
    if (value == null || value.trim().isEmpty) {
      return null; // Ne pas valider si vide (utiliser required() pour ça)
    }

    // Regex pour valider le format email
    // Explication de la regex :
    // ^[a-zA-Z0-9._%+-]+ : Commence par lettres, chiffres ou caractères spéciaux autorisés
    // @ : Le @ obligatoire
    // [a-zA-Z0-9.-]+ : Nom de domaine (lettres, chiffres, tirets, points)
    // \. : Le point avant l'extension
    // [a-zA-Z]{2,}$ : Extension du domaine (minimum 2 lettres)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return errorMessage ?? 'Adresse email invalide';
    }

    return null;
  }

  // ============================================================
  // VALIDATEURS DE MOT DE PASSE
  // ============================================================

  /// Vérifie la solidité d'un mot de passe.
  ///
  /// Critères de validation :
  /// - Au moins 8 caractères
  /// - Au moins une lettre minuscule
  /// - Au moins une lettre majuscule
  /// - Au moins un chiffre
  /// - Au moins un caractère spécial (@$!%*?&)
  ///
  /// **Paramètres :**
  /// - [value] : Le mot de passe à valider
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si le mot de passe est solide
  /// - Message d'erreur détaillé si critères non respectés
  static String? password(String? value, [String? errorMessage]) {
    if (value == null || value.isEmpty) {
      return null; // Ne pas valider si vide
    }

    // Vérifier la longueur minimale
    if (value.length < 8) {
      return errorMessage ??
          'Le mot de passe doit contenir au moins 8 caractères';
    }

    // Vérifier la présence d'au moins une minuscule
    if (!value.contains(RegExp(r'[a-z]'))) {
      return errorMessage ??
          'Le mot de passe doit contenir au moins une minuscule';
    }

    // Vérifier la présence d'au moins une majuscule
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return errorMessage ??
          'Le mot de passe doit contenir au moins une majuscule';
    }

    // Vérifier la présence d'au moins un chiffre
    if (!value.contains(RegExp(r'[0-9]'))) {
      return errorMessage ??
          'Le mot de passe doit contenir au moins un chiffre';
    }

    // Vérifier la présence d'au moins un caractère spécial
    if (!value.contains(RegExp(r'[@$!%*?&]'))) {
      return errorMessage ??
          'Le mot de passe doit contenir au moins un caractère spécial (@\$!%*?&)';
    }

    return null;
  }

  /// Vérifie que deux mots de passe correspondent.
  ///
  /// Utilisé pour confirmer un mot de passe lors de l'inscription.
  ///
  /// **Paramètres :**
  /// - [value] : Le mot de passe de confirmation
  /// - [originalPassword] : Le mot de passe original
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si les mots de passe correspondent
  /// - Message d'erreur s'ils ne correspondent pas
  ///
  /// **Exemple :**
  /// ```dart
  /// TextFormField(
  ///   validator: (value) => Validators.passwordMatch(
  ///     value,
  ///     _passwordController.text,
  ///   ),
  /// )
  /// ```
  static String? passwordMatch(
    String? value,
    String originalPassword, [
    String? errorMessage,
  ]) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value != originalPassword) {
      return errorMessage ?? 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  // ============================================================
  // VALIDATEURS DE TÉLÉPHONE
  // ============================================================

  /// Vérifie le format d'un numéro de téléphone.
  ///
  /// Accepte plusieurs formats courants :
  /// - +228 XX XX XX XX (format international)
  /// - 90 XX XX XX (format local Togo)
  /// - 97 XX XX XX (format local Bénin)
  /// - +229 XX XX XX XX (format international Bénin)
  ///
  /// **Paramètres :**
  /// - [value] : Le numéro à valider
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si le format est valide
  /// - Message d'erreur si le format est invalide
  static String? phone(String? value, [String? errorMessage]) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Enlever les espaces et tirets pour la validation
    final cleanedValue = value.replaceAll(RegExp(r'[\s-]'), '');

    // Regex pour valider les formats de téléphone
    // Accepte :
    // - +228XXXXXXXX ou +229XXXXXXXX (format international)
    // - 90XXXXXX ou 97XXXXXX (format local)
    final phoneRegex = RegExp(r'^(\+228|\+229|90|97)\d{6,8}$');

    if (!phoneRegex.hasMatch(cleanedValue)) {
      return errorMessage ?? 'Numéro de téléphone invalide';
    }

    return null;
  }

  // ============================================================
  // VALIDATEURS D'URL
  // ============================================================

  /// Vérifie le format d'une URL.
  ///
  /// Accepte les URLs avec http://, https://, ou sans protocole.
  ///
  /// **Exemples valides :**
  /// - https://example.com
  /// - http://www.example.com/page
  /// - example.com
  ///
  /// **Paramètres :**
  /// - [value] : L'URL à valider
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si l'URL est valide
  /// - Message d'erreur si le format est invalide
  static String? url(String? value, [String? errorMessage]) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Regex pour valider les URLs
    final urlRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return errorMessage ?? 'URL invalide';
    }

    return null;
  }

  // ============================================================
  // VALIDATEURS NUMÉRIQUES
  // ============================================================

  /// Vérifie qu'une valeur est un nombre valide.
  ///
  /// **Paramètres :**
  /// - [value] : La valeur à valider
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si c'est un nombre valide
  /// - Message d'erreur si ce n'est pas un nombre
  static String? number(String? value, [String? errorMessage]) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (double.tryParse(value) == null) {
      return errorMessage ?? 'Veuillez entrer un nombre valide';
    }

    return null;
  }

  /// Vérifie qu'un nombre est dans une plage donnée.
  ///
  /// **Paramètres :**
  /// - [value] : La valeur à valider
  /// - [min] : Valeur minimale (incluse)
  /// - [max] : Valeur maximale (incluse)
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si le nombre est dans la plage
  /// - Message d'erreur si hors plage
  static String? numberInRange(
    String? value,
    double min,
    double max, [
    String? errorMessage,
  ]) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Veuillez entrer un nombre valide';
    }

    if (numValue < min || numValue > max) {
      return errorMessage ?? 'La valeur doit être entre $min et $max';
    }

    return null;
  }

  // ============================================================
  // VALIDATEURS SPÉCIFIQUES À L'APPLICATION
  // ============================================================

  /// Vérifie le format d'un nom d'utilisateur.
  ///
  /// Règles de validation :
  /// - Longueur entre 3 et 30 caractères
  /// - Caractères autorisés : a-z, A-Z, 0-9, tirets (-), underscores (_)
  /// - Doit commencer et finir par une lettre ou un chiffre
  ///
  /// **Exemples valides :**
  /// - john-doe
  /// - user_123
  /// - JohnDoe2024
  ///
  /// **Exemples invalides :**
  /// - jo (trop court)
  /// - -john (commence par un tiret)
  /// - john- (finit par un tiret)
  ///
  /// **Paramètres :**
  /// - [value] : Le username à valider
  /// - [errorMessage] : Message d'erreur personnalisé (optionnel)
  ///
  /// **Retourne :**
  /// - null si le username est valide
  /// - Message d'erreur détaillé si invalide
  static String? username(String? value, [String? errorMessage]) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final trimmed = value.trim();

    // Vérifier la longueur minimale
    if (trimmed.length < 3) {
      return errorMessage ?? 'Minimum 3 caractères';
    }

    // Vérifier la longueur maximale
    if (trimmed.length > 30) {
      return errorMessage ?? 'Maximum 30 caractères';
    }

    // Vérifier le format avec une regex
    // ^[a-zA-Z0-9] : commence par lettre ou chiffre
    // [a-zA-Z0-9_-]* : suivi de lettres, chiffres, tirets ou underscores
    // [a-zA-Z0-9]$ : finit par lettre ou chiffre
    final usernameRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]$');

    if (!usernameRegex.hasMatch(trimmed)) {
      return errorMessage ??
          'Format invalide (lettres, chiffres, - et _ uniquement)';
    }

    return null;
  }

  // ============================================================
  // VALIDATEURS COMPOSÉS
  // ============================================================

  /// Combine plusieurs validateurs.
  ///
  /// Exécute les validateurs dans l'ordre et retourne la première erreur rencontrée.
  ///
  /// **Paramètres :**
  /// - [validators] : Liste de fonctions de validation
  ///
  /// **Retourne :**
  /// - Une fonction de validation qui exécute tous les validateurs
  ///
  /// **Exemple :**
  /// ```dart
  /// validator: Validators.compose([
  ///   (value) => Validators.required(value),
  ///   (value) => Validators.email(value),
  ///   (value) => Validators.minLength(value, 5),
  /// ])
  /// ```
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error; // Retourner la première erreur
        }
      }
      return null; // Toutes les validations ont réussi
    };
  }
}
