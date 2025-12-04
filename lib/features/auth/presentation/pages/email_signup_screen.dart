import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/input.dart';
import '../../../../shared/widgets/custom_checkbox.dart';
import '../../application/registration_provider.dart';

/// Page d'inscription par email (Flow Ablony - Image 2).
///
/// Cette page combine plusieurs étapes en un seul formulaire :
/// - Saisie du nom d'utilisateur
/// - Saisie de l'email
/// - Saisie du mot de passe
/// - Acceptation des CGU (obligatoire)
/// - Consentement marketing (optionnel)
///
/// Après validation, l'utilisateur est redirigé vers la sélection du pays.
class EmailSignUpScreen extends ConsumerStatefulWidget {
  const EmailSignUpScreen({super.key});

  @override
  ConsumerState<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends ConsumerState<EmailSignUpScreen> {
  // ============================================================
  // CONTROLLERS ET ÉTAT LOCAL
  // ============================================================

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _marketingEnabled = false;
  bool _termsAccepted = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIQUE DE SOUMISSION
  // ============================================================

  /// Valide et soumet le formulaire d'inscription.
  ///
  /// 1. Vérifie que les CGU sont acceptées
  /// 2. Valide le formulaire
  /// 3. Appelle startEmailSignUp du RegistrationNotifier
  /// 4. Redirige vers /auth/country si succès
  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;

    // Vérifier l'acceptation des CGU
    setState(() {
      _showTermsError = !_termsAccepted;
    });

    if (!_termsAccepted) return;

    // Valider le formulaire
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(registrationProvider.notifier)
          .startEmailSignUp(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            acceptedTerms: _termsAccepted,
            marketingEmailsEnabled: _marketingEnabled,
          );

      if (success && mounted) {
        context.go('/auth/country');
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final registrationState = ref.watch(registrationProvider);

    // Écouter les erreurs
    ref.listen(registrationProvider, (previous, next) {
      if (next.errorMessage != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(registrationProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.emailSignupTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ============================================================
                // CHAMP USERNAME
                // ============================================================
                Input(
                  controller: _usernameController,
                  placeholder: l10n.emailSignupUsernamePlaceholder,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.emailSignupUsernameRequired;
                    }
                    if (value.length < 3) {
                      return l10n.emailSignupUsernameMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ============================================================
                // CHAMP EMAIL
                // ============================================================
                // Utilise le validateur automatique pour email
                Input(
                  controller: _emailController,
                  placeholder: l10n.emailSignupEmailPlaceholder,
                  type: InputType.email,
                ),
                const SizedBox(height: 16),

                // ============================================================
                // CHAMP MOT DE PASSE
                // ============================================================
                // Utilise le validateur automatique pour password
                Input(
                  controller: _passwordController,
                  placeholder: l10n.emailSignupPasswordPlaceholder,
                  type: InputType.password,
                ),
                const SizedBox(height: 8),

                // Indication mot de passe
                Text(
                  l10n.emailSignupPasswordHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
                const SizedBox(height: 32),

                // ============================================================
                // CHECKBOX MARKETING
                // ============================================================
                CustomCheckbox(
                  value: _marketingEnabled,
                  onChanged: (value) {
                    setState(() => _marketingEnabled = value ?? false);
                  },
                  message: l10n.emailSignupMarketing,
                  messageStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                ),
                const SizedBox(height: 16),

                // ============================================================
                // CHECKBOX CGU (OBLIGATOIRE)
                // ============================================================
                CustomCheckbox(
                  value: _termsAccepted,
                  onChanged: (value) {
                    setState(() {
                      _termsAccepted = value ?? false;
                      if (_termsAccepted) _showTermsError = false;
                    });
                  },
                  errorMessage: _showTermsError ? l10n.emailSignupTermsError : null,
                  richMessage: RichText(
                    text: TextSpan(
                      text: l10n.termsPrefix,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                      children: [
                        TextSpan(
                          text: l10n.termsTitle,
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          // TODO: Add tap handler for terms
                        ),
                        TextSpan(text: l10n.privacyPrefix),
                        TextSpan(
                          text: l10n.privacyTitle,
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          // TODO: Add tap handler for privacy policy
                        ),
                        TextSpan(text: l10n.termsAge),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ============================================================
                // BOUTON CONTINUER
                // ============================================================
                PrimaryButton(
                  text: l10n.continueButton,
                  onPressed: _submit,
                  isLoading: registrationState.isLoading,
                  isFullWidth: true,
                ),

                const SizedBox(height: 24),

                // ============================================================
                // LIEN AIDE
                // ============================================================
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Help action
                    },
                    child: Text(
                      l10n.problemLink,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
