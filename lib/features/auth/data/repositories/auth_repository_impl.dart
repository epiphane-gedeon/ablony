import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Implémentation concrète du [AuthRepository] utilisant Firebase.
///
/// Cette classe implémente toutes les méthodes définies dans l'interface
/// [AuthRepository] en utilisant les services Firebase :
/// - Firebase Authentication pour l'authentification
/// - Cloud Firestore pour le stockage des profils utilisateurs
/// - Google Sign-In, Facebook Auth, Sign in with Apple pour les connexions sociales
///
/// **Architecture :**
/// ```
/// Presentation Layer (UI)
///       ↓
/// Provider (Riverpod)
///       ↓
/// AuthRepository (Interface) ← Vous êtes ici
///       ↓
/// AuthRepositoryImpl (Implémentation Firebase)
///       ↓
/// Firebase Services (Auth, Firestore, etc.)
/// ```
///
/// **Responsabilités :**
/// 1. Gérer les connexions sociales (Google, Facebook, Apple)
/// 2. Gérer l'authentification par email/password
/// 3. Créer et mettre à jour les profils utilisateurs dans Firestore
/// 4. Vérifier l'unicité des usernames
/// 5. Générer des suggestions de usernames
/// 6. Gérer la déconnexion et la réinitialisation de mot de passe
///
/// **Note sur les erreurs :**
/// Les exceptions Firebase sont propagées vers les couches supérieures
/// pour être gérées par les ViewModels/Providers.
class AuthRepositoryImpl implements AuthRepository {
  // ============================================================
  // DÉPENDANCES
  // ============================================================

  /// Instance de Firebase Authentication.
  ///
  /// Utilisée pour toutes les opérations d'authentification :
  /// - Connexion/Déconnexion
  /// - Création de compte
  /// - Gestion des tokens
  /// - État d'authentification
  final firebase_auth.FirebaseAuth _firebaseAuth;

  /// Instance de Cloud Firestore.
  ///
  /// Utilisée pour :
  /// - Stocker les profils utilisateurs (collection 'users')
  /// - Vérifier l'unicité des usernames (collection 'usernames')
  /// - Écouter les changements en temps réel
  final FirebaseFirestore _firestore;

  /// Instance de Google Sign-In.
  ///
  /// Gère le flow d'authentification Google :
  /// - Affichage du sélecteur de compte
  /// - Récupération des tokens OAuth
  /// - Déconnexion Google
  final GoogleSignIn _googleSignIn;

  /// Instance de Facebook Authentication.
  ///
  /// Gère le flow d'authentification Facebook :
  /// - Affichage de la page de connexion Facebook
  /// - Gestion des permissions
  /// - Récupération du token d'accès
  final FacebookAuth _facebookAuth;

  // ============================================================
  // CONSTRUCTEUR
  // ============================================================

  /// Crée une instance de [AuthRepositoryImpl].
  ///
  /// **Paramètres :**
  /// - [firebaseAuth] : Instance Firebase Auth (injectable pour tests)
  /// - [firestore] : Instance Firestore (injectable pour tests)
  /// - [googleSignIn] : Instance Google Sign-In (injectable pour tests)
  /// - [facebookAuth] : Instance Facebook Auth (injectable pour tests)
  ///
  /// **Utilisation avec injection de dépendances (Riverpod) :**
  /// ```dart
  /// final authRepositoryProvider = Provider<AuthRepository>((ref) {
  ///   return AuthRepositoryImpl(
  ///     firebaseAuth: FirebaseAuth.instance,
  ///     firestore: FirebaseFirestore.instance,
  ///     googleSignIn: GoogleSignIn(),
  ///     facebookAuth: FacebookAuth.instance,
  ///   );
  /// });
  /// ```
  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  // ============================================================
  // AUTHENTIFICATION SOCIALE - GOOGLE
  // ============================================================

  @override
  Future<User?> signInWithGoogle() async {
    try {
      // ÉTAPE 1 : Déclencher le flow d'authentification Google
      // Cela affiche le sélecteur de compte Google natif
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Si l'utilisateur annule la sélection, googleUser sera null
      if (googleUser == null) {
        return null; // L'utilisateur a annulé
      }

      // ÉTAPE 2 : Obtenir les détails d'authentification depuis Google
      // Ces détails contiennent les tokens OAuth nécessaires
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // ÉTAPE 3 : Créer les credentials Firebase depuis les tokens Google
      // Firebase utilise ces credentials pour authentifier l'utilisateur
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ÉTAPE 4 : Se connecter à Firebase avec les credentials Google
      // Cette opération crée automatiquement le compte s'il n'existe pas
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'null-user',
          message: 'L\'utilisateur Firebase est null après connexion Google',
        );
      }

