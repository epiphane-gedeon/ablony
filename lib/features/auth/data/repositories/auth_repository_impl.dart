import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/exceptions/exceptions.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../wallet/domain/models/wallet.dart';
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
        throw UnknownException(
          message: 'L\'utilisateur Firebase n\'a pas pu être créé',
          originalException: null,
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
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      // Erreur Firebase Auth (compte désactivé, etc.)
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      // Autres erreurs (réseau, configuration, etc.)
      throw UnknownException(
        message: 'Erreur lors de la connexion avec Google',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
        throw UnknownException(message: 'Échec de la connexion Facebook');
      }

      // ÉTAPE 2 : Obtenir le token d'accès Facebook
      final AccessToken? accessToken = result.accessToken;

      if (accessToken == null) {
        throw UnknownException(
          message: 'Le token d\'accès Facebook n\'a pas pu être récupéré',
        );
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
        throw UnknownException(
          message: 'L\'utilisateur Firebase n\'a pas pu être créé',
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
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la connexion avec Facebook',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
        throw UnknownException(
          message: 'L\'utilisateur Firebase n\'a pas pu être créé',
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
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on SignInWithAppleAuthorizationException catch (e) {
      // Erreur spécifique Apple (utilisateur annule, etc.)
      if (e.code == AuthorizationErrorCode.canceled) {
        return null; // L'utilisateur a annulé
      }
      throw UnknownException(
        message: 'Erreur Apple Sign In',
        originalException: e as Exception?,
      );
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la connexion avec Apple',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
        throw UnknownException(
          message: 'L\'utilisateur Firebase n\'a pas pu être récupéré',
        );
      }

      // Charger les données complètes depuis Firestore
      return await getUserById(firebaseUser.uid);
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la connexion',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
        throw UnknownException(
          message: 'L\'utilisateur Firebase n\'a pas pu être créé',
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
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de l\'inscription',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
        throw UsernameTakenException(username: username);
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
    } on FirebaseException catch (e, stackTrace) {
      print(
        '🔴 [completeUserProfile] FirebaseException: ${e.code} - ${e.message}',
      );
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      // Propager les exceptions d'application
      rethrow;
    } catch (e, stackTrace) {
      print('🔴 [completeUserProfile] Exception inattendue: $e');
      print('🔴 [completeUserProfile] Stack trace: $stackTrace');
      throw UnknownException(
        message: 'Erreur lors de la création du profil',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
    Wallet? wallet,
  }) async {
    try {
      // Charger l'utilisateur actuel
      final currentUser = await getUserById(uid);

      // Si le username change, vérifier sa disponibilité
      if (username != null && username != currentUser.username) {
        final isAvailable = await isUsernameAvailable(username);
        if (!isAvailable) {
          throw UsernameTakenException(username: username);
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
        wallet: wallet,
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
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la mise à jour du profil',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<User> getUserById(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (!docSnapshot.exists) {
        throw ProductNotFoundException(productId: uid);
      }

      return UserModel.fromFirestore(docSnapshot, null);
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement de l\'utilisateur',
        originalException: e as Exception?,
        stackTrace: stackTrace,
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
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la vérification du pseudo',
        originalException: e as Exception?,
        stackTrace: stackTrace,
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
      // Récupérer l'utilisateur actuel pour savoir quel provider a été utilisé
      final user = _firebaseAuth.currentUser;

      if (user != null) {
        // Vérifier les providers utilisés pour cette connexion
        final providers = user.providerData
            .map((info) => info.providerId)
            .toList();

        // Déconnexion Google si utilisé
        if (providers.contains('google.com')) {
          try {
            await _googleSignIn.signOut();
            print('✅ Déconnexion Google réussie');
          } catch (e) {
            print('⚠️ Erreur déconnexion Google (ignorée): $e');
          }
        }

        // Déconnexion Facebook si utilisé
        if (providers.contains('facebook.com')) {
          try {
            await _facebookAuth.logOut();
            print('✅ Déconnexion Facebook réussie');
          } catch (e) {
            print('⚠️ Erreur déconnexion Facebook (ignorée): $e');
          }
        }

        // Note: Apple Sign In n'a pas besoin de déconnexion explicite
        // car il utilise uniquement Firebase Auth
      }

      // Le plus important : Firebase Auth (toujours nécessaire)
      await _firebaseAuth.signOut();
      print('✅ Déconnexion Firebase réussie');
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la déconnexion',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de l\'envoi de l\'email de vérification',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de l\'envoi de l\'email de réinitialisation',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // RECHERCHE D'UTILISATEURS
  // ============================================================

  @override
  Future<List<User>> searchUsersByUsername(String query) async {
    try {
      // Convertir la requête en minuscules pour une recherche insensible à la casse
      final queryLower = query.toLowerCase();

      // Effectuer une requête Firestore avec recherche par préfixe
      // Note : Firestore ne supporte pas la recherche en texte intégral (full-text search)
      // On utilise donc une recherche par préfixe (commence par)
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: queryLower)
          .where('username', isLessThan: '${queryLower}z')
          .limit(10) // Limiter à 10 résultats pour les performances
          .get();

      // Convertir les documents Firestore en objets User
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc, null))
          .toList();

      // Optionnel : Exclure l'utilisateur actuel des résultats
      final currentUserId = _firebaseAuth.currentUser?.uid;
      if (currentUserId != null) {
        users.removeWhere((user) => user.uid == currentUserId);
      }

      return users;
    } on FirebaseException catch (e, stackTrace) {
      // Erreur Firestore (permissions, réseau, etc.)
      throw UnknownException(
        message: 'Erreur lors de la recherche d\'utilisateurs: ${e.message}',
        originalException: Exception(e),
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      // Autres erreurs inattendues
      throw UnknownException(
        message: 'Erreur inattendue lors de la recherche d\'utilisateurs',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }
}
