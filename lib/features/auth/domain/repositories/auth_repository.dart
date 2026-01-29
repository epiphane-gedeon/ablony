import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../entities/entities.dart';

/// Interface définissant le contrat pour les opérations d'authentification.
///
/// Cette interface (classe abstraite) définit toutes les méthodes nécessaires
/// pour gérer l'authentification des utilisateurs dans Ablony, sans spécifier
/// comment elles sont implémentées.
///
/// **Principe de l'architecture Clean :**
/// - Le **Domain Layer** définit QUOI faire (cette interface)
/// - Le **Data Layer** définit COMMENT le faire (implémentation concrète)
/// - Le **Presentation Layer** utilise l'interface sans connaître l'implémentation
///
/// **Avantages de cette approche :**
/// 1. **Testabilité** : Facile de créer des mocks pour les tests
/// 2. **Flexibilité** : On peut changer l'implémentation sans toucher au code métier
/// 3. **Indépendance** : Le domaine ne dépend d'aucune technologie externe
/// 4. **Maintenabilité** : Séparation claire des responsabilités
///
/// **Exemple d'utilisation :**
/// ```dart
/// class LoginViewModel {
///   final AuthRepository _authRepository;
///
///   LoginViewModel(this._authRepository);
///
///   Future<void> login() async {
///     // Utilise l'interface, pas l'implémentation
///     final result = await _authRepository.signInWithGoogle();
///     // ...
///   }
/// }
/// ```
abstract class AuthRepository {
  // ============================================================
  // AUTHENTIFICATION SOCIALE
  // ============================================================

  /// Connecte l'utilisateur avec son compte Google.
  ///
  /// Cette méthode déclenche le flow d'authentification Google :
  /// 1. Affiche le sélecteur de compte Google natif
  /// 2. L'utilisateur choisit un compte
  /// 3. Récupère les informations du profil (email, nom, photo)
  /// 4. Crée ou met à jour l'utilisateur dans Firebase Auth
  ///
  /// **Retour :**
  /// - [User] : Les données de l'utilisateur si connexion réussie
  /// - [null] : Si l'utilisateur annule la connexion
  ///
  /// **Exceptions possibles :**
  /// - [FirebaseAuthException] : Erreur Firebase (compte désactivé, etc.)
  /// - [PlatformException] : Erreur de la plateforme native
  /// - [Exception] : Autres erreurs (réseau, configuration, etc.)
  ///
  /// **Exemple :**
  /// ```dart
  /// try {
  ///   final user = await authRepository.signInWithGoogle();
  ///   if (user != null) {
  ///     // Connexion réussie, rediriger vers la page username
  ///     navigateToUsername(user);
  ///   } else {
  ///     // Utilisateur a annulé
  ///     showMessage('Connexion annulée');
  ///   }
  /// } catch (e) {
  ///   showError('Erreur de connexion: $e');
  /// }
  /// ```
  Future<User?> signInWithGoogle();

  /// Connecte l'utilisateur avec son compte Facebook.
  ///
  /// Cette méthode déclenche le flow d'authentification Facebook :
  /// 1. Affiche la page de connexion Facebook (natif ou web)
  /// 2. L'utilisateur se connecte à son compte Facebook
  /// 3. Autorise l'application à accéder à ses informations
  /// 4. Récupère les données du profil (email, nom, photo)
  /// 5. Crée ou met à jour l'utilisateur dans Firebase Auth
  ///
  /// **Permissions demandées :**
  /// - email (obligatoire)
  /// - public_profile (nom, photo)
  ///
  /// **Retour :**
  /// - [User] : Les données de l'utilisateur si connexion réussie
  /// - [null] : Si l'utilisateur annule la connexion
  ///
  /// **Exceptions possibles :**
  /// - [FirebaseAuthException] : Erreur Firebase
  /// - [FacebookAuthException] : Erreur spécifique Facebook
  /// - [Exception] : Autres erreurs
  ///
  /// **Note :** Facebook est très populaire en Afrique de l'Ouest, cette
  /// méthode est donc essentielle pour Ablony.
  Future<User?> signInWithFacebook();

