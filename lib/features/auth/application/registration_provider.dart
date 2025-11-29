import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/entities.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// État représentant les données collectées pendant le flow d'inscription.
///
/// Cette classe stocke temporairement toutes les informations collectées
/// au fur et à mesure que l'utilisateur progresse dans le processus
/// d'inscription :
///
/// **Flow complet :**
/// 1. Connexion sociale (Google/Facebook/Apple) → récupère uid, email, nom, photo
/// 2. Page Username → récupère username, checkboxes
/// 3. Page Captcha → valide l'utilisateur (pas de données à stocker)
/// 4. Page Country → récupère country
/// 5. Sauvegarde complète dans Firestore → Inscription terminée
///
/// **Exemple de progression :**
/// ```dart
/// // Après connexion Google
/// RegistrationState(
///   uid: 'abc123',
///   email: 'user@gmail.com',
///   displayName: 'John Doe',
///   authProvider: AuthProvider.google,
///   status: RegistrationStatus.providerId,
/// )
///
/// // Après saisie du username
/// RegistrationState(
///   uid: 'abc123',
///   email: 'user@gmail.com',
///   username: 'john-doe',
///   acceptedTerms: true,
///   status: RegistrationStatus.username,
/// )
///
/// // Après sélection du pays
/// RegistrationState(
///   uid: 'abc123',
///   email: 'user@gmail.com',
///   username: 'john-doe',
///   country: Country.togo,
///   status: RegistrationStatus.completed,
/// )
/// ```
class RegistrationState {
  // ============================================================
  // DONNÉES DE L'UTILISATEUR
  // ============================================================

  /// Identifiant unique Firebase (récupéré après connexion)
  final String? uid;

  /// Email de l'utilisateur (récupéré du provider social ou saisi)
  final String? email;

  /// Nom complet (récupéré du provider social)
  final String? displayName;

  /// URL de la photo de profil (récupéré du provider social)
  final String? photoUrl;

  /// Numéro de téléphone (optionnel)
  final String? phoneNumber;

  /// Méthode d'authentification utilisée
  final AuthProvider? authProvider;

  /// Identifiant du compte social (Google ID, Facebook ID, Apple ID)
  final String? providerId;

  /// Nom d'utilisateur choisi (saisi dans username_page)
  final String? username;

  /// Pays de résidence choisi (sélectionné dans country_selection_page)
  final Country? country;

  /// Ville (optionnel, peut être ajouté plus tard)
  final String? city;

  /// L'utilisateur a accepté les CGU (checkbox obligatoire)
  final bool acceptedTerms;

  /// L'utilisateur accepte de recevoir des emails marketing (checkbox optionnelle)
  final bool marketingEmailsEnabled;

  // ============================================================
  // ÉTAT DU PROCESSUS
  // ============================================================

  /// Statut actuel du processus d'inscription
  final RegistrationStatus status;

  /// Message d'erreur si une erreur s'est produite
  final String? errorMessage;

  /// Indique si une opération est en cours (affichage du loader)
  final bool isLoading;

  // ============================================================
  // CONSTRUCTEUR
  // ============================================================

  const RegistrationState({
    this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.authProvider,
    this.providerId,
    this.username,
    this.country,
    this.city,
    this.acceptedTerms = false,
    this.marketingEmailsEnabled = false,
    this.status = RegistrationStatus.initial,
    this.errorMessage,
    this.isLoading = false,
  });

  /// État initial (aucune donnée)
  factory RegistrationState.initial() {
    return const RegistrationState();
  }

