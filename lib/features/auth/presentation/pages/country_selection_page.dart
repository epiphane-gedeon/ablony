import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/entities.dart';
import '../../application/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';

/// Page de sélection du pays lors de l'inscription.
///
/// Cette page permet à l'utilisateur de choisir son pays de résidence
/// parmi une liste restreinte (Togo et Bénin uniquement pour l'instant).
/// C'est la dernière étape du flow d'inscription.
///
/// **Flow complet :**
/// 1. Connexion sociale (Google/Facebook/Apple) → LoginFlowSheet
/// 2. → UsernamePage
/// 3. → CaptchaPage
/// 4. **→ CountrySelectionPage (vous êtes ici)**
/// 5. → HomePage (inscription terminée, profil complet)
///
/// **Objectif :**
/// - Récupérer le pays de l'utilisateur pour personnaliser l'expérience
/// - Adapter les devises affichées (XOF pour Togo/Bénin)
/// - Faciliter la logistique (livraisons, paiements locaux)
/// - Filtrer les annonces par région
///
/// **Pays supportés actuellement :**
/// - 🇹🇬 Togo (code: TG, devise: XOF, ville principale: Lomé)
/// - 🇧🇯 Bénin (code: BJ, devise: XOF, ville principale: Cotonou)
///
/// **TODO :**
/// - [ ] Ajouter d'autres pays d'Afrique de l'Ouest (Niger, Burkina Faso, etc.)
/// - [ ] Détecter automatiquement le pays via l'IP (avec confirmation)
/// - [ ] Ajouter un champ "Ville" après la sélection du pays
/// - [ ] Gérer les multi-devises si on ajoute des pays hors zone FCFA
///
/// **Exemple d'utilisation avec go_router :**
/// ```dart
/// context.go('/auth/country');
/// ```
class CountrySelectionPage extends ConsumerStatefulWidget {
  const CountrySelectionPage({super.key});

  @override
  ConsumerState<CountrySelectionPage> createState() =>
      _CountrySelectionPageState();
}

class _CountrySelectionPageState extends ConsumerState<CountrySelectionPage> {
  // ============================================================
  // ÉTAT
  // ============================================================

  /// Indique si une opération de sauvegarde est en cours.
  ///
  /// Lorsque l'utilisateur sélectionne un pays, on appelle
  /// `completeRegistration()` qui sauvegarde les données dans Firestore.
  /// Cette variable permet d'afficher un loader pendant cette opération.
  bool _isLoading = false;

  /// Pays actuellement sélectionné (null si aucun pays sélectionné).
  ///
  /// Permet de mettre en surbrillance le pays sélectionné avant
  /// la validation finale.
  Country? _selectedCountry;

  // ============================================================
  // MÉTHODES PRIVÉES
  // ============================================================

