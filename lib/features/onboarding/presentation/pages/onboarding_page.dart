/// Fichier: onboarding_page.dart
/// Description: Écran d'accueil (onboarding) de l'application Ablony.
///
/// Cet écran présente l'application aux nouveaux utilisateurs et propose
/// deux options : s'inscrire ou se connecter avec un compte existant.
///
/// Structure de l'écran :
/// 1. Header avec sélecteur de langue et bouton "Ignorer"
/// 2. Grille d'images de produits (2 rangées x 4 colonnes)
/// 3. Texte accrocheur principal
/// 4. Bouton "S'inscrire" (plein, bleu)
/// 5. Bouton "J'ai déjà un compte" (outline, transparent)
/// 6. Lien "À propos" en bas
///
/// Pour modifier :
/// - Le texte accrocheur : voir _buildCatchPhrase()
/// - Les images : voir _buildProductGrid()
/// - Les boutons : voir _buildActionButtons()

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/link.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../widgets/language_selector_dialog.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';

/// Page d'onboarding affichée après le splash screen.
///
/// Cette page est stateful car elle gère l'animation de défilement des images.
/// Deux lignes d'images défilent automatiquement dans des directions opposées.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  // Contrôleurs d'animation pour les deux lignes de défilement
  late AnimationController _topRowController;
  late AnimationController _bottomRowController;

  @override
  void initState() {
    super.initState();

    // Configuration de l'animation pour la ligne du haut (défile vers la gauche)
    _topRowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Durée d'un cycle complet
    )..repeat(); // Répète l'animation en boucle

    // Configuration de l'animation pour la ligne du bas (défile vers la droite)
    _bottomRowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Durée d'un cycle complet
    )..repeat(); // Répète l'animation en boucle
  }

  @override
  void dispose() {
    // Libère les ressources des contrôleurs
    _topRowController.dispose();
    _bottomRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Fond adapté au thème (blanc en clair, noir en sombre)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // SafeArea évite que le contenu ne passe sous la barre de statut
      body: SafeArea(
        // Column pour disposer les éléments verticalement avec tailles adaptables
        child: Column(
          children: [
            // ================================================================
            // 1. HEADER - Sélecteur de langue et bouton ignorer
            // ================================================================
            _buildHeader(),

            // Espace flexible qui pousse le contenu vers le centre
            const Spacer(flex: 2),

            // ================================================================
            // 2. LIGNES D'IMAGES DÉFILANTES - Aperçu des produits
            // ================================================================
            // Deux lignes qui défilent automatiquement dans des directions opposées
            _buildScrollingProductRows(),

            // Espacement relatif (4% de la hauteur de l'écran)
            SizedBox(height: screenHeight * 0.04),

            // ================================================================
            // 3. TEXTE ACCROCHEUR - Message principal
            // ================================================================
            // Pour modifier le texte : éditer _buildCatchPhrase()
            _buildCatchPhrase(),

            // Espace flexible avant les boutons
            const Spacer(flex: 2),

            // ================================================================
            // 4. BOUTONS D'ACTION - Inscription / Connexion
            // ================================================================
            _buildActionButtons(context),

            // Espacement relatif (2% de la hauteur de l'écran)
            SizedBox(height: screenHeight * 0.02),

            // ================================================================
            // 5. LIEN À PROPOS - Informations sur la plateforme
            // ================================================================
            _buildAboutLink(),

            // Espacement final relatif (3% de la hauteur de l'écran)
            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
    );
  }

  /// Construit le header avec le sélecteur de langue et le bouton ignorer.
  ///
  /// Ce header apparaît en haut de l'écran et contient :
  /// - À gauche : Sélecteur de langue fonctionnel (change entre FR et EN)
  /// - À droite : Bouton "Ignorer" pour passer l'onboarding
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => LanguageSelectorDialog(
                  currentLocale: currentLocale,
                  onLocaleChanged: (newLocale) {
                    ref.read(localeProvider.notifier).setLocale(newLocale);
                  },
                ),
              );
            },
            child: Row(
              children: [
                Icon(Icons.language, color: Theme.of(context).iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  currentLocale.languageCode == 'fr'
                      ? l10n.languageFrench
                      : l10n.languageEnglish,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Icon(Icons.arrow_drop_down, color: Theme.of(context).iconTheme.color),
              ],
            ),
          ),
          Link(
            text: l10n.skip,
            onTap: () {
              // Redirige vers la page d'accueil avec GoRouter
              context.go('/home');
            },
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Construit les deux lignes d'images qui défilent.
  ///
  /// Ligne 1 (haut) : Défile vers la GAUCHE
  /// Ligne 2 (bas) : Défile vers la DROITE
  ///
  /// Pour modifier :
  /// - La vitesse : changer duration dans les AnimationControllers (initState)
  /// - La taille des cartes : modifier width et height dans _buildProductCard()
  /// - Le nombre d'images : changer la liste dans _buildScrollingRow()
  Widget _buildScrollingProductRows() {
    return Column(
      children: [
        // ============================================================
        // LIGNE 1 : Défile vers la GAUCHE
        // ============================================================
        _buildScrollingRow(
          controller: _topRowController,
          reverse: false, // false = défile vers la gauche
          // Liste des images pour la première ligne (1 à 5)
          images: [
            'assets/images/1.jpg',
            'assets/images/2.jpg',
            'assets/images/3.jpg',
            'assets/images/4.jpg',
            'assets/images/5.jpg',
          ],
        ),

        // Espacement entre les deux lignes
        const SizedBox(height: 12),

        // ============================================================
        // LIGNE 2 : Défile vers la DROITE
        // ============================================================
        _buildScrollingRow(
          controller: _bottomRowController,
          reverse: true, // true = défile vers la droite
          // Liste des images pour la deuxième ligne (6 à 10)
          images: [
            'assets/images/6.jpg',
            'assets/images/7.jpg',
            'assets/images/8.jpg',
            'assets/images/9.jpg',
            'assets/images/10.jpg',
          ],
        ),
      ],
    );
  }

  /// Construit une ligne horizontale d'images qui défile en boucle infinie.
  ///
  /// [controller] : Contrôleur d'animation pour gérer le défilement
  /// [reverse] : Si true, défile vers la droite, sinon vers la gauche
  ///
  /// Le défilement infini est réalisé en dupliquant les images :
  /// Quand la dernière image disparaît, la première réapparaît immédiatement
  Widget _buildScrollingRow({
    required AnimationController controller,
    required bool reverse,
    required List<String> images, // Liste des chemins d'images à afficher
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Hauteur adaptable : 22% de la hauteur de l'écran pour chaque ligne
    final rowHeight = screenHeight * 0.22;

    // Largeur d'une carte + espacement (adaptée à la hauteur)
    final cardWidth = rowHeight * 0.6 + 12.0; // ratio 0.6 + espacement
    // Nombre de cartes à afficher (basé sur la taille de la liste d'images)
    final cardCount = images.length;
    // Largeur totale d'un cycle complet
    final totalWidth = cardWidth * cardCount;

    return SizedBox(
      height: rowHeight, // Hauteur adaptable
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          // Calcul de l'offset qui boucle de 0 à totalWidth
          final offset = (controller.value * totalWidth) % totalWidth;

          return Stack(
            children: [
              // On affiche 2 fois la liste pour créer l'effet de boucle infinie
              Positioned(
                left: reverse ? offset : -offset,
                child: Row(
                  children: List.generate(cardCount, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      // Passe le chemin de l'image correspondante à la carte
                      child: _buildProductCard(images[index]),
                    );
                  }),
                ),
              ),
              // Deuxième copie des images pour la boucle
              Positioned(
                left: reverse ? offset - totalWidth : -offset + totalWidth,
                child: Row(
                  children: List.generate(cardCount, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      // Passe le chemin de l'image correspondante à la carte
                      child: _buildProductCard(images[index]),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construit une carte de produit individuelle.
  ///
  /// [imagePath] : Le chemin de l'image à afficher (ex: 'assets/images/1.jpg')
  ///
  /// Pour modifier :
  /// - La taille : changer width et height
  /// - Les coins arrondis : modifier borderRadius
  /// - La couleur de fond : changer color
  ///
  /// Pour ajouter de vraies images :
  /// Remplacer le Container par Image.asset() avec ClipRRect
  Widget _buildProductCard(String imagePath) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Hauteur de la carte : 22% de la hauteur de l'écran
    final cardHeight = screenHeight * 0.22;
    // Largeur de la carte : ratio 0.6 pour garder des cartes verticales
    final cardWidth = cardHeight * 0.6;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest, // Fond adapté au thème
        borderRadius: BorderRadius.circular(16), // Coins arrondis
      ),
      // Affiche l'image avec des coins arrondis
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover, // L'image couvre tout l'espace sans déformation
          errorBuilder: (context, error, stackTrace) {
            // Fallback en cas d'erreur de chargement : icône par défaut
            return Center(
              child: Icon(
                Icons.image_outlined,
                color: Theme.of(context).textTheme.bodySmall?.color,
                size:
                    cardHeight * 0.3, // Taille de l'icône adaptée (30% de la hauteur)
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construit le texte accrocheur principal.
  ///
  /// Ce texte présente la proposition de valeur de l'application en 2 lignes.
  /// Il doit être court, impactant et facile à comprendre.
  Widget _buildCatchPhrase() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      // Marges horizontales de 32px pour centrer le texte avec du padding
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          // ============================================================
          // PREMIÈRE LIGNE DU SLOGAN
          // ============================================================
          Text(
            l10n.onboardingCatchPhrase1,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),

          // Petit espacement entre les deux lignes
          const SizedBox(height: 8),

          // ============================================================
          // DEUXIÈME LIGNE DU SLOGAN
          // ============================================================
          Text(
            l10n.onboardingCatchPhrase2,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ],
      ),
    );
  }

  /// Construit les boutons d'action principaux.
  ///
  /// Deux boutons sont affichés :
  /// 1. Bouton principal "S'inscrire" - Style plein (ElevatedButton) avec fond bleu
  /// 2. Bouton secondaire "J'ai déjà un compte" - Style outline avec bordure bleu
  ///
  /// Les deux boutons prennent toute la largeur disponible (double.infinity).
  ///
  /// Pour modifier :
  /// - Le texte des boutons : changer les chaînes dans Text()
  /// - L'ordre : inverser l'ordre des SizedBox
  /// - L'espacement entre eux : modifier height dans SizedBox du milieu
  /// - Les marges : modifier horizontal dans padding
  Widget _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      // Marges horizontales de 24px de chaque côté
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // ============================================================
          // BOUTON PRINCIPAL - S'INSCRIRE
          // ============================================================
          // Utilise le widget PrimaryButton réutilisable
          PrimaryButton(
            text: l10n.signUpButton,
            onPressed: () {
              // Affiche le bottom sheet du flow d'authentification
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const LoginFlowSheet(),
              );
            },
          ),

          // Espacement de 12px entre les deux boutons
        // Espacement de 12px entre les deux boutons
          const SizedBox(height: 12),

          // ============================================================
          // BOUTON SECONDAIRE - SE CONNECTER
          // ============================================================
          // Utilise le widget SecondaryButton réutilisable
          SecondaryButton(
            text: l10n.loginButton,
            onPressed: () {
              // Affiche le bottom sheet du flow d'authentification en mode connexion
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const LoginFlowSheet(isLogin: true),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Construit le lien "À propos" affiché en bas de l'écran.
  ///
  /// Ce lien permet d'accéder aux informations sur la plateforme.
  /// Il utilise RichText pour avoir une partie soulignée (le lien cliquable).
  /// Utilise GestureDetector pour un comportement de lien web (sans effet splash)
  Widget _buildAboutLink() {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        // TODO: Ajouter la navigation vers la page À propos
        // Exemple : Navigator.of(context).push(
        //   MaterialPageRoute(builder: (context) => const AboutPage()),
        // );
      },
      child: RichText(
        text: TextSpan(
          // ============================================================
          // PARTIE 1 : Texte normal (non souligné)
          // ============================================================
          text: l10n.aboutAblony,
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            // ============================================================
            // PARTIE 2 : Lien cliquable (souligné)
            // ============================================================
            TextSpan(
              text: l10n.ourPlatform,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
