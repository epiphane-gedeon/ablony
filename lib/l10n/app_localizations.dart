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

  /// Titre du flow de connexion
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire sur Ablony'**
  String get loginTitle;

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
  /// **'Il doit contenir 7 lettres minimum, dont au moins un chiffre.'**
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