  /// Gère la sélection d'un pays.
  ///
  /// Cette méthode est appelée lorsque l'utilisateur tape sur une carte de pays.
  /// Elle :
  /// 1. Met à jour le state local (_selectedCountry)
  /// 2. Met à jour le provider d'inscription (country)
  /// 3. Appelle `completeRegistration()` pour sauvegarder dans Firestore
  /// 4. Navigue vers HomePage si succès, affiche une erreur sinon
  ///
  /// **Paramètres :**
  /// - [country] : Le pays sélectionné (Togo ou Bénin)
  ///
  /// **Flow technique :**
  /// ```
  /// 1. setCountry(country) → met à jour RegistrationState.country
  /// 2. completeRegistration() → transaction Firestore :
  ///    - Crée le document users/{uid}
  ///    - Crée le document usernames/{username} (réservation)
  /// 3. Navigation vers /home
  /// ```
  ///
  /// **Gestion d'erreurs :**
  /// - Si username déjà pris → affiche "Nom d'utilisateur déjà pris"
  /// - Si erreur réseau → affiche "Erreur lors de l'inscription"
  /// - Si données manquantes → affiche "Données incomplètes"
  Future<void> _handleCountrySelection(Country country) async {
    setState(() {
      _selectedCountry = country;
      _isLoading = true;
    });

    try {
      // Récupérer le notifier d'inscription
      final registrationNotifier = ref.read(registrationProvider.notifier);

      // 1. Mettre à jour le pays dans le state d'inscription
      registrationNotifier.setCountry(country);

      // Optionnel : Définir la ville principale par défaut
      // L'utilisateur pourra la changer plus tard dans son profil
      registrationNotifier.setCity(country.mainCity);

      // 2. Compléter l'inscription (sauvegarde dans Firestore)
      // Cette méthode crée l'utilisateur et réserve le username
      final user = await registrationNotifier.completeRegistration();

      // 3. Vérifier que l'utilisateur a bien été créé
      if (user != null && mounted) {
        print('✅ [CountrySelection] User créé: ${user.username}');

        // Le document existe maintenant dans Firestore
        // Les providers vont se rafraîchir automatiquement grâce aux Streams
        // Pas besoin d'attendre, le router va gérer la redirection

        if (!mounted) return;

        // Inscription réussie → Navigation vers la page d'accueil
        // Le redirect du router détectera que le profil est complet
        context.go('/home');
      } else if (mounted) {
        // Erreur inattendue
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.countryErrorGeneric);
      }
    } catch (e) {
      // Gestion des erreurs
      if (mounted) {
        setState(() => _isLoading = false);

        // Afficher un message d'erreur approprié
        final l10n = AppLocalizations.of(context)!;
        String errorMessage = l10n.countryErrorGeneric;
        if (e.toString().contains('username')) {
          errorMessage = l10n.countryErrorUsername;
        } else if (e.toString().contains('network')) {
          errorMessage = l10n.countryErrorNetwork;
        }
        _showError(errorMessage);
      }
    }
  }

  /// Affiche un message d'erreur en bas de l'écran.
  ///
  /// Utilise un SnackBar avec fond rouge pour indiquer une erreur.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Récupérer les dimensions de l'écran pour le responsive
    final screenHeight = context.layoutHeight();
    final screenWidth = context.layoutWidth();

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.countryTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                l10n.countrySubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              l10n.countryLoading,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          _buildCountryCard(
                            context: context,
                            country: Country.togo,
                            isSelected: _selectedCountry == Country.togo,
                            onTap: () => _handleCountrySelection(Country.togo),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildCountryCard(
                            context: context,
                            country: Country.benin,
                            isSelected: _selectedCountry == Country.benin,
                            onTap: () => _handleCountrySelection(Country.benin),
                          ),
                        ],
                      ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        l10n.countryInfo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
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

  /// Construit une carte pour un pays.
  ///
  /// Chaque carte affiche :
  /// - Le drapeau (emoji) du pays
  /// - Le nom du pays
  /// - Un sous-titre avec la ville principale et la devise
  /// - Une flèche pour indiquer que c'est cliquable
  ///
  /// **Paramètres :**
  /// - [context] : BuildContext pour accéder au thème et aux dimensions
  /// - [country] : Le pays à afficher (Togo ou Bénin)
  /// - [isSelected] : Si true, la carte est mise en surbrillance
  /// - [onTap] : Callback appelé lorsque l'utilisateur tape sur la carte
  ///
  /// **Style :**
  /// - Fond blanc avec ombre légère
  /// - Border bleu si sélectionné
  /// - Padding et spacing responsive
  /// - Animation au tap (Material InkWell)
  Widget _buildCountryCard({
    required BuildContext context,
    required Country country,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final screenHeight = context.layoutHeight();
    final screenWidth = context.layoutWidth();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.04), // 4% de padding
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // Border bleu si sélectionné, gris sinon
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ============================================================
              // DRAPEAU
              // ============================================================
              Container(
                width: screenWidth * 0.15, // 15% de la largeur
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    country.flag,
                    style: TextStyle(
                      fontSize: screenWidth * 0.08,
                    ), // 8% de la largeur
                  ),
                ),
              ),

              SizedBox(width: screenWidth * 0.04),

              // ============================================================
              // NOM ET INFORMATIONS
              // ============================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du pays
                    Text(
                      country.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    // Ville principale et devise
                    Text(
                      '${country.mainCity} • ${country.currencyCode}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),

              // ============================================================
              // ICÔNE FLÈCHE
              // ============================================================
              Icon(
                Icons.arrow_forward_ios,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
