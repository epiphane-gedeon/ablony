import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/link.dart';
import '../../../../shared/widgets/input.dart';
import '../../../../shared/widgets/custom_checkbox.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/providers.dart';

/// Page de saisie du nom d'utilisateur lors de l'inscription.
///
/// Cette page est affichée après que l'utilisateur s'est connecté avec
/// Google, Facebook ou Apple. Elle permet de :
/// - Saisir un nom d'utilisateur unique
/// - Voir une suggestion générée automatiquement
/// - Accepter les conditions d'utilisation (obligatoire)
/// - Accepter les emails marketing (optionnel)
///
/// **Flow complet :**
/// 1. Connexion sociale (Google/Facebook/Apple) → LoginFlowSheet
/// 2. **→ UsernamePage (vous êtes ici)**
/// 3. → CaptchaPage
/// 4. → CountrySelectionPage
/// 5. → HomePage (inscription terminée)
///
/// **Données collectées :**
/// - Username (3-30 caractères, alphanumérique + tirets/underscores)
/// - Acceptation des CGU (checkbox obligatoire)
/// - Consentement emails marketing (checkbox optionnelle)
///
/// **Validation :**
/// - Username non vide
/// - Username unique (vérifié en temps réel avec Firestore)
/// - CGU acceptées
///
/// **Exemple d'utilisation avec go_router :**
/// ```dart
/// context.go('/auth/username');
/// ```
class UsernamePage extends ConsumerStatefulWidget {
  const UsernamePage({super.key});

  @override
  ConsumerState<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends ConsumerState<UsernamePage> {
  // ============================================================
  // CONTRÔLEURS ET ÉTAT
  // ============================================================

  /// Contrôleur du champ de saisie du username.
  ///
  /// Permet de récupérer le texte saisi et de le modifier programmatiquement.
  late final TextEditingController _usernameController;

  /// Clé du formulaire pour la validation.
  ///
  /// Utilisée pour valider tous les champs du formulaire en une fois.
  final _formKey = GlobalKey<FormState>();

  /// État de la checkbox "Accepter les CGU" (obligatoire).
  bool _acceptedTerms = false;

  /// État de la checkbox "Recevoir les emails marketing" (optionnelle).
  bool _marketingEmails = false;

  /// Indique si on affiche la suggestion de username.
  ///
  /// La suggestion est générée automatiquement depuis le displayName
  /// ou l'email de l'utilisateur.
  bool _showSuggestion = true;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();

    // Charger la suggestion au démarrage
    _loadSuggestion();
  }

  @override
  void dispose() {
    // Nettoyer le contrôleur pour éviter les fuites mémoire
    _usernameController.dispose();
    super.dispose();
  }

  // ============================================================
  // MÉTHODES PRIVÉES
  // ============================================================

  /// Charge la suggestion de username depuis le provider.
  ///
  /// La suggestion est générée automatiquement par le repository
  /// en fonction du displayName ou de l'email de l'utilisateur.
  Future<void> _loadSuggestion() async {
    // Attendre un frame pour que le provider soit disponible
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    // Récupérer la suggestion depuis le provider
    final suggestionAsync = ref.read(usernameSuggestionProvider);

    suggestionAsync.when(
      data: (suggestion) {
        // Ne remplir que si le champ est vide
        if (_usernameController.text.isEmpty) {
          setState(() {
            _usernameController.text = suggestion;
          });
        }
      },
      loading: () {
        // La suggestion est en cours de génération
      },
      error: (error, _) {
        // Erreur lors de la génération (ne pas bloquer l'utilisateur)
        debugPrint('Erreur génération username : $error');
      },
    );
  }

  /// Valide et soumet le formulaire.
  ///
  /// Cette méthode :
  /// 1. Valide le formulaire (username non vide, CGU acceptées)
  /// 2. Vérifie que le username est disponible
  /// 3. Enregistre les données dans le RegistrationProvider
  /// 4. Navigue vers la page Captcha
  Future<void> _handleSubmit() async {
    // ÉTAPE 1 : Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      return; // Formulaire invalide, ne pas continuer
    }

