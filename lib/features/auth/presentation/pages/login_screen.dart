import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/input.dart';
import '../controllers/login_controller.dart';

/// Page de connexion (Flow Ablony - Image 3).
///
/// Cette page permet aux utilisateurs existants de se connecter
/// avec leur email/username et mot de passe.
///
/// Après connexion réussie, la navigation est gérée automatiquement
/// par AppRouter (redirection vers /home).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ============================================================
  // CONTROLLERS ET ÉTAT LOCAL
  // ============================================================

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // Ne pas utiliser ref dans dispose() car le widget est démonté
    // La réinitialisation du controller se fera automatiquement
    super.dispose();
  }

  // ============================================================
  // LOGIQUE DE SOUMISSION
  // ============================================================

  /// Valide et soumet le formulaire de connexion.
  ///
  /// 1. Valide le formulaire
  /// 2. Appelle login du LoginController
  /// 3. La navigation est automatique via AppRouter
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(loginControllerProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // La navigation est gérée automatiquement par AppRouter
      // basé sur l'état d'authentification
      if (success && mounted) {
        // Navigation automatique vers /home
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginState = ref.watch(loginControllerProvider);

    // Écouter les erreurs
    ref.listen(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.loginScreenTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // ============================================================
                // CHAMP IDENTIFIANT (EMAIL OU USERNAME)
                // ============================================================
                Input(
                  controller: _emailController,
                  placeholder: l10n.loginScreenIdentifierPlaceholder,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.loginScreenIdentifierRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ============================================================
                // CHAMP MOT DE PASSE
                // ============================================================
                // Utilise le validateur automatique pour password
                Input(
                  controller: _passwordController,
                  placeholder: l10n.loginScreenPasswordPlaceholder,
                  type: InputType.password,
                ),

                const SizedBox(height: 32),

                // ============================================================
                // BOUTON SE CONNECTER
                // ============================================================
                PrimaryButton(
                  text: l10n.loginScreenSubmit,
                  onPressed: _submit,
                  isLoading: loginState.isLoading,
                  isFullWidth: true,
                ),

                const SizedBox(height: 24),

                // ============================================================
                // LIEN MOT DE PASSE OUBLIÉ
                // ============================================================
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Forgot password flow
                    },
                    child: Text(
                      l10n.loginScreenForgotPassword,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