  /// Crée une copie avec certains champs modifiés
  RegistrationState copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    AuthProvider? authProvider,
    String? providerId,
    String? username,
    Country? country,
    String? city,
    bool? acceptedTerms,
    bool? marketingEmailsEnabled,
    RegistrationStatus? status,
    String? errorMessage,
    bool? isLoading,
  }) {
    return RegistrationState(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authProvider: authProvider ?? this.authProvider,
      providerId: providerId ?? this.providerId,
      username: username ?? this.username,
      country: country ?? this.country,
      city: city ?? this.city,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      marketingEmailsEnabled:
          marketingEmailsEnabled ?? this.marketingEmailsEnabled,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Vérifie si toutes les données nécessaires sont présentes
  bool get isComplete {
    return uid != null &&
        email != null &&
        username != null &&
        username!.isNotEmpty &&
        country != null &&
        acceptedTerms;
  }
}

/// Énumération des étapes du processus d'inscription.
///
/// Permet de suivre la progression de l'utilisateur et de déterminer
/// quelle page afficher ensuite.
enum RegistrationStatus {
  /// État initial, aucune connexion effectuée
  initial,

  /// L'utilisateur s'est connecté avec un provider social
  providerId,

  /// L'utilisateur a saisi son username
  username,

  /// L'utilisateur a validé le captcha
  captcha,

  /// L'utilisateur a choisi son pays
  country,

  /// L'inscription est terminée et sauvegardée
  completed,

  /// Une erreur s'est produite
  error,
}

/// Notifier pour gérer l'état du processus d'inscription.
///
/// Ce Notifier orchestre tout le flow d'inscription en gérant
/// l'état et en appelant les méthodes du repository aux moments appropriés.
///
/// **Responsabilités :**
/// - Gérer les connexions sociales (Google, Facebook, Apple)
/// - Stocker temporairement les données saisies
/// - Valider les données
/// - Sauvegarder le profil complet dans Firestore
/// - Gérer les erreurs
///
/// **Utilisation :**
/// ```dart
/// // Dans un widget
/// final registrationNotifier = ref.read(registrationProvider.notifier);
///
/// // Connexion Google
/// await registrationNotifier.signInWithGoogle();
///
/// // Définir le username
/// registrationNotifier.setUsername('john-doe');
///
/// // Définir le pays
/// registrationNotifier.setCountry(Country.togo);
///
/// // Compléter l'inscription
/// await registrationNotifier.completeRegistration();
/// ```
class RegistrationNotifier extends Notifier<RegistrationState> {
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  RegistrationState build() {
    return RegistrationState.initial();
  }

  // ============================================================
  // CONNEXION AVEC LES PROVIDERS SOCIAUX
  // ============================================================

  /// Connecte l'utilisateur avec Google et initialise le state.
  ///
  /// Cette méthode :
  /// 1. Affiche le sélecteur de compte Google
  /// 2. Récupère les informations de l'utilisateur
  /// 3. Met à jour le state avec ces informations
  /// 4. Change le statut à [RegistrationStatus.providerId]
  ///
  /// **Retourne :**
  /// - [true] : Connexion réussie, passer à la page suivante (username)
  /// - [false] : Connexion annulée ou échouée
  ///
  /// **Exemple :**
  /// ```dart
  /// final success = await registrationNotifier.signInWithGoogle();
  /// if (success) {
  ///   context.go('/auth/username'); // Naviguer vers username page
  /// }
  /// ```
  Future<bool> signInWithGoogle() async {
    // Indiquer qu'une opération est en cours
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Appeler le repository pour se connecter avec Google
      final user = await _authRepository.signInWithGoogle();

      if (user == null) {
        // L'utilisateur a annulé la connexion
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Vérifier si l'utilisateur existe déjà dans Firestore
      if (user.username.isNotEmpty) {
        // Utilisateur existant → connexion terminée, pas besoin du flow
        state = state.copyWith(
          isLoading: false,
          status: RegistrationStatus.completed,
        );
        return false; // Ne pas continuer le flow d'inscription
      }

      // Nouvel utilisateur → initialiser le state avec ses infos
      state = RegistrationState(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        authProvider: AuthProvider.google,
        providerId: user.providerId,
        status: RegistrationStatus.providerId,
        isLoading: false,
      );

      return true; // Continuer vers username page
    } catch (e) {
      // Gérer l'erreur
      state = state.copyWith(
        isLoading: false,
        status: RegistrationStatus.error,
        errorMessage: 'Erreur lors de la connexion avec Google : $e',
      );
      return false;
    }
  }

  /// Connecte l'utilisateur avec Facebook et initialise le state.
  ///
  /// Similaire à [signInWithGoogle] mais pour Facebook.
  Future<bool> signInWithFacebook() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.signInWithFacebook();

      if (user == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      if (user.username.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          status: RegistrationStatus.completed,
        );
        return false;
      }

      state = RegistrationState(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        authProvider: AuthProvider.facebook,
        providerId: user.providerId,
        status: RegistrationStatus.providerId,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: RegistrationStatus.error,
        errorMessage: 'Erreur lors de la connexion avec Facebook : $e',
      );
      return false;
    }
  }

  /// Connecte l'utilisateur avec Apple et initialise le state.
  ///
  /// Similaire à [signInWithGoogle] mais pour Apple Sign-In.
  /// **Attention :** Ne fonctionne que sur iOS/macOS.
  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.signInWithApple();

      if (user == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      if (user.username.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          status: RegistrationStatus.completed,
        );
        return false;
      }

      state = RegistrationState(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        authProvider: AuthProvider.apple,
        providerId: user.providerId,
        status: RegistrationStatus.providerId,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: RegistrationStatus.error,
        errorMessage: 'Erreur lors de la connexion avec Apple : $e',
      );
      return false;
    }
  }

  // ============================================================
  // MISE À JOUR DES DONNÉES DU FLOW
  // ============================================================

  /// Définit le username et les préférences (page username).
  ///
  /// Appelé depuis [UsernamePage] après validation du formulaire.
  ///
  /// **Paramètres :**
  /// - [username] : Le nom d'utilisateur choisi
  /// - [acceptedTerms] : Acceptation des CGU (doit être true)
  /// - [marketingEmailsEnabled] : Consentement marketing (optionnel)
  void setUsername({
    required String username,
    required bool acceptedTerms,
    required bool marketingEmailsEnabled,
  }) {
    state = state.copyWith(
      username: username,
      acceptedTerms: acceptedTerms,
      marketingEmailsEnabled: marketingEmailsEnabled,
      status: RegistrationStatus.username,
    );
  }

  /// Valide le captcha (page captcha).
  ///
  /// Pour l'instant, cette méthode change juste le statut.
  /// Plus tard, on intégrera un vrai système de captcha.
  void validateCaptcha() {
    state = state.copyWith(status: RegistrationStatus.captcha);
  }

  /// Définit le pays choisi (page country).
  ///
  /// Appelé depuis [CountrySelectionPage] quand l'utilisateur
  /// sélectionne son pays.
  ///
  /// **Paramètre :**
  /// - [country] : Le pays choisi (Togo ou Bénin)
  void setCountry(Country country) {
    state = state.copyWith(
      country: country,
      status: RegistrationStatus.country,
    );
  }

  /// Définit la ville (optionnel).
  void setCity(String? city) {
    state = state.copyWith(city: city);
  }

  // ============================================================
  // FINALISATION DE L'INSCRIPTION
  // ============================================================

  /// Complète l'inscription en sauvegardant tout dans Firestore.
  ///
  /// Cette méthode :
  /// 1. Vérifie que toutes les données obligatoires sont présentes
  /// 2. Appelle le repository pour sauvegarder dans Firestore
  /// 3. Met à jour le statut à [RegistrationStatus.completed]
  /// 4. Retourne le User complet
  ///
  /// **Appelé après :**
  /// - Connexion sociale (Google/Facebook/Apple)
  /// - Saisie du username
  /// - Validation du captcha
  /// - Sélection du pays
  ///
  /// **Retourne :**
  /// - [User] : Le profil utilisateur complet si succès
  /// - [null] : Si une erreur s'est produite
  ///
  /// **Exemple :**
  /// ```dart
  /// // Après que l'utilisateur a choisi son pays
  /// final user = await registrationNotifier.completeRegistration();
  /// if (user != null) {
  ///   context.go('/home'); // Inscription terminée, aller à l'accueil
  /// } else {
  ///   showError('Erreur lors de l\'inscription');
  /// }
  /// ```
  Future<User?> completeRegistration() async {
    // Vérifier que toutes les données sont présentes
    if (!state.isComplete) {
      state = state.copyWith(
        status: RegistrationStatus.error,
        errorMessage: 'Données incomplètes. Veuillez remplir tous les champs.',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Appeler le repository pour créer le profil complet
      final user = await _authRepository.completeUserProfile(
        uid: state.uid!,
        username: state.username!,
        country: state.country!,
        acceptedTerms: state.acceptedTerms,
        marketingEmailsEnabled: state.marketingEmailsEnabled,
        email: state.email,
        displayName: state.displayName,
        photoUrl: state.photoUrl,
        phoneNumber: state.phoneNumber,
        authProvider: state.authProvider,
        providerId: state.providerId,
        city: state.city,
      );

      // Inscription terminée !
      state = state.copyWith(
        isLoading: false,
        status: RegistrationStatus.completed,
      );

      return user;
    } catch (e) {
      // Erreur lors de la sauvegarde
      state = state.copyWith(
        isLoading: false,
        status: RegistrationStatus.error,
        errorMessage: 'Erreur lors de la finalisation de l\'inscription : $e',
      );
      return null;
    }
  }

  // ============================================================
  // GESTION DE L'ÉTAT
  // ============================================================

  /// Réinitialise l'état d'inscription.
  ///
  /// Utilisé si l'utilisateur annule le processus ou veut recommencer.
  void reset() {
    state = RegistrationState.initial();
  }

  /// Efface le message d'erreur.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider pour le notifier d'inscription.
///
/// Ce provider donne accès au [RegistrationNotifier] et à son état
/// [RegistrationState] dans toute l'application.
///
/// **Utilisation pour lire l'état :**
/// ```dart
/// // Dans un ConsumerWidget
/// final registrationState = ref.watch(registrationProvider);
///
/// if (registrationState.isLoading) {
///   return CircularProgressIndicator();
/// }
///
/// if (registrationState.errorMessage != null) {
///   return Text('Erreur: ${registrationState.errorMessage}');
/// }
/// ```
///
/// **Utilisation pour modifier l'état :**
/// ```dart
/// // Dans un ConsumerWidget
/// final registrationNotifier = ref.read(registrationProvider.notifier);
///
/// onPressed: () async {
///   final success = await registrationNotifier.signInWithGoogle();
///   if (success) {
///     // Naviguer vers username page
///   }
/// }
/// ```
final registrationProvider =
    NotifierProvider<RegistrationNotifier, RegistrationState>(
      RegistrationNotifier.new,
    );
