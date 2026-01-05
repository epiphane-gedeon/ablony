/// Widget pour le bottom sheet du flow d'authentification (inscription/connexion).
///
/// Ce bottom sheet s'affiche depuis le bas de l'écran et propose plusieurs
/// options de connexion : Apple, Google, Facebook et email.
///
/// Utilise le thème de l'application avec un fond blanc.

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/link.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/providers.dart';

/// Bottom sheet présentant les options d'authentification.
///
/// Affiche :
/// - Un titre
/// - Un sous-titre explicatif
/// - Bouton "Continuer avec Apple" (blanc)
/// - Texte séparateur "ou"
/// - Bouton "Continuer avec Google" (bordure blanche)
/// - Bouton "Continuer avec Facebook" (bordure blanche)
/// - Lien "Continuer avec une adresse e-mail" (texte cyan)
/// - Lien "Tu es une entreprise ?" en bas
///
/// **Intégration avec Riverpod :**
/// Utilise [RegistrationNotifier] pour gérer le flow d'inscription.
/// Les boutons déclenchent les méthodes :
/// - [signInWithGoogle()] → Navigation vers /auth/username si succès
/// - [signInWithFacebook()] → Navigation vers /auth/username si succès
/// - [signInWithApple()] → Navigation vers /auth/username si succès
///
/// Pour afficher :
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (context) => const LoginFlowSheet(),
/// );
/// ```
class LoginFlowSheet extends ConsumerStatefulWidget {
  /// Si true, affiche le titre "Se connecter" et redirige vers /auth/login.
  /// Si false (défaut), affiche "S'inscrire" et redirige vers /auth/signup/email.
  final bool isLogin;

  const LoginFlowSheet({
    super.key,
    this.isLogin = false,
  });

  @override
  ConsumerState<LoginFlowSheet> createState() => _LoginFlowSheetState();
}

class _LoginFlowSheetState extends ConsumerState<LoginFlowSheet> {
  /// Indique si une opération d'authentification est en cours.
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isIOS = Platform.isIOS;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      // Hauteur adaptable : 50% de la hauteur de l'écran
      height: screenHeight * 0.5,
      decoration: BoxDecoration(
        // Fond blanc du thème
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ============================================================
          // BARRE DE FERMETURE
          // ============================================================
          _buildCloseBar(context),

          // ============================================================
          // CONTENU PRINCIPAL
          // ============================================================
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenHeight * 0.03,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ============================================================
                  // TITRE
                  // ============================================================
                  Text(
                    widget.isLogin ? l10n.loginTitleLogin : l10n.loginTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  // ============================================================
                  // SOUS-TITRE (différent selon plateforme)
                  // ============================================================
                  Text(
                    isIOS ? l10n.loginSubtitleApple : l10n.loginSubtitleGoogle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.025),

                  // ============================================================
                  // BOUTON APPLE (Blanc) - iOS uniquement
                  // ============================================================
                  if (isIOS) ...[
                    _buildAppleButton(context),
                    SizedBox(height: screenHeight * 0.015),

                    // ============================================================
                    // SÉPARATEUR "ou" - iOS uniquement
                    // ============================================================
                    _buildOrDivider(context),
                    SizedBox(height: screenHeight * 0.015),
                  ],

                  // ============================================================
                  // BOUTON GOOGLE (Bordure)
                  // ============================================================
                  _buildGoogleButton(context),

                  SizedBox(height: screenHeight * 0.01),

                  // ============================================================
                  // BOUTON FACEBOOK (Bordure)
                  // ============================================================
                  _buildFacebookButton(context),

                  SizedBox(height: screenHeight * 0.015),

                  // ============================================================
                  // LIEN EMAIL (Texte cyan)
                  // ============================================================
                  _buildEmailLink(context),

                  SizedBox(height: screenHeight * 0.015),

                  // ============================================================
                  // LIEN ENTREPRISE
                  // ============================================================
                  _buildBusinessLink(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la barre de fermeture en haut du bottom sheet.
  Widget _buildCloseBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bouton fermer (X)
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  /// Gère la connexion avec Apple.
  ///
  /// Cette méthode :
  /// 1. Appelle [signInWithApple()] du RegistrationNotifier
  /// 2. Affiche un loader pendant l'opération
  /// 3. Ferme le bottom sheet
  /// 4. Navigue vers /auth/username si succès
  /// 5. Affiche une erreur sinon
  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final registrationNotifier = ref.read(registrationProvider.notifier);
      final success = await registrationNotifier.signInWithApple();
      if (mounted) {
        setState(() => _isLoading = false);
        final status = ref.read(registrationProvider).status;
        
        if (success) {
          Navigator.of(context).pop();
          context.go('/auth/username');
        } else if (status == RegistrationStatus.completed) {
          Navigator.of(context).pop();
          // La redirection vers /home est gérée automatiquement par le routeur
        } else {
          _showError(l10n.loginAppleError);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur: ${e.toString()}');
      }
    }
  }

  /// Gère la connexion avec Google.
  ///
  /// Cette méthode :
  /// 1. Appelle [signInWithGoogle()] du RegistrationNotifier
  /// 2. Affiche un loader pendant l'opération
  /// 3. Ferme le bottom sheet
  /// 4. Navigue vers /auth/username si succès
  /// 5. Affiche une erreur sinon
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final registrationNotifier = ref.read(registrationProvider.notifier);
      final success = await registrationNotifier.signInWithGoogle();
      if (mounted) {
        setState(() => _isLoading = false);
        final status = ref.read(registrationProvider).status;

        if (success) {
          Navigator.of(context).pop();
          context.go('/auth/username');
        } else if (status == RegistrationStatus.completed) {
          Navigator.of(context).pop();
          // La redirection vers /home est gérée automatiquement par le routeur
        } else {
          _showError(l10n.loginGoogleError);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur: ${e.toString()}');
      }
    }
  }

  /// Gère la connexion avec Facebook.
  ///
  /// Cette méthode :
  /// 1. Appelle [signInWithFacebook()] du RegistrationNotifier
  /// 2. Affiche un loader pendant l'opération
  /// 3. Ferme le bottom sheet
  /// 4. Navigue vers /auth/username si succès
  /// 5. Affiche une erreur sinon
  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final registrationNotifier = ref.read(registrationProvider.notifier);
      final success = await registrationNotifier.signInWithFacebook();
      if (mounted) {
        setState(() => _isLoading = false);
        final status = ref.read(registrationProvider).status;

        if (success) {
          Navigator.of(context).pop();
          context.go('/auth/username');
        } else if (status == RegistrationStatus.completed) {
          Navigator.of(context).pop();
          // La redirection vers /home est gérée automatiquement par le routeur
        } else {
          _showError(l10n.loginFacebookError);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur: ${e.toString()}');
      }
    }
  }