      // ÉTAPE 5 : Vérifier si l'utilisateur existe déjà dans Firestore
      // Si oui, retourner ses données complètes
      // Si non, retourner les données basiques de Firebase Auth
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        // L'utilisateur existe déjà dans Firestore, charger ses données
        return UserModel.fromFirestore(userDoc, null);
      } else {
        // Nouvel utilisateur, retourner un User basique (sera complété plus tard)
        // On ne crée PAS encore le document Firestore, ça sera fait après
        // avoir collecté username, pays, etc. dans completeUserProfile()
        return User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: '', // Sera défini plus tard
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          authProvider: AuthProvider.google,
          providerId: googleUser.id,
          country: Country.togo, // Valeur temporaire, sera changée
          acceptedTerms: false, // Sera défini dans le flow d'inscription
          acceptedTermsDate: DateTime.now(),
          marketingEmailsEnabled: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: firebaseUser.emailVerified,
          isActive: true,
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Erreur Firebase Auth (compte désactivé, etc.)
      throw firebase_auth.FirebaseAuthException(
        code: e.code,
        message: 'Erreur Firebase lors de la connexion Google : ${e.message}',
      );
    } catch (e) {
      // Autres erreurs (réseau, configuration, etc.)
      throw Exception('Erreur lors de la connexion avec Google : $e');
    }
  }

  // ============================================================
  // AUTHENTIFICATION SOCIALE - FACEBOOK
  // ============================================================

  @override
  Future<User?> signInWithFacebook() async {
    try {
      // ÉTAPE 1 : Déclencher le flow d'authentification Facebook
      // Cela affiche la page de connexion Facebook (native ou web)
      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'], // Permissions demandées
      );

      // Vérifier le statut de la connexion
      if (result.status == LoginStatus.cancelled) {
        return null; // L'utilisateur a annulé
      }

      if (result.status != LoginStatus.success) {
        throw Exception('Échec de la connexion Facebook : ${result.status}');
      }

      // ÉTAPE 2 : Obtenir le token d'accès Facebook
      final AccessToken? accessToken = result.accessToken;

      if (accessToken == null) {
        throw Exception('Token d\'accès Facebook null');
      }

      // ÉTAPE 3 : Créer les credentials Firebase depuis le token Facebook
      final credential = firebase_auth.FacebookAuthProvider.credential(
        accessToken.token,
      );

      // ÉTAPE 4 : Se connecter à Firebase avec les credentials Facebook
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'null-user',
          message: 'L\'utilisateur Firebase est null après connexion Facebook',
        );
      }

      // ÉTAPE 5 : Vérifier si l'utilisateur existe dans Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc, null);
      } else {
        // Nouvel utilisateur, retourner User basique
        return User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: '', // Sera défini plus tard
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          authProvider: AuthProvider.facebook,
          providerId: accessToken.userId,
          country: Country.togo, // Temporaire
          acceptedTerms: false,
          acceptedTermsDate: DateTime.now(),
          marketingEmailsEnabled: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: firebaseUser.emailVerified,
          isActive: true,
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: e.code,
        message: 'Erreur Firebase lors de la connexion Facebook : ${e.message}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la connexion avec Facebook : $e');
    }
  }

  // ============================================================
  // AUTHENTIFICATION SOCIALE - APPLE (iOS/macOS uniquement)
  // ============================================================

  @override
  Future<User?> signInWithApple() async {
    try {
      // ÉTAPE 1 : Déclencher le flow Sign in with Apple
      // Affiche le dialogue Apple natif (Face ID/Touch ID/Password)
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // ÉTAPE 2 : Créer les credentials OAuth pour Firebase
      final oAuthCredential = firebase_auth.OAuthProvider('apple.com')
          .credential(
            idToken: appleCredential.identityToken,
            accessToken: appleCredential.authorizationCode,
          );

      // ÉTAPE 3 : Se connecter à Firebase avec les credentials Apple
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(oAuthCredential);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'null-user',
          message: 'L\'utilisateur Firebase est null après connexion Apple',
        );
      }

      // ÉTAPE 4 : Construire le displayName depuis les données Apple
      // Apple ne fournit le nom complet QUE lors de la première connexion
      String? displayName = firebaseUser.displayName;
      if (displayName == null && appleCredential.givenName != null) {
        displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();

        // Mettre à jour le displayName dans Firebase Auth
        await firebaseUser.updateDisplayName(displayName);
      }

      // ÉTAPE 5 : Vérifier si l'utilisateur existe dans Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc, null);
      } else {
        // Nouvel utilisateur
        return User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? appleCredential.email ?? '',
          username: '', // Sera défini plus tard
          displayName: displayName,
          photoUrl: firebaseUser.photoURL,
          authProvider: AuthProvider.apple,
          providerId: appleCredential.userIdentifier,
          country: Country.togo, // Temporaire
          acceptedTerms: false,
          acceptedTermsDate: DateTime.now(),
          marketingEmailsEnabled: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: firebaseUser.emailVerified,
          isActive: true,
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: e.code,
        message: 'Erreur Firebase lors de la connexion Apple : ${e.message}',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // Erreur spécifique Apple (utilisateur annule, etc.)
      if (e.code == AuthorizationErrorCode.canceled) {
        return null; // L'utilisateur a annulé
      }
      throw Exception('Erreur Apple Sign In : ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la connexion avec Apple : $e');
    }
  }

  // ============================================================
  // AUTHENTIFICATION PAR EMAIL
  // ============================================================

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Se connecter avec email et mot de passe
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'null-user',
          message: 'L\'utilisateur Firebase est null après connexion email',
        );
      }

      // Charger les données complètes depuis Firestore
      return await getUserById(firebaseUser.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Propager l'erreur avec un message en français
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun compte trouvé avec cet email';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          message = 'Format d\'email invalide';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé';
          break;
        default:
          message = 'Erreur de connexion : ${e.message}';
      }
      throw firebase_auth.FirebaseAuthException(code: e.code, message: message);
    }
  }

  @override
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'null-user',
          message: 'L\'utilisateur Firebase est null après inscription',
        );
      }

      // Envoyer l'email de vérification
      await firebaseUser.sendEmailVerification();

      // Retourner un User basique (sera complété dans le flow d'inscription)
      return User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        username: '', // Sera défini plus tard
        authProvider: AuthProvider.email,
        country: Country.togo, // Temporaire
        acceptedTerms: false,
        acceptedTermsDate: DateTime.now(),
        marketingEmailsEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: false,
        isActive: true,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Un compte existe déjà avec cet email';
          break;
        case 'invalid-email':
          message = 'Format d\'email invalide';
          break;
        case 'weak-password':
          message = 'Le mot de passe est trop faible (minimum 6 caractères)';
          break;
        case 'operation-not-allowed':
          message = 'L\'authentification par email est désactivée';
          break;
        default:
          message = 'Erreur d\'inscription : ${e.message}';
      }
      throw firebase_auth.FirebaseAuthException(code: e.code, message: message);
    }
  }

  // ============================================================
  // GESTION DU PROFIL UTILISATEUR
  // ============================================================

  @override
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
  }) async {
    try {
      print(
        '🔵 [completeUserProfile] Début - uid: $uid, username: $username, country: ${country.name}',
      );

      // ÉTAPE 1 : Vérifier si le username est disponible
      print('🔵 [completeUserProfile] Vérification disponibilité username...');
      final isAvailable = await isUsernameAvailable(username);
      print('🔵 [completeUserProfile] Username disponible: $isAvailable');

      if (!isAvailable) {
        print('🔴 [completeUserProfile] Username déjà pris: $username');
        throw ArgumentError(
          'Le nom d\'utilisateur "$username" est déjà utilisé',
        );
      }

      // ÉTAPE 2 : Créer l'entité User complète
      print('🔵 [completeUserProfile] Création entité User...');
      final now = DateTime.now();
      final user = User(
        uid: uid,
        email: email ?? '',
        username: username,
        displayName: displayName,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        authProvider: authProvider ?? AuthProvider.email,
        providerId: providerId,
        country: country,
        city: city,
        acceptedTerms: acceptedTerms,
        acceptedTermsDate: now,
        marketingEmailsEnabled: marketingEmailsEnabled,
        createdAt: now,
        updatedAt: now,
        isVerified: _firebaseAuth.currentUser?.emailVerified ?? false,
        isActive: true,
        productsCount: 0,
        salesCount: 0,
        rating: 0.0,
        reviewsCount: 0,
      );
      print('🔵 [completeUserProfile] User créé: ${user.toString()}');

      // ÉTAPE 3 : Sauvegarder dans Firestore avec transaction
      // La transaction garantit l'atomicité (tout ou rien)
      print('🔵 [completeUserProfile] Début transaction Firestore...');
      await _firestore.runTransaction((transaction) async {
        print(
          '🔵 [completeUserProfile] Dans la transaction - création documents...',
        );

        // Créer le document utilisateur
        final userRef = _firestore.collection('users').doc(uid);
        final userData = UserModel.fromEntity(user).toFirestore();
        print('🔵 [completeUserProfile] UserData à sauvegarder: $userData');
        transaction.set(userRef, userData);

        // Réserver le username dans la collection 'usernames'
        final usernameRef = _firestore.collection('usernames').doc(username);
        transaction.set(usernameRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('🔵 [completeUserProfile] Documents ajoutés à la transaction');
      });

      print('✅ [completeUserProfile] Transaction réussie!');
      return user;
    } on FirebaseException catch (e) {
      print(
        '🔴 [completeUserProfile] FirebaseException: ${e.code} - ${e.message}',
      );
      throw Exception('Erreur Firestore : ${e.message}');
    } catch (e, stackTrace) {
      print('🔴 [completeUserProfile] Exception inattendue: $e');
      print('🔴 [completeUserProfile] Stack trace: $stackTrace');
      throw Exception('Erreur lors de la création du profil : $e');
    }
  }

  @override
  Future<User> updateUserProfile({
    required String uid,
    String? username,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? city,
    bool? marketingEmailsEnabled,
  }) async {
    try {
      // Charger l'utilisateur actuel
      final currentUser = await getUserById(uid);

      // Si le username change, vérifier sa disponibilité
      if (username != null && username != currentUser.username) {
        final isAvailable = await isUsernameAvailable(username);
        if (!isAvailable) {
          throw ArgumentError(
            'Le nom d\'utilisateur "$username" est déjà utilisé',
          );
        }
      }

      // Créer le user mis à jour
      final updatedUser = currentUser.copyWith(
        username: username,
        displayName: displayName,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        city: city,
        marketingEmailsEnabled: marketingEmailsEnabled,
        updatedAt: DateTime.now(),
      );

      // Mettre à jour dans Firestore avec transaction
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(uid);
        transaction.update(
          userRef,
          UserModel.fromEntity(updatedUser).toFirestore(),
        );

        // Si le username a changé, mettre à jour la collection 'usernames'
        if (username != null && username != currentUser.username) {
          // Supprimer l'ancien username
          final oldUsernameRef = _firestore
              .collection('usernames')
              .doc(currentUser.username);
          transaction.delete(oldUsernameRef);

          // Créer le nouveau username
          final newUsernameRef = _firestore
              .collection('usernames')
              .doc(username);
          transaction.set(newUsernameRef, {
            'userId': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return updatedUser;
    } on FirebaseException catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil : ${e.message}');
    }
  }

  @override
  Future<User> getUserById(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (!docSnapshot.exists) {
        throw Exception('Utilisateur non trouvé : $uid');
      }

      return UserModel.fromFirestore(docSnapshot, null);
    } on FirebaseException catch (e) {
      throw Exception(
        'Erreur lors du chargement de l\'utilisateur : ${e.message}',
      );
    }
  }

  @override
  Stream<User> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => UserModel.fromFirestore(snapshot, null));
  }

  // ============================================================
  // VÉRIFICATION ET VALIDATION
  // ============================================================

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final doc = await _firestore.collection('usernames').doc(username).get();
      return !doc.exists; // Disponible si le document n'existe pas
    } on FirebaseException catch (e) {
      throw Exception(
        'Erreur lors de la vérification du username : ${e.message}',
      );
    }
  }

  @override
  Future<String> generateUsername({String? displayName, String? email}) async {
    // Déterminer la base du username
    String base;

    if (displayName != null && displayName.isNotEmpty) {
      // Utiliser le displayName
      base = displayName
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^\w\s-]'), '') // Supprimer caractères spéciaux
          .replaceAll(RegExp(r'\s+'), '-'); // Remplacer espaces par tirets
    } else if (email != null && email.isNotEmpty) {
      // Utiliser la partie avant @ de l'email
      base = email.split('@').first.toLowerCase();
    } else {
      // Par défaut, utiliser 'user'
      base = 'user';
    }

    // Limiter la longueur à 20 caractères
    if (base.length > 20) {
      base = base.substring(0, 20);
    }

    // Essayer le username de base
    if (await isUsernameAvailable(base)) {
      return base;
    }

    // Si déjà pris, essayer avec des suffixes numériques
    for (int i = 1; i <= 999; i++) {
      final candidate = '$base$i';
      if (await isUsernameAvailable(candidate)) {
        return candidate;
      }
    }

    // Si tous les suffixes 1-999 sont pris, utiliser un timestamp
    return '$base${DateTime.now().millisecondsSinceEpoch}';
  }

  // ============================================================
  // ÉTAT D'AUTHENTIFICATION
  // ============================================================

  @override
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // ============================================================
  // DÉCONNEXION
  // ============================================================

  @override
  Future<void> signOut() async {
    try {
      // Déconnexion de tous les providers
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
        _facebookAuth.logOut(),
      ]);
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion : $e');
    }
  }

  // ============================================================
  // GESTION DES ERREURS ET RÉCUPÉRATION
  // ============================================================

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email : ${e.message}');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun compte trouvé avec cet email';
          break;
        case 'invalid-email':
          message = 'Format d\'email invalide';
          break;
        default:
          message = 'Erreur : ${e.message}';
      }
      throw firebase_auth.FirebaseAuthException(code: e.code, message: message);
    }
  }
}
