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

  /// forgotPasswordTitle
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordTitle;

  /// forgotPasswordDescription
  ///
  /// In fr, this message translates to:
  /// **'Indique ton email, on t\'envoie un lien pour réinitialiser ton mot de passe.'**
  String get forgotPasswordDescription;

  /// resetPasswordEmailPlaceholder
  ///
  /// In fr, this message translates to:
  /// **'Ton adresse email'**
  String get resetPasswordEmailPlaceholder;

  /// sendResetLink
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get sendResetLink;

  /// resetEmailSentMessage
  ///
  /// In fr, this message translates to:
  /// **'Si un compte existe avec cet email, un lien de réinitialisation vient d\'être envoyé.'**
  String get resetEmailSentMessage;

  /// resetPasswordPageTitle
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get resetPasswordPageTitle;

  /// resetPasswordPageDescription
  ///
  /// In fr, this message translates to:
  /// **'Choisis un nouveau mot de passe.'**
  String get resetPasswordPageDescription;

  /// resetPasswordNewPasswordPlaceholder
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get resetPasswordNewPasswordPlaceholder;

  /// resetPasswordConfirmPasswordPlaceholder
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get resetPasswordConfirmPasswordPlaceholder;

  /// resetPasswordMismatch
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get resetPasswordMismatch;

  /// resetPasswordSubmitButton
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetPasswordSubmitButton;

  /// resetPasswordSuccessMessage
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe réinitialisé avec succès. Tu peux maintenant te connecter.'**
  String get resetPasswordSuccessMessage;

  /// resetLinkInvalidMessage
  ///
  /// In fr, this message translates to:
  /// **'Ce lien de réinitialisation est invalide ou a expiré. Redemande un nouveau lien depuis la page de connexion.'**
  String get resetLinkInvalidMessage;

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

  /// clearDraft
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearDraft;

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
  /// **'Recherche'**
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

  /// openInBrowser
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans le navigateur'**
  String get openInBrowser;

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

  /// deleteAccount
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get deleteAccount;

  /// deleteAccountConfirmTitle
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte ?'**
  String get deleteAccountConfirmTitle;

  /// deleteAccountConfirmMessage
  ///
  /// In fr, this message translates to:
  /// **'Cette suppression sera définitive : toutes vos informations personnelles seront remplacées par des données génériques et vous ne pourrez plus vous reconnecter à ce compte. Vous pourrez créer un nouveau compte avec les mêmes identifiants si vous le souhaitez.'**
  String get deleteAccountConfirmMessage;

  /// deleteAccountConfirmAction
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get deleteAccountConfirmAction;

  /// deleteAccountDoneTitle
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get deleteAccountDoneTitle;

  /// deleteAccountDoneMessage
  ///
  /// In fr, this message translates to:
  /// **'Votre compte a bien été supprimé. Vous pouvez créer un nouveau compte avec les mêmes identifiants à tout moment.'**
  String get deleteAccountDoneMessage;

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

  /// cancelReservation
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réservation'**
  String get cancelReservation;

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

  /// unhide
  ///
  /// In fr, this message translates to:
  /// **'Republier'**
  String get unhide;

  /// productHidden
  ///
  /// In fr, this message translates to:
  /// **'Annonce masquée'**
  String get productHidden;

  /// productUnhidden
  ///
  /// In fr, this message translates to:
  /// **'Annonce republiée'**
  String get productUnhidden;

  /// productUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Produit indisponible'**
  String get productUnavailable;

  /// soldBadge
  ///
  /// In fr, this message translates to:
  /// **'Vendu'**
  String get soldBadge;

  /// reservedBadge
  ///
  /// In fr, this message translates to:
  /// **'Réservé'**
  String get reservedBadge;

  /// hiddenBadge
  ///
  /// In fr, this message translates to:
  /// **'Masqué'**
  String get hiddenBadge;

  /// productMarkedAsSold
  ///
  /// In fr, this message translates to:
  /// **'Produit marqué comme vendu'**
  String get productMarkedAsSold;

  /// productMarkedAsReserved
  ///
  /// In fr, this message translates to:
  /// **'Produit marqué comme réservé'**
  String get productMarkedAsReserved;

  /// reservationCancelled
  ///
  /// In fr, this message translates to:
  /// **'Réservation annulée'**
  String get reservationCancelled;

  /// productReserved
  ///
  /// In fr, this message translates to:
  /// **'Produit réservé'**
  String get productReserved;

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

  /// boostedBadge
  ///
  /// In fr, this message translates to:
  /// **'Boosté'**
  String get boostedBadge;

  /// boostSheetTitle
  ///
  /// In fr, this message translates to:
  /// **'Booster ce produit'**
  String get boostSheetTitle;

  /// boostSheetDescription
  ///
  /// In fr, this message translates to:
  /// **'Ton produit apparaîtra dans les emplacements mis en avant pendant {hours}h.'**
  String boostSheetDescription(int hours);

  /// boostAlreadyActive
  ///
  /// In fr, this message translates to:
  /// **'Ce produit est déjà boosté jusqu\'au {date}.'**
  String boostAlreadyActive(String date);

  /// boostPay
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get boostPay;

  /// boostSuccess
  ///
  /// In fr, this message translates to:
  /// **'Produit boosté avec succès !'**
  String get boostSuccess;

  /// boostInsufficientBalance
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant. Choisis un autre moyen de paiement.'**
  String get boostInsufficientBalance;

  /// Solde de boosts accumulés
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun boost en réserve} =1{1 boost en réserve} other{{count} boosts en réserve}}'**
  String boostCreditsBalance(int count);

  /// Bouton pour dépenser un crédit de boost
  ///
  /// In fr, this message translates to:
  /// **'Utiliser un boost'**
  String get boostUseCredit;

  /// Sous-titre du bouton utiliser un boost
  ///
  /// In fr, this message translates to:
  /// **'Puisé dans votre réserve, sans payer'**
  String get boostUseCreditSubtitle;

  /// Bouton boost occasionnel payant
  ///
  /// In fr, this message translates to:
  /// **'Booster maintenant · {price} FCFA'**
  String boostPayOccasional(int price);

  /// Ouvre l'achat de boosts en réserve
  ///
  /// In fr, this message translates to:
  /// **'Acheter des boosts'**
  String get boostBuyPacks;

  /// Confirmation après usage d'un crédit
  ///
  /// In fr, this message translates to:
  /// **'Boost appliqué ! Il vous reste {count, plural, =0{aucun boost} =1{1 boost} other{{count} boosts}}.'**
  String boostCreditApplied(int count);

  /// Titre de la feuille d'achat de boosts
  ///
  /// In fr, this message translates to:
  /// **'Acheter des boosts'**
  String get boostPackTitle;

  /// Explication de l'achat de boosts
  ///
  /// In fr, this message translates to:
  /// **'Achetez des boosts d\'avance et utilisez-les quand vous voulez, sur l\'annonce de votre choix. Chaque boost met un article en avant pendant {hours}h.'**
  String boostPackDescription(int hours);

  /// Libellé du sélecteur de quantité
  ///
  /// In fr, this message translates to:
  /// **'Nombre de boosts'**
  String get boostPackQuantity;

  /// Total à payer pour le lot
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get boostPackTotal;

  /// Bouton d'achat du lot
  ///
  /// In fr, this message translates to:
  /// **'Acheter {count, plural, =1{1 boost} other{{count} boosts}} · {price} FCFA'**
  String boostPackBuy(int count, int price);

  /// Confirmation d'achat de lot
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 boost ajouté} other{{count} boosts ajoutés}} à votre réserve !'**
  String boostPackSuccess(int count);

  /// Titre de la carte réserve de boosts
  ///
  /// In fr, this message translates to:
  /// **'Vos boosts en réserve'**
  String get promotionCreditsTitle;

  /// Mise en avant indisponible sur cette plateforme
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get promotionUnavailable;

  /// Explication de l'indisponibilité
  ///
  /// In fr, this message translates to:
  /// **'La mise en avant arrive prochainement sur mobile. Elle est déjà disponible depuis le site Ablony.'**
  String get promotionUnavailableHint;

  /// Sous-titre de la carte réserve
  ///
  /// In fr, this message translates to:
  /// **'Utilisez-les sur n\'importe quelle annonce, quand vous voulez.'**
  String get promotionCreditsHint;

  /// Placeholder de la barre de recherche de lieu
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un lieu, un quartier…'**
  String get locationSearchHint;

  /// Recherche de lieu sans résultat
  ///
  /// In fr, this message translates to:
  /// **'Aucun lieu trouvé pour « {query} »'**
  String locationSearchNoResult(String query);

  /// Erreur de recherche de lieu
  ///
  /// In fr, this message translates to:
  /// **'La recherche a échoué. Vérifiez votre connexion.'**
  String get locationSearchFailed;

  /// shareProduct
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareProduct;

  /// Subtitle line included when sharing a product listing
  ///
  /// In fr, this message translates to:
  /// **'{price} FCFA ({condition})'**
  String shareProductSubtitle(String price, String condition);

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

  /// minPrice
  ///
  /// In fr, this message translates to:
  /// **'Prix minimum'**
  String get minPrice;

  /// maxPrice
  ///
  /// In fr, this message translates to:
  /// **'Prix maximum'**
  String get maxPrice;

  /// apply
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// resetFilter
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetFilter;

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

  /// Button label when already following this user (tap to unfollow)
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get unfollowButton;

  /// Followers count label
  ///
  /// In fr, this message translates to:
  /// **'{count} abonnés'**
  String followersCountLabel(int count);

  /// Following count label
  ///
  /// In fr, this message translates to:
  /// **'{count} abonnements'**
  String followingCountLabel(int count);

  /// Followers list page title
  ///
  /// In fr, this message translates to:
  /// **'Abonnés'**
  String get followersPageTitle;

  /// Following list page title
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get followingPageTitle;

  /// Empty followers list state
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonné pour le moment'**
  String get noFollowersYet;

  /// Empty following list state
  ///
  /// In fr, this message translates to:
  /// **'Ne suit personne pour le moment'**
  String get noFollowingYet;

  /// Receipt page title
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get receiptPageTitle;

  /// Receipt: transaction reference label
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get receiptReference;

  /// Receipt: date label
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get receiptDate;

  /// Receipt: seller label
  ///
  /// In fr, this message translates to:
  /// **'Vendeur'**
  String get receiptSeller;

  /// Receipt: buyer label
  ///
  /// In fr, this message translates to:
  /// **'Acheteur'**
  String get receiptBuyer;

  /// Receipt: payment method label
  ///
  /// In fr, this message translates to:
  /// **'Moyen de paiement'**
  String get receiptPaymentMethod;

  /// Receipt: product price label
  ///
  /// In fr, this message translates to:
  /// **'Prix de l\'article'**
  String get receiptProductPrice;

  /// Receipt: total paid label
  ///
  /// In fr, this message translates to:
  /// **'Total payé'**
  String get receiptTotalPaid;

  /// Receipt: download button
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le reçu'**
  String get receiptDownloadButton;

  /// Rate seller page title
  ///
  /// In fr, this message translates to:
  /// **'Notez votre vendeur'**
  String get rateSellerPageTitle;

  /// Rate seller page headline
  ///
  /// In fr, this message translates to:
  /// **'Comment s\'est passé votre achat de \"{productTitle}\" ?'**
  String rateSellerHeadline(String productTitle);

  /// Rate seller: comment field hint
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un commentaire (facultatif)'**
  String get rateSellerCommentHint;

  /// Rate seller: submit button
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon avis'**
  String get rateSellerSubmitButton;

  /// Buyer button: confirm the parcel was received
  ///
  /// In fr, this message translates to:
  /// **'J\'ai reçu mon colis'**
  String get confirmDeliveryButton;

  /// Disabled button label when the product is sold to someone else
  ///
  /// In fr, this message translates to:
  /// **'Article déjà vendu'**
  String get productAlreadySold;

  /// Shown when delivery has already been confirmed
  ///
  /// In fr, this message translates to:
  /// **'Réception confirmée'**
  String get deliveryAlreadyConfirmed;

  /// Scan delivery QR page title
  ///
  /// In fr, this message translates to:
  /// **'Scanner le code'**
  String get scanQrPageTitle;

  /// Scan delivery QR page instructions
  ///
  /// In fr, this message translates to:
  /// **'Scannez le code QR affiché par le vendeur pour confirmer la réception'**
  String get scanQrInstructions;

  /// Delivery confirmed dialog title
  ///
  /// In fr, this message translates to:
  /// **'Réception confirmée !'**
  String get deliveryConfirmedTitle;

  /// Delivery confirmed dialog message
  ///
  /// In fr, this message translates to:
  /// **'Merci ! Le paiement a été débloqué pour le vendeur.'**
  String get deliveryConfirmedMessage;

  /// Button to switch to manual receipt reference entry instead of scanning
  ///
  /// In fr, this message translates to:
  /// **'Saisir la référence du reçu'**
  String get scanQrManualEntryButton;

  /// Manual receipt reference entry dialog title
  ///
  /// In fr, this message translates to:
  /// **'Confirmer avec la référence'**
  String get scanQrManualEntryDialogTitle;

  /// Manual receipt reference text field hint
  ///
  /// In fr, this message translates to:
  /// **'Référence du reçu'**
  String get scanQrManualEntryHint;

  /// Validation error when the manual reference field is empty
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir une référence'**
  String get scanQrManualEntryError;

  /// Buyer menu item to report a product
  ///
  /// In fr, this message translates to:
  /// **'Signaler cet article'**
  String get reportProduct;

  /// Report product dialog title
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi signalez-vous cet article ?'**
  String get reportDialogTitle;

  /// Report reason: counterfeit item
  ///
  /// In fr, this message translates to:
  /// **'Contrefaçon'**
  String get reportReasonCounterfeit;

  /// Report reason: inappropriate content
  ///
  /// In fr, this message translates to:
  /// **'Contenu inapproprié'**
  String get reportReasonInappropriate;

  /// Report reason: potential scam
  ///
  /// In fr, this message translates to:
  /// **'Arnaque potentielle'**
  String get reportReasonScam;

  /// Report reason: other
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get reportReasonOther;

  /// Report product optional comment field hint
  ///
  /// In fr, this message translates to:
  /// **'Précisions (facultatif)'**
  String get reportCommentHint;

  /// Report product dialog submit button
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get reportSubmitButton;

  /// Confirmation shown after a report is submitted
  ///
  /// In fr, this message translates to:
  /// **'Signalement envoyé, merci pour votre vigilance.'**
  String get reportSuccessMessage;

  /// Image source sheet: camera option
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get imageSourceCameraOption;

  /// Image source sheet: gallery option
  ///
  /// In fr, this message translates to:
  /// **'Choisir depuis la galerie'**
  String get imageSourceGalleryOption;

  /// Last message preview for an image message
  ///
  /// In fr, this message translates to:
  /// **'📷 Photo'**
  String get photoMessage;

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

  /// Seller button: open the printable parcel label
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'étiquette du colis'**
  String get parcelLabelButton;

  /// Receipt row: the parcel code to track the delivery
  ///
  /// In fr, this message translates to:
  /// **'Code du colis'**
  String get receiptParcelCode;

  /// Buyer confirmation dialog title
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la réception'**
  String get confirmDeliveryTitle;

  /// Buyer confirmation dialog question
  ///
  /// In fr, this message translates to:
  /// **'Avez-vous bien reçu votre colis ? Le paiement sera immédiatement versé au vendeur, et ce geste est définitif.'**
  String get confirmDeliveryQuestion;

  /// Buyer confirmation dialog confirm action
  ///
  /// In fr, this message translates to:
  /// **'Oui, je l\'ai reçu'**
  String get confirmDeliveryConfirm;

  /// Snackbar after a successful delivery confirmation
  ///
  /// In fr, this message translates to:
  /// **'Réception confirmée. Le vendeur a été payé.'**
  String get deliveryConfirmedSuccess;

  /// No description provided for @walletStatement.
  ///
  /// In fr, this message translates to:
  /// **'Relevé'**
  String get walletStatement;

  /// No description provided for @walletStatementEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun mouvement pour l\'instant'**
  String get walletStatementEmpty;

  /// No description provided for @walletStatementEmptyDetail.
  ///
  /// In fr, this message translates to:
  /// **'Vos achats, vos ventes et vos rechargements apparaîtront ici.'**
  String get walletStatementEmptyDetail;

  /// No description provided for @walletStatementError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre relevé.'**
  String get walletStatementError;

  /// No description provided for @walletEntryTopUp.
  ///
  /// In fr, this message translates to:
  /// **'Rechargement'**
  String get walletEntryTopUp;

  /// No description provided for @walletEntryPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat'**
  String get walletEntryPurchase;

  /// No description provided for @walletEntryBoost.
  ///
  /// In fr, this message translates to:
  /// **'Mise en avant'**
  String get walletEntryBoost;

  /// No description provided for @walletEntrySale.
  ///
  /// In fr, this message translates to:
  /// **'Vente'**
  String get walletEntrySale;

  /// No description provided for @walletEntryOnHold.
  ///
  /// In fr, this message translates to:
  /// **'en attente'**
  String get walletEntryOnHold;

  /// No description provided for @scanParcelStaff.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un colis'**
  String get scanParcelStaff;

  /// No description provided for @scanParcelBuyer.
  ///
  /// In fr, this message translates to:
  /// **'Scanner mon colis'**
  String get scanParcelBuyer;

  /// No description provided for @scanHintStaff.
  ///
  /// In fr, this message translates to:
  /// **'Visez l\'étiquette collée sur le colis.'**
  String get scanHintStaff;

  /// No description provided for @scanHintBuyer.
  ///
  /// In fr, this message translates to:
  /// **'Visez l\'étiquette de votre colis pour confirmer que vous l\'avez bien reçu.'**
  String get scanHintBuyer;

  /// No description provided for @scanTorch.
  ///
  /// In fr, this message translates to:
  /// **'Lampe'**
  String get scanTorch;

  /// No description provided for @scanFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le scan a échoué. Réessayez.'**
  String get scanFailed;

  /// No description provided for @checkpointRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Étape enregistrée.'**
  String get checkpointRecorded;

  /// No description provided for @parcelStatusLabel.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get parcelStatusLabel;

  /// No description provided for @parcelDestinationRelay.
  ///
  /// In fr, this message translates to:
  /// **'Point relais'**
  String get parcelDestinationRelay;

  /// No description provided for @parcelDestinationHome.
  ///
  /// In fr, this message translates to:
  /// **'Livraison à domicile'**
  String get parcelDestinationHome;

  /// No description provided for @parcelRecordStep.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une étape'**
  String get parcelRecordStep;

  /// No description provided for @parcelNoStepLeft.
  ///
  /// In fr, this message translates to:
  /// **'Ce colis a terminé son parcours.'**
  String get parcelNoStepLeft;

  /// No description provided for @parcelAwaitingDropoff.
  ///
  /// In fr, this message translates to:
  /// **'En attente de dépôt'**
  String get parcelAwaitingDropoff;

  /// No description provided for @parcelDroppedOff.
  ///
  /// In fr, this message translates to:
  /// **'Déposé'**
  String get parcelDroppedOff;

  /// No description provided for @parcelInTransit.
  ///
  /// In fr, this message translates to:
  /// **'En transit'**
  String get parcelInTransit;

  /// No description provided for @parcelReadyForPickup.
  ///
  /// In fr, this message translates to:
  /// **'À retirer en point relais'**
  String get parcelReadyForPickup;

  /// No description provided for @parcelOutForDelivery.
  ///
  /// In fr, this message translates to:
  /// **'En cours de livraison'**
  String get parcelOutForDelivery;

  /// No description provided for @parcelDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Remis'**
  String get parcelDelivered;

  /// No description provided for @parcelReturned.
  ///
  /// In fr, this message translates to:
  /// **'Retourné'**
  String get parcelReturned;

  /// No description provided for @parcelLost.
  ///
  /// In fr, this message translates to:
  /// **'Égaré'**
  String get parcelLost;

  /// No description provided for @stepDroppedOff.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt'**
  String get stepDroppedOff;

  /// No description provided for @stepInTransit.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get stepInTransit;

  /// No description provided for @stepArrived.
  ///
  /// In fr, this message translates to:
  /// **'Arrivé au relais'**
  String get stepArrived;

  /// No description provided for @stepOutForDelivery.
  ///
  /// In fr, this message translates to:
  /// **'En tournée'**
  String get stepOutForDelivery;

  /// No description provided for @stepDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Remis'**
  String get stepDelivered;

  /// No description provided for @stepReturned.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get stepReturned;

  /// No description provided for @stepLost.
  ///
  /// In fr, this message translates to:
  /// **'Égaré'**
  String get stepLost;

  /// No description provided for @stuckParcelsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Colis bloqués'**
  String get stuckParcelsTitle;

  /// No description provided for @stuckParcelsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Rien ne traîne. Tout avance.'**
  String get stuckParcelsEmpty;

  /// No description provided for @stuckNeverDroppedOff.
  ///
  /// In fr, this message translates to:
  /// **'Jamais déposé — délai dépassé'**
  String get stuckNeverDroppedOff;

  /// No description provided for @stuckInTransitTooLong.
  ///
  /// In fr, this message translates to:
  /// **'En transit depuis trop longtemps'**
  String get stuckInTransitTooLong;

  /// No description provided for @stuckWaitingAtRelay.
  ///
  /// In fr, this message translates to:
  /// **'Attend en point relais'**
  String get stuckWaitingAtRelay;

  /// No description provided for @stuckBuyerScanned.
  ///
  /// In fr, this message translates to:
  /// **'scanné par l\'acheteur'**
  String get stuckBuyerScanned;

  /// No description provided for @staffTools.
  ///
  /// In fr, this message translates to:
  /// **'Espace personnel Ablony'**
  String get staffTools;

  /// No description provided for @walletEntryRefund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get walletEntryRefund;

  /// No description provided for @refundBuyer.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser l\'acheteur'**
  String get refundBuyer;

  /// No description provided for @refundReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce motif est envoyé à l\'acheteur et au vendeur. Expliquez, ne résumez pas.'**
  String get refundReasonHint;

  /// No description provided for @refundReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get refundReasonLabel;

  /// No description provided for @refundConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser'**
  String get refundConfirm;

  /// No description provided for @refundDone.
  ///
  /// In fr, this message translates to:
  /// **'L\'acheteur a été remboursé.'**
  String get refundDone;

  /// No description provided for @parcelNoTrackingYet.
  ///
  /// In fr, this message translates to:
  /// **'Préparation en cours — le suivi détaillé s\'affichera dès le premier scan'**
  String get parcelNoTrackingYet;

  /// No description provided for @releaseSeller.
  ///
  /// In fr, this message translates to:
  /// **'Verser au vendeur'**
  String get releaseSeller;

  /// No description provided for @releaseDone.
  ///
  /// In fr, this message translates to:
  /// **'Le vendeur a été payé.'**
  String get releaseDone;

  /// No description provided for @withdrawTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l\'argent'**
  String get withdrawTitle;

  /// No description provided for @withdrawAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant à retirer'**
  String get withdrawAmount;

  /// No description provided for @withdrawAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout retirer'**
  String get withdrawAll;

  /// No description provided for @withdrawMethod.
  ///
  /// In fr, this message translates to:
  /// **'Moyen de réception'**
  String get withdrawMethod;

  /// No description provided for @withdrawDestination.
  ///
  /// In fr, this message translates to:
  /// **'Où envoyer l\'argent'**
  String get withdrawDestination;

  /// No description provided for @withdrawDestinationPhoneHint.
  ///
  /// In fr, this message translates to:
  /// **'+228 90 00 00 00'**
  String get withdrawDestinationPhoneHint;

  /// No description provided for @withdrawDestinationBankHint.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de compte ou IBAN'**
  String get withdrawDestinationBankHint;

  /// No description provided for @withdrawAmountRequested.
  ///
  /// In fr, this message translates to:
  /// **'Montant demandé'**
  String get withdrawAmountRequested;

  /// No description provided for @withdrawFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de transfert'**
  String get withdrawFee;

  /// No description provided for @withdrawYouReceive.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevez'**
  String get withdrawYouReceive;

  /// No description provided for @withdrawFeeExplained.
  ///
  /// In fr, this message translates to:
  /// **'Ces frais couvrent le transfert vers votre compte mobile money. Retirer une grosse somme d\'un coup coûte proportionnellement moins cher.'**
  String get withdrawFeeExplained;

  /// No description provided for @withdrawInsufficient.
  ///
  /// In fr, this message translates to:
  /// **'Votre solde disponible ne couvre pas ce montant.'**
  String get withdrawInsufficient;

  /// No description provided for @withdrawAlreadyPending.
  ///
  /// In fr, this message translates to:
  /// **'Une demande est déjà en cours de traitement. Vous pouvez en faire une autre, mais elles seront versées séparément.'**
  String get withdrawAlreadyPending;

  /// No description provided for @withdrawConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Demander le retrait'**
  String get withdrawConfirm;

  /// No description provided for @withdrawManualNotice.
  ///
  /// In fr, this message translates to:
  /// **'Les versements sont effectués manuellement, sous 24 à 48 heures ouvrées.'**
  String get withdrawManualNotice;

  /// No description provided for @withdrawActivateFirst.
  ///
  /// In fr, this message translates to:
  /// **'Activez votre porte-monnaie pour pouvoir retirer'**
  String get withdrawActivateFirst;

  /// No description provided for @withdrawPending.
  ///
  /// In fr, this message translates to:
  /// **'En cours de versement'**
  String get withdrawPending;

  /// No description provided for @withdrawPaid.
  ///
  /// In fr, this message translates to:
  /// **'Versé'**
  String get withdrawPaid;

  /// No description provided for @withdrawRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusé'**
  String get withdrawRejected;

  /// No description provided for @withdrawMinimum.
  ///
  /// In fr, this message translates to:
  /// **'Minimum : {amount} FCFA'**
  String withdrawMinimum(String amount);

  /// No description provided for @withdrawRequested.
  ///
  /// In fr, this message translates to:
  /// **'Demande enregistrée. Vous recevrez {amount} FCFA.'**
  String withdrawRequested(String amount);

  /// No description provided for @walletEntryWithdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Retrait'**
  String get walletEntryWithdrawal;

  /// No description provided for @walletEntryWithdrawalRefund.
  ///
  /// In fr, this message translates to:
  /// **'Retrait refusé'**
  String get walletEntryWithdrawalRefund;

  /// No description provided for @moderationCorrectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annonce à corriger'**
  String get moderationCorrectionTitle;

  /// No description provided for @moderationRemovedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annonce retirée'**
  String get moderationRemovedTitle;

  /// No description provided for @moderationCorrectionHint.
  ///
  /// In fr, this message translates to:
  /// **'Corrigez-la et elle repart en ligne automatiquement.'**
  String get moderationCorrectionHint;

  /// No description provided for @moderationRemovedHint.
  ///
  /// In fr, this message translates to:
  /// **'Cette annonce ne peut pas être remise en ligne.'**
  String get moderationRemovedHint;

  /// No description provided for @moderationCorrectionAction.
  ///
  /// In fr, this message translates to:
  /// **'Corriger l\'annonce'**
  String get moderationCorrectionAction;

  /// No description provided for @moderationReasonBlurryPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos floues ou inexploitables'**
  String get moderationReasonBlurryPhotos;

  /// No description provided for @moderationReasonWrongCategory.
  ///
  /// In fr, this message translates to:
  /// **'Mauvaise catégorie'**
  String get moderationReasonWrongCategory;

  /// No description provided for @moderationReasonMissingDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description insuffisante'**
  String get moderationReasonMissingDescription;

  /// No description provided for @moderationReasonWrongPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix incohérent'**
  String get moderationReasonWrongPrice;

  /// No description provided for @moderationReasonCounterfeit.
  ///
  /// In fr, this message translates to:
  /// **'Contrefaçon'**
  String get moderationReasonCounterfeit;

  /// No description provided for @moderationReasonProhibitedItem.
  ///
  /// In fr, this message translates to:
  /// **'Article interdit à la vente'**
  String get moderationReasonProhibitedItem;

  /// No description provided for @moderationReasonInappropriate.
  ///
  /// In fr, this message translates to:
  /// **'Contenu inapproprié'**
  String get moderationReasonInappropriate;

  /// No description provided for @moderationReasonFraud.
  ///
  /// In fr, this message translates to:
  /// **'Tentative de fraude'**
  String get moderationReasonFraud;

  /// No description provided for @moderationReasonOffPlatformSale.
  ///
  /// In fr, this message translates to:
  /// **'Vente hors de la plateforme'**
  String get moderationReasonOffPlatformSale;

  /// No description provided for @moderationReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Motif non précisé'**
  String get moderationReasonOther;

  /// No description provided for @disputeOpen.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai un problème avec cette commande'**
  String get disputeOpen;

  /// No description provided for @disputeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get disputeTitle;

  /// No description provided for @disputeReason.
  ///
  /// In fr, this message translates to:
  /// **'Que s\'est-il passé ?'**
  String get disputeReason;

  /// No description provided for @disputeNotReceived.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai jamais reçu le colis'**
  String get disputeNotReceived;

  /// No description provided for @disputeNotAsDescribed.
  ///
  /// In fr, this message translates to:
  /// **'L\'article ne correspond pas à l\'annonce'**
  String get disputeNotAsDescribed;

  /// No description provided for @disputeDamaged.
  ///
  /// In fr, this message translates to:
  /// **'L\'article est arrivé abîmé'**
  String get disputeDamaged;

  /// Motif de litige côté vendeur
  ///
  /// In fr, this message translates to:
  /// **'L\'acheteur ne confirme pas la réception'**
  String get disputeBuyerNotConfirming;

  /// Motif de litige côté vendeur
  ///
  /// In fr, this message translates to:
  /// **'L\'acheteur réclame sans motif valable'**
  String get disputeBuyerNoValidReason;

  /// No description provided for @disputeOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get disputeOther;

  /// No description provided for @disputeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le problème'**
  String get disputeDescription;

  /// No description provided for @disputeDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Soyez précis : c\'est ce qui permettra de trancher.'**
  String get disputeDescriptionHint;

  /// No description provided for @disputeDescriptionTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Encore {count} caractères'**
  String disputeDescriptionTooShort(int count);

  /// No description provided for @disputePhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des photos (jusqu\'à 4)'**
  String get disputePhotos;

  /// No description provided for @disputePhotosHint.
  ///
  /// In fr, this message translates to:
  /// **'Une photo vaut mieux qu\'une description.'**
  String get disputePhotosHint;

  /// No description provided for @disputeSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get disputeSubmit;

  /// No description provided for @disputeSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Votre signalement est enregistré. Réponse sous 48 heures.'**
  String get disputeSubmitted;

  /// No description provided for @disputeUnderReview.
  ///
  /// In fr, this message translates to:
  /// **'Litige en cours d\'examen'**
  String get disputeUnderReview;

  /// No description provided for @disputeUnderReviewHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'administration examine votre dossier. Réponse sous 48 heures.'**
  String get disputeUnderReviewHint;

  /// No description provided for @disputeResolvedRefunded.
  ///
  /// In fr, this message translates to:
  /// **'Litige tranché : vous avez été remboursé'**
  String get disputeResolvedRefunded;

  /// No description provided for @disputeResolvedReleased.
  ///
  /// In fr, this message translates to:
  /// **'Litige tranché en faveur du vendeur'**
  String get disputeResolvedReleased;

  /// No description provided for @disputeOpenedByOther.
  ///
  /// In fr, this message translates to:
  /// **'L\'autre partie a ouvert un litige sur cette commande.'**
  String get disputeOpenedByOther;

  /// No description provided for @disputeSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours…'**
  String get disputeSending;

  /// No description provided for @blockUser.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer'**
  String get unblockUser;

  /// No description provided for @blockConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer {username} ?'**
  String blockConfirmTitle(String username);

  /// No description provided for @blockConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pourrez plus vous écrire. Cette personne ne sera pas prévenue. Une vente en cours suit son cours normalement.'**
  String get blockConfirmBody;

  /// No description provided for @blockDone.
  ///
  /// In fr, this message translates to:
  /// **'{username} a été bloqué.'**
  String blockDone(String username);

  /// No description provided for @blockAlsoReport.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous aussi le signaler à Ablony ?'**
  String get blockAlsoReport;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnes bloquées'**
  String get blockedUsersTitle;

  /// No description provided for @blockedUsersEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez bloqué personne.'**
  String get blockedUsersEmpty;

  /// No description provided for @blockedUsersHint.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer quelqu\'un ferme la messagerie entre vous, dans les deux sens. Personne n\'en est prévenu.'**
  String get blockedUsersHint;

  /// No description provided for @blockedConversation.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez bloqué cette personne.'**
  String get blockedConversation;

  /// No description provided for @blockedByOther.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez plus écrire dans cette conversation.'**
  String get blockedByOther;

  /// No description provided for @unblockDone.
  ///
  /// In fr, this message translates to:
  /// **'Déblocage effectué.'**
  String get unblockDone;

  /// No description provided for @reportUser.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get reportUser;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @ordersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ventes et achats'**
  String get ordersTitle;

  /// No description provided for @ordersPurchases.
  ///
  /// In fr, this message translates to:
  /// **'Achats'**
  String get ordersPurchases;

  /// No description provided for @ordersSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get ordersSales;

  /// No description provided for @ordersNoPurchases.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez encore rien acheté'**
  String get ordersNoPurchases;

  /// No description provided for @ordersNoPurchasesHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous achetez apparaît ici, avec l\'avancement de la livraison.'**
  String get ordersNoPurchasesHint;

  /// No description provided for @ordersNoSales.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez encore rien vendu'**
  String get ordersNoSales;

  /// No description provided for @ordersNoSalesHint.
  ///
  /// In fr, this message translates to:
  /// **'Mettez un article en vente : dès qu\'il trouve preneur, vous le suivez d\'ici.'**
  String get ordersNoSalesHint;

  /// No description provided for @orderDropOffBy.
  ///
  /// In fr, this message translates to:
  /// **'À déposer avant le {date}'**
  String orderDropOffBy(String date);

  /// No description provided for @orderDropOffLate.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé — remboursement en cours'**
  String get orderDropOffLate;

  /// No description provided for @orderPrintLabel.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer l\'étiquette'**
  String get orderPrintLabel;

  /// No description provided for @orderInTransit.
  ///
  /// In fr, this message translates to:
  /// **'En cours d\'acheminement'**
  String get orderInTransit;

  /// No description provided for @orderAwaitingPickup.
  ///
  /// In fr, this message translates to:
  /// **'À retirer au point relais'**
  String get orderAwaitingPickup;

  /// No description provided for @orderSellerPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Le vendeur prépare votre colis'**
  String get orderSellerPreparing;

  /// No description provided for @orderDeliveredWaiting.
  ///
  /// In fr, this message translates to:
  /// **'Remis — paiement à venir'**
  String get orderDeliveredWaiting;

  /// No description provided for @orderConfirmReception.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez la réception'**
  String get orderConfirmReception;

  /// No description provided for @orderPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé : {amount} FCFA'**
  String orderPaid(String amount);

  /// No description provided for @orderReceived.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get orderReceived;

  /// No description provided for @orderRefunded.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé : {amount} FCFA'**
  String orderRefunded(String amount);

  /// No description provided for @orderCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Vente annulée'**
  String get orderCancelled;

  /// No description provided for @orderTrack.
  ///
  /// In fr, this message translates to:
  /// **'Suivre'**
  String get orderTrack;

  /// No description provided for @orderSee.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get orderSee;

  /// No description provided for @ordersLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get ordersLoadMore;

  /// No description provided for @promotionEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce à mettre en avant'**
  String get promotionEmpty;

  /// No description provided for @promotionEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Mettez un article en vente : vous pourrez ensuite le faire remonter dans les listes.'**
  String get promotionEmptyHint;

  /// No description provided for @promotionBoost.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en avant'**
  String get promotionBoost;

  /// No description provided for @promotionActiveUntil.
  ///
  /// In fr, this message translates to:
  /// **'En avant jusqu\'au {date}'**
  String promotionActiveUntil(String date);

  /// No description provided for @termsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions générales d\'utilisation'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @legalNotice.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales'**
  String get legalNotice;

  /// No description provided for @editProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations du profil'**
  String get editProfileTitle;

  /// No description provided for @editProfilePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get editProfilePhoto;

  /// No description provided for @editProfileDisplayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom affiché'**
  String get editProfileDisplayName;

  /// No description provided for @editProfileCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get editProfileCity;

  /// No description provided for @editProfileSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get editProfileSave;

  /// No description provided for @editProfileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour.'**
  String get editProfileSaved;

  /// No description provided for @securityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get securityTitle;

  /// No description provided for @securityCurrentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get securityCurrentPassword;

  /// No description provided for @securityNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get securityNewPassword;

  /// No description provided for @securityConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get securityConfirmPassword;

  /// No description provided for @securityChangePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get securityChangePassword;

  /// No description provided for @securityPasswordChanged.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe changé.'**
  String get securityPasswordChanged;

  /// No description provided for @securityMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux saisies ne correspondent pas.'**
  String get securityMismatch;

  /// No description provided for @securityTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères.'**
  String get securityTooShort;

  /// No description provided for @securityWrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel incorrect.'**
  String get securityWrongPassword;

  /// No description provided for @securitySocialAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vous vous connectez avec {provider}'**
  String securitySocialAccount(String provider);

  /// No description provided for @securitySocialHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe est géré par ce service. Il n\'y a rien à changer ici.'**
  String get securitySocialHint;

  /// No description provided for @emailSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailSettingsTitle;

  /// No description provided for @emailVerified.
  ///
  /// In fr, this message translates to:
  /// **'Adresse vérifiée'**
  String get emailVerified;

  /// No description provided for @emailNotVerified.
  ///
  /// In fr, this message translates to:
  /// **'Adresse non vérifiée'**
  String get emailNotVerified;

  /// No description provided for @emailNotVerifiedHint.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre adresse : c\'est par elle que passent les alertes de vente et de retrait.'**
  String get emailNotVerifiedHint;

  /// No description provided for @emailResendLink.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le lien de vérification'**
  String get emailResendLink;

  /// No description provided for @emailLinkSent.
  ///
  /// In fr, this message translates to:
  /// **'Lien envoyé. Regardez votre boîte de réception.'**
  String get emailLinkSent;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour l\'instant'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Vos ventes, vos achats et vos messages apparaîtront ici.'**
  String get notificationsEmptyHint;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get notificationsMarkAllRead;

  /// No description provided for @timeAgoNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get timeAgoNow;

  /// No description provided for @receiptPurchaseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reçu d\'achat'**
  String get receiptPurchaseTitle;

  /// No description provided for @receiptSaleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif de vente'**
  String get receiptSaleTitle;

  /// No description provided for @receiptTotalPaidLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total payé'**
  String get receiptTotalPaidLabel;

  /// No description provided for @receiptYouReceive.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevez'**
  String get receiptYouReceive;

  /// No description provided for @receiptYouReceiveHint.
  ///
  /// In fr, this message translates to:
  /// **'Le prix de l\'article. Les frais de livraison et de protection sont à la charge de l\'acheteur.'**
  String get receiptYouReceiveHint;

  /// No description provided for @receiptDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get receiptDetails;

  /// No description provided for @receiptParties.
  ///
  /// In fr, this message translates to:
  /// **'Parties'**
  String get receiptParties;

  /// No description provided for @receiptDeliverySection.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get receiptDeliverySection;

  /// No description provided for @receiptActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get receiptActions;

  /// No description provided for @founderBadge.
  ///
  /// In fr, this message translates to:
  /// **'Fondateur'**
  String get founderBadge;

  /// No description provided for @starBadge.
  ///
  /// In fr, this message translates to:
  /// **'Star'**
  String get starBadge;

  /// Veuillez sélectionner un mode de paiement
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un mode de paiement'**
  String get paymentMethodSelectPrompt;

  /// Veuillez entrer votre numéro T-Money
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre numéro T-Money'**
  String get paymentMethodTmoneyPrompt;

  /// Veuillez entrer votre numéro Flooz
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre numéro Flooz'**
  String get paymentMethodFloozPrompt;

  /// Numéro de téléphone T-Money
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone T-Money'**
  String get paymentMethodTmoneyLabel;

  /// Numéro de téléphone Flooz
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone Flooz'**
  String get paymentMethodFloozLabel;

  /// Impossible de récupérer votre position
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer votre position'**
  String get locationCurrentFailed;

  /// Veuillez sélectionner une localisation
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une localisation'**
  String get locationSelectPrompt;

  /// Choisir une localisation
  ///
  /// In fr, this message translates to:
  /// **'Choisir une localisation'**
  String get locationPickTitle;

  /// Étiquette du colis
  ///
  /// In fr, this message translates to:
  /// **'Étiquette du colis'**
  String get parcelLabelTitle;

  /// Copier le code
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get parcelLabelCopyCode;

  /// Code copié
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get parcelLabelCodeCopied;

  /// Confirmation après suppression d'une notification au swipe
  ///
  /// In fr, this message translates to:
  /// **'Notification supprimée'**
  String get notificationDeleted;

  /// Entrée de menu du profil personnel pour ouvrir son profil public (avis, note)
  ///
  /// In fr, this message translates to:
  /// **'Voir mon profil public'**
  String get viewPublicProfile;

  /// Mention affichée sur mobile où l'achat de boosts n'est pas disponible dans l'app
  ///
  /// In fr, this message translates to:
  /// **'Les boosts s\'achètent sur la version web d\'Ablony (ablony.app).'**
  String get boostBuyOnWeb;

  /// Bouton pour télécharger/imprimer l'étiquette du colis en PDF
  ///
  /// In fr, this message translates to:
  /// **'Télécharger l\'étiquette'**
  String get parcelLabelDownload;

  /// Erreur lors de la génération du PDF de l'étiquette
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer l\'étiquette'**
  String get parcelLabelError;

  /// Nom et prénom
  ///
  /// In fr, this message translates to:
  /// **'Nom et prénom'**
  String get addressFullName;

  /// Libellé du champ téléphone de livraison
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get deliveryPhoneLabel;

  /// Erreur : téléphone de livraison manquant
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un numéro de téléphone'**
  String get deliveryPhoneRequired;

  /// Erreur : téléphone de livraison invalide
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide'**
  String get deliveryPhoneInvalid;

  /// Libellé de la tuile coordonnées de contact
  ///
  /// In fr, this message translates to:
  /// **'Nom et téléphone'**
  String get deliveryContactLabel;

  /// Placeholder de la tuile coordonnées de contact
  ///
  /// In fr, this message translates to:
  /// **'Ajouter vos coordonnées'**
  String get deliveryContactPlaceholder;

  /// Titre du formulaire de coordonnées de contact
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées de contact'**
  String get deliveryContactTitle;

  /// Titre de la bascule emails marketing dans les réglages
  ///
  /// In fr, this message translates to:
  /// **'Emails marketing'**
  String get marketingEmailToggleTitle;

  /// Sous-titre de la bascule emails marketing
  ///
  /// In fr, this message translates to:
  /// **'Offres, nouveautés et promotions'**
  String get marketingEmailToggleSubtitle;

  /// Modifier la localisation
  ///
  /// In fr, this message translates to:
  /// **'Modifier la localisation'**
  String get addressEditLocation;

  /// Livraison à domicile
  ///
  /// In fr, this message translates to:
  /// **'Livraison à domicile'**
  String get paymentHomeDelivery;

  /// Payer la différence
  ///
  /// In fr, this message translates to:
  /// **'Payer la différence'**
  String get paymentPayDifference;

  /// Détail de la facture
  ///
  /// In fr, this message translates to:
  /// **'Détail de la facture'**
  String get paymentInvoiceDetail;

  /// Source de données manquante
  ///
  /// In fr, this message translates to:
  /// **'Source de données manquante'**
  String get dynamicMissingSource;

  /// Aucun élément trouvé
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément trouvé'**
  String get dynamicNoItems;

  /// Recharger le portefeuille
  ///
  /// In fr, this message translates to:
  /// **'Recharger le portefeuille'**
  String get walletTopUpTitle;

  /// Saisissez le montant à recharger (min. 200 FCFA) :
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le montant à recharger (min. 200 FCFA) :'**
  String get walletTopUpPrompt;

  /// Cet article a déjà été vendu
  ///
  /// In fr, this message translates to:
  /// **'Cet article a déjà été vendu'**
  String get itemAlreadySold;

  /// Offre envoyée avec succès !
  ///
  /// In fr, this message translates to:
  /// **'Offre envoyée avec succès !'**
  String get offerSentSuccess;

  /// Choisir un point relais
  ///
  /// In fr, this message translates to:
  /// **'Choisir un point relais'**
  String get relayPointPickTitle;

  /// Veuillez compléter le captcha
  ///
  /// In fr, this message translates to:
  /// **'Veuillez compléter le captcha'**
  String get captchaIncomplete;

  /// Rechercher dans les favoris…
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans les favoris…'**
  String get favoritesSearchHint;

  /// Avertissement anti-arnaque en tête de conversation
  ///
  /// In fr, this message translates to:
  /// **'Ne partagez jamais ici un code reçu par SMS, un mot de passe ou vos données bancaires. L\'équipe Ablony ne vous les demandera jamais.'**
  String get chatSafetyWarning;

  /// Précision sur l'absence de chiffrement de bout en bout
  ///
  /// In fr, this message translates to:
  /// **'Les messages ne sont pas chiffrés de bout en bout.'**
  String get chatNotEncrypted;

  /// Parcours de paiement sur navigateur
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours dans un autre onglet'**
  String get paymentWaitingTitle;

  /// Parcours de paiement sur navigateur
  ///
  /// In fr, this message translates to:
  /// **'Terminez le paiement dans l\'onglet qui vient de s\'ouvrir. Cette page se met à jour toute seule dès que le paiement est confirmé.'**
  String get paymentWaitingBody;

  /// Parcours de paiement sur navigateur
  ///
  /// In fr, this message translates to:
  /// **'Terminez le paiement dans l\'onglet qui vient de s\'ouvrir, puis revenez ici.'**
  String get paymentWaitingBodyManual;

  /// Parcours de paiement sur navigateur
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir la page de paiement'**
  String get paymentReopen;

  /// Parcours de paiement sur navigateur
  ///
  /// In fr, this message translates to:
  /// **'Annuler le paiement'**
  String get paymentCancel;

  /// Parcours de paiement sur navigateur
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la page de paiement. Votre navigateur a peut-être bloqué la fenêtre — autorisez-la, puis réessayez.'**
  String get paymentOpenFailed;

  /// Bouton principal d'ouverture du paiement
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la page de paiement'**
  String get paymentOpenPage;

  /// Attente de confirmation de paiement
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours de vérification'**
  String get paymentVerifyingTitle;

  /// Attente de confirmation de paiement
  ///
  /// In fr, this message translates to:
  /// **'Si votre compte a été débité, le montant sera crédité automatiquement dès que la confirmation nous parvient. Vous n\'avez rien à refaire, et rien n\'est perdu.'**
  String get paymentVerifyingBody;

  /// Attente de confirmation de paiement
  ///
  /// In fr, this message translates to:
  /// **'La confirmation prend parfois quelques minutes, et jusqu\'à une heure quand l\'opérateur est lent.'**
  String get paymentVerifyingDelay;

  /// Attente de confirmation de paiement
  ///
  /// In fr, this message translates to:
  /// **'Référence : {reference}'**
  String paymentReference(String reference);

  /// Attente de confirmation de paiement
  ///
  /// In fr, this message translates to:
  /// **'Conservez cette référence si vous nous écrivez.'**
  String get paymentKeepReference;

  /// Attente de confirmation de paiement
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get paymentClose;

  /// Assistance intégrée
  ///
  /// In fr, this message translates to:
  /// **'Assistance Ablony'**
  String get supportTitle;

  /// Assistance intégrée
  ///
  /// In fr, this message translates to:
  /// **'Décrivez votre problème…'**
  String get supportHint;

  /// Assistance intégrée
  ///
  /// In fr, this message translates to:
  /// **'Joindre une capture'**
  String get supportAttach;

  /// Assistance intégrée
  ///
  /// In fr, this message translates to:
  /// **'Vous écrivez à l\'équipe Ablony'**
  String get supportWelcomeTitle;

  /// Assistance intégrée
  ///
  /// In fr, this message translates to:
  /// **'Expliquez ce qui s\'est passé et joignez une capture si vous avez été débité — c\'est ce qui permet de trancher le plus vite. Nous répondons sous 24 h ouvrées.'**
  String get supportWelcomeEmpty;

  /// Assistance intégrée
  ///
  /// In fr, this message translates to:
  /// **'Nous répondons sous 24 h ouvrées.'**
  String get supportWelcomeDelay;

  /// Assistance intégrée
  ///
  /// In fr, this message translates to:
  /// **'Contacter l\'assistance'**
  String get supportOpen;

  /// Assistance intégrée
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, j\'ai été débité mais mon paiement apparaît toujours en attente.\n\nRéférence : {reference}\n\n(Joignez ici la capture du débit.)'**
  String supportPaymentPrefill(String reference);

  /// Explication affichée au choix du paiement par carte
  ///
  /// In fr, this message translates to:
  /// **'Vous saisirez votre carte sur la page sécurisée de notre prestataire de paiement. Ablony ne voit ni n\'enregistre vos données bancaires.'**
  String get paymentCardRedirectNotice;

  /// Formulaire carte (masqué pour le moment)
  ///
  /// In fr, this message translates to:
  /// **'Nom figurant sur la carte'**
  String get paymentMethodCardName;

  /// Formulaire carte (masqué pour le moment)
  ///
  /// In fr, this message translates to:
  /// **'Numéro de carte bancaire'**
  String get paymentMethodCardNumber;

  /// Formulaire carte (masqué pour le moment)
  ///
  /// In fr, this message translates to:
  /// **'Code de sécurité'**
  String get paymentMethodCardCvv;
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
