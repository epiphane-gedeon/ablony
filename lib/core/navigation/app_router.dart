import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../features/auth/presentation/pages/pages.dart';
import '../../features/auth/application/providers.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/search/presentation/pages/search_results_page.dart';
import '../../features/search/presentation/pages/searching_page.dart';
import '../../features/messages/presentation/pages/messages_page.dart';
import '../../features/messages/presentation/pages/chat_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../core/layout/main_layout.dart';
import 'router_notifier.dart';

/// Configuration du routeur de l'application avec go_router.
///
/// Ce fichier gère toute la navigation de l'application avec :
/// - Routes définies de manière déclarative
/// - Navigation par chemin (ex: /auth/username)
/// - Redirections automatiques selon l'état d'authentification
/// - Gestion du profil complet/incomplet
///
/// **Architecture de navigation :**
/// ```
/// / (Splash) → /onboarding OU /home OU /auth/username
///    ↓
/// /onboarding → /auth/... (après clic sur bouton)
///    ↓
/// /auth/username → /auth/captcha → /auth/country → /home
/// ```
///
/// **États utilisateur :**
/// 1. **Non authentifié** → /onboarding
/// 2. **Authentifié + profil incomplet** → /auth/username, /auth/captcha, /auth/country
/// 3. **Authentifié + profil complet** → /home
///
/// **Redirections automatiques :**
/// - Si on essaie d'accéder à /home sans être auth → redirigé vers /onboarding
/// - Si on est auth mais profil incomplet → redirigé vers /auth/username
/// - Si on est auth avec profil complet → redirigé vers /home depuis /onboarding
///
/// **Exemple d'utilisation :**
/// ```dart
/// // Navigation simple
/// context.go('/auth/username');
///
/// // Navigation avec paramètres
/// context.go('/product/123');
///
/// // Navigation avec pop (retour)
/// context.pop();
///
/// // Remplacer toute la stack
/// context.go('/home'); // Utiliser go() au lieu de push() après inscription
/// ```

