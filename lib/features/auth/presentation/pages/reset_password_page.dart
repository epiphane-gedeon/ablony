import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/exceptions/exceptions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/input.dart';
import '../../application/auth_providers.dart';

/// Page de réinitialisation du mot de passe.
///
/// Ouverte depuis le lien reçu par email après "Mot de passe oublié"
/// (cf. `LoginScreen._showForgotPasswordDialog`) : Firebase y ajoute un
/// paramètre `oobCode` dans l'URL (ex: `/auth/reset-password?oobCode=...`),
/// à condition d'avoir configuré cette URL comme "Action URL" personnalisée
/// pour le template "Réinitialisation du mot de passe" dans la console
/// Firebase (Authentication → Templates) — sinon le lien pointe vers la page
/// générique hébergée par Firebase au lieu de celle-ci.
///
/// Accessible sans authentification (route publique, cf. `app_router.dart`)
/// puisqu'un utilisateur qui a oublié son mot de passe n'est justement pas
/// connecté.
class ResetPasswordPage extends ConsumerStatefulWidget {
  /// Code de réinitialisation extrait de l'URL (paramètre `oobCode`).
  final String? oobCode;

  const ResetPasswordPage({super.key, required this.oobCode});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

enum _ResetPasswordStatus { verifying, valid, invalid, success }

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ResetPasswordStatus _status = _ResetPasswordStatus.verifying;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _verifyCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Vérifie que le code reçu dans l'URL est valide avant d'afficher le
  /// formulaire — évite de laisser l'utilisateur remplir un formulaire pour
  /// un lien déjà utilisé ou expiré.
  Future<void> _verifyCode() async {
    final code = widget.oobCode;
    if (code == null || code.isEmpty) {
      setState(() => _status = _ResetPasswordStatus.invalid);
      return;
    }

    try {
      await ref.read(authRepositoryProvider).verifyPasswordResetCode(code);
      if (mounted) setState(() => _status = _ResetPasswordStatus.valid);
    } catch (_) {
      if (mounted) setState(() => _status = _ResetPasswordStatus.invalid);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
        code: widget.oobCode!,
        newPassword: _passwordController.text,
      );
      if (mounted) setState(() => _status = _ResetPasswordStatus.success);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : l10n.errorGenericMsg(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.resetPasswordPageTitle),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: switch (_status) {
            _ResetPasswordStatus.verifying => const Center(
              child: CircularProgressIndicator(),
            ),
            _ResetPasswordStatus.invalid => _buildInvalidState(l10n),
            _ResetPasswordStatus.success => _buildSuccessState(l10n),
            _ResetPasswordStatus.valid => _buildForm(l10n),
          },
        ),
      ),
    );
  }

  Widget _buildInvalidState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.resetLinkInvalidMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: l10n.loginButton,
            onPressed: () => context.go('/auth/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.resetPasswordSuccessMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: l10n.loginButton,
            onPressed: () => context.go('/auth/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.resetPasswordPageDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Input(
            controller: _passwordController,
            placeholder: l10n.resetPasswordNewPasswordPlaceholder,
            type: InputType.password,
          ),
          const SizedBox(height: 16),
          Input(
            controller: _confirmPasswordController,
            placeholder: l10n.resetPasswordConfirmPasswordPlaceholder,
            type: InputType.password,
            autoValidate: false,
            validator: (value) {
              if (value != _passwordController.text) {
                return l10n.resetPasswordMismatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: l10n.resetPasswordSubmitButton,
            onPressed: _submit,
            isLoading: _isSubmitting,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
