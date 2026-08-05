import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/auth_repository.dart';

/// **PROVIDERS FIREBASE**
///
/// Ces providers fournissent les instances des services Firebase
/// nécessaires pour l'authentification. Ils sont définis ici pour
/// permettre l'injection de dépendances et faciliter les tests.

/// Provider pour l'instance Firebase Authentication.
///
/// Firebase Auth gère toutes les opérations d'authentification :
/// - Connexion/Déconnexion
/// - Création de comptes
/// - Gestion des sessions
/// - Tokens d'authentification
///
/// **Utilisation :**
/// ```dart
/// final firebaseAuth = ref.watch(firebaseAuthProvider);
/// final currentUser = firebaseAuth.currentUser;
/// ```
final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>((ref) {
  return firebase_auth.FirebaseAuth.instance;
});

/// Provider pour l'instance Cloud Firestore.
///
/// Firestore est la base de données NoSQL utilisée pour stocker :
/// - Les profils utilisateurs (collection 'users')
/// - Les usernames (collection 'usernames' pour vérifier l'unicité)
/// - Les produits, commandes, messages, etc.
///
/// **Utilisation :**
/// ```dart
/// final firestore = ref.watch(firestoreProvider);
/// final usersCollection = firestore.collection('users');
/// ```
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider pour l'instance Google Sign-In.
///
/// Gère le flow d'authentification Google :
/// - Affichage du sélecteur de compte
/// - Récupération des tokens OAuth
/// - Déconnexion Google
///
/// **Configuration :**
/// Pour Android : ajouter le SHA-1 dans Firebase Console
/// Pour iOS : configurer le URL Scheme dans Info.plist
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    // Scopes optionnels supplémentaires (email et profile sont inclus par défaut)
    scopes: ['email', 'profile'],
    // Requis par google_sign_in_web : sans clientId explicite (ou balise
    // meta google-signin-client_id), la connexion échoue silencieusement
    // sur web. Le client Android/iOS utilise sa propre config native,
    // non affectée par ce paramètre.
    clientId: kIsWeb
        ? '2762433205-qd3fesoffe98hk9oto62151mgdg235f1.apps.googleusercontent.com'
        : null,
  );
});

/// Provider pour l'instance Facebook Authentication.
///
/// Gère le flow d'authentification Facebook :
/// - Affichage de la page de connexion Facebook
/// - Gestion des permissions
/// - Récupération du profil utilisateur
///
/// **Configuration requise :**
/// - Android : Ajouter l'App ID Facebook dans strings.xml
/// - iOS : Configurer le URL Scheme et l'App ID dans Info.plist
final facebookAuthProvider = Provider<FacebookAuth>((ref) {
  return FacebookAuth.instance;
});

// ============================================================
// PROVIDER DU REPOSITORY D'AUTHENTIFICATION
// ============================================================

/// Provider pour le repository d'authentification.
///
/// Ce provider crée et fournit l'instance du repository d'authentification
/// avec toutes ses dépendances injectées. C'est le point d'entrée principal
/// pour toutes les opérations d'authentification dans l'application.
///
/// **Architecture :**
/// ```
/// UI/Widgets
///      ↓
/// Providers (State Management)
///      ↓
/// AuthRepository ← Vous êtes ici
///      ↓
/// Firebase Services
/// ```
///
/// **Utilisation dans un widget :**
/// ```dart
/// class LoginButton extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final authRepo = ref.read(authRepositoryProvider);
///
///     return ElevatedButton(
///       onPressed: () async {
///         try {
///           final user = await authRepo.signInWithGoogle();
///           // Naviguer vers la page suivante
///         } catch (e) {
///           // Afficher l'erreur
///         }
///       },
///       child: Text('Se connecter avec Google'),
///     );
///   }
/// }
/// ```
///
/// **Pourquoi utiliser un Provider ?**
/// 1. **Injection de dépendances** : Facilite les tests unitaires
/// 2. **Singleton** : Une seule instance partagée dans toute l'app
/// 3. **Réactivité** : Peut être reconstruit si les dépendances changent
/// 4. **Découplage** : Le code UI ne connaît pas l'implémentation
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
    facebookAuth: ref.watch(facebookAuthProvider),
  );
});

