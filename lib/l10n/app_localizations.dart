import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Nom de la langue française
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// Nom de la langue anglaise
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get languageEnglish;

  /// Bouton pour ignorer l'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get skip;

  /// Première ligne du slogan
  ///
  /// In fr, this message translates to:
  /// **'Achetez et vendez'**
  String get onboardingCatchPhrase1;

  /// Deuxième ligne du slogan
  ///
  /// In fr, this message translates to:
  /// **'facilement.'**
  String get onboardingCatchPhrase2;

  /// Bouton d'inscription
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire sur Ablony'**
  String get signUpButton;

  /// Bouton de connexion
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un compte'**
  String get loginButton;

  /// Texte du lien à propos
  ///
  /// In fr, this message translates to:
  /// **'À propos d\'Ablony : '**
  String get aboutAblony;

  /// Lien vers la plateforme
  ///
  /// In fr, this message translates to:
  /// **'Notre plateforme'**
  String get ourPlatform;

  /// Titre du dialogue de sélection de langue
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue'**
  String get changeLanguage;

  /// Bouton de validation
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// Bouton de fermeture
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// Titre de la page d'erreur 404
  ///
  /// In fr, this message translates to:
  /// **'Page non trouvée'**
  String get pageNotFound;

  /// Message d'erreur 404 avec la route
  ///
  /// In fr, this message translates to:
  /// **'La route \"{route}\" n\'existe pas.'**
  String pageNotFoundMessage(String route);

  /// Bouton pour retourner à l'accueil
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// Titre de la page d'inscription
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get registerTitle;

  /// Label du champ username
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get usernameLabel;

  /// Placeholder du champ username
  ///
  /// In fr, this message translates to:
  /// **'john-doe'**
  String get usernamePlaceholder;

  /// Erreur champ username obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Le nom d\'utilisateur est obligatoire'**
  String get usernameRequired;

  /// Erreur longueur minimale username
  ///
  /// In fr, this message translates to:
  /// **'Minimum 3 caractères'**
  String get usernameMinLength;

  /// Erreur longueur maximale username
  ///
  /// In fr, this message translates to:
  /// **'Maximum 30 caractères'**
  String get usernameMaxLength;

  /// Erreur format username
  ///
  /// In fr, this message translates to:
  /// **'Format invalide (lettres, chiffres, - et _ uniquement)'**
  String get usernameFormatError;

  /// Texte suggestion username
  ///
  /// In fr, this message translates to:
  /// **'Nous te suggérons ce nom d\'utilisateur :'**
  String get usernameSuggestion;

  /// Message checkbox marketing email
  ///
  /// In fr, this message translates to:
  /// **'Je souhaite recevoir par e-mail des offres personnalisées et les dernières mises à jour d\'Ablony.'**
  String get marketingEmailMessage;

  /// Préfixe CGU
  ///
  /// In fr, this message translates to:
  /// **'En t\'inscrivant, tu confirmes que tu acceptes les '**
  String get termsPrefix;

  /// Lien CGU
  ///
  /// In fr, this message translates to:
  /// **'Termes & Conditions de Ablony'**
  String get termsTitle;

  /// Préfixe politique de confidentialité
  ///
  /// In fr, this message translates to:
  /// **', avoir lu la '**
  String get privacyPrefix;

  /// Lien politique de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyTitle;

  /// Âge minimum inscription
  ///
  /// In fr, this message translates to:
  /// **' et avoir au moins 18 ans.'**
  String get termsAge;

  /// Bouton continuer inscription
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// Lien aide inscription
  ///
  /// In fr, this message translates to:
  /// **'Un problème ?'**
  String get problemLink;

  /// Titre du flow de connexion (inscription)
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire sur Ablony'**
  String get loginTitle;

  /// Titre du flow de connexion (login)
  ///
  /// In fr, this message translates to:
  /// **'Se connecter à Ablony'**
  String get loginTitleLogin;

  /// Sous-titre Apple
  ///
  /// In fr, this message translates to:
  /// **'Utilise ton identifiant Apple, c\'est plus rapide.'**
  String get loginSubtitleApple;

  /// Sous-titre Google
  ///
  /// In fr, this message translates to:
  /// **'Utilise ton compte Google, c\'est plus rapide.'**
  String get loginSubtitleGoogle;

  /// Erreur connexion Apple
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion avec Apple'**
  String get loginAppleError;

  /// Erreur connexion Google
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion avec Google'**
  String get loginGoogleError;

  /// Erreur connexion Facebook
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion avec Facebook'**
  String get loginFacebookError;

  /// Bouton Apple
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get loginApple;

  /// Bouton Google
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get loginGoogle;

  /// Bouton Facebook
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Facebook'**
  String get loginFacebook;

  /// Séparateur ou
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get loginOr;

  /// Lien email
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec une adresse e-mail'**
  String get loginEmail;

  /// Texte entreprise
  ///
  /// In fr, this message translates to:
  /// **'Tu es une entreprise ? '**
  String get loginBusiness;

  /// Lien entreprise
  ///
  /// In fr, this message translates to:
  /// **'En savoir plus'**
  String get loginBusinessMore;

  /// Titre de la page d'accueil
  ///
  /// In fr, this message translates to:
  /// **'Ablony'**
  String get homeTitle;

  /// Message de bienvenue sur la home
  ///
  /// In fr, this message translates to:
  /// **'Hello World! 🎉'**
  String get homeWelcome;

  /// Sous-titre de la home
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Ablony !'**
  String get homeSubtitle;

  /// Message de succès inscription
  ///
  /// In fr, this message translates to:
  /// **'L\'inscription est terminée avec succès.'**
  String get homeSuccess;

  /// Titre de la page de sélection du pays
  ///
  /// In fr, this message translates to:
  /// **'Où habites-tu ?'**
  String get countryTitle;

  /// Sous-titre de la page de sélection du pays
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne ton pays pour personnaliser ton expérience.'**
  String get countrySubtitle;

  /// Texte du loader inscription
  ///
  /// In fr, this message translates to:
  /// **'Finalisation de ton inscription...'**
  String get countryLoading;

  /// Erreur générique inscription
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get countryErrorGeneric;

  /// Erreur réseau inscription
  ///
  /// In fr, this message translates to:
  /// **'Problème de connexion. Vérifiez votre réseau.'**
  String get countryErrorNetwork;

  /// Erreur username déjà pris
  ///
  /// In fr, this message translates to:
  /// **'Le nom d\'utilisateur est déjà pris.'**
  String get countryErrorUsername;

  /// Texte info modification pays/ville
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras modifier ton pays et ta ville plus tard dans tes paramètres.'**
  String get countryInfo;

  /// Titre de la page d'inscription email
  ///
  /// In fr, this message translates to:
  /// **'Inscris-toi'**
  String get emailSignupTitle;

  /// Label champ username
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get emailSignupUsername;

  /// Placeholder username
  ///
  /// In fr, this message translates to:
  /// **'Choisis un nom d\'utilisateur'**
  String get emailSignupUsernamePlaceholder;

  /// Label champ email
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get emailSignupEmail;

  /// Placeholder email
  ///
  /// In fr, this message translates to:
  /// **'Ton adresse email'**
  String get emailSignupEmailPlaceholder;

  /// Label champ mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get emailSignupPassword;

  /// Placeholder mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Crée un mot de passe'**
  String get emailSignupPasswordPlaceholder;

  /// Indication mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Il doit contenir 8 caractères minimum, dont au moins un chiffre une majuscule et un caractère spécial.'**
  String get emailSignupPasswordHint;

  /// Checkbox marketing
  ///
  /// In fr, this message translates to:
  /// **'Je souhaite recevoir par e-mail des offres personnalisées et les dernières mises à jour d\'Ablony.'**
  String get emailSignupMarketing;

  /// Erreur CGU non acceptées
  ///
  /// In fr, this message translates to:
  /// **'Tu dois accepter les conditions pour continuer'**
  String get emailSignupTermsError;

  /// Erreur username requis
  ///
  /// In fr, this message translates to:
  /// **'Le nom d\'utilisateur est requis'**
  String get emailSignupUsernameRequired;

  /// Erreur longueur min username
  ///
  /// In fr, this message translates to:
  /// **'Le nom d\'utilisateur doit contenir au moins 3 caractères'**
  String get emailSignupUsernameMinLength;

  /// Erreur email requis
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get emailSignupEmailRequired;

  /// Erreur email invalide
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un email valide'**
  String get emailSignupEmailInvalid;

  /// Erreur mot de passe requis
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get emailSignupPasswordRequired;

  /// Erreur longueur min mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 7 caractères'**
  String get emailSignupPasswordMinLength;

  /// Erreur pas de chiffre dans mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins un chiffre'**
  String get emailSignupPasswordNoDigit;

  /// Titre de la page de connexion
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi'**
  String get loginScreenTitle;

  /// Label champ identifiant
  ///
  /// In fr, this message translates to:
  /// **'Identifiant ou adresse email'**
  String get loginScreenIdentifier;

  /// Placeholder identifiant
  ///
  /// In fr, this message translates to:
  /// **'Entre ton email ou pseudo'**
  String get loginScreenIdentifierPlaceholder;

  /// Label champ mot de passe connexion
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginScreenPassword;

  /// Placeholder mot de passe connexion
  ///
  /// In fr, this message translates to:
  /// **'Ton mot de passe'**
  String get loginScreenPasswordPlaceholder;

  /// Bouton de connexion
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginScreenSubmit;

  /// Lien mot de passe oublié
  ///
  /// In fr, this message translates to:
  /// **'Tu as oublié ton mot de passe ?'**
  String get loginScreenForgotPassword;

  /// Erreur identifiant requis
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est requis'**
  String get loginScreenIdentifierRequired;

  /// Erreur mot de passe requis
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get loginScreenPasswordRequired;

  /// Titre écran vente
  ///
  /// In fr, this message translates to:
  /// **'Vends un article'**
  String get sellTitle;

  /// Bouton ajouter photos
  ///
  /// In fr, this message translates to:
  /// **'Ajouter photos'**
  String get addPhotos;

  /// Label titre produit
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get productTitle;

  /// Hint titre produit
  ///
  /// In fr, this message translates to:
  /// **'Dis aux acheteurs ce que tu vends'**
  String get productTitleHint;

  /// Label description produit
  ///
  /// In fr, this message translates to:
  /// **'Décris ton article'**
  String get productDescription;

  /// Hint description produit
  ///
  /// In fr, this message translates to:
  /// **'Ajoute des informations utiles'**
  String get productDescriptionHint;

  /// Label catégorie
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// Titre page sélection catégorie
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une catégorie'**
  String get selectCategory;

  /// Label état
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get condition;

  /// État neuf
  ///
  /// In fr, this message translates to:
  /// **'Neuf avec étiquette'**
  String get conditionNew;

  /// Condition: Excellent
  ///
  /// In fr, this message translates to:
  /// **'Excellent état'**
  String get conditionExcellent;

  /// Condition: Good
  ///
  /// In fr, this message translates to:
  /// **'Bon état'**
  String get conditionGood;

  /// État correct
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get conditionFair;

  /// Label prix
  ///
  /// In fr, this message translates to:
  /// **'Prix sans les frais de port'**
  String get price;

  /// Hint prix
  ///
  /// In fr, this message translates to:
  /// **'0'**
  String get priceHint;

  /// Bouton publier
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get publish;

  /// Erreur champ requis
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire'**
  String get requiredField;

  /// Erreur sélection photo
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne au moins 1 photo'**
  String get selectAtLeast1Photo;

  /// Erreur max photos
  ///
  /// In fr, this message translates to:
  /// **'Maximum 6 photos'**
  String get maxPhotosReached;

  /// Attribut marque
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get brand;

  /// Attribut taille
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get size;

  /// Attribut couleur
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get color;

  /// Attribut matière
  ///
  /// In fr, this message translates to:
  /// **'Matière'**
  String get material;

  /// Attribut longueur
  ///
  /// In fr, this message translates to:
  /// **'Longueur'**
  String get length;

  /// Attribut type de sac
  ///
  /// In fr, this message translates to:
  /// **'Type de sac'**
  String get bagType;

  /// Attribut type de bijou
  ///
  /// In fr, this message translates to:
  /// **'Type de bijou'**
  String get jewelType;

  /// Attribut mouvement
  ///
  /// In fr, this message translates to:
  /// **'Mouvement'**
  String get movement;

  /// Placeholder sélection état
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner l\'état'**
  String get selectCondition;

  /// Placeholder recherche catégorie
  ///
  /// In fr, this message translates to:
  /// **'Chercher une catégorie'**
  String get searchCategory;

  /// Placeholder sélection sous-catégorie
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une sous-catégorie'**
  String get selectSubcategory;

  /// Message pendant la publication
  ///
  /// In fr, this message translates to:
  /// **'Publication en cours...'**
  String get publishing;

  /// Label prix sans frais
  ///
  /// In fr, this message translates to:
  /// **'Prix sans les frais de port'**
  String get priceWithoutShipping;

  /// Message de succès après publication d'un produit
  ///
  /// In fr, this message translates to:
  /// **'Produit publié avec succès ! 🎉'**
  String get productPublishedSuccess;

  /// Message d'erreur générique lors de la publication
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue lors de la publication'**
  String get productPublishError;

  /// Erreur quand l'utilisateur n'est pas authentifié
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur non connecté'**
  String get userNotConnected;

  /// Erreur lors de l'upload des images vers Firebase Storage
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'upload des images'**
  String get imageUploadError;

  /// Bouton de confirmation
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// Bouton pour réessayer après une erreur
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Devise monétaire (Franc CFA)
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get currency;

  /// Placeholder générique pour sélection d'attributs (utilisé dynamiquement)
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner {attributeName}'**
  String selectAttributePlaceholder(String attributeName);

  /// Placeholder générique pour entrée de texte d'attributs (utilisé dynamiquement)
  ///
  /// In fr, this message translates to:
  /// **'Entrer {attributeName}'**
  String enterAttributePlaceholder(String attributeName);

  /// Label for price input field
  ///
  /// In fr, this message translates to:
  /// **'Indique ton prix'**
  String get indicateYourPrice;

  /// Placeholder for price input showing format (0,00 FCFA)
  ///
  /// In fr, this message translates to:
  /// **'0,00 FCFA'**
  String get priceFormatPlaceholder;

  /// Button label to confirm price entry
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validatePrice;

  /// Placeholder for search bar in selection screens
  ///
  /// In fr, this message translates to:
  /// **'Trouver...'**
  String get searchPlaceholder;

  /// Category name for women's items
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get categoryFemme;

  /// Category name for men's items
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get categoryHomme;

  /// Filter option to see all products
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get seeAll;

  /// Subcategory: Top clothing
  ///
  /// In fr, this message translates to:
  /// **'Haut'**
  String get subcategoryHaut;

  /// Subcategory: Bottom clothing
  ///
  /// In fr, this message translates to:
  /// **'Bas'**
  String get subcategoryBas;

  /// Subcategory: Shoes
  ///
  /// In fr, this message translates to:
  /// **'Chaussures'**
  String get subcategoryChaussures;

  /// Subcategory: Accessories
  ///
  /// In fr, this message translates to:
  /// **'Accessoires'**
  String get subcategoryAccessoires;

  /// Subcategory: Shirt
  ///
  /// In fr, this message translates to:
  /// **'Chemise'**
  String get subcategoryChemise;

  /// Subcategory: T-shirt
  ///
  /// In fr, this message translates to:
  /// **'T-shirt'**
  String get subcategoryTshirt;

  /// Subcategory: Tank top
  ///
  /// In fr, this message translates to:
  /// **'Débardeur'**
  String get subcategoryDebardeur;

  /// Subcategory: Sweater
  ///
  /// In fr, this message translates to:
  /// **'Pull'**
  String get subcategoryPull;

  /// Subcategory: Jacket
  ///
  /// In fr, this message translates to:
  /// **'Veste'**
  String get subcategoryVeste;

  /// Subcategory: Pants
  ///
  /// In fr, this message translates to:
  /// **'Pantalon'**
  String get subcategoryPantalon;

  /// Subcategory: Skirt
  ///
  /// In fr, this message translates to:
  /// **'Jupe'**
  String get subcategoryJupe;

  /// Subcategory: Shorts
  ///
  /// In fr, this message translates to:
  /// **'Short'**
  String get subcategoryShort;

  /// Subcategory: Dress
  ///
  /// In fr, this message translates to:
  /// **'Robe'**
  String get subcategoryRobe;

  /// Subcategory: Sneakers
  ///
  /// In fr, this message translates to:
  /// **'Baskets'**
  String get subcategoryBaskets;

  /// Subcategory: Sandals
  ///
  /// In fr, this message translates to:
  /// **'Sandales'**
  String get subcategorySandales;

  /// Subcategory: Heels
  ///
  /// In fr, this message translates to:
  /// **'Talons'**
  String get subcategoryTalons;

  /// Subcategory: Bag
  ///
  /// In fr, this message translates to:
  /// **'Sac'**
  String get subcategorySac;

  /// Subcategory: Jewelry
  ///
  /// In fr, this message translates to:
  /// **'Bijoux'**
  String get subcategoryBijoux;

  /// Subcategory: Cap
  ///
  /// In fr, this message translates to:
  /// **'Casquette'**
  String get subcategoryCasquette;

  /// Subcategory: Belt
  ///
  /// In fr, this message translates to:
  /// **'Ceinture'**
  String get subcategoryCeinture;

  /// Subcategory: Watch
  ///
  /// In fr, this message translates to:
  /// **'Montre'**
  String get subcategoryMontre;

  /// Attribute: Condition
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get attributeEtat;

  /// Attribute: Brand
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get attributeMarque;

  /// Attribute: Size
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get attributeTaille;

  /// Attribute: Shoe size
  ///
  /// In fr, this message translates to:
  /// **'Pointure'**
  String get attributePointure;

  /// Attribute: Color
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get attributeCouleur;

  /// Attribute: Material
  ///
  /// In fr, this message translates to:
  /// **'Matière'**
  String get attributeMatiere;

  /// Attribute: Length
  ///
  /// In fr, this message translates to:
  /// **'Longueur'**
  String get attributeLongueur;

  /// Attribute: Bag type
  ///
  /// In fr, this message translates to:
  /// **'Type de sac'**
  String get attributeTypeSac;

  /// Attribute: Jewelry type
  ///
  /// In fr, this message translates to:
  /// **'Type de bijou'**
  String get attributeTypeBijou;

  /// Attribute: Movement (watch)
  ///
  /// In fr, this message translates to:
  /// **'Mouvement'**
  String get attributeMouvement;

  /// Condition: New with tags
  ///
  /// In fr, this message translates to:
  /// **'Neuf avec étiquette'**
  String get conditionNewWithTags;

  /// Condition: Satisfactory
  ///
  /// In fr, this message translates to:
  /// **'Satisfaisant'**
  String get conditionSatisfactory;

  /// Condition: Used
  ///
  /// In fr, this message translates to:
  /// **'Usé'**
  String get conditionUsed;

  /// Dynamic condition value translation
  ///
  /// In fr, this message translates to:
  /// **'{value, select, newWithTags{Neuf avec étiquette} excellent{Excellent} good{Bon état} satisfactory{Satisfaisant} worn{Usé} other{Bon état}}'**
  String conditionValue(String value);

  /// Help text for condition attribute
  ///
  /// In fr, this message translates to:
  /// **'État général du produit'**
  String get helpTextCondition;

  /// Help text for brand attribute
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez la marque du produit'**
  String get helpTextBrand;

  /// Help text for top size
  ///
  /// In fr, this message translates to:
  /// **'Taille pour hauts, chemises, pulls, vestes'**
  String get helpTextSizeTop;

  /// Help text for bottom size
  ///
  /// In fr, this message translates to:
  /// **'Taille pour pantalons, shorts, jupes'**
  String get helpTextSizeBottom;

  /// Help text for shoe size
  ///
  /// In fr, this message translates to:
  /// **'Pointure de chaussures'**
  String get helpTextShoeSize;

  /// Help text for color
  ///
  /// In fr, this message translates to:
  /// **'Couleur principale du produit'**
  String get helpTextColor;

  /// Help text for material
  ///
  /// In fr, this message translates to:
  /// **'Matière principale du produit'**
  String get helpTextMaterial;

  /// Help text for length
  ///
  /// In fr, this message translates to:
  /// **'Longueur de la robe ou jupe'**
  String get helpTextLength;

  /// Help text for bag type
  ///
  /// In fr, this message translates to:
  /// **'Type de sac (sac à main, sac à dos, etc.)'**
  String get helpTextBagType;

  /// Help text for jewelry type
  ///
  /// In fr, this message translates to:
  /// **'Type de bijou (collier, bague, bracelet, etc.)'**
  String get helpTextJewelryType;

  /// Help text for watch movement
  ///
  /// In fr, this message translates to:
  /// **'Type de mouvement de la montre'**
  String get helpTextMovement;

  /// Short length option
  ///
  /// In fr, this message translates to:
  /// **'Court'**
  String get lengthShort;

  /// Medium length option
  ///
  /// In fr, this message translates to:
  /// **'Mi-long'**
  String get lengthMedium;

  /// Long length option
  ///
  /// In fr, this message translates to:
  /// **'Long'**
  String get lengthLong;

  /// Black color
  ///
  /// In fr, this message translates to:
  /// **'Noir'**
  String get colorBlack;

  /// White color
  ///
  /// In fr, this message translates to:
  /// **'Blanc'**
  String get colorWhite;

  /// Gray color
  ///
  /// In fr, this message translates to:
  /// **'Gris'**
  String get colorGray;

  /// Beige color
  ///
  /// In fr, this message translates to:
  /// **'Beige'**
  String get colorBeige;

  /// Brown color
  ///
  /// In fr, this message translates to:
  /// **'Marron'**
  String get colorBrown;

  /// Blue color
  ///
  /// In fr, this message translates to:
  /// **'Bleu'**
  String get colorBlue;

  /// Navy blue color
  ///
  /// In fr, this message translates to:
  /// **'Bleu marine'**
  String get colorNavyBlue;

  /// Light blue color
  ///
  /// In fr, this message translates to:
  /// **'Bleu clair'**
  String get colorLightBlue;

  /// Red color
  ///
  /// In fr, this message translates to:
  /// **'Rouge'**
  String get colorRed;

  /// Pink color
  ///
  /// In fr, this message translates to:
  /// **'Rose'**
  String get colorPink;

  /// Purple color
  ///
  /// In fr, this message translates to:
  /// **'Violet'**
  String get colorPurple;

  /// Green color
  ///
  /// In fr, this message translates to:
  /// **'Vert'**
  String get colorGreen;

  /// Khaki green color
  ///
  /// In fr, this message translates to:
  /// **'Vert kaki'**
  String get colorKhakiGreen;

  /// Yellow color
  ///
  /// In fr, this message translates to:
  /// **'Jaune'**
  String get colorYellow;

  /// Orange color
  ///
  /// In fr, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// Multicolor
  ///
  /// In fr, this message translates to:
  /// **'Multicolore'**
  String get colorMulticolor;

  /// Gold color
  ///
  /// In fr, this message translates to:
  /// **'Doré'**
  String get colorGold;

  /// Silver color
  ///
  /// In fr, this message translates to:
  /// **'Argenté'**
  String get colorSilver;

  /// Cotton material
  ///
  /// In fr, this message translates to:
  /// **'Coton'**
  String get materialCotton;

  /// Polyester material
  ///
  /// In fr, this message translates to:
  /// **'Polyester'**
  String get materialPolyester;

  /// Wool material
  ///
  /// In fr, this message translates to:
  /// **'Laine'**
  String get materialWool;

  /// Silk material
  ///
  /// In fr, this message translates to:
  /// **'Soie'**
  String get materialSilk;

  /// Linen material
  ///
  /// In fr, this message translates to:
  /// **'Lin'**
  String get materialLinen;

  /// Denim material
  ///
  /// In fr, this message translates to:
  /// **'Jean'**
  String get materialDenim;

  /// Leather material
  ///
  /// In fr, this message translates to:
  /// **'Cuir'**
  String get materialLeather;

  /// Suede material
  ///
  /// In fr, this message translates to:
  /// **'Daim'**
  String get materialSuede;

  /// Synthetic material
  ///
  /// In fr, this message translates to:
  /// **'Synthétique'**
  String get materialSynthetic;

  /// Velvet material
  ///
  /// In fr, this message translates to:
  /// **'Velours'**
  String get materialVelvet;

  /// Cashmere material
  ///
  /// In fr, this message translates to:
  /// **'Cachemire'**
  String get materialCashmere;

  /// Viscose material
  ///
  /// In fr, this message translates to:
  /// **'Viscose'**
  String get materialViscose;

  /// Other material
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get materialOther;

  /// Handbag type
  ///
  /// In fr, this message translates to:
  /// **'Sac à main'**
  String get bagTypeHandbag;

  /// Backpack type
  ///
  /// In fr, this message translates to:
  /// **'Sac à dos'**
  String get bagTypeBackpack;

  /// Clutch type
  ///
  /// In fr, this message translates to:
  /// **'Pochette'**
  String get bagTypeClutch;

  /// Tote bag type
  ///
  /// In fr, this message translates to:
  /// **'Tote bag'**
  String get bagTypeTote;

  /// Crossbody bag type
  ///
  /// In fr, this message translates to:
  /// **'Sac bandoulière'**
  String get bagTypeCrossbody;

  /// Travel bag type
  ///
  /// In fr, this message translates to:
  /// **'Sac de voyage'**
  String get bagTypeTravel;

  /// Satchel type
  ///
  /// In fr, this message translates to:
  /// **'Sacoche'**
  String get bagTypeSatchel;

  /// Necklace type
  ///
  /// In fr, this message translates to:
  /// **'Collier'**
  String get jewelryTypeNecklace;

  /// Bracelet type
  ///
  /// In fr, this message translates to:
  /// **'Bracelet'**
  String get jewelryTypeBracelet;

  /// Earrings type
  ///
  /// In fr, this message translates to:
  /// **'Boucles d\'oreilles'**
  String get jewelryTypeEarrings;

  /// Ring type
  ///
  /// In fr, this message translates to:
  /// **'Bague'**
  String get jewelryTypeRing;

  /// Brooch type
  ///
  /// In fr, this message translates to:
  /// **'Broche'**
  String get jewelryTypeBrooch;

  /// Watch bracelet type
  ///
  /// In fr, this message translates to:
  /// **'Montre bracelet'**
  String get jewelryTypeWatchBracelet;

  /// Quartz watch movement
  ///
  /// In fr, this message translates to:
  /// **'Quartz'**
  String get watchMovementQuartz;

  /// Automatic watch movement
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get watchMovementAutomatic;

  /// Manual watch movement
  ///
  /// In fr, this message translates to:
  /// **'Manuel'**
  String get watchMovementManual;

  /// Digital watch movement
  ///
  /// In fr, this message translates to:
  /// **'Numérique'**
  String get watchMovementDigital;

  /// Other brand
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get brandOther;

  /// Home navigation label
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// Search navigation label
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get navSearch;

  /// Sell navigation label
  ///
  /// In fr, this message translates to:
  /// **'Vendre'**
  String get navSell;

  /// Messages navigation label
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// Profile navigation label
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// Price with buyer protection included
  ///
  /// In fr, this message translates to:
  /// **'{price} FCFA incl.'**
  String priceWithProtection(String price);

  /// Articles tab in search page
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get searchArticlesTab;

  /// Members tab in search page
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get searchMembersTab;

  /// Search bar placeholder
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un article ou un membre...'**
  String get searchArticlesPlaceholder;

  /// Close button text
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeButton;

  /// No search results found
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get searchNoResults;

  /// Message when search field is empty
  ///
  /// In fr, this message translates to:
  /// **'Commencez à taper pour rechercher...'**
  String get searchTyping;

  /// Filter modal title
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get filterTitle;

  /// Sort by label
  ///
  /// In fr, this message translates to:
  /// **'Classer par'**
  String get sortBy;

  /// Sort by relevance
  ///
  /// In fr, this message translates to:
  /// **'Pertinence'**
  String get sortRelevance;

  /// Sort by most recent
  ///
  /// In fr, this message translates to:
  /// **'Plus récents'**
  String get sortRecent;

  /// Sort by price ascending
  ///
  /// In fr, this message translates to:
  /// **'Prix croissant'**
  String get sortPriceAsc;

  /// Sort by price descending
  ///
  /// In fr, this message translates to:
  /// **'Prix décroissant'**
  String get sortPriceDesc;

  /// Sort by most popular
  ///
  /// In fr, this message translates to:
  /// **'Plus populaires'**
  String get sortPopular;

  /// Category filter label
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get filterCategory;

  /// Size filter label
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get filterSize;

  /// Brand filter label
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get filterBrand;

  /// Condition filter label
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get filterCondition;

  /// Color filter label
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get filterColor;

  /// Price filter label
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get filterPrice;

  /// Material filter label
  ///
  /// In fr, this message translates to:
  /// **'Matière'**
  String get filterMaterial;

  /// All/Everything filter option
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get filterAll;

  /// All categories option
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filterAllCategories;

  /// Custom price filter
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get filterCustomPrice;

  /// Clear filters button
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get filterClear;

  /// Show results button
  ///
  /// In fr, this message translates to:
  /// **'Afficher les résultats'**
  String get filterShowResults;

  /// Validate selection button
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get filterValidate;

  /// Number of results found
  ///
  /// In fr, this message translates to:
  /// **'{count} résultats'**
  String resultsCount(int count);

  /// Tab label for messages
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get messagesTab;

  /// Tab label for notifications
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTab;

  /// Empty messages state
  ///
  /// In fr, this message translates to:
  /// **'Aucun message'**
  String get noMessages;

  /// Empty state message for notifications
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de notifications'**
  String get noNotifications;

  /// Title of the make offer bottom sheet
  ///
  /// In fr, this message translates to:
  /// **'Faire une offre'**
  String get makeOfferTitle;

  /// Item price label in make offer sheet
  ///
  /// In fr, this message translates to:
  /// **'prix de l\'article : {price}'**
  String itemPrice(String price);

  /// Reduction percentage label
  ///
  /// In fr, this message translates to:
  /// **'{percent}% de réduction'**
  String reductionLabel(int percent);

  /// Other offer option
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get otherOffer;

  /// Hint for custom price offer
  ///
  /// In fr, this message translates to:
  /// **'Propose un prix'**
  String get otherOfferHint;

  /// Propose button text
  ///
  /// In fr, this message translates to:
  /// **'Proposer {amount}'**
  String proposeButton(String amount);

  /// Simple propose button text
  ///
  /// In fr, this message translates to:
  /// **'Proposer'**
  String get proposeButtonSimple;

  /// Error message when offer is too low
  ///
  /// In fr, this message translates to:
  /// **'Ton offre doit être de {minAmount} minimum (-{limit}%)'**
  String offerLimitError(String minAmount, int limit);

  /// Remaining offers for today
  ///
  /// In fr, this message translates to:
  /// **'{count} propositions restante(s) pour aujourd\'hui'**
  String suggestionsRemaining(int count);

  /// Why link in make offer sheet
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi ?'**
  String get whyLink;

  /// settingsTitle
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// profileInfo
  ///
  /// In fr, this message translates to:
  /// **'Informations du profil'**
  String get profileInfo;

  /// accountSettings
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du compte'**
  String get accountSettings;

  /// payments
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get payments;

  /// shipping
  ///
  /// In fr, this message translates to:
  /// **'Envoi'**
  String get shipping;

  /// security
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get security;

  /// notifications
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// mobile
  ///
  /// In fr, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// email
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// appLanguage
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'appli'**
  String get appLanguage;

  /// language
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// darkMode
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// privacySettings
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de confidentialité'**
  String get privacySettings;

  /// logout
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// appVersion
  ///
  /// In fr, this message translates to:
  /// **'Version de l\'application : {version}'**
  String appVersion(String version);

  /// chooseLanguage
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue'**
  String get chooseLanguage;

  /// cancel
  ///
  /// In fr, this message translates to:
  /// **'ANNULER'**
  String get cancel;

  /// logoutConfirm
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get logoutConfirm;

  /// profileTitle
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// favorites
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// inviteFriends
  ///
  /// In fr, this message translates to:
  /// **'Inviter des amis'**
  String get inviteFriends;

  /// myWallet
  ///
  /// In fr, this message translates to:
  /// **'Mon porte-monnaie'**
  String get myWallet;

  /// salesAndPurchases
  ///
  /// In fr, this message translates to:
  /// **'Mes ventes et achats'**
  String get salesAndPurchases;

  /// promotionTools
  ///
  /// In fr, this message translates to:
  /// **'Outils de promotion'**
  String get promotionTools;

  /// personalization
  ///
  /// In fr, this message translates to:
  /// **'Personnalisation'**
  String get personalization;

  /// bundleDiscount
  ///
  /// In fr, this message translates to:
  /// **'Réduction sur les lots'**
  String get bundleDiscount;

  /// vacationMode
  ///
  /// In fr, this message translates to:
  /// **'Mode vacances'**
  String get vacationMode;

  /// donations
  ///
  /// In fr, this message translates to:
  /// **'Dons'**
  String get donations;

  /// ablonyGuide
  ///
  /// In fr, this message translates to:
  /// **'Ton guide Ablony'**
  String get ablonyGuide;

  /// helpCenter
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get helpCenter;

  /// cookieSettings
  ///
  /// In fr, this message translates to:
  /// **'Paramètres des cookies'**
  String get cookieSettings;

  /// aboutUs
  ///
  /// In fr, this message translates to:
  /// **'À propos de nous'**
  String get aboutUs;

  /// legalInfo
  ///
  /// In fr, this message translates to:
  /// **'Informations légales'**
  String get legalInfo;

  /// viewMyListings
  ///
  /// In fr, this message translates to:
  /// **'Voir mes annonces'**
  String get viewMyListings;

  /// productNotFound
  ///
  /// In fr, this message translates to:
  /// **'Produit introuvable'**
  String get productNotFound;

  /// clickToTranslate
  ///
  /// In fr, this message translates to:
  /// **'Clique ici pour traduire'**
  String get clickToTranslate;

  /// activelyPublishes
  ///
  /// In fr, this message translates to:
  /// **'Publie activement'**
  String get activelyPublishes;

  /// sendsQuickly
  ///
  /// In fr, this message translates to:
  /// **'Envoie rapidement'**
  String get sendsQuickly;

  /// markAsSold
  ///
  /// In fr, this message translates to:
  /// **'Indiquer comme vendu'**
  String get markAsSold;

  /// markAsReserved
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme réservé'**
  String get markAsReserved;

  /// edit
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// hide
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get hide;

  /// productMarkedAsSold
  ///
  /// In fr, this message translates to:
  /// **'Produit marqué comme vendu'**
  String get productMarkedAsSold;

  /// deleteProductConfirm
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le produit ?'**
  String get deleteProductConfirm;

  /// deleteProductBtn
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get deleteProductBtn;

  /// productDeletedSuccess
  ///
  /// In fr, this message translates to:
  /// **'Produit supprimé avec succès'**
  String get productDeletedSuccess;

  /// errorGenericMsg
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String errorGenericMsg(String error);

  /// walletConfig
  ///
  /// In fr, this message translates to:
  /// **'Configuration du porte-monnaie'**
  String get walletConfig;

  /// enterFirstName
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre prénom'**
  String get enterFirstName;

  /// enterLastName
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre nom'**
  String get enterLastName;

  /// selectNationality
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une nationalité'**
  String get selectNationality;

  /// selectBirthDate
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner votre date de naissance'**
  String get selectBirthDate;

  /// walletActivatedSuccess
  ///
  /// In fr, this message translates to:
  /// **'Porte-monnaie activé avec succès !'**
  String get walletActivatedSuccess;

  /// helpPageComingSoon
  ///
  /// In fr, this message translates to:
  /// **'Page d\'aide à venir'**
  String get helpPageComingSoon;

  /// topUpComingSoon
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité de recharge à venir'**
  String get topUpComingSoon;

  /// withdrawalComingSoon
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité de retrait à venir'**
  String get withdrawalComingSoon;

  /// activatedStr
  ///
  /// In fr, this message translates to:
  /// **'Activé'**
  String get activatedStr;

  /// deactivatedStr
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get deactivatedStr;

  /// listings
  ///
  /// In fr, this message translates to:
  /// **'Annonces'**
  String get listings;

  /// reviews
  ///
  /// In fr, this message translates to:
  /// **'Évaluations'**
  String get reviews;

  /// aboutTab
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutTab;

  /// addItems
  ///
  /// In fr, this message translates to:
  /// **'Ajoute des articles...'**
  String get addItems;

  /// verifiedInfo
  ///
  /// In fr, this message translates to:
  /// **'Informations vérifiées :'**
  String get verifiedInfo;

  /// pendingAmount
  ///
  /// In fr, this message translates to:
  /// **'Montant en attente'**
  String get pendingAmount;

  /// pendingAmountInfo
  ///
  /// In fr, this message translates to:
  /// **'Lorsqu\'un acheteur valide un achat, le montant est mis en attente jusqu\'à la réception et la confirmation du produit.'**
  String get pendingAmountInfo;

  /// learnMore
  ///
  /// In fr, this message translates to:
  /// **'En savoir plus'**
  String get learnMore;

  /// availableAmount
  ///
  /// In fr, this message translates to:
  /// **'Montant disponible'**
  String get availableAmount;

  /// activateWallet
  ///
  /// In fr, this message translates to:
  /// **'Activer le porte-monnaie'**
  String get activateWallet;

  /// topUpWallet
  ///
  /// In fr, this message translates to:
  /// **'Recharger'**
  String get topUpWallet;

  /// withdrawWallet
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get withdrawWallet;

  /// accountHolderFirstName
  ///
  /// In fr, this message translates to:
  /// **'Prénom(s) du titulaire du compte'**
  String get accountHolderFirstName;

  /// accountHolderLastName
  ///
  /// In fr, this message translates to:
  /// **'Nom de famille du titulaire du compte'**
  String get accountHolderLastName;

  /// nationality
  ///
  /// In fr, this message translates to:
  /// **'Nationalité'**
  String get nationality;

  /// selectNationalityPlaceholder
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne une nationalité'**
  String get selectNationalityPlaceholder;

  /// birthDate
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get birthDate;

  /// productDescriptionTitle
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get productDescriptionTitle;

  /// readMore
  ///
  /// In fr, this message translates to:
  /// **'plus'**
  String get readMore;

  /// readLess
  ///
  /// In fr, this message translates to:
  /// **'moins'**
  String get readLess;

  /// productCategory
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get productCategory;

  /// productSize
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get productSize;

  /// productCondition
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get productCondition;

  /// productColor
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get productColor;

  /// productAddedDate
  ///
  /// In fr, this message translates to:
  /// **'Ajouté'**
  String get productAddedDate;

  /// notSpecified
  ///
  /// In fr, this message translates to:
  /// **'Non spécifiée'**
  String get notSpecified;

  /// membersWardrobe
  ///
  /// In fr, this message translates to:
  /// **'Dressing du membre'**
  String get membersWardrobe;

  /// similarItems
  ///
  /// In fr, this message translates to:
  /// **'Articles similaires'**
  String get similarItems;

  /// boostProduct
  ///
  /// In fr, this message translates to:
  /// **'Booster'**
  String get boostProduct;

  /// shareProduct
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareProduct;

  /// priceIncl
  ///
  /// In fr, this message translates to:
  /// **'incl.'**
  String get priceIncl;

  /// subtotalForBuyer
  ///
  /// In fr, this message translates to:
  /// **'(sous-total pour l\'acheteur)'**
  String get subtotalForBuyer;

  /// deleteProductConfirmationMessage
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ce produit ? Cette action est irréversible.'**
  String get deleteProductConfirmationMessage;

  /// noReviewsYet
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'évaluations'**
  String get noReviewsYet;

  /// priceFilterDevelopment
  ///
  /// In fr, this message translates to:
  /// **'Filtre de prix en cours de développement'**
  String get priceFilterDevelopment;

  /// Subtitle when there are no reviews
  ///
  /// In fr, this message translates to:
  /// **'Demande à la personne avec qui tu as effectué une transaction réussie de te laisser une évaluation.'**
  String get noReviewsSubtitle;

  /// Message button label
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get messageButton;

  /// Buyer protection fees section title
  ///
  /// In fr, this message translates to:
  /// **'Frais de Protection acheteurs'**
  String get buyerProtectionTitle;

  /// Buyer protection fees description
  ///
  /// In fr, this message translates to:
  /// **'Pour tout achat effectué par le biais du bouton Acheter, nous appliquons des frais couvrant notre Protection acheteurs.'**
  String get buyerProtectionDescription;

  /// Delete product menu item
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteProduct;

  /// Make an offer button
  ///
  /// In fr, this message translates to:
  /// **'Faire une offre'**
  String get makeOffer;

  /// Buy now button
  ///
  /// In fr, this message translates to:
  /// **'Acheter'**
  String get buyNow;

  /// Empty state for product grids
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit disponible'**
  String get noProductsAvailable;

  /// Time ago: 1 year
  ///
  /// In fr, this message translates to:
  /// **'Il y a 1 an'**
  String get timeAgoYear;

  /// Time ago: multiple years
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} ans'**
  String timeAgoYears(int count);

  /// Time ago: months
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} mois'**
  String timeAgoMonths(int count);

  /// Time ago: 1 day
  ///
  /// In fr, this message translates to:
  /// **'Il y a 1 jour'**
  String get timeAgoDay;

  /// Time ago: multiple days
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} jours'**
  String timeAgoDays(int count);

  /// Time ago: 1 hour
  ///
  /// In fr, this message translates to:
  /// **'Il y a 1 heure'**
  String get timeAgoHour;

  /// Time ago: multiple hours
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} heures'**
  String timeAgoHours(int count);

  /// Time ago: 1 minute
  ///
  /// In fr, this message translates to:
  /// **'Il y a 1 minute'**
  String get timeAgoMinute;

  /// Time ago: multiple minutes
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} minutes'**
  String timeAgoMinutes(int count);

  /// Time ago: just now
  ///
  /// In fr, this message translates to:
  /// **'À l\'instant'**
  String get timeAgoJustNow;

  /// Follow user button
  ///
  /// In fr, this message translates to:
  /// **'Suivre'**
  String get followButton;

  /// Snackbar message when follow is tapped
  ///
  /// In fr, this message translates to:
  /// **'Suivre {username} bientôt disponible !'**
  String followComingSoon(String username);

  /// Placeholder for chat input field
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un message'**
  String get sendMessagePlaceholder;

  /// Success message when offer is accepted
  ///
  /// In fr, this message translates to:
  /// **'Offre acceptée !'**
  String get offerAcceptedSuccess;

  /// Success message when offer is rejected
  ///
  /// In fr, this message translates to:
  /// **'Offre refusée'**
  String get offerRejectedSuccess;

  /// Title of the chat page
  ///
  /// In fr, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// Message shown when conversation is not found
  ///
  /// In fr, this message translates to:
  /// **'Conversation introuvable'**
  String get conversationNotFound;

  /// Welcome message showing user's name in chat
  ///
  /// In fr, this message translates to:
  /// **'Bonjour ! Moi c\'est {username}'**
  String chatWelcomeMessage(String username);

  /// Shows the year the user joined
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis {year}'**
  String memberSinceYear(int year);

  /// Fallback text for system messages
  ///
  /// In fr, this message translates to:
  /// **'Message système'**
  String get systemMessage;

  /// Notification that a user made an offer
  ///
  /// In fr, this message translates to:
  /// **'Hey, {name} t\'a fait une offre'**
  String heyUserMadeOffer(String name);

  /// Default name when user name is missing
  ///
  /// In fr, this message translates to:
  /// **'un utilisateur'**
  String get defaultUser;

  /// Offer status: accepted
  ///
  /// In fr, this message translates to:
  /// **'Acceptée'**
  String get offerStatusAccepted;

  /// Offer status: rejected
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get offerStatusRejected;

  /// Offer status: pending
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get offerStatusPending;

  /// Accept button label
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get acceptButton;

  /// Reject button label
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get rejectButton;

  /// Counter offer label
  ///
  /// In fr, this message translates to:
  /// **'Contre-offre'**
  String get counterOffer;

  /// Error loading state
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get errorLoading;

  /// Please login message
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous connecter'**
  String get pleaseLogin;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