/// Provider du GoRouter configuré avec toutes les routes de l'app.
///
/// Ce provider est utilisé dans MaterialApp.router() pour gérer
/// la navigation de manière réactive avec Riverpod.
///
/// **Dépendances :**
/// - [authStateProvider] : Écoute les changements d'état d'authentification
/// - [isProfileCompleteProvider] : Vérifie si le profil est complet
///
/// **Utilisation :**
/// ```dart
/// final router = ref.watch(routerProvider);
/// MaterialApp.router(
///   routerConfig: router,
/// );
/// ```
final routerProvider = Provider<GoRouter>((ref) {
  // Le routeur a besoin du notifier pour écouter les changements d'état.
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    // ============================================================
    // CONFIGURATION GÉNÉRALE
    // ============================================================

    /// Le [refreshListenable] est la clé pour une redirection réactive.
    /// Il écoute notre [RouterNotifier] et ré-évalue la redirection
    /// à chaque fois que [notifyListeners] est appelé, sans recréer le routeur.
    refreshListenable: notifier,

    /// Route initiale de l'application.
    /// On commence toujours par le splash screen qui décide où aller ensuite.
    initialLocation: '/',

    /// Active les logs de navigation en mode debug.
    /// Utile pour comprendre les redirections et transitions.
    debugLogDiagnostics: true,

    // ============================================================
    // GESTION DES ERREURS
    // ============================================================

    /// Page affichée quand une route n'existe pas (404).
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.pageNotFound,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pageNotFoundMessage(state.uri.toString()),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: Text(l10n.backToHome),
              ),
            ],
          ),
        ),
      );
    },

    // ============================================================
    // REDIRECTIONS GLOBALES
    // ============================================================

    /// Fonction de redirection appelée avant chaque navigation.
    ///
    /// Cette fonction vérifie l'état d'authentification et le profil
    /// pour rediriger l'utilisateur vers la bonne page.
    ///
    /// **Logique de redirection :**
    /// ```
    /// 1. Si authState en chargement → null (attendre)
    /// 2. Si non auth + tentative d'accès zone protégée → /onboarding
    /// 3. Si auth + profil incomplet + hors zone /auth → /auth/username
    /// 4. Si auth + profil complet + sur /onboarding ou /auth → /home
    /// 5. Sinon → null (laisser passer)
    /// ```
    ///
    /// **Cas particuliers :**
    /// - Le splash (/) est toujours accessible
    /// - L'onboarding est accessible par défaut pour les non-auth
    /// - Les routes /auth/* ne sont accessibles que si auth mais profil incomplet
    /// Cette fonction est maintenant appelée uniquement lorsque le [refreshListenable]
    /// le demande (c'est-à-dire lors d'un changement d'auth ou de profil).
    redirect: (context, state) {
      final location = state.uri.path;

      // On utilise ref.read() ici car on ne veut pas que le routeur se recrée.
      // La logique de "watch" est gérée par le refreshListenable.
      final authState = ref.read(authStateProvider);
      final profileCompleteAsync = ref.read(isProfileCompleteProvider);

      print('🟡 [Router redirect] Location: $location');

      // 1. Attendre que l'état d'auth soit chargé
      if (authState.isLoading) {
        print('🟡 [Router redirect] Auth state loading...');
        return null; // Rester sur la page actuelle pendant le chargement
      }

      // 2. Vérifier si l'utilisateur est authentifié
      final isAuthenticated = authState.value != null;
      print(
        '🟡 [Router redirect] isAuthenticated: $isAuthenticated, uid: ${authState.value?.uid}',
      );

      // 3. Si authentifié, vérifier si le profil est complet
      print('🟡 [Router redirect] profileCompleteAsync: $profileCompleteAsync');

      // Si le provider est en loading, ne pas rediriger (attendre les données)
      if (profileCompleteAsync.isLoading) {
        print('🟡 [Router redirect] Provider en loading, pas de redirect');
        return null;
      }

      final isProfileComplete = profileCompleteAsync.value ?? false;
      print(
        '🟡 [Router redirect] isProfileComplete: $isProfileComplete',
      ); // ============================================================
      // CAS 1 : UTILISATEUR NON AUTHENTIFIÉ
      // ============================================================
      if (!isAuthenticated) {
        // Liste des routes publiques accessibles sans authentification
        const publicRoutes = [
          '/',
          '/onboarding',
          '/auth/signup/email',
          '/auth/login',
          '/home', // Permettre l'accès à la home sans être connecté
        ];

        // Si l'utilisateur essaie d'accéder à une route protégée
        if (!publicRoutes.contains(location)) {
          return '/onboarding'; // Rediriger vers l'onboarding
        }

        return null; // Laisser passer pour les routes publiques
      }

      // ============================================================
      // CAS 2 : UTILISATEUR AUTHENTIFIÉ MAIS PROFIL INCOMPLET
      // ============================================================
      if (isAuthenticated && !isProfileComplete) {
        // Routes autorisées pour compléter le profil
        const authRoutes = [
          '/auth/username',
          '/auth/country',
          '/auth/signup/email',
        ];

        // Si l'utilisateur n'est pas sur une route d'auth
        if (!authRoutes.contains(location)) {
          return '/auth/username'; // Forcer la complétion du profil
        }

        return null; // Laisser passer pour les routes /auth
      }

      // ============================================================
      // CAS 3 : UTILISATEUR AUTHENTIFIÉ ET PROFIL COMPLET
      // ============================================================
      if (isAuthenticated && isProfileComplete) {
        // Routes qui ne sont plus nécessaires (on redirige vers /home)
        const unnecessaryRoutes = [
          '/', // Splash screen
          '/splash', // Au cas où elle est appelée par son nom
          '/onboarding',
          '/auth/username',
          '/auth/signup/email',
          '/auth/login',
          '/auth/country',
        ];

        // Si l'utilisateur est sur une de ces routes
        if (unnecessaryRoutes.contains(location)) {
          print(
            '➡️ [Router redirect] Auth & profile complete. Redirecting from "$location" to /home',
          );
          return '/home';
        }

        return null; // Laisser passer pour les autres routes (ex: /settings)
      }

      // Par défaut, laisser passer
      return null;
    },

    // ============================================================
    // DÉFINITION DES ROUTES
    // ============================================================
    routes: [
      // ============================================================
      // ROUTE : SPLASH SCREEN
      // ============================================================
      /// Page de démarrage affichée au lancement de l'app.
      /// Vérifie l'auth et redirige automatiquement.
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // ============================================================
      // ROUTE : ONBOARDING
      // ============================================================
      /// Page d'accueil pour les utilisateurs non authentifiés.
      /// Affiche les bénéfices de l'app et les boutons de connexion.
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // ============================================================
      // ROUTE : AUTHENTIFICATION (FLOW D'INSCRIPTION)
      // ============================================================
      /// Route parente pour toutes les étapes d'inscription.
      /// Chemin : /auth/*
      GoRoute(
        path: '/auth',
        builder: (context, state) => const SizedBox.shrink(),
        routes: [
          // ====================================================
          // ÉTAPE 1 : USERNAME
          // ====================================================
          /// Page de saisie du nom d'utilisateur.
          /// L'utilisateur doit :
          /// - Choisir un username unique (3-30 caractères)
          /// - Accepter les CGU (obligatoire)
          /// - Accepter les emails marketing (optionnel)
          GoRoute(
            path: 'username',
            name: 'username',
            builder: (context, state) => const UsernamePage(),
          ),

          // ====================================================
          // INSCRIPTION PAR EMAIL (FLOW ABLONY)
          // ====================================================
          /// Page d'inscription par email (Image 2).
          /// Formulaire combiné : username + email + password + CGU
          GoRoute(
            path: 'signup/email',
            name: 'signup_email',
            builder: (context, state) => const EmailSignUpScreen(),
          ),

          // ====================================================
          // CONNEXION
          // ====================================================
          /// Page de connexion pour utilisateurs existants (Image 3).
          /// Email/username + password
          GoRoute(
            path: 'login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),

          // ...captcha step removed...

          // ====================================================
          // ÉTAPE 3 : COUNTRY
          // ====================================================
          /// Page de sélection du pays.
          /// Pays supportés : Togo 🇹🇬 et Bénin 🇧🇯
          /// Dernière étape avant la création du compte.
          GoRoute(
            path: 'country',
            name: 'country',
            builder: (context, state) => const CountrySelectionPage(),
          ),
        ],
      ),

      // ============================================================
      // NAVIGATION PRINCIPALE (BOTTOM BAR)
      // ============================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          // 1. ACCUEIL
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          // 2. RECHERCHER
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
          // 3. VENDRE (Placeholder pour l'index, géré par le layout)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sell',
                name: 'sell',
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
          // 4. MESSAGES
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                name: 'messages',
                builder: (context, state) => const MessagesPage(),
              ),
            ],
          ),
          // 5. PROFIL
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  // Sous-route : Porte-monnaie
                  GoRoute(
                    path: 'wallet',
                    name: 'wallet',
                    builder: (context, state) => const WalletPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ============================================================
      // ROUTE : RECHERCHE DÉTAILLÉE
      // ============================================================
      /// Page de recherche détaillée avec suggestions en temps réel
      /// Accessible depuis n'importe où dans l'app
      GoRoute(
        path: '/searching',
        name: 'searching',
        pageBuilder: (context, state) {
          final initialQuery = state.uri.queryParameters['q'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: SearchingPage(initialQuery: initialQuery),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Transition fade pour un effet fondu
                  return FadeTransition(opacity: animation, child: child);
                },
          );
        },
      ),

      // ============================================================
      // ROUTE : RÉSULTATS DE RECHERCHE
      // ============================================================
      /// Page affichant les résultats de recherche
      GoRoute(
        path: '/search-results',
        name: 'search-results',
        builder: (context, state) {
          final query = state.extra as String;
          return SearchResultsPage(query: query);
        },
      ),

      // ============================================================
      // ROUTE : DÉTAIL PRODUIT
      // ============================================================
      /// Page affichant le détail d'un produit
      GoRoute(
        path: '/product/:id',
        name: 'product-detail',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailPage(productId: productId);
        },
      ),

      // ============================================================
      // ROUTE : CHAT
      // ============================================================
      /// Page de conversation avec un utilisateur
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chat',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatPage(conversationId: conversationId);
        },
      ),

      // ============================================================
      // TODO: AUTRES ROUTES
      // ============================================================
      // - /search : Page de recherche
      // - /messages : Page des conversations
      // - /profile/:userId : Page de profil utilisateur
      // - /product/add : Page d'ajout de produit
      // - /settings : Page des paramètres
      // - /notifications : Page des notifications
    ],
  );
});