// ============================================================
// PROVIDERS DE L'ÉTAT D'AUTHENTIFICATION
// ============================================================

/// Provider qui écoute l'état d'authentification Firebase.
///
/// Ce StreamProvider émet une valeur chaque fois que l'état d'authentification
/// change (connexion, déconnexion, refresh du token).
///
/// **Retourne :**
/// - [firebase_auth.User] : Si un utilisateur est connecté
/// - [null] : Si aucun utilisateur n'est connecté
///
/// **Note importante :**
/// Ce provider retourne l'objet Firebase Auth User, pas notre entité User
/// du domaine. Pour obtenir le User complet avec username, country, etc.,
/// utilisez [currentUserProvider].
///
/// **Utilisation pour l'écran initial :**
/// ```dart
/// class App extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final authState = ref.watch(authStateProvider);
///
///     return authState.when(
///       data: (firebaseUser) {
///         if (firebaseUser == null) {
///           // Non connecté → Afficher onboarding
///           return OnboardingPage();
///         } else {
///           // Connecté → Vérifier si profil complet
///           return HomeOrProfileCompletion();
///         }
///       },
///       loading: () => SplashScreen(), // Chargement initial
///       error: (error, stack) => ErrorPage(error: error),
///     );
///   }
/// }
/// ```
final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider qui fournit l'utilisateur Firebase actuellement connecté.
///
/// Contrairement à [authStateProvider] qui est un Stream, celui-ci est
/// un Provider simple qui retourne l'utilisateur connecté de manière
/// synchrone (ou null si non connecté).
///
/// **Utilisation :**
/// ```dart
/// final firebaseUser = ref.watch(currentFirebaseUserProvider);
/// if (firebaseUser != null) {
///   print('UID: ${firebaseUser.uid}');
///   print('Email: ${firebaseUser.email}');
/// }
/// ```
///
/// **Différence avec authStateProvider :**
/// - authStateProvider : Stream (asynchrone, réactif)
/// - currentFirebaseUserProvider : Valeur actuelle (synchrone)
final currentFirebaseUserProvider = Provider<firebase_auth.User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentUser;
});

/// Provider qui fournit le User complet depuis Firestore.
///
/// Ce StreamProvider charge les données complètes de l'utilisateur
/// depuis Firestore (username, country, rating, etc.) et écoute
/// les changements en temps réel.
///
/// **Retourne :**
/// - [User] : Le profil complet de l'utilisateur
/// - [null] : Si non connecté ou profil non créé
///
/// **Utilisation :**
/// ```dart
/// final userAsync = ref.watch(currentUserProvider);
///
/// return userAsync.when(
///   data: (user) {
///     if (user == null) return Text('Non connecté');
///     return Text('Bienvenue ${user.username}');
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Erreur: $e'),
/// );
/// ```
///
/// **Flux de données :**
/// ```
/// 1. authStateProvider émet un firebase_auth.User
/// 2. On récupère son UID
/// 3. On écoute le document Firestore 'users/{uid}'
/// 4. On convertit en User entité
/// 5. On émet les mises à jour en temps réel
/// ```
final currentUserProvider = StreamProvider<User?>((ref) {
  // Écouter l'état d'authentification
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) {
        // Pas d'utilisateur connecté → retourner null
        return Stream.value(null);
      }

      // Utilisateur connecté → charger depuis Firestore
      final authRepository = ref.watch(authRepositoryProvider);
      return authRepository.getUserStream(firebaseUser.uid).handleError((
        error,
      ) {
        // Si le document n'existe pas encore (inscription en cours),
        // retourner null au lieu de lancer une erreur
        if (error.toString().contains('not found') ||
            error.toString().contains('non trouvé')) {
          return null;
        }
        throw error;
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Provider qui indique si l'utilisateur est connecté.
///
/// Simple provider booléen dérivé de [currentFirebaseUserProvider].
///
/// **Utilisation :**
/// ```dart
/// final isLoggedIn = ref.watch(isAuthenticatedProvider);
///
/// if (isLoggedIn) {
///   return HomePage();
/// } else {
///   return LoginPage();
/// }
/// ```
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  return user != null;
});

/// Provider qui indique si le profil utilisateur est complet.
///
/// Vérifie si l'utilisateur a complété toutes les étapes de l'inscription :
/// - Username défini
/// - Pays sélectionné
/// - CGU acceptées
///
/// **Utilisation :**
/// ```dart
/// final isComplete = ref.watch(isProfileCompleteProvider);
///
/// return isComplete.when(
///   data: (complete) {
///     if (complete) {
///       return HomePage(); // Profil complet
///     } else {
///       return UsernamePage(); // Compléter le profil
///     }
///   },
///   loading: () => LoadingPage(),
///   error: (e, _) => ErrorPage(),
/// );
/// ```
final isProfileCompleteProvider = Provider<AsyncValue<bool>>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      print('🟣 [isProfileCompleteProvider] User data: $user');

      if (user == null) {
        print(
          '🟣 [isProfileCompleteProvider] User est null → profil incomplet',
        );
        // Pas connecté → profil incomplet
        return const AsyncValue.data(false);
      }

      // Vérifier si le profil est complet
      // Un profil est complet si :
      // - Le username est défini (non vide)
      // - Les CGU ont été acceptées
      // Note: Le pays est obligatoire lors de la création, donc toujours défini
      final isComplete = user.username.isNotEmpty && user.acceptedTerms;

      print(
        '🟣 [isProfileCompleteProvider] username: "${user.username}", acceptedTerms: ${user.acceptedTerms}, isComplete: $isComplete',
      );

      return AsyncValue.data(isComplete);
    },
    loading: () {
      print('🟣 [isProfileCompleteProvider] Loading...');
      return const AsyncValue.loading();
    },
    error: (error, stack) {
      print('🔴 [isProfileCompleteProvider] Error: $error');
      return AsyncValue.error(error, stack);
    },
  );
});

