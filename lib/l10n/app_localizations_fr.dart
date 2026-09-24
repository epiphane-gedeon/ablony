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
  String get cityPickTitle => 'Ta ville';

  @override
  String get cityPickSubtitle =>
      'Choisis ta ville. Elle nous aide à te proposer la livraison là où c\'est disponible.';

  @override
  String get citySearchHint => 'Rechercher une ville';

  @override
  String get cityErrorGeneric =>
      'Impossible d\'enregistrer la ville. Réessaie.';

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
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get forgotPasswordDescription =>
      'Indique ton email, on t\'envoie un lien pour réinitialiser ton mot de passe.';

  @override
  String get resetPasswordEmailPlaceholder => 'Ton adresse email';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get resetEmailSentMessage =>
      'Si un compte existe avec cet email, un lien de réinitialisation vient d\'être envoyé.';

  @override
  String get resetPasswordPageTitle => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordPageDescription => 'Choisis un nouveau mot de passe.';

  @override
  String get resetPasswordNewPasswordPlaceholder => 'Nouveau mot de passe';

  @override
  String get resetPasswordConfirmPasswordPlaceholder =>
      'Confirmer le mot de passe';

  @override
  String get resetPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get resetPasswordSubmitButton => 'Réinitialiser';

  @override
  String get resetPasswordSuccessMessage =>
      'Mot de passe réinitialisé avec succès. Tu peux maintenant te connecter.';

  @override
  String get resetLinkInvalidMessage =>
      'Ce lien de réinitialisation est invalide ou a expiré. Redemande un nouveau lien depuis la page de connexion.';

  @override
  String get loginScreenForgotPassword => 'Tu as oublié ton mot de passe ?';

  @override
  String get loginScreenIdentifierRequired => 'Ce champ est requis';

  @override
  String get loginScreenPasswordRequired => 'Le mot de passe est requis';

  @override
  String get sellTitle => 'Vends un article';

  @override
  String get clearDraft => 'Effacer';

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
  String get searchArticlesPlaceholder => 'Recherche';

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
  String get noMessages => 'Aucun message';

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

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get profileInfo => 'Informations du profil';

  @override
  String get accountSettings => 'Paramètres du compte';

  @override
  String get payments => 'Paiements';

  @override
  String get shipping => 'Envoi';

  @override
  String get security => 'Sécurité';

  @override
  String get notifications => 'Notifications';

  @override
  String get mobile => 'Mobile';

  @override
  String get email => 'Email';

  @override
  String get appLanguage => 'Langue de l\'appli';

  @override
  String get language => 'Langue';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get privacySettings => 'Paramètres de confidentialité';

  @override
  String get logout => 'Déconnexion';

  @override
  String appVersion(String version) {
    return 'Version de l\'application : $version';
  }

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get cancel => 'ANNULER';

  @override
  String get logoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountConfirmTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountConfirmMessage =>
      'Cette suppression sera définitive : toutes vos informations personnelles seront remplacées par des données génériques et vous ne pourrez plus vous reconnecter à ce compte. Vous pourrez créer un nouveau compte avec les mêmes identifiants si vous le souhaitez.';

  @override
  String get deleteAccountConfirmAction => 'SUPPRIMER';

  @override
  String get deleteAccountDoneTitle => 'Compte supprimé';

  @override
  String get deleteAccountDoneMessage =>
      'Votre compte a bien été supprimé. Vous pouvez créer un nouveau compte avec les mêmes identifiants à tout moment.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get favorites => 'Favoris';

  @override
  String get inviteFriends => 'Inviter des amis';

  @override
  String get myWallet => 'Mon porte-monnaie';

  @override
  String get salesAndPurchases => 'Mes ventes et achats';

  @override
  String get promotionTools => 'Outils de promotion';

  @override
  String get personalization => 'Personnalisation';

  @override
  String get bundleDiscount => 'Réduction sur les lots';

  @override
  String get vacationMode => 'Mode vacances';

  @override
  String get donations => 'Dons';

  @override
  String get ablonyGuide => 'Ton guide Ablony';

  @override
  String get helpCenter => 'Centre d\'aide';

  @override
  String get cookieSettings => 'Paramètres des cookies';

  @override
  String get aboutUs => 'À propos de nous';

  @override
  String get legalInfo => 'Informations légales';

  @override
  String get viewMyListings => 'Voir mes annonces';

  @override
  String get productNotFound => 'Produit introuvable';

  @override
  String get markAsSold => 'Indiquer comme vendu';

  @override
  String get markAsReserved => 'Marquer comme réservé';

  @override
  String get cancelReservation => 'Annuler la réservation';

  @override
  String get edit => 'Modifier';

  @override
  String get hide => 'Masquer';

  @override
  String get unhide => 'Republier';

  @override
  String get productHidden => 'Annonce masquée';

  @override
  String get productUnhidden => 'Annonce republiée';

  @override
  String get productUnavailable => 'Produit indisponible';

  @override
  String get soldBadge => 'Vendu';

  @override
  String get reservedBadge => 'Réservé';

  @override
  String get hiddenBadge => 'Masqué';

  @override
  String get productMarkedAsSold => 'Produit marqué comme vendu';

  @override
  String get productMarkedAsReserved => 'Produit marqué comme réservé';

  @override
  String get reservationCancelled => 'Réservation annulée';

  @override
  String get productReserved => 'Produit réservé';

  @override
  String get deleteProductConfirm => 'Supprimer le produit ?';

  @override
  String get deleteProductBtn => 'SUPPRIMER';

  @override
  String get productDeletedSuccess => 'Produit supprimé avec succès';

  @override
  String errorGenericMsg(String error) {
    return 'Erreur : $error';
  }

  @override
  String get walletConfig => 'Configuration du porte-monnaie';

  @override
  String get enterFirstName => 'Veuillez saisir votre prénom';

  @override
  String get enterLastName => 'Veuillez saisir votre nom';

  @override
  String get selectNationality => 'Veuillez sélectionner une nationalité';

  @override
  String get selectBirthDate => 'Veuillez sélectionner votre date de naissance';

  @override
  String get walletActivatedSuccess => 'Porte-monnaie activé avec succès !';

  @override
  String get helpPageComingSoon => 'Page d\'aide à venir';

  @override
  String get topUpComingSoon => 'Fonctionnalité de recharge à venir';

  @override
  String get withdrawalComingSoon => 'Fonctionnalité de retrait à venir';

  @override
  String get activatedStr => 'Activé';

  @override
  String get deactivatedStr => 'Désactivé';

  @override
  String get listings => 'Annonces';

  @override
  String get reviews => 'Évaluations';

  @override
  String get aboutTab => 'À propos';

  @override
  String get addItems => 'Ajoute des articles...';

  @override
  String get verifiedInfo => 'Informations vérifiées :';

  @override
  String get pendingAmount => 'Montant en attente';

  @override
  String get pendingAmountInfo =>
      'Lorsqu\'un acheteur valide un achat, le montant est mis en attente jusqu\'à la réception et la confirmation du produit.';

  @override
  String get learnMore => 'En savoir plus';

  @override
  String get availableAmount => 'Montant disponible';

  @override
  String get activateWallet => 'Activer le porte-monnaie';

  @override
  String get topUpWallet => 'Recharger';

  @override
  String get withdrawWallet => 'Retirer';

  @override
  String get accountHolderFirstName => 'Prénom(s) du titulaire du compte';

  @override
  String get accountHolderLastName => 'Nom de famille du titulaire du compte';

  @override
  String get nationality => 'Nationalité';

  @override
  String get selectNationalityPlaceholder => 'Sélectionne une nationalité';

  @override
  String get birthDate => 'Date de naissance';

  @override
  String get productDescriptionTitle => 'Description';

  @override
  String get readMore => 'plus';

  @override
  String get readLess => 'moins';

  @override
  String get productCategory => 'Catégorie';

  @override
  String get productSize => 'Taille';

  @override
  String get productCondition => 'État';

  @override
  String get productColor => 'Couleur';

  @override
  String get productAddedDate => 'Ajouté';

  @override
  String get notSpecified => 'Non spécifiée';

  @override
  String get membersWardrobe => 'Dressing du membre';

  @override
  String get similarItems => 'Articles similaires';

  @override
  String get boostProduct => 'Booster';

  @override
  String get boostedBadge => 'Boosté';

  @override
  String get boostSheetTitle => 'Booster ce produit';

  @override
  String boostSheetDescription(int hours) {
    return 'Ton produit apparaîtra dans les emplacements mis en avant pendant ${hours}h.';
  }

  @override
  String boostAlreadyActive(String date) {
    return 'Ce produit est déjà boosté jusqu\'au $date.';
  }

  @override
  String get boostPay => 'Payer';

  @override
  String get boostSuccess => 'Produit boosté avec succès !';

  @override
  String get boostInsufficientBalance =>
      'Solde insuffisant. Choisis un autre moyen de paiement.';

  @override
  String boostCreditsBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts en réserve',
      one: '1 boost en réserve',
      zero: 'Aucun boost en réserve',
    );
    return '$_temp0';
  }

  @override
  String get boostUseCredit => 'Utiliser un boost';

  @override
  String get boostUseCreditSubtitle => 'Puisé dans votre réserve, sans payer';

  @override
  String boostPayOccasional(int price) {
    return 'Booster maintenant · $price FCFA';
  }

  @override
  String get boostBuyPacks => 'Acheter des boosts';

  @override
  String boostCreditApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts',
      one: '1 boost',
      zero: 'aucun boost',
    );
    return 'Boost appliqué ! Il vous reste $_temp0.';
  }

  @override
  String get boostPackTitle => 'Acheter des boosts';

  @override
  String boostPackDescription(int hours) {
    return 'Achetez des boosts d\'avance et utilisez-les quand vous voulez, sur l\'annonce de votre choix. Chaque boost met un article en avant pendant ${hours}h.';
  }

  @override
  String get boostPackQuantity => 'Nombre de boosts';

  @override
  String get boostPackTotal => 'Total';

  @override
  String boostPackBuy(int count, int price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts',
      one: '1 boost',
    );
    return 'Acheter $_temp0 · $price FCFA';
  }

  @override
  String boostPackSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts ajoutés',
      one: '1 boost ajouté',
    );
    return '$_temp0 à votre réserve !';
  }

  @override
  String get promotionCreditsTitle => 'Vos boosts en réserve';

  @override
  String get promotionUnavailable => 'Bientôt disponible';

  @override
  String get promotionUnavailableHint =>
      'La mise en avant arrive prochainement sur mobile. Elle est déjà disponible depuis le site Ablony.';

  @override
  String get promotionCreditsHint =>
      'Utilisez-les sur n\'importe quelle annonce, quand vous voulez.';

  @override
  String get locationSearchHint => 'Rechercher un lieu, un quartier…';

  @override
  String locationSearchNoResult(String query) {
    return 'Aucun lieu trouvé pour « $query »';
  }

  @override
  String get locationSearchFailed =>
      'La recherche a échoué. Vérifiez votre connexion.';

  @override
  String get shareProduct => 'Partager';

  @override
  String shareProductSubtitle(String price, String condition) {
    return '$price FCFA ($condition)';
  }

  @override
  String get priceIncl => 'incl.';

  @override
  String get subtotalForBuyer => '(sous-total pour l\'acheteur)';

  @override
  String get deleteProductConfirmationMessage =>
      'Êtes-vous sûr de vouloir supprimer ce produit ? Cette action est irréversible.';

  @override
  String get noReviewsYet => 'Pas encore d\'évaluations';

  @override
  String get minPrice => 'Prix minimum';

  @override
  String get maxPrice => 'Prix maximum';

  @override
  String get apply => 'Appliquer';

  @override
  String get resetFilter => 'Réinitialiser';

  @override
  String get priceFilterDevelopment =>
      'Filtre de prix en cours de développement';

  @override
  String get noReviewsSubtitle =>
      'Demande à la personne avec qui tu as effectué une transaction réussie de te laisser une évaluation.';

  @override
  String get messageButton => 'Message';

  @override
  String get buyerProtectionTitle => 'Frais de Protection acheteurs';

  @override
  String get buyerProtectionDescription =>
      'Pour tout achat effectué par le biais du bouton Acheter, nous appliquons des frais couvrant notre Protection acheteurs.';

  @override
  String get deleteProduct => 'Supprimer';

  @override
  String get makeOffer => 'Faire une offre';

  @override
  String get buyNow => 'Acheter';

  @override
  String get noProductsAvailable => 'Aucun produit disponible';

  @override
  String get timeAgoYear => 'Il y a 1 an';

  @override
  String timeAgoYears(int count) {
    return 'Il y a $count ans';
  }

  @override
  String timeAgoMonths(int count) {
    return 'Il y a $count mois';
  }

  @override
  String get timeAgoDay => 'Il y a 1 jour';

  @override
  String timeAgoDays(int count) {
    return 'Il y a $count jours';
  }

  @override
  String get timeAgoHour => 'Il y a 1 heure';

  @override
  String timeAgoHours(int count) {
    return 'Il y a $count heures';
  }

  @override
  String get timeAgoMinute => 'Il y a 1 minute';

  @override
  String timeAgoMinutes(int count) {
    return 'Il y a $count minutes';
  }

  @override
  String get timeAgoJustNow => 'À l\'instant';

  @override
  String get followButton => 'Suivre';

  @override
  String get unfollowButton => 'Suivi';

  @override
  String followersCountLabel(int count) {
    return '$count abonnés';
  }

  @override
  String followingCountLabel(int count) {
    return '$count abonnements';
  }

  @override
  String get followersPageTitle => 'Abonnés';

  @override
  String get followingPageTitle => 'Abonnements';

  @override
  String get noFollowersYet => 'Aucun abonné pour le moment';

  @override
  String get noFollowingYet => 'Ne suit personne pour le moment';

  @override
  String get receiptPageTitle => 'Reçu';

  @override
  String get receiptReference => 'Référence';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptSeller => 'Vendeur';

  @override
  String get receiptBuyer => 'Acheteur';

  @override
  String get receiptPaymentMethod => 'Moyen de paiement';

  @override
  String get receiptProductPrice => 'Prix de l\'article';

  @override
  String get receiptTotalPaid => 'Total payé';

  @override
  String get receiptDownloadButton => 'Télécharger le reçu';

  @override
  String get rateSellerPageTitle => 'Notez votre vendeur';

  @override
  String rateSellerHeadline(String productTitle) {
    return 'Comment s\'est passé votre achat de \"$productTitle\" ?';
  }

  @override
  String get rateSellerCommentHint => 'Ajouter un commentaire (facultatif)';

  @override
  String get rateSellerSubmitButton => 'Envoyer mon avis';

  @override
  String get confirmDeliveryButton => 'J\'ai reçu mon colis';

  @override
  String get productAlreadySold => 'Article déjà vendu';

  @override
  String get deliveryAlreadyConfirmed => 'Réception confirmée';

  @override
  String get scanQrPageTitle => 'Scanner le code';

  @override
  String get scanQrInstructions =>
      'Scannez le code QR affiché par le vendeur pour confirmer la réception';

  @override
  String get deliveryConfirmedTitle => 'Réception confirmée !';

  @override
  String get deliveryConfirmedMessage =>
      'Merci ! Le paiement a été débloqué pour le vendeur.';

  @override
  String get scanQrManualEntryButton => 'Saisir la référence du reçu';

  @override
  String get scanQrManualEntryDialogTitle => 'Confirmer avec la référence';

  @override
  String get scanQrManualEntryHint => 'Référence du reçu';

  @override
  String get scanQrManualEntryError => 'Veuillez saisir une référence';

  @override
  String get reportProduct => 'Signaler cet article';

  @override
  String get reportDialogTitle => 'Pourquoi signalez-vous cet article ?';

  @override
  String get reportReasonCounterfeit => 'Contrefaçon';

  @override
  String get reportReasonInappropriate => 'Contenu inapproprié';

  @override
  String get reportReasonScam => 'Arnaque potentielle';

  @override
  String get reportReasonOther => 'Autre';

  @override
  String get reportCommentHint => 'Précisions (facultatif)';

  @override
  String get reportSubmitButton => 'Envoyer le signalement';

  @override
  String get reportSuccessMessage =>
      'Signalement envoyé, merci pour votre vigilance.';

  @override
  String get imageSourceCameraOption => 'Prendre une photo';

  @override
  String get imageSourceGalleryOption => 'Choisir depuis la galerie';

  @override
  String get photoMessage => '📷 Photo';

  @override
  String get sendMessagePlaceholder => 'Envoyer un message';

  @override
  String get offerAcceptedSuccess => 'Offre acceptée !';

  @override
  String get offerRejectedSuccess => 'Offre refusée';

  @override
  String get chatTitle => 'Chat';

  @override
  String get conversationNotFound => 'Conversation introuvable';

  @override
  String chatWelcomeMessage(String username) {
    return 'Bonjour ! Moi c\'est $username';
  }

  @override
  String memberSinceYear(int year) {
    return 'Membre depuis $year';
  }

  @override
  String get systemMessage => 'Message système';

  @override
  String heyUserMadeOffer(String name) {
    return 'Hey, $name t\'a fait une offre';
  }

  @override
  String get defaultUser => 'un utilisateur';

  @override
  String get offerStatusAccepted => 'Acceptée';

  @override
  String get offerStatusRejected => 'Refusée';

  @override
  String get offerStatusPending => 'En attente';

  @override
  String get acceptButton => 'Accepter';

  @override
  String get rejectButton => 'Refuser';

  @override
  String get counterOffer => 'Contre-offre';

  @override
  String get errorLoading => 'Erreur de chargement';

  @override
  String get pleaseLogin => 'Veuillez vous connecter';

  @override
  String get parcelLabelButton => 'Voir l\'étiquette du colis';

  @override
  String get receiptParcelCode => 'Code du colis';

  @override
  String get confirmDeliveryTitle => 'Confirmer la réception';

  @override
  String get confirmDeliveryQuestion =>
      'Avez-vous bien reçu votre colis ? Le paiement sera immédiatement versé au vendeur, et ce geste est définitif.';

  @override
  String get confirmDeliveryConfirm => 'Oui, je l\'ai reçu';

  @override
  String get deliveryConfirmedSuccess =>
      'Réception confirmée. Le vendeur a été payé.';

  @override
  String get walletStatement => 'Relevé';

  @override
  String get walletStatementEmpty => 'Aucun mouvement pour l\'instant';

  @override
  String get walletStatementEmptyDetail =>
      'Vos achats, vos ventes et vos rechargements apparaîtront ici.';

  @override
  String get walletStatementError => 'Impossible de charger votre relevé.';

  @override
  String get walletEntryTopUp => 'Rechargement';

  @override
  String get walletEntryPurchase => 'Achat';

  @override
  String get walletEntryBoost => 'Mise en avant';

  @override
  String get walletEntrySale => 'Vente';

  @override
  String get walletEntryOnHold => 'en attente';

  @override
  String get scanParcelStaff => 'Scanner un colis';

  @override
  String get scanParcelBuyer => 'Scanner mon colis';

  @override
  String get scanHintStaff => 'Visez l\'étiquette collée sur le colis.';

  @override
  String get scanHintBuyer =>
      'Visez l\'étiquette de votre colis pour confirmer que vous l\'avez bien reçu.';

  @override
  String get scanTorch => 'Lampe';

  @override
  String get scanFailed => 'Le scan a échoué. Réessayez.';

  @override
  String get checkpointRecorded => 'Étape enregistrée.';

  @override
  String get parcelStatusLabel => 'État';

  @override
  String get parcelDestinationRelay => 'Point relais';

  @override
  String get parcelDestinationHome => 'Livraison à domicile';

  @override
  String get parcelRecordStep => 'Enregistrer une étape';

  @override
  String get parcelNoStepLeft => 'Ce colis a terminé son parcours.';

  @override
  String get parcelAwaitingDropoff => 'En attente de dépôt';

  @override
  String get parcelDroppedOff => 'Déposé';

  @override
  String get parcelInTransit => 'En transit';

  @override
  String get parcelReadyForPickup => 'À retirer en point relais';

  @override
  String get parcelOutForDelivery => 'En cours de livraison';

  @override
  String get parcelDelivered => 'Remis';

  @override
  String get parcelReturned => 'Retourné';

  @override
  String get parcelLost => 'Égaré';

  @override
  String get stepDroppedOff => 'Dépôt';

  @override
  String get stepInTransit => 'Départ';

  @override
  String get stepArrived => 'Arrivé au relais';

  @override
  String get stepOutForDelivery => 'En tournée';

  @override
  String get stepDelivered => 'Remis';

  @override
  String get stepReturned => 'Retour';

  @override
  String get stepLost => 'Égaré';

  @override
  String get stuckParcelsTitle => 'Colis bloqués';

  @override
  String get stuckParcelsEmpty => 'Rien ne traîne. Tout avance.';

  @override
  String get stuckNeverDroppedOff => 'Jamais déposé — délai dépassé';

  @override
  String get stuckInTransitTooLong => 'En transit depuis trop longtemps';

  @override
  String get stuckWaitingAtRelay => 'Attend en point relais';

  @override
  String get stuckBuyerScanned => 'scanné par l\'acheteur';

  @override
  String get staffTools => 'Espace personnel Ablony';

  @override
  String get walletEntryRefund => 'Remboursement';

  @override
  String get refundBuyer => 'Rembourser l\'acheteur';

  @override
  String get refundReasonHint =>
      'Ce motif est envoyé à l\'acheteur et au vendeur. Expliquez, ne résumez pas.';

  @override
  String get refundReasonLabel => 'Motif';

  @override
  String get refundConfirm => 'Rembourser';

  @override
  String get refundDone => 'L\'acheteur a été remboursé.';

  @override
  String get parcelNoTrackingYet =>
      'Préparation en cours — le suivi détaillé s\'affichera dès le premier scan';

  @override
  String get releaseSeller => 'Verser au vendeur';

  @override
  String get releaseDone => 'Le vendeur a été payé.';

  @override
  String get withdrawTitle => 'Retirer de l\'argent';

  @override
  String get withdrawAmount => 'Montant à retirer';

  @override
  String get withdrawAll => 'Tout retirer';

  @override
  String get withdrawMethod => 'Moyen de réception';

  @override
  String get withdrawDestination => 'Où envoyer l\'argent';

  @override
  String get withdrawDestinationPhoneHint => '+228 90 00 00 00';

  @override
  String get withdrawDestinationBankHint => 'Numéro de compte ou IBAN';

  @override
  String get withdrawAmountRequested => 'Montant demandé';

  @override
  String get withdrawFee => 'Frais de transfert';

  @override
  String get withdrawYouReceive => 'Vous recevez';

  @override
  String get withdrawFeeExplained =>
      'Ces frais couvrent le transfert vers votre compte mobile money. Retirer une grosse somme d\'un coup coûte proportionnellement moins cher.';

  @override
  String get withdrawInsufficient =>
      'Votre solde disponible ne couvre pas ce montant.';

  @override
  String get withdrawAlreadyPending =>
      'Une demande est déjà en cours de traitement. Vous pouvez en faire une autre, mais elles seront versées séparément.';

  @override
  String get withdrawConfirm => 'Demander le retrait';

  @override
  String get withdrawManualNotice =>
      'Les versements sont effectués manuellement, sous 24 à 48 heures ouvrées.';

  @override
  String get withdrawActivateFirst =>
      'Activez votre porte-monnaie pour pouvoir retirer';

  @override
  String get withdrawPending => 'En cours de versement';

  @override
  String get withdrawPaid => 'Versé';

  @override
  String get withdrawRejected => 'Refusé';

  @override
  String withdrawMinimum(String amount) {
    return 'Minimum : $amount FCFA';
  }

  @override
  String withdrawRequested(String amount) {
    return 'Demande enregistrée. Vous recevrez $amount FCFA.';
  }

  @override
  String get walletEntryWithdrawal => 'Retrait';

  @override
  String get walletEntryWithdrawalRefund => 'Retrait refusé';

  @override
  String get moderationCorrectionTitle => 'Annonce à corriger';

  @override
  String get moderationRemovedTitle => 'Annonce retirée';

  @override
  String get moderationCorrectionHint =>
      'Corrigez-la et elle repart en ligne automatiquement.';

  @override
  String get moderationRemovedHint =>
      'Cette annonce ne peut pas être remise en ligne.';

  @override
  String get moderationCorrectionAction => 'Corriger l\'annonce';

  @override
  String get moderationReasonBlurryPhotos => 'Photos floues ou inexploitables';

  @override
  String get moderationReasonWrongCategory => 'Mauvaise catégorie';

  @override
  String get moderationReasonMissingDescription => 'Description insuffisante';

  @override
  String get moderationReasonWrongPrice => 'Prix incohérent';

  @override
  String get moderationReasonCounterfeit => 'Contrefaçon';

  @override
  String get moderationReasonProhibitedItem => 'Article interdit à la vente';

  @override
  String get moderationReasonInappropriate => 'Contenu inapproprié';

  @override
  String get moderationReasonFraud => 'Tentative de fraude';

  @override
  String get moderationReasonOffPlatformSale => 'Vente hors de la plateforme';

  @override
  String get moderationReasonOther => 'Motif non précisé';

  @override
  String get disputeOpen => 'J\'ai un problème avec cette commande';

  @override
  String get disputeTitle => 'Signaler un problème';

  @override
  String get disputeReason => 'Que s\'est-il passé ?';

  @override
  String get disputeNotReceived => 'Je n\'ai jamais reçu le colis';

  @override
  String get disputeNotAsDescribed =>
      'L\'article ne correspond pas à l\'annonce';

  @override
  String get disputeDamaged => 'L\'article est arrivé abîmé';

  @override
  String get disputeBuyerNotConfirming =>
      'L\'acheteur ne confirme pas la réception';

  @override
  String get disputeBuyerNoValidReason =>
      'L\'acheteur réclame sans motif valable';

  @override
  String get disputeOther => 'Autre';

  @override
  String get disputeDescription => 'Décrivez le problème';

  @override
  String get disputeDescriptionHint =>
      'Soyez précis : c\'est ce qui permettra de trancher.';

  @override
  String disputeDescriptionTooShort(int count) {
    return 'Encore $count caractères';
  }

  @override
  String get disputePhotos => 'Ajoutez des photos (jusqu\'à 4)';

  @override
  String get disputePhotosHint => 'Une photo vaut mieux qu\'une description.';

  @override
  String get disputeSubmit => 'Envoyer le signalement';

  @override
  String get disputeSubmitted =>
      'Votre signalement est enregistré. Réponse sous 48 heures.';

  @override
  String get disputeUnderReview => 'Litige en cours d\'examen';

  @override
  String get disputeUnderReviewHint =>
      'L\'administration examine votre dossier. Réponse sous 48 heures.';

  @override
  String get disputeResolvedRefunded =>
      'Litige tranché : vous avez été remboursé';

  @override
  String get disputeResolvedReleased => 'Litige tranché en faveur du vendeur';

  @override
  String get disputeOpenedByOther =>
      'L\'autre partie a ouvert un litige sur cette commande.';

  @override
  String get disputeSending => 'Envoi en cours…';

  @override
  String get blockUser => 'Bloquer';

  @override
  String get unblockUser => 'Débloquer';

  @override
  String blockConfirmTitle(String username) {
    return 'Bloquer $username ?';
  }

  @override
  String get blockConfirmBody =>
      'Vous ne pourrez plus vous écrire. Cette personne ne sera pas prévenue. Une vente en cours suit son cours normalement.';

  @override
  String blockDone(String username) {
    return '$username a été bloqué.';
  }

  @override
  String get blockAlsoReport => 'Voulez-vous aussi le signaler à Ablony ?';

  @override
  String get blockedUsersTitle => 'Personnes bloquées';

  @override
  String get blockedUsersEmpty => 'Vous n\'avez bloqué personne.';

  @override
  String get blockedUsersHint =>
      'Bloquer quelqu\'un ferme la messagerie entre vous, dans les deux sens. Personne n\'en est prévenu.';

  @override
  String get blockedConversation => 'Vous avez bloqué cette personne.';

  @override
  String get blockedByOther =>
      'Vous ne pouvez plus écrire dans cette conversation.';

  @override
  String get unblockDone => 'Déblocage effectué.';

  @override
  String get reportUser => 'Signaler';

  @override
  String get later => 'Plus tard';

  @override
  String get ordersTitle => 'Ventes et achats';

  @override
  String get ordersPurchases => 'Achats';

  @override
  String get ordersSales => 'Ventes';

  @override
  String get ordersNoPurchases => 'Vous n\'avez encore rien acheté';

  @override
  String get ordersNoPurchasesHint =>
      'Ce que vous achetez apparaît ici, avec l\'avancement de la livraison.';

  @override
  String get ordersNoSales => 'Vous n\'avez encore rien vendu';

  @override
  String get ordersNoSalesHint =>
      'Mettez un article en vente : dès qu\'il trouve preneur, vous le suivez d\'ici.';

  @override
  String orderDropOffBy(String date) {
    return 'À déposer avant le $date';
  }

  @override
  String get orderDropOffLate => 'Délai dépassé — remboursement en cours';

  @override
  String get orderPrintLabel => 'Imprimer l\'étiquette';

  @override
  String get orderInTransit => 'En cours d\'acheminement';

  @override
  String get orderAwaitingPickup => 'À retirer au point relais';

  @override
  String get orderSellerPreparing => 'Le vendeur prépare votre colis';

  @override
  String get orderDeliveredWaiting => 'Remis — paiement à venir';

  @override
  String get orderConfirmReception => 'Confirmez la réception';

  @override
  String orderPaid(String amount) {
    return 'Payé : $amount FCFA';
  }

  @override
  String get orderReceived => 'Terminé';

  @override
  String orderRefunded(String amount) {
    return 'Remboursé : $amount FCFA';
  }

  @override
  String get orderCancelled => 'Vente annulée';

  @override
  String get orderTrack => 'Suivre';

  @override
  String get orderSee => 'Voir';

  @override
  String get ordersLoadMore => 'Voir plus';

  @override
  String get promotionEmpty => 'Aucune annonce à mettre en avant';

  @override
  String get promotionEmptyHint =>
      'Mettez un article en vente : vous pourrez ensuite le faire remonter dans les listes.';

  @override
  String get promotionBoost => 'Mettre en avant';

  @override
  String promotionActiveUntil(String date) {
    return 'En avant jusqu\'au $date';
  }

  @override
  String get termsOfService => 'Conditions générales d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get legalNotice => 'Mentions légales';

  @override
  String get editProfileTitle => 'Informations du profil';

  @override
  String get editProfilePhoto => 'Photo de profil';

  @override
  String get editProfileDisplayName => 'Nom affiché';

  @override
  String get editProfileCity => 'Ville';

  @override
  String get editProfileSave => 'Enregistrer';

  @override
  String get editProfileSaved => 'Profil mis à jour.';

  @override
  String get securityTitle => 'Sécurité';

  @override
  String get securityCurrentPassword => 'Mot de passe actuel';

  @override
  String get securityNewPassword => 'Nouveau mot de passe';

  @override
  String get securityConfirmPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get securityChangePassword => 'Changer le mot de passe';

  @override
  String get securityPasswordChanged => 'Mot de passe changé.';

  @override
  String get securityMismatch => 'Les deux saisies ne correspondent pas.';

  @override
  String get securityTooShort => 'Au moins 8 caractères.';

  @override
  String get securityWrongPassword => 'Mot de passe actuel incorrect.';

  @override
  String securitySocialAccount(String provider) {
    return 'Vous vous connectez avec $provider';
  }

  @override
  String get securitySocialHint =>
      'Votre mot de passe est géré par ce service. Il n\'y a rien à changer ici.';

  @override
  String get emailSettingsTitle => 'Adresse e-mail';

  @override
  String get emailVerified => 'Adresse vérifiée';

  @override
  String get emailNotVerified => 'Adresse non vérifiée';

  @override
  String get emailNotVerifiedHint =>
      'Vérifiez votre adresse : c\'est par elle que passent les alertes de vente et de retrait.';

  @override
  String get emailResendLink => 'Renvoyer le lien de vérification';

  @override
  String get emailLinkSent => 'Lien envoyé. Regardez votre boîte de réception.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'Aucune notification pour l\'instant';

  @override
  String get notificationsEmptyHint =>
      'Vos ventes, vos achats et vos messages apparaîtront ici.';

  @override
  String get notificationsMarkAllRead => 'Tout marquer comme lu';

  @override
  String get timeAgoNow => 'à l\'instant';

  @override
  String get receiptPurchaseTitle => 'Reçu d\'achat';

  @override
  String get receiptSaleTitle => 'Récapitulatif de vente';

  @override
  String get receiptTotalPaidLabel => 'Total payé';

  @override
  String get receiptYouReceive => 'Vous recevez';

  @override
  String get receiptYouReceiveHint =>
      'Le prix de l\'article. Les frais de livraison et de protection sont à la charge de l\'acheteur.';

  @override
  String get receiptDetails => 'Détails';

  @override
  String get receiptParties => 'Parties';

  @override
  String get receiptDeliverySection => 'Livraison';

  @override
  String get receiptActions => 'Actions';

  @override
  String get founderBadge => 'Fondateur';

  @override
  String get starBadge => 'Star';

  @override
  String get paymentMethodSelectPrompt =>
      'Veuillez sélectionner un mode de paiement';

  @override
  String get paymentMethodTmoneyPrompt =>
      'Veuillez entrer votre numéro T-Money';

  @override
  String get paymentMethodFloozPrompt => 'Veuillez entrer votre numéro Flooz';

  @override
  String get paymentMethodTmoneyLabel => 'Numéro de téléphone T-Money';

  @override
  String get paymentMethodFloozLabel => 'Numéro de téléphone Flooz';

  @override
  String get locationCurrentFailed => 'Impossible de récupérer votre position';

  @override
  String get locationSelectPrompt => 'Veuillez sélectionner une localisation';

  @override
  String get locationPickTitle => 'Choisir une localisation';

  @override
  String get parcelLabelTitle => 'Étiquette du colis';

  @override
  String get parcelLabelCopyCode => 'Copier le code';

  @override
  String get parcelLabelCodeCopied => 'Code copié';

  @override
  String get notificationDeleted => 'Notification supprimée';

  @override
  String get viewPublicProfile => 'Voir mon profil public';

  @override
  String get boostBuyOnWeb =>
      'Les boosts s\'achètent sur la version web d\'Ablony (ablony.app).';

  @override
  String get parcelLabelDownload => 'Télécharger l\'étiquette';

  @override
  String get parcelLabelError => 'Impossible de générer l\'étiquette';

  @override
  String get addressFullName => 'Nom et prénom';

  @override
  String get deliveryPhoneLabel => 'Téléphone';

  @override
  String get deliveryPhoneRequired => 'Veuillez entrer un numéro de téléphone';

  @override
  String get deliveryPhoneInvalid => 'Numéro de téléphone invalide';

  @override
  String get deliveryContactLabel => 'Nom et téléphone';

  @override
  String get deliveryContactPlaceholder => 'Ajouter vos coordonnées';

  @override
  String get deliveryContactTitle => 'Coordonnées de contact';

  @override
  String get marketingEmailToggleTitle => 'Emails marketing';

  @override
  String get marketingEmailToggleSubtitle => 'Offres, nouveautés et promotions';

  @override
  String get addressEditLocation => 'Modifier la localisation';

  @override
  String get paymentHomeDelivery => 'Livraison à domicile';

  @override
  String get paymentPayDifference => 'Payer la différence';

  @override
  String get paymentInvoiceDetail => 'Détail de la facture';

  @override
  String get dynamicMissingSource => 'Source de données manquante';

  @override
  String get dynamicNoItems => 'Aucun élément trouvé';

  @override
  String get walletTopUpTitle => 'Recharger le portefeuille';

  @override
  String get walletTopUpPrompt =>
      'Saisissez le montant à recharger (min. 200 FCFA) :';

  @override
  String get itemAlreadySold => 'Cet article a déjà été vendu';

  @override
  String get offerSentSuccess => 'Offre envoyée avec succès !';

  @override
  String get relayPointPickTitle => 'Choisir un point relais';

  @override
  String get captchaIncomplete => 'Veuillez compléter le captcha';

  @override
  String get favoritesSearchHint => 'Rechercher dans les favoris…';

  @override
  String get chatSafetyWarning =>
      'Ne partagez jamais ici un code reçu par SMS, un mot de passe ou vos données bancaires. L\'équipe Ablony ne vous les demandera jamais.';

  @override
  String get chatNotEncrypted =>
      'Les messages ne sont pas chiffrés de bout en bout.';

  @override
  String get paymentWaitingTitle => 'Paiement en cours dans un autre onglet';

  @override
  String get paymentWaitingBody =>
      'Terminez le paiement dans l\'onglet qui vient de s\'ouvrir. Cette page se met à jour toute seule dès que le paiement est confirmé.';

  @override
  String get paymentWaitingBodyManual =>
      'Terminez le paiement dans l\'onglet qui vient de s\'ouvrir, puis revenez ici.';

  @override
  String get paymentReopen => 'Rouvrir la page de paiement';

  @override
  String get paymentCancel => 'Annuler le paiement';

  @override
  String get paymentOpenFailed =>
      'Impossible d\'ouvrir la page de paiement. Votre navigateur a peut-être bloqué la fenêtre — autorisez-la, puis réessayez.';

  @override
  String get paymentOpenPage => 'Ouvrir la page de paiement';

  @override
  String get paymentVerifyingTitle => 'Paiement en cours de vérification';

  @override
  String get paymentVerifyingBody =>
      'Si votre compte a été débité, le montant sera crédité automatiquement dès que la confirmation nous parvient. Vous n\'avez rien à refaire, et rien n\'est perdu.';

  @override
  String get paymentVerifyingDelay =>
      'La confirmation prend parfois quelques minutes, et jusqu\'à une heure quand l\'opérateur est lent.';

  @override
  String paymentReference(String reference) {
    return 'Référence : $reference';
  }

  @override
  String get paymentKeepReference =>
      'Conservez cette référence si vous nous écrivez.';

  @override
  String get paymentClose => 'Fermer';

  @override
  String get supportTitle => 'Assistance Ablony';

  @override
  String get supportHint => 'Décrivez votre problème…';

  @override
  String get supportAttach => 'Joindre une capture';

  @override
  String get supportWelcomeTitle => 'Vous écrivez à l\'équipe Ablony';

  @override
  String get supportWelcomeEmpty =>
      'Expliquez ce qui s\'est passé et joignez une capture si vous avez été débité — c\'est ce qui permet de trancher le plus vite. Nous répondons sous 24 h ouvrées.';

  @override
  String get supportWelcomeDelay => 'Nous répondons sous 24 h ouvrées.';

  @override
  String get supportOpen => 'Contacter l\'assistance';

  @override
  String supportPaymentPrefill(String reference) {
    return 'Bonjour, j\'ai été débité mais mon paiement apparaît toujours en attente.\n\nRéférence : $reference\n\n(Joignez ici la capture du débit.)';
  }

  @override
  String get paymentCardRedirectNotice =>
      'Vous saisirez votre carte sur la page sécurisée de notre prestataire de paiement. Ablony ne voit ni n\'enregistre vos données bancaires.';

  @override
  String get paymentMethodCardName => 'Nom figurant sur la carte';

  @override
  String get paymentMethodCardNumber => 'Numéro de carte bancaire';

  @override
  String get paymentMethodCardCvv => 'Code de sécurité';
}
