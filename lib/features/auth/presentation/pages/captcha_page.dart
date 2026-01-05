import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/recaptcha_widget.dart';
import '../../application/providers.dart';

/// Page de vérification Captcha lors de l'inscription.
///
/// Cette page affiche un captcha pour vérifier que l'utilisateur est bien
/// un humain et non un robot. Elle s'affiche après la saisie du username
/// et avant la sélection du pays.
///
/// **Flow complet :**
/// 1. Connexion sociale (Google/Facebook/Apple) → LoginFlowSheet
/// 2. → UsernamePage
/// 3. **→ CaptchaPage (vous êtes ici)**
/// 4. → CountrySelectionPage
/// 5. → HomePage (inscription terminée)
///
/// **Objectif :**
/// - Prévenir les inscriptions automatisées (bots)
/// - Sécuriser la plateforme
/// - Protéger contre le spam
///
/// **État actuel :**
/// Pour l'instant, cette page affiche uniquement l'UI du captcha
/// sans intégration réelle. L'intégration d'un service de captcha
/// (reCAPTCHA, hCaptcha, etc.) sera faite ultérieurement.
///
/// **TODO :**
/// - [ ] Intégrer flutter_recaptcha_v2 ou un service similaire
/// - [ ] Implémenter la logique de vérification
/// - [ ] Gérer les cas d'échec (trop de tentatives, timeout)
/// - [ ] Ajouter un système de retry
///
/// **Exemple d'utilisation avec go_router :**
/// ```dart
/// context.go('/auth/captcha');
/// ```
class CaptchaPage extends ConsumerStatefulWidget {
  const CaptchaPage({super.key});

  @override
  ConsumerState<CaptchaPage> createState() => _CaptchaPageState();
}

class _CaptchaPageState extends ConsumerState<CaptchaPage> {
  // ============================================================
  // ÉTAT
  // ============================================================

  /// Indique si le captcha a été résolu avec succès.
  bool _captchaVerified = false;

  /// Token reCAPTCHA reçu après vérification
  String? _captchaToken;

  /// Contrôleur pour le widget RecaptchaWidget
  late RecaptchaWidgetController _recaptchaController;

  // TODO: Remplacez cette clé par votre vraie clé reCAPTCHA
  // Obtenir une clé sur : https://www.google.com/recaptcha/admin
  static const String _recaptchaSiteKey =
      '6Le3NxYsAAAAAITnIke4lK2zXMgIFlJSA6FIocL9';

  // ============================================================
  // MÉTHODES PRIVÉES
  // ============================================================

  /// Callback appelé quand le captcha est vérifié avec succès
  void _onCaptchaVerified(String token) {
    setState(() {
      _captchaToken = token;
      _captchaVerified = true;
    });

    debugPrint('✅ Captcha vérifié : $token');

    // TODO: Envoyer le token au backend pour vérification
    // Exemple avec Firebase Functions :
    // final result = await functions.httpsCallable('verifyCaptcha').call({
    //   'token': token,
    // });
  }

  /// Callback appelé en cas d'erreur du captcha
  void _onCaptchaError(String error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
  }

  /// Continue vers la page de sélection du pays.
  ///
  /// Cette méthode est appelée après que le captcha a été vérifié
  /// avec succès. Elle :
  /// 1. Vérifie que le token existe
  /// 2. Met à jour le state d'inscription (statut = captcha validé)
  /// 3. Navigue vers la page de sélection du pays
  void _handleContinue() {
    if (_captchaToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez compléter le captcha'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Envoyer le token au backend pour vérification côté serveur
    // IMPORTANT: La vérification côté client n'est pas suffisante !
    // Vous devez vérifier le token côté serveur avec votre Secret Key

    // Mettre à jour le provider d'inscription
    ref.read(registrationProvider.notifier).validateCaptcha();

    // Naviguer vers la sélection du pays
    context.go('/auth/country');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  void initState() {
    super.initState();
    _recaptchaController = RecaptchaWidgetController();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.02),
              Center(
                child: SvgPicture.asset(
                  'assets/icons/logo_full.svg',
                  width: screenWidth * 0.5,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Text(
                'On s\'assure qu\'on s\'adresse bien à vous, et non pas à un robot.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.04),
              Container(
                height: screenHeight * 0.4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _captchaVerified
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RecaptchaWidget(
                    siteKey: _recaptchaSiteKey,
                    onVerified: _onCaptchaVerified,
                    onError: _onCaptchaError,
                    theme: 'light',
                    controller: _recaptchaController,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              PrimaryButton(
                text: 'Continuer',
                onPressed: () {
                  // Déclenche le captcha invisible
                  _recaptchaController.executeCaptcha();
                },
                isFullWidth: true,
                fontSize: 16,
              ),
              SizedBox(height: screenHeight * 0.02),
              if (_captchaVerified)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'Vérifié avec succès !',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      PrimaryButton(
                        text: 'Continuer',
                        onPressed: _handleContinue,
                        isFullWidth: true,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