// ============================================================
// PROVIDERS UTILITAIRES
// ============================================================

/// Provider pour vérifier si un username est disponible.
///
/// Ce provider famille permet de vérifier dynamiquement si un username
/// est disponible en fonction de la valeur saisie par l'utilisateur.
///
/// **Utilisation :**
/// ```dart
/// // Dans un TextField avec validation
/// final isAvailableAsync = ref.watch(
///   usernameAvailabilityProvider('john-doe'),
/// );
///
/// isAvailableAsync.when(
///   data: (available) {
///     if (available) {
///       return Icon(Icons.check, color: Colors.green);
///     } else {
///       return Text('Username déjà pris');
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Icon(Icons.error),
/// );
/// ```
///
/// **Note :** Utiliser un debounce pour éviter trop de requêtes pendant
/// que l'utilisateur tape.
final usernameAvailabilityProvider = FutureProvider.family<bool, String>((
  ref,
  username,
) async {
  // Ne vérifier que si le username a au moins 3 caractères
  if (username.length < 3) {
    return false;
  }

  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.isUsernameAvailable(username);
});

/// Provider pour générer une suggestion de username.
///
/// Génère un username unique basé sur le nom complet ou l'email
/// de l'utilisateur connecté.
///
/// **Utilisation :**
/// ```dart
/// final suggestionAsync = ref.watch(usernameSuggestionProvider);
///
/// suggestionAsync.when(
///   data: (suggestion) {
///     return Text('Suggestion: $suggestion');
///   },
///   loading: () => Text('Génération...'),
///   error: (e, _) => Text('Erreur'),
/// );
/// ```
final usernameSuggestionProvider = FutureProvider<String>((ref) async {
  final firebaseUser = ref.watch(currentFirebaseUserProvider);

  if (firebaseUser == null) {
    throw Exception('Utilisateur non connecté');
  }

  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.generateUsername(
    displayName: firebaseUser.displayName,
    email: firebaseUser.email,
  );
});

/// Écoute en temps réel le profil complet d'un utilisateur par son UID
/// (profil public, reçus, listes d'abonnés/abonnements, etc.).
///
/// Un [StreamProvider] plutôt qu'un [FutureProvider] : les compteurs
/// (followersCount, rating, ...) doivent rester à jour même sans action
/// explicite de l'utilisateur affiché (ex : quelqu'un d'autre le suit
/// pendant qu'il regarde sa propre page).
final userByIdProvider = StreamProvider.family<User, String>((ref, userId) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getUserStream(userId);
});
