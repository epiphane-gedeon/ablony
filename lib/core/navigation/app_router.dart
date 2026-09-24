import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/analytics_service.dart';
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
import '../../features/profile/presentation/pages/public_profile_page.dart';
import '../../features/profile/presentation/pages/user_listings_page.dart';
import '../../features/block/presentation/pages/blocked_users_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/product/presentation/pages/promotion_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/email_settings_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/profile/presentation/pages/security_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/wallet/presentation/pages/wallet_statement_page.dart';
import '../../features/wallet/presentation/pages/withdraw_page.dart';
import '../../features/product_fav/presentation/pages/favorites_page.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/address/presentation/pages/add_address_page.dart';
import '../../features/payment_method/presentation/pages/payment_method_page.dart';
import '../../features/relay_point/presentation/pages/select_relay_point_page.dart';
import '../../features/follow/presentation/pages/followers_page.dart';
import '../../features/follow/presentation/pages/following_page.dart';
import '../../features/dispute/presentation/pages/open_dispute_page.dart';
import '../../features/receipt/presentation/pages/receipt_page.dart';
import '../../features/reviews/presentation/pages/rate_seller_page.dart';
import '../../features/delivery/data/parcel_repository.dart';
import '../../features/delivery/presentation/pages/parcel_label_page.dart';
import '../../features/delivery/presentation/pages/scan_parcel_page.dart';
import '../../features/delivery/presentation/pages/stuck_parcels_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/product/domain/entities/product.dart';
import '../../core/layout/main_layout.dart';
import 'router_notifier.dart';
import 'navigator_key.dart';

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

    /// Clé de navigation racine, réutilisée par les handlers de notifications
    /// push (FCM) pour naviguer/afficher un SnackBar hors de l'arbre de widgets.
    navigatorKey: rootNavigatorKey,

    /// Logge chaque écran visité dans Analytics, sans un appel par page :
    /// l'observateur suit les transitions de route tout seul.
    observers: [ref.read(analyticsServiceProvider).observer],

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

      // La page de réinitialisation de mot de passe doit être accessible
      // par tous, quel que soit l'état d'authentification : un utilisateur
      // qui a oublié son mot de passe n'est justement pas connecté, et le
      // lien reçu par email doit fonctionner même si une session (partielle
      // ou non) traîne sur l'appareil.
      if (location == '/auth/reset-password') {
        return null;
      }

      // On utilise ref.read() ici car on ne veut pas que le routeur se recrée.
      // La logique de "watch" est gérée par le refreshListenable.
      final authState = ref.read(authStateProvider);
      final profileCompleteAsync = ref.read(isProfileCompleteProvider);

      // 1. Attendre que l'état d'auth soit chargé
      if (authState.isLoading) {
        return null; // Rester sur la page actuelle pendant le chargement
      }

      // 2. Vérifier si l'utilisateur est authentifié
      final isAuthenticated = authState.value != null;

      // Si le provider est en loading, ne pas rediriger (attendre les données)
      if (profileCompleteAsync.isLoading) {
        return null;
      }

      final isProfileComplete = profileCompleteAsync.value ?? false;
      // ============================================================
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
          // La recherche est en pure lecture (comme /home) : un visiteur non
          // connecté doit pouvoir parcourir/chercher des articles librement,
          // et ne sera invité à se connecter qu'au moment d'agir (message,
          // profil, achat, etc.).
          '/search',
          '/searching',
          '/search-results',
        ];

        // Les fiches produit sont publiques (lecture Firestore ouverte, cf.
        // firestore.rules) : un lien partagé (cf. lib/features/share/) doit
        // amener droit dessus même sans compte, sinon le contenu partagé se
        // perd derrière l'onboarding.
        final isPublicProductRoute = location.startsWith('/product/');

        // Si l'utilisateur essaie d'accéder à une route protégée
        if (!publicRoutes.contains(location) && !isPublicProductRoute) {
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
          '/auth/city',
          '/auth/signup/email',
        ];

        // Déjà sur une étape de complétion → laisser faire.
        if (authRoutes.contains(location)) {
          return null;
        }

        // On vise l'étape MANQUANTE, pas systématiquement le username : un
        // compte existant qui a déjà tout sauf la ville (backfill) ne doit pas
        // recommencer par le pseudo. Le document existe alors et a un username.
        final existingUser = ref.read(currentUserProvider).value;
        if (existingUser != null && existingUser.username.isNotEmpty) {
          return '/auth/city';
        }
        return '/auth/username';
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
          '/auth/city',
        ];

        // Si l'utilisateur est sur une de ces routes
        if (unnecessaryRoutes.contains(location)) {
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
          // MOT DE PASSE OUBLIÉ
          // ====================================================
          /// Page ouverte depuis le lien reçu par email (cf.
          /// `LoginScreen._showForgotPasswordDialog`). Le paramètre
          /// `oobCode` est ajouté par Firebase dans l'URL — nécessite d'avoir
          /// configuré cette URL comme "Action URL" du template
          /// "Réinitialisation du mot de passe" dans la console Firebase
          /// (Authentication → Templates), sinon Firebase utilise sa propre
          /// page générique au lieu de celle-ci.
          GoRoute(
            path: 'reset-password',
            name: 'reset_password',
            builder: (context, state) => ResetPasswordPage(
              oobCode: state.uri.queryParameters['oobCode'],
            ),
          ),

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

          // ====================================================
          // ÉTAPE 4 : VILLE
          // ====================================================
          /// Sélection de la ville (après le pays). C'est elle qui termine
          /// l'inscription. Sert aussi au backfill des comptes existants.
          GoRoute(
            path: 'city',
            name: 'city',
            builder: (context, state) => const CitySelectionPage(),
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
                    routes: [
                      // Sous-route : relevé du porte-monnaie
                      GoRoute(
                        path: 'statement',
                        name: 'wallet_statement',
                        builder: (context, state) =>
                            const WalletStatementPage(),
                      ),
                      // Sous-route : demande de retrait
                      GoRoute(
                        path: 'withdraw',
                        name: 'withdraw',
                        builder: (context, state) => const WithdrawPage(),
                      ),
                    ],
                  ),
                  // Sous-route : Favoris
                  GoRoute(
                    path: 'favorites',
                    name: 'favorites',
                    builder: (context, state) => const FavoritesPage(),
                  ),
                  // Sous-route : Mes annonces
                  GoRoute(
                    path: 'my-listings',
                    name: 'my-listings',
                    builder: (context, state) => const UserListingsPage(),
                  ),
                  // Sous-route : Ventes et achats
                  GoRoute(
                    path: 'orders',
                    name: 'orders',
                    builder: (context, state) => OrdersPage(
                      // `?tab=sales` arrive directement sur les ventes :
                      // c'est de là que vient un vendeur alerté d'un colis.
                      ongletVentes:
                          state.uri.queryParameters['tab'] == 'sales',
                    ),
                  ),
                  // Sous-route : Mise en avant
                  GoRoute(
                    path: 'promotion',
                    name: 'promotion',
                    builder: (context, state) => const PromotionPage(),
                  ),
                  // L'assistance, accessible depuis le profil comme depuis
                  // un paiement resté en attente.
                  GoRoute(
                    path: 'support',
                    name: 'support',
                    builder: (context, state) => SupportPage(
                      messageInitial: state.extra is String
                          ? state.extra as String
                          : null,
                    ),
                  ),
                  // Sous-route : Paramètres
                  GoRoute(
                    path: 'settings',
                    name: 'settings',
                    builder: (context, state) => const SettingsPage(),
                    routes: [
                      // Les personnes bloquées, sous les réglages : c'est là
                      // qu'on va les chercher, et c'est une des entrées
                      // mortes qui prend enfin vie.
                      GoRoute(
                        path: 'bloques',
                        name: 'blocked_users',
                        builder: (context, state) => const BlockedUsersPage(),
                      ),
                      GoRoute(
                        path: 'profil',
                        name: 'edit_profile',
                        builder: (context, state) => const EditProfilePage(),
                      ),
                      GoRoute(
                        path: 'securite',
                        name: 'security',
                        builder: (context, state) => const SecurityPage(),
                      ),
                      GoRoute(
                        path: 'email',
                        name: 'email_settings',
                        builder: (context, state) => const EmailSettingsPage(),
                      ),
                    ],
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
          String query = '';
          String? categoryId;
          String? categoryName;
          String? brand;
          String? size;
          String? condition;

          if (state.extra is String) {
            query = state.extra as String;
          } else if (state.extra is Map<String, dynamic>) {
            final params = state.extra as Map<String, dynamic>;
            query = params['query'] ?? '';
            categoryId = params['categoryId'];
            categoryName = params['categoryName'];
            brand = params['brand'];
            size = params['size'];
            condition = params['condition'];
          }

          return SearchResultsPage(
            query: query,
            categoryId: categoryId,
            categoryName: categoryName,
            initialBrand: brand,
            initialSize: size,
            initialCondition: condition,
          );
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
          // `?corriger=1` ouvre le formulaire de modification par-dessus la
          // fiche : c'est là qu'aboutit un appui sur « Annonce à corriger ».
          return ProductDetailPage(
            productId: productId,
            ouvrirCorrection: state.uri.queryParameters['corriger'] == '1',
          );
        },
      ),

      /// Signaler un problème sur une commande
      ///
      /// Sous le reçu : c'est là que le problème se pose, et c'est là qu'on
      /// doit trouver le recours.
      GoRoute(
        path: '/receipt/:receiptId/probleme',
        name: 'open_dispute',
        builder: (context, state) => OpenDisputePage(
          transactionRef: state.pathParameters['receiptId']!,
          // Le rôle décide des motifs affichés ; passé en query pour survivre à
          // un rechargement web (le litige vendeur n'existe que via ce drapeau).
          isSeller: state.uri.queryParameters['role'] == 'seller',
        ),
      ),

      /// La boîte de réception
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // ============================================================
      // ROUTE : PAIEMENT
      // ============================================================
      /// Page de paiement pour finaliser un achat
      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) {
          if (state.extra is Product) {
            return PaymentPage(product: state.extra as Product);
          } else if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            return PaymentPage(
              product: extra['product'] as Product?,
              amount: extra['amount'] as double?,
              pickupParcelCode: extra['pickupParcelCode'] as String?,
            );
          }
          return const Scaffold(
            body: Center(child: Text('Erreur de navigation')),
          );
        },
      ),

      // ============================================================
      // ROUTE : ADRESSE
      // ============================================================
      /// Page d'ajout/modification d'adresse de livraison
      GoRoute(
        path: '/address/add',
        name: 'add_address',
        builder: (context, state) {
          return const AddAddressPage();
        },
      ),

      // ============================================================
      // ROUTE : POINT RELAIS
      // ============================================================
      /// Page de sélection d'un point relais
      GoRoute(
        path: '/relay-point/select',
        name: 'select_relay_point',
        builder: (context, state) {
          return const SelectRelayPointPage();
        },
      ),

      // ============================================================
      // ROUTE : MOYEN DE PAIEMENT
      // ============================================================
      /// Page de sélection du moyen de paiement
      GoRoute(
        path: '/payment-method/select',
        name: 'select_payment_method',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isRecharge = extra?['isRecharge'] as bool? ?? false;
          return PaymentMethodPage(isRecharge: isRecharge);
        },
      ),

      // ============================================================
      // ROUTE : REÇU D'ACHAT
      // ============================================================
      /// Page de détail/téléchargement d'un reçu d'achat
      GoRoute(
        path: '/receipt/:receiptId',
        name: 'receipt',
        builder: (context, state) {
          final receiptId = state.pathParameters['receiptId']!;
          return ReceiptPage(receiptId: receiptId);
        },
      ),

      // ============================================================
      // ROUTE : NOTER LE VENDEUR
      // ============================================================
      /// Page proposée à l'acheteur juste après un achat finalisé
      GoRoute(
        path: '/rate-seller',
        name: 'rate_seller',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RateSellerPage(
            transactionRef: extra['transactionRef'] as String,
            sellerId: extra['sellerId'] as String,
            productId: extra['productId'] as String,
            productTitle: extra['productTitle'] as String,
          );
        },
      ),

      // ============================================================
      // ROUTE : ÉTIQUETTE DU COLIS
      // ============================================================
      /// Affichée au vendeur : le code à imprimer et à coller sur le carton
      /// avant de le déposer en point relais.
      ///
      /// Le code est dans l'URL, et non dans `extra` : une étiquette doit
      /// survivre à un rafraîchissement de la page web et à un retour depuis
      /// une notification. L'ancienne route passait l'identifiant par `extra`
      /// et se serait vidée dans les deux cas.
      // Scan d'une étiquette. Un seul écran pour tout le monde : c'est le
      // rôle de celui qui scanne qui décide de ce qui se passe ensuite, et
      // c'est le serveur qui le vérifie.
      GoRoute(
        path: '/delivery/scan',
        name: 'scan_parcel',
        builder: (context, state) => const ScanParcelPage(),
      ),
      // La file des colis bloqués. L'écran ne s'affiche que pour le personnel,
      // mais c'est la Cloud Function qui refuse : un lien partagé ne donne
      // rien à qui n'a pas le rôle.
      GoRoute(
        path: '/delivery/stuck',
        name: 'stuck_parcels',
        builder: (context, state) => const StuckParcelsPage(),
      ),
      GoRoute(
        path: '/delivery/label/:parcelCode',
        name: 'parcel_label',
        builder: (context, state) {
          final code = state.pathParameters['parcelCode']!;
          return Consumer(
            builder: (context, ref, _) {
              final parcel = ref.watch(parcelByCodeProvider(code));
              return parcel.when(
                data: (colis) => colis == null
                    ? const Scaffold(
                        body: Center(child: Text('Colis introuvable')),
                      )
                    : ParcelLabelPage(parcel: colis),
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Scaffold(
                  body: Center(child: Text('Erreur : $error')),
                ),
              );
            },
          );
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
      // ROUTE : PROFIL PUBLIC
      // ============================================================
      /// Page de profil public d'un utilisateur
      GoRoute(
        path: '/profile/:userId',
        name: 'public_profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return PublicProfilePage(userId: userId);
        },
        routes: [
          // Sous-route : Abonnés
          GoRoute(
            path: 'followers',
            name: 'followers',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return FollowersPage(userId: userId);
            },
          ),
          // Sous-route : Abonnements
          GoRoute(
            path: 'following',
            name: 'following',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return FollowingPage(userId: userId);
            },
          ),
        ],
      ),

      // ============================================================
      // TODO: AUTRES ROUTES
      // ============================================================
      // - /search : Page de recherche
      // - /messages : Page des conversations
      // - /product/add : Page d'ajout de produit
      // - /settings : Page des paramètres
      // - /notifications : Page des notifications
    ],
  );
});