  /// Affiche un message d'erreur en bas de l'écran.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Construit le bouton Apple (utilise le thème primary).
  Widget _buildAppleButton(BuildContext context) {
    return PrimaryButton(
      text: AppLocalizations.of(context)!.loginApple,
      onPressed: _isLoading ? null : _handleAppleSignIn,
      icon: Icons.apple,
      fontSize: 14,
      isLoading: _isLoading,
    );
  }

  /// Construit le séparateur "ou".
  Widget _buildOrDivider(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).dividerColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.loginOr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurfaceVariant, thickness: 1)),
      ],
    );
  }

  /// Construit le bouton Google avec logo Google.
  Widget _buildGoogleButton(BuildContext context) {
    return SecondaryButton(
      text: AppLocalizations.of(context)!.loginGoogle,
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      customIcon: Image.asset('assets/icons/google.png', width: 20, height: 20),
      fontSize: 14,
      isLoading: _isLoading,
    );
  }

  /// Construit le bouton Facebook (utilise le thème).
  Widget _buildFacebookButton(BuildContext context) {
    return SecondaryButton(
      text: AppLocalizations.of(context)!.loginFacebook,
      onPressed: _isLoading ? null : _handleFacebookSignIn,
      icon: Icons.facebook,
      fontSize: 14,
      isLoading: _isLoading,
    );
  }

  /// Construit le lien pour continuer avec email (utilise la couleur primaire).
  Widget _buildEmailLink(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Link(
        text: l10n.loginEmail,
        onTap: () {
          Navigator.of(context).pop();
          if (widget.isLogin) {
            context.push('/auth/login');
          } else {
            context.push('/auth/signup/email');
          }
        },
        underline: false,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Construit le lien pour les entreprises.
  Widget _buildBusinessLink(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(l10n.loginBusiness, style: Theme.of(context).textTheme.bodySmall),
        Link(
          text: l10n.loginBusinessMore,
          onTap: () {
            // TODO: Navigation vers la page entreprise
          },
          underline: true,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }
}
