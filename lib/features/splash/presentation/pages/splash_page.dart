/// Fichier: splash_page.dart
/// Description: Écran de démarrage (splash screen) de l'application Ablony.
/// Cet écran s'affiche au lancement de l'app pendant le chargement initial.
/// Il vérifie l'état d'authentification de l'utilisateur et redirige vers
/// la page appropriée (onboarding ou home).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../auth/application/providers.dart';

/// Page du splash screen affichée au lancement de l'application.
/// Gère l'initialisation et la navigation initiale.
///
/// **Logique de redirection :**
/// 1. Attendre 2 secondes (afficher le logo)
/// 2. Vérifier l'état d'authentification via Riverpod
/// 3. Si authentifié + profil complet → /home
/// 4. Si authentifié + profil incomplet → /auth/username
/// 5. Si non authentifié → /onboarding
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Démarre le processus d'initialisation
    _initializeApp();
  }

  /// Initialise l'application et navigue vers l'écran approprié.
  ///
  /// Cette méthode :
  /// 1. Affiche le splash pendant 2 secondes minimum
  /// 2. Écoute l'état d'authentification via [authStateProvider]
  /// 3. Vérifie si le profil est complet via [isProfileCompleteProvider]
  /// 4. Redirige vers la page appropriée avec go_router
  Future<void> _initializeApp() async {
    // Attendre minimum 2 secondes pour afficher le splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Écouter l'état d'authentification
    final authState = ref.read(authStateProvider);

    // Attendre que l'état soit chargé
    authState.when(
      data: (user) {
        if (user != null) {
          // Utilisateur authentifié → vérifier si profil complet
          final isProfileCompleteAsync = ref.read(isProfileCompleteProvider);

          isProfileCompleteAsync.when(
            data: (isComplete) {
              if (!mounted) return;

              if (isComplete) {
                // Profil complet → page d'accueil
                context.go('/home');
              } else {
                // Profil incomplet → compléter l'inscription
                context.go('/auth/username');
              }
            },
            loading: () {
              // En attente de vérification du profil
              if (mounted) context.go('/auth/username');
            },
            error: (_, __) {
              // Erreur lors de la vérification → aller à l'onboarding
              if (mounted) context.go('/onboarding');
            },
          );
        } else {
          // Non authentifié → onboarding
          if (mounted) context.go('/onboarding');
        }
      },
      loading: () {
        // Encore en chargement → attendre que go_router redirige automatiquement
        // Ne rien faire ici, le redirect de go_router va gérer
      },
      error: (_, __) {
        // En cas d'erreur, aller à l'onboarding
        if (mounted) context.go('/onboarding');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond bleu uni
      backgroundColor: Theme.of(context).colorScheme.primary,
      // Logo et loader centrés
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Espace flexible pour centrer le logo
          const Spacer(),

          // Logo centré horizontalement
          Center(child: _buildLogo()),

          // Espace flexible
          const Spacer(),

          // Petit loader en bas, centré horizontalement
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le widget du logo.
  /// Affiche le logo depuis assets/images/logo.png
  Widget _buildLogo() {
    return Image.asset(
      AppAssets.logo,
      width: 250,
      height: 150,
      fit: BoxFit.contain,
    );
  }
}