    // ÉTAPE 2 : Vérifier que les CGU sont acceptées
    if (!_acceptedTerms) {
      _showError('Vous devez accepter les conditions d\'utilisation');
      return;
    }

    final username = _usernameController.text.trim();

    // ÉTAPE 3 : Vérifier que le username est disponible
    final isAvailable = await ref.read(
      usernameAvailabilityProvider(username).future,
    );

    if (!isAvailable) {
      _showError('Ce nom d\'utilisateur est déjà pris');
      return;
    }

    // ÉTAPE 4 : Enregistrer dans le provider
    ref
        .read(registrationProvider.notifier)
        .setUsername(
          username: username,
          acceptedTerms: _acceptedTerms,
          marketingEmailsEnabled: _marketingEmails,
        );

    // ÉTAPE 5 : Naviguer directement vers la sélection du pays
    if (mounted) {
      context.go('/auth/country');
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

  /// Valide le format du username.
  ///
  /// Règles de validation :
  /// - Longueur entre 3 et 30 caractères
  /// - Caractères autorisés : a-z, A-Z, 0-9, tirets (-), underscores (_)
  /// - Doit commencer et finir par une lettre ou un chiffre
  String? _validateUsername(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.usernameRequired;
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return l10n.usernameMinLength;
    }
    if (trimmed.length > 30) {
      return l10n.usernameMaxLength;
    }
    final regex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]$');
    if (!regex.hasMatch(trimmed)) {
      return l10n.usernameFormatError;
    }
    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Récupérer la hauteur de l'écran pour le responsive
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Écouter l'état d'inscription pour afficher les erreurs
    final registrationState = ref.watch(registrationProvider);

    // Afficher une erreur si elle existe
    if (registrationState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError(registrationState.errorMessage!);
        // Effacer l'erreur après affichage
        ref.read(registrationProvider.notifier).clearError();
      });
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.registerTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Input(
                  label: l10n.usernameLabel,
                  placeholder: l10n.usernamePlaceholder,
                  controller: _usernameController,
                  validator: _validateUsername,
                  borderRadius: 12,
                  textColor: AppColors.textPrimary,
                  borderColor: AppColors.textSecondary,
                  focusedBorderColor: AppColors.primary,
                  fillColor: AppColors.background,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  type: InputType.text,
                  onChanged: (value) {
                    if (_showSuggestion && value.isNotEmpty) {
                      setState(() => _showSuggestion = false);
                    }
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
                if (_showSuggestion)
                  Consumer(
                    builder: (context, ref, child) {
                      final suggestionAsync = ref.watch(
                        usernameSuggestionProvider,
                      );
                      return suggestionAsync.when(
                        data: (suggestion) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                l10n.usernameSuggestion,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _usernameController.text = suggestion;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    suggestion,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                SizedBox(height: screenHeight * 0.03),
                CustomCheckbox(
                  value: _marketingEmails,
                  onChanged: (value) {
                    setState(() => _marketingEmails = value ?? false);
                  },
                  message: l10n.marketingEmailMessage,
                  activeColor: AppColors.primary,
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomCheckbox(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() => _acceptedTerms = value ?? false);
                  },
                  richMessage: Wrap(
                    children: [
                      Text(
                        l10n.termsPrefix,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Link(
                        text: l10n.termsTitle,
                        onTap: () {
                          debugPrint('Ouvrir les CGU');
                        },
                        underline: true,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.privacyPrefix,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Link(
                        text: l10n.privacyTitle,
                        onTap: () {
                          debugPrint('Ouvrir la politique');
                        },
                        underline: true,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.termsAge,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  activeColor: AppColors.primary,
                ),
                SizedBox(height: screenHeight * 0.04),
                PrimaryButton(
                  text: l10n.continueButton,
                  onPressed: _handleSubmit,
                  isLoading: registrationState.isLoading,
                  isFullWidth: true,
                  fontSize: 16,
                ),
                SizedBox(height: screenHeight * 0.02),
                Center(
                  child: Link(
                    text: l10n.problemLink,
                    onTap: () {
                      debugPrint('Ouvrir l\'aide');
                    },
                    underline: false,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