  /// Connecte l'utilisateur avec son identifiant Apple (iOS/macOS uniquement).
  ///
  /// Cette méthode déclenche le flow Sign in with Apple :
  /// 1. Affiche le dialogue Apple natif
  /// 2. L'utilisateur s'authentifie (Face ID, Touch ID, ou mot de passe)
  /// 3. L'utilisateur peut choisir de masquer son email réel
  /// 4. Récupère les informations du profil
  /// 5. Crée ou met à jour l'utilisateur dans Firebase Auth
  ///
  /// **Particularités Apple :**
  /// - Email peut être masqué (privaterelay.appleid.com)
  /// - Nom complet fourni uniquement à la première connexion
  /// - Obligatoire si l'app propose d'autres connexions sociales (règles Apple)
  ///
  /// **Retour :**
  /// - [User] : Les données de l'utilisateur si connexion réussie
  /// - [null] : Si l'utilisateur annule la connexion
  ///
  /// **Exceptions possibles :**
  /// - [SignInWithAppleAuthorizationException] : Erreur Apple
  /// - [FirebaseAuthException] : Erreur Firebase
  /// - [UnsupportedError] : Si appelé sur Android (ne pas appeler sur Android)
  ///
  /// **Important :** Cette méthode ne doit être appelée que sur iOS/macOS.
  /// Vérifier Platform.isIOS avant d'appeler.
  Future<User?> signInWithApple();

