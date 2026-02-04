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
  String get loginTitleLogin => 'Se connecter à Ablony';

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

  @override
  String get emailSignupTitle => 'Inscris-toi';

  @override
  String get emailSignupUsername => 'Nom d\'utilisateur';

  @override
  String get emailSignupUsernamePlaceholder => 'Choisis un nom d\'utilisateur';

  @override
  String get emailSignupEmail => 'Email';

  @override
  String get emailSignupEmailPlaceholder => 'Ton adresse email';

  @override
  String get emailSignupPassword => 'Mot de passe';

  @override
  String get emailSignupPasswordPlaceholder => 'Crée un mot de passe';

  @override
  String get emailSignupPasswordHint =>
      'Il doit contenir 8 caractères minimum, dont au moins un chiffre une majuscule et un caractère spécial.';

  @override
  String get emailSignupMarketing =>
      'Je souhaite recevoir par e-mail des offres personnalisées et les dernières mises à jour d\'Ablony.';

  @override
  String get emailSignupTermsError =>
      'Tu dois accepter les conditions pour continuer';

  @override
  String get emailSignupUsernameRequired => 'Le nom d\'utilisateur est requis';

  @override
  String get emailSignupUsernameMinLength =>
      'Le nom d\'utilisateur doit contenir au moins 3 caractères';

  @override
  String get emailSignupEmailRequired => 'L\'email est requis';

  @override
  String get emailSignupEmailInvalid => 'Veuillez entrer un email valide';

  @override
  String get emailSignupPasswordRequired => 'Le mot de passe est requis';

  @override
  String get emailSignupPasswordMinLength =>
      'Le mot de passe doit contenir au moins 7 caractères';

  @override
  String get emailSignupPasswordNoDigit =>
      'Le mot de passe doit contenir au moins un chiffre';

  @override
  String get loginScreenTitle => 'Connecte-toi';

  @override
  String get loginScreenIdentifier => 'Identifiant ou adresse email';

  @override
  String get loginScreenIdentifierPlaceholder => 'Entre ton email ou pseudo';

  @override
  String get loginScreenPassword => 'Mot de passe';

  @override
  String get loginScreenPasswordPlaceholder => 'Ton mot de passe';

  @override
  String get loginScreenSubmit => 'Se connecter';

  @override
  String get loginScreenForgotPassword => 'Tu as oublié ton mot de passe ?';

  @override
  String get loginScreenIdentifierRequired => 'Ce champ est requis';

  @override
  String get loginScreenPasswordRequired => 'Le mot de passe est requis';

  @override
  String get sellTitle => 'Vends un article';

  @override
  String get addPhotos => 'Ajouter photos';

  @override
  String get productTitle => 'Titre';

  @override
  String get productTitleHint => 'Dis aux acheteurs ce que tu vends';

  @override
  String get productDescription => 'Décris ton article';

  @override
  String get productDescriptionHint => 'Ajoute des informations utiles';

  @override
  String get category => 'Catégorie';

  @override
  String get selectCategory => 'Sélectionner une catégorie';

  @override
  String get condition => 'État';

  @override
  String get conditionNew => 'Neuf avec étiquette';

  @override
  String get conditionExcellent => 'Excellent état';

  @override
  String get conditionGood => 'Bon état';

  @override
  String get conditionFair => 'Correct';

  @override
  String get price => 'Prix sans les frais de port';

  @override
  String get priceHint => '0';

  @override
  String get publish => 'Publier';

  @override
  String get requiredField => 'Ce champ est obligatoire';

  @override
  String get selectAtLeast1Photo => 'Sélectionne au moins 1 photo';

  @override
  String get maxPhotosReached => 'Maximum 6 photos';

  @override
  String get brand => 'Marque';

  @override
  String get size => 'Taille';

  @override
  String get color => 'Couleur';

  @override
  String get material => 'Matière';

  @override
  String get length => 'Longueur';

  @override
  String get bagType => 'Type de sac';

  @override
  String get jewelType => 'Type de bijou';

  @override
  String get movement => 'Mouvement';

  @override
  String get selectCondition => 'Sélectionner l\'état';

  @override
  String get searchCategory => 'Chercher une catégorie';

  @override
  String get selectSubcategory => 'Sélectionner une sous-catégorie';

  @override
  String get publishing => 'Publication en cours...';

  @override
  String get priceWithoutShipping => 'Prix sans les frais de port';

  @override
  String get productPublishedSuccess => 'Produit publié avec succès ! 🎉';

  @override
  String get productPublishError =>
      'Une erreur est survenue lors de la publication';

  @override
  String get userNotConnected => 'Utilisateur non connecté';

  @override
  String get imageUploadError => 'Erreur lors de l\'upload des images';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Réessayer';

  @override
  String get currency => 'FCFA';

  @override
  String selectAttributePlaceholder(String attributeName) {
    return 'Sélectionner $attributeName';
  }

  @override
  String enterAttributePlaceholder(String attributeName) {
    return 'Entrer $attributeName';
  }

  @override
  String get indicateYourPrice => 'Indique ton prix';

  @override
  String get priceFormatPlaceholder => '0,00 FCFA';

  @override
  String get validatePrice => 'Valider';

  @override
  String get searchPlaceholder => 'Trouver...';

  @override
  String get categoryFemme => 'Femme';

  @override
  String get categoryHomme => 'Homme';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get subcategoryHaut => 'Haut';

  @override
  String get subcategoryBas => 'Bas';

  @override
  String get subcategoryChaussures => 'Chaussures';

  @override
  String get subcategoryAccessoires => 'Accessoires';

  @override
  String get subcategoryChemise => 'Chemise';

  @override
  String get subcategoryTshirt => 'T-shirt';

  @override
  String get subcategoryDebardeur => 'Débardeur';

  @override
  String get subcategoryPull => 'Pull';

  @override
  String get subcategoryVeste => 'Veste';

  @override
  String get subcategoryPantalon => 'Pantalon';

  @override
  String get subcategoryJupe => 'Jupe';

  @override
  String get subcategoryShort => 'Short';

  @override
  String get subcategoryRobe => 'Robe';

  @override
  String get subcategoryBaskets => 'Baskets';

  @override
  String get subcategorySandales => 'Sandales';

  @override
  String get subcategoryTalons => 'Talons';

  @override
  String get subcategorySac => 'Sac';

  @override
  String get subcategoryBijoux => 'Bijoux';

  @override
  String get subcategoryCasquette => 'Casquette';

  @override
  String get subcategoryCeinture => 'Ceinture';

  @override
  String get subcategoryMontre => 'Montre';

  @override
  String get attributeEtat => 'État';

  @override
  String get attributeMarque => 'Marque';

  @override
  String get attributeTaille => 'Taille';

  @override
  String get attributePointure => 'Pointure';

  @override
  String get attributeCouleur => 'Couleur';

  @override
  String get attributeMatiere => 'Matière';

  @override
  String get attributeLongueur => 'Longueur';

  @override
  String get attributeTypeSac => 'Type de sac';

  @override
  String get attributeTypeBijou => 'Type de bijou';

  @override
  String get attributeMouvement => 'Mouvement';

  @override
  String get conditionNewWithTags => 'Neuf avec étiquette';

  @override
  String get conditionSatisfactory => 'Satisfaisant';

  @override
  String get conditionUsed => 'Usé';

  @override
  String conditionValue(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'newWithTags': 'Neuf avec étiquette',
      'excellent': 'Excellent',
      'good': 'Bon état',
      'satisfactory': 'Satisfaisant',
      'worn': 'Usé',
      'other': 'Bon état',
    });
    return '$_temp0';
  }

  @override
  String get helpTextCondition => 'État général du produit';

  @override
  String get helpTextBrand => 'Sélectionnez la marque du produit';

  @override
  String get helpTextSizeTop => 'Taille pour hauts, chemises, pulls, vestes';

  @override
  String get helpTextSizeBottom => 'Taille pour pantalons, shorts, jupes';

  @override
  String get helpTextShoeSize => 'Pointure de chaussures';

  @override
  String get helpTextColor => 'Couleur principale du produit';

  @override
  String get helpTextMaterial => 'Matière principale du produit';

  @override
  String get helpTextLength => 'Longueur de la robe ou jupe';

  @override
  String get helpTextBagType => 'Type de sac (sac à main, sac à dos, etc.)';

  @override
  String get helpTextJewelryType =>
      'Type de bijou (collier, bague, bracelet, etc.)';

  @override
  String get helpTextMovement => 'Type de mouvement de la montre';

  @override
  String get lengthShort => 'Court';

  @override
  String get lengthMedium => 'Mi-long';

  @override
  String get lengthLong => 'Long';

  @override
  String get colorBlack => 'Noir';

  @override
  String get colorWhite => 'Blanc';

  @override
  String get colorGray => 'Gris';

  @override
  String get colorBeige => 'Beige';

  @override
  String get colorBrown => 'Marron';

  @override
  String get colorBlue => 'Bleu';

  @override
  String get colorNavyBlue => 'Bleu marine';

  @override
  String get colorLightBlue => 'Bleu clair';

  @override
  String get colorRed => 'Rouge';

  @override
  String get colorPink => 'Rose';

  @override
  String get colorPurple => 'Violet';

  @override
  String get colorGreen => 'Vert';

  @override
  String get colorKhakiGreen => 'Vert kaki';

  @override
  String get colorYellow => 'Jaune';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorMulticolor => 'Multicolore';

  @override
  String get colorGold => 'Doré';

  @override
  String get colorSilver => 'Argenté';

  @override
  String get materialCotton => 'Coton';

  @override
  String get materialPolyester => 'Polyester';

  @override
  String get materialWool => 'Laine';

  @override
  String get materialSilk => 'Soie';

  @override
  String get materialLinen => 'Lin';

  @override
  String get materialDenim => 'Jean';

  @override
  String get materialLeather => 'Cuir';

  @override
  String get materialSuede => 'Daim';

  @override
  String get materialSynthetic => 'Synthétique';

  @override
  String get materialVelvet => 'Velours';

  @override
  String get materialCashmere => 'Cachemire';

  @override
  String get materialViscose => 'Viscose';

  @override
  String get materialOther => 'Autre';

  @override
  String get bagTypeHandbag => 'Sac à main';

  @override
  String get bagTypeBackpack => 'Sac à dos';

  @override
  String get bagTypeClutch => 'Pochette';

  @override
  String get bagTypeTote => 'Tote bag';

  @override
  String get bagTypeCrossbody => 'Sac bandoulière';

  @override
  String get bagTypeTravel => 'Sac de voyage';

  @override
  String get bagTypeSatchel => 'Sacoche';

  @override
  String get jewelryTypeNecklace => 'Collier';

  @override
  String get jewelryTypeBracelet => 'Bracelet';

  @override
  String get jewelryTypeEarrings => 'Boucles d\'oreilles';

  @override
  String get jewelryTypeRing => 'Bague';

  @override
  String get jewelryTypeBrooch => 'Broche';

  @override
  String get jewelryTypeWatchBracelet => 'Montre bracelet';

  @override
  String get watchMovementQuartz => 'Quartz';

  @override
  String get watchMovementAutomatic => 'Automatique';

  @override
  String get watchMovementManual => 'Manuel';

  @override
  String get watchMovementDigital => 'Numérique';

  @override
  String get brandOther => 'Autre';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Rechercher';

  @override
  String get navSell => 'Vendre';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profil';

  @override
  String priceWithProtection(String price) {
    return '$price FCFA incl.';
  }

  @override
  String get searchArticlesTab => 'Articles';

  @override
  String get searchMembersTab => 'Membres';

  @override
  String get searchArticlesPlaceholder =>
      'Rechercher un article ou un membre...';

  @override
  String get closeButton => 'Fermer';

  @override
  String get searchNoResults => 'Aucun résultat trouvé';

  @override
  String get searchTyping => 'Commencez à taper pour rechercher...';

  @override
  String get filterTitle => 'Filtrer';

  @override
  String get sortBy => 'Classer par';

  @override
  String get sortRelevance => 'Pertinence';

  @override
  String get sortRecent => 'Plus récents';

  @override
  String get sortPriceAsc => 'Prix croissant';

  @override
  String get sortPriceDesc => 'Prix décroissant';

  @override
  String get sortPopular => 'Plus populaires';

  @override
  String get filterCategory => 'Catégorie';

  @override
  String get filterSize => 'Taille';

  @override
  String get filterBrand => 'Marque';

  @override
  String get filterCondition => 'État';

  @override
  String get filterColor => 'Couleur';

  @override
  String get filterPrice => 'Prix';

  @override
  String get filterMaterial => 'Matière';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterAllCategories => 'Tous';

  @override
  String get filterCustomPrice => 'Personnalisé';

  @override
  String get filterClear => 'Effacer';

  @override
  String get filterShowResults => 'Afficher les résultats';

  @override
  String get filterValidate => 'Valider';

  @override
  String resultsCount(int count) {
    return '$count résultats';
  }

  @override
  String get messagesTab => 'Messages';

  @override
  String get notificationsTab => 'Notifications';

  @override
  String get noMessages => 'Pas encore de messages';

  @override
  String get noNotifications => 'Pas encore de notifications';

  @override
  String get makeOfferTitle => 'Faire une offre';

  @override
  String itemPrice(String price) {
    return 'prix de l\'article : $price';
  }

  @override
  String reductionLabel(int percent) {
    return '$percent% de réduction';
  }

  @override
  String get otherOffer => 'Autre';

  @override
  String get otherOfferHint => 'Propose un prix';

  @override
  String proposeButton(String amount) {
    return 'Proposer $amount';
  }

  @override
  String get proposeButtonSimple => 'Proposer';

  @override
  String offerLimitError(String minAmount, int limit) {
    return 'Ton offre doit être de $minAmount minimum (-$limit%)';
  }

  @override
  String suggestionsRemaining(int count) {
    return '$count propositions restante(s) pour aujourd\'hui';
  }

  @override
  String get whyLink => 'Pourquoi ?';
}
