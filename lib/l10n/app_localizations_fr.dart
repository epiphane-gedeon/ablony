// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get skip => 'Ignorer';

  @override
  String get onboardingCatchPhrase1 => 'Achetez et vendez';

  @override
  String get onboardingCatchPhrase2 => 'facilement.';

  @override
  String get signUpButton => 'S\'inscrire sur Ablony';

  @override
  String get loginButton => 'J\'ai déjà un compte';

  @override
  String get aboutAblony => 'À propos d\'Ablony : ';

  @override
  String get ourPlatform => 'Notre plateforme';

  @override
  String get changeLanguage => 'Changer la langue';

  @override
  String get validate => 'Valider';

  @override
  String get close => 'Fermer';

  @override
  String get pageNotFound => 'Page non trouvée';

  @override
  String pageNotFoundMessage(String route) {
    return 'La route \"$route\" n\'existe pas.';
  }

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get registerTitle => 'S\'inscrire';

  @override
  String get usernameLabel => 'Nom d\'utilisateur';

  @override
  String get usernamePlaceholder => 'john-doe';

  @override
  String get usernameRequired => 'Le nom d\'utilisateur est obligatoire';

  @override
  String get usernameMinLength => 'Minimum 3 caractères';

  @override
  String get usernameMaxLength => 'Maximum 30 caractères';

  @override
  String get usernameFormatError =>
      'Format invalide (lettres, chiffres, - et _ uniquement)';

  @override
  String get usernameSuggestion => 'Nous te suggérons ce nom d\'utilisateur :';

  @override
  String get marketingEmailMessage =>
      'Je souhaite recevoir par e-mail des offres personnalisées et les dernières mises à jour d\'Ablony.';

  @override
  String get termsPrefix =>
      'En t\'inscrivant, tu confirmes que tu acceptes les ';

  @override
  String get termsTitle => 'Termes & Conditions de Ablony';

  @override
  String get privacyPrefix => ', avoir lu la ';

  @override
  String get privacyTitle => 'Politique de confidentialité';

  @override
  String get termsAge => ' et avoir au moins 18 ans.';

  @override
  String get continueButton => 'Continuer';

  @override
  String get problemLink => 'Un problème ?';

  @override
  String get loginTitle => 'S\'inscrire sur Ablony';

  @override
  String get loginSubtitleApple =>
      'Utilise ton identifiant Apple, c\'est plus rapide.';

  @override
  String get loginSubtitleGoogle =>
      'Utilise ton compte Google, c\'est plus rapide.';

  @override
  String get loginAppleError => 'Échec de la connexion avec Apple';

  @override
  String get loginGoogleError => 'Échec de la connexion avec Google';

  @override
  String get loginFacebookError => 'Échec de la connexion avec Facebook';

  @override
  String get loginApple => 'Continuer avec Apple';

  @override
  String get loginGoogle => 'Continuer avec Google';

  @override
  String get loginFacebook => 'Continuer avec Facebook';

  @override
  String get loginOr => 'ou';

  @override
  String get loginEmail => 'Continuer avec une adresse e-mail';

  @override
  String get loginBusiness => 'Tu es une entreprise ? ';

  @override
  String get loginBusinessMore => 'En savoir plus';

  @override
  String get homeTitle => 'Ablony';

  @override
  String get homeWelcome => 'Hello World! 🎉';

  @override
  String get homeSubtitle => 'Bienvenue sur Ablony !';

  @override
  String get homeSuccess => 'L\'inscription est terminée avec succès.';

  @override
  String get countryTitle => 'Où habites-tu ?';

  @override
  String get countrySubtitle =>
      'Sélectionne ton pays pour personnaliser ton expérience.';

  @override
  String get countryLoading => 'Finalisation de ton inscription...';

  @override
  String get countryErrorGeneric =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get countryErrorNetwork =>
      'Problème de connexion. Vérifiez votre réseau.';

  @override
  String get countryErrorUsername => 'Le nom d\'utilisateur est déjà pris.';

  @override
  String get countryInfo =>
      'Tu pourras modifier ton pays et ta ville plus tard dans tes paramètres.';
}