  /// Connecte l'utilisateur avec email et mot de passe.
  ///
  /// Authentification classique par email/mot de passe.
  /// L'utilisateur doit avoir créé un compte au préalable avec [signUpWithEmail].
  ///
  /// **Paramètres :**
  /// - [email] : Adresse email de l'utilisateur
  /// - [password] : Mot de passe (minimum 6 caractères recommandé)
  ///
  /// **Retour :**
  /// - [User] : Les données de l'utilisateur si connexion réussie
  ///
  /// **Exceptions possibles :**
  /// - [FirebaseAuthException] avec codes :
  ///   - 'user-not-found' : Aucun compte avec cet email
  ///   - 'wrong-password' : Mot de passe incorrect
  ///   - 'invalid-email' : Format d'email invalide
  ///   - 'user-disabled' : Compte désactivé
  ///
  /// **Exemple :**
  /// ```dart
  /// try {
  ///   final user = await authRepository.signInWithEmail(
  ///     email: 'user@example.com',
  ///     password: 'monMotDePasse123',
  ///   );
  ///   navigateToHome(user);
  /// } on FirebaseAuthException catch (e) {
  ///   if (e.code == 'user-not-found') {
  ///     showError('Aucun compte trouvé avec cet email');
  ///   } else if (e.code == 'wrong-password') {
  ///     showError('Mot de passe incorrect');
  ///   }
  /// }
  /// ```
  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  /// Crée un nouveau compte avec email et mot de passe.
  ///
  /// Cette méthode crée un nouveau compte utilisateur dans Firebase Auth
  /// et envoie un email de vérification.
  ///
  /// **Paramètres :**
  /// - [email] : Adresse email (doit être valide et non utilisée)
  /// - [password] : Mot de passe (minimum 6 caractères)
  ///
  /// **Retour :**
  /// - [User] : Les données du nouvel utilisateur créé
  ///
  /// **Exceptions possibles :**
  /// - [FirebaseAuthException] avec codes :
  ///   - 'email-already-in-use' : Email déjà utilisé par un autre compte
  ///   - 'invalid-email' : Format d'email invalide
  ///   - 'weak-password' : Mot de passe trop faible (< 6 caractères)
  ///   - 'operation-not-allowed' : Auth par email désactivée dans Firebase
  ///
  /// **Workflow complet :**
  /// 1. Créer le compte avec cette méthode
  /// 2. Rediriger vers la page username
  /// 3. Compléter le profil (username, pays, etc.)
  /// 4. Appeler [completeUserProfile] pour sauvegarder dans Firestore
  ///
  /// **Exemple :**
  /// ```dart
  /// try {
  ///   final user = await authRepository.signUpWithEmail(
  ///     email: 'nouveau@example.com',
  ///     password: 'motDePasseSecurise123',
  ///   );
  ///   navigateToUsername(user);
  /// } on FirebaseAuthException catch (e) {
  ///   if (e.code == 'email-already-in-use') {
  ///     showError('Un compte existe déjà avec cet email');
  ///   }
  /// }
  /// ```
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  });

  // ============================================================
  // GESTION DU PROFIL UTILISATEUR
  // ============================================================

  /// Complète et sauvegarde le profil utilisateur dans Firestore.
  ///
  /// Cette méthode est appelée après la connexion sociale (Google/Facebook/Apple)
  /// pour compléter les informations manquantes et créer le document utilisateur
  /// dans Firestore.
  ///
  /// **Workflow d'inscription :**
  /// 1. Utilisateur se connecte avec Google/Facebook/Apple
  /// 2. On récupère uid, email, displayName, photoUrl du provider
  /// 3. Utilisateur choisit son username (page username)
  /// 4. Utilisateur valide le captcha (page captcha)
  /// 5. Utilisateur choisit son pays (page country)
  /// 6. **On appelle completeUserProfile avec toutes les infos**
  /// 7. Utilisateur est redirigé vers la home
  ///
  /// **Paramètres :**
  /// - [uid] : ID Firebase de l'utilisateur (obligatoire)
  /// - [username] : Nom d'utilisateur unique choisi (obligatoire)
  /// - [country] : Pays de résidence (obligatoire)
  /// - [acceptedTerms] : Acceptation des CGU (doit être true)
  /// - [marketingEmailsEnabled] : Consentement marketing (défaut: false)
  /// - [email], [displayName], [photoUrl], [phoneNumber], [city] : Optionnels
  ///
  /// **Retour :**
  /// - [User] : Le profil utilisateur complet sauvegardé
  ///
  /// **Exceptions possibles :**
  /// - [FirebaseException] : Erreur Firestore (réseau, permissions)
  /// - [ArgumentError] : Username déjà utilisé ou invalide
  ///
  /// **Exemple :**
  /// ```dart
  /// // Après connexion Google et saisie des infos
  /// final completeUser = await authRepository.completeUserProfile(
  ///   uid: firebaseUser.uid,
  ///   email: firebaseUser.email!,
  ///   displayName: firebaseUser.displayName,
  ///   photoUrl: firebaseUser.photoURL,
  ///   username: 'john_doe_tg',
  ///   country: Country.togo,
  ///   acceptedTerms: true,
  ///   marketingEmailsEnabled: false,
  /// );
  /// navigateToHome(completeUser);
  /// ```
  Future<User> completeUserProfile({
    required String uid,
    required String username,
    required Country country,
    required bool acceptedTerms,
    required bool marketingEmailsEnabled,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    AuthProvider? authProvider,
    String? providerId,
    String? city,
  });

  /// Met à jour les informations du profil utilisateur.
  ///
  /// Cette méthode permet de modifier les informations d'un utilisateur
  /// existant dans Firestore. Seuls les champs fournis seront modifiés.
  ///
  /// **Champs modifiables :**
  /// - username (avec vérification d'unicité)
  /// - displayName
  /// - photoUrl
  /// - phoneNumber
  /// - city
  /// - marketingEmailsEnabled
  ///
  /// **Champs NON modifiables :**
  /// - uid, email, country, createdAt
  /// - authProvider, providerId
  ///
  /// **Paramètres :**
  /// - [uid] : ID de l'utilisateur à mettre à jour
  /// - Tous les autres paramètres sont optionnels
  ///
  /// **Retour :**
  /// - [User] : Le profil utilisateur mis à jour
  ///
  /// **Exemple :**
  /// ```dart
  /// // Mettre à jour seulement le username et la ville
  /// final updated = await authRepository.updateUserProfile(
  ///   uid: currentUser.uid,
  ///   username: 'nouveau_username',
  ///   city: 'Lomé',
  /// );
  /// ```
  Future<User> updateUserProfile({
    required String uid,
    String? username,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? city,
    bool? marketingEmailsEnabled,
  });

  /// Récupère les données d'un utilisateur depuis Firestore.
  ///
  /// Charge le document utilisateur depuis Firestore et le convertit
  /// en instance de [User].
  ///
  /// **Paramètres :**
  /// - [uid] : L'identifiant unique de l'utilisateur
  ///
  /// **Retour :**
  /// - [User] : Les données de l'utilisateur
  ///
  /// **Exceptions :**
  /// - [FirebaseException] : Si l'utilisateur n'existe pas ou erreur réseau
  ///
  /// **Utilisation :**
  /// ```dart
  /// final user = await authRepository.getUserById(uid);
  /// print(user.username); // 'john_doe'
  /// ```
  Future<User> getUserById(String uid);

  /// Écoute les changements du profil utilisateur en temps réel.
  ///
  /// Retourne un Stream qui émet une nouvelle valeur à chaque fois que
  /// le document utilisateur est modifié dans Firestore.
  ///
  /// **Utilisation avec Riverpod :**
  /// ```dart
  /// final userStreamProvider = StreamProvider<User?>((ref) {
  ///   final uid = ref.watch(currentUserIdProvider);
  ///   if (uid == null) return Stream.value(null);
  ///   return ref.watch(authRepositoryProvider).getUserStream(uid);
  /// });
  /// ```
  ///
  /// **Paramètres :**
  /// - [uid] : L'identifiant de l'utilisateur à écouter
  ///
  /// **Retour :**
  /// - [Stream<User>] : Stream qui émet les mises à jour en temps réel
  Stream<User> getUserStream(String uid);

  // ============================================================
  // VÉRIFICATION ET VALIDATION
  // ============================================================

  /// Vérifie si un nom d'utilisateur est disponible.
  ///
  /// Vérifie dans la collection 'usernames' de Firestore si le username
  /// demandé est déjà utilisé par un autre utilisateur.
  ///
  /// **Utilisation :**
  /// Cette méthode doit être appelée avant de valider l'inscription pour
  /// s'assurer que le username choisi est unique.
  ///
  /// **Paramètres :**
  /// - [username] : Le nom d'utilisateur à vérifier
  ///
  /// **Retour :**
  /// - [true] : Username disponible (peut être utilisé)
  /// - [false] : Username déjà pris (choisir un autre)
  ///
  /// **Exemple dans l'UI :**
  /// ```dart
  /// // Dans un TextField avec validation en temps réel
  /// onChanged: (value) async {
  ///   final available = await authRepository.isUsernameAvailable(value);
  ///   setState(() {
  ///     errorText = available ? null : 'Ce nom d\'utilisateur est déjà pris';
  ///   });
  /// }
  /// ```
  Future<bool> isUsernameAvailable(String username);

  /// Génère une suggestion de nom d'utilisateur unique.
  ///
  /// Crée un nom d'utilisateur basé sur le nom complet de l'utilisateur
  /// et vérifie qu'il est disponible. Si non disponible, ajoute un suffixe
  /// numérique jusqu'à trouver un username libre.
  ///
  /// **Algorithme :**
  /// 1. Prend le displayName (ex: "Jean Pierre Kouassi")
  /// 2. Convertit en "jean-pierre-kouassi"
  /// 3. Si disponible, retourne tel quel
  /// 4. Sinon, essaie "jean-pierre-kouassi1", "jean-pierre-kouassi2", etc.
  ///
  /// **Paramètres :**
  /// - [displayName] : Le nom complet de l'utilisateur (optionnel)
  /// - [email] : L'email de l'utilisateur (utilisé si displayName est null)
  ///
  /// **Retour :**
  /// - [String] : Un nom d'utilisateur unique et disponible
  ///
  /// **Exemple :**
  /// ```dart
  /// // Après connexion Google
  /// final suggestion = await authRepository.generateUsername(
  ///   displayName: googleUser.displayName, // "Marie Kouassi"
  ///   email: googleUser.email, // "marie.kouassi@gmail.com"
  /// );
  /// print(suggestion); // "marie-kouassi" ou "marie-kouassi1" si déjà pris
  /// ```
  Future<String> generateUsername({String? displayName, String? email});

  // ============================================================
  // ÉTAT D'AUTHENTIFICATION
  // ============================================================

  /// Récupère l'utilisateur actuellement connecté.
  ///
  /// Retourne les données de l'utilisateur Firebase Auth actuellement
  /// authentifié, ou null si aucun utilisateur n'est connecté.
  ///
  /// **Retour :**
  /// - [firebase_auth.User?] : L'utilisateur Firebase (pas notre User entité)
  /// - [null] : Si non connecté
  ///
  /// **Différence User vs firebase_auth.User :**
  /// - [firebase_auth.User] : Données Firebase Auth (uid, email, providerData)
  /// - [User] : Notre entité métier avec username, country, etc.
  ///
  /// **Exemple :**
  /// ```dart
  /// final firebaseUser = authRepository.currentUser;
  /// if (firebaseUser != null) {
  ///   // Charger les données complètes depuis Firestore
  ///   final user = await authRepository.getUserById(firebaseUser.uid);
  /// }
  /// ```
  firebase_auth.User? get currentUser;

  /// Écoute les changements d'état d'authentification.
  ///
  /// Retourne un Stream qui émet une valeur chaque fois que l'état
  /// d'authentification change (connexion, déconnexion, token refresh).
  ///
  /// **Utilisation principale :**
  /// Déterminer si l'utilisateur est connecté ou non pour afficher
  /// l'écran approprié (onboarding vs home).
  ///
  /// **Retour :**
  /// - [Stream<firebase_auth.User?>] : Stream des changements d'auth
  ///
  /// **Exemple avec Riverpod :**
  /// ```dart
  /// final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  ///   return ref.watch(authRepositoryProvider).authStateChanges;
  /// });
  ///
  /// // Dans un widget
  /// final authState = ref.watch(authStateProvider);
  /// return authState.when(
  ///   data: (user) => user != null ? HomePage() : OnboardingPage(),
  ///   loading: () => SplashScreen(),
  ///   error: (e, _) => ErrorPage(error: e),
  /// );
  /// ```
  Stream<firebase_auth.User?> get authStateChanges;

  // ============================================================
  // DÉCONNEXION
  // ============================================================

  /// Déconnecte l'utilisateur actuel.
  ///
  /// Déconnecte l'utilisateur de :
  /// - Firebase Auth
  /// - Google Sign-In (si connecté via Google)
  /// - Facebook (si connecté via Facebook)
  /// - Apple (si connecté via Apple)
  ///
  /// Après la déconnexion, l'utilisateur est redirigé vers l'écran d'onboarding.
  ///
  /// **Exemple :**
  /// ```dart
  /// // Dans les paramètres
  /// onPressed: () async {
  ///   await authRepository.signOut();
  ///   navigateToOnboarding();
  /// }
  /// ```
  Future<void> signOut();

  // ============================================================
  // GESTION DES ERREURS ET RÉCUPÉRATION
  // ============================================================

  /// Envoie un email de vérification à l'utilisateur.
  ///
  /// Envoie un email avec un lien de vérification à l'adresse email
  /// de l'utilisateur connecté.
  ///
  /// **Utilisation :**
  /// À appeler après l'inscription par email pour vérifier l'adresse.
  ///
  /// **Exemple :**
  /// ```dart
  /// // Après inscription
  /// await authRepository.sendEmailVerification();
  /// showMessage('Un email de vérification vous a été envoyé');
  /// ```
  Future<void> sendEmailVerification();

  /// Envoie un email de réinitialisation du mot de passe.
  ///
  /// Envoie un email avec un lien pour réinitialiser le mot de passe
  /// à l'adresse email fournie.
  ///
  /// **Paramètres :**
  /// - [email] : L'adresse email du compte
  ///
  /// **Exemple :**
  /// ```dart
  /// // Page "Mot de passe oublié"
  /// await authRepository.sendPasswordResetEmail(email: userEmail);
  /// showMessage('Email de réinitialisation envoyé');
  /// ```
  Future<void> sendPasswordResetEmail({required String email});

  // ============================================================
  // RECHERCHE D'UTILISATEURS
  // ============================================================

  /// Recherche des utilisateurs par nom d'utilisateur.
  ///
  /// Cette méthode effectue une recherche partielle et insensible à la casse
  /// dans la collection des utilisateurs pour trouver ceux dont le username
  /// correspond à la requête.
  ///
  /// **Paramètres :**
  /// - [query] : Le terme de recherche (minimum 1 caractère recommandé)
  ///
  /// **Retour :**
  /// - [List<User>] : Liste des utilisateurs trouvés (maximum 10 résultats)
  ///   La liste est vide si aucun utilisateur ne correspond
  ///
  /// **Comportement :**
  /// - Recherche insensible à la casse
  /// - Recherche par préfixe (commence par la requête)
  /// - Limite les résultats à 10 utilisateurs
  /// - Exclut l'utilisateur actuel des résultats (optionnel)
  ///
  /// **Exceptions possibles :**
  /// - [FirebaseException] : Erreur Firestore
  /// - [Exception] : Autres erreurs (réseau, permissions, etc.)
  ///
  /// **Exemple :**
  /// ```dart
  /// // Dans la page de recherche
  /// final users = await authRepository.searchUsersByUsername('john');
  /// // Retourne : [User(username: 'john_doe'), User(username: 'johnny')]
  ///
  /// // Afficher les résultats
  /// for (final user in users) {
  ///   print(user.username);
  /// }
  /// ```
  ///
  /// **Note :** Cette méthode est utilisée principalement dans la page de
  /// recherche (SearchingPage) pour permettre aux utilisateurs de trouver
  /// d'autres membres de la communauté.
  Future<List<User>> searchUsersByUsername(String query);
}
