// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get skip => 'Skip';

  @override
  String get onboardingCatchPhrase1 => 'Buy and sell';

  @override
  String get onboardingCatchPhrase2 => 'easily.';

  @override
  String get signUpButton => 'Sign up on Ablony';

  @override
  String get loginButton => 'I already have an account';

  @override
  String get aboutAblony => 'About Ablony: ';

  @override
  String get ourPlatform => 'Our platform';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get validate => 'Validate';

  @override
  String get close => 'Close';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String pageNotFoundMessage(String route) {
    return 'The route \"$route\" does not exist.';
  }

  @override
  String get backToHome => 'Back to home';

  @override
  String get registerTitle => 'Sign up';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernamePlaceholder => 'john-doe';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameMinLength => 'Minimum 3 characters';

  @override
  String get usernameMaxLength => 'Maximum 30 characters';

  @override
  String get usernameFormatError =>
      'Invalid format (letters, numbers, - and _ only)';

  @override
  String get usernameSuggestion => 'We suggest this username:';

  @override
  String get marketingEmailMessage =>
      'I want to receive personalized offers and the latest updates from Ablony by email.';

  @override
  String get termsPrefix => 'By signing up, you confirm that you accept the ';

  @override
  String get termsTitle => 'Ablony Terms & Conditions';

  @override
  String get privacyPrefix => ', have read the ';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get termsAge => ' and are at least 18 years old.';

  @override
  String get continueButton => 'Continue';

  @override
  String get problemLink => 'A problem?';

  @override
  String get loginTitle => 'Sign up on Ablony';

  @override
  String get loginTitleLogin => 'Log in to Ablony';

  @override
  String get loginSubtitleApple => 'Use your Apple ID, it\'s faster.';

  @override
  String get loginSubtitleGoogle => 'Use your Google account, it\'s faster.';

  @override
  String get loginAppleError => 'Failed to sign in with Apple';

  @override
  String get loginGoogleError => 'Failed to sign in with Google';

  @override
  String get loginFacebookError => 'Failed to sign in with Facebook';

  @override
  String get loginApple => 'Continue with Apple';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginFacebook => 'Continue with Facebook';

  @override
  String get loginOr => 'or';

  @override
  String get loginEmail => 'Continue with an email address';

  @override
  String get loginBusiness => 'Are you a business? ';

  @override
  String get loginBusinessMore => 'Learn more';

  @override
  String get homeTitle => 'Ablony';

  @override
  String get homeWelcome => 'Hello World! 🎉';

  @override
  String get homeSubtitle => 'Welcome to Ablony!';

  @override
  String get homeSuccess => 'Registration completed successfully.';

  @override
  String get countryTitle => 'Where do you live?';

  @override
  String get countrySubtitle =>
      'Select your country to personalize your experience.';

  @override
  String get countryLoading => 'Finalizing your registration...';

  @override
  String get countryErrorGeneric => 'An error occurred. Please try again.';

  @override
  String get countryErrorNetwork =>
      'Network issue. Please check your connection.';

  @override
  String get countryErrorUsername => 'Username is already taken.';

  @override
  String get countryInfo =>
      'You can change your country and city later in your settings.';

  @override
  String get emailSignupTitle => 'Sign up';

  @override
  String get emailSignupUsername => 'Username';

  @override
  String get emailSignupUsernamePlaceholder => 'Choose a username';

  @override
  String get emailSignupEmail => 'Email';

  @override
  String get emailSignupEmailPlaceholder => 'Your email address';

  @override
  String get emailSignupPassword => 'Password';

  @override
  String get emailSignupPasswordPlaceholder => 'Create a password';

  @override
  String get emailSignupPasswordHint =>
      'It must contain at least 8 carachters, including at least one digit, one uppercase letter and one special character.';

  @override
  String get emailSignupMarketing =>
      'I want to receive personalized offers and the latest updates from Ablony by email.';

  @override
  String get emailSignupTermsError => 'You must accept the terms to continue';

  @override
  String get emailSignupUsernameRequired => 'Username is required';

  @override
  String get emailSignupUsernameMinLength =>
      'Username must be at least 3 characters';

  @override
  String get emailSignupEmailRequired => 'Email is required';

  @override
  String get emailSignupEmailInvalid => 'Please enter a valid email';

  @override
  String get emailSignupPasswordRequired => 'Password is required';

  @override
  String get emailSignupPasswordMinLength =>
      'Password must be at least 7 characters';

  @override
  String get emailSignupPasswordNoDigit =>
      'Password must contain at least one digit';

  @override
  String get loginScreenTitle => 'Log in';

  @override
  String get loginScreenIdentifier => 'Identifier or email address';

  @override
  String get loginScreenIdentifierPlaceholder => 'Enter your email or username';

  @override
  String get loginScreenPassword => 'Password';

  @override
  String get loginScreenPasswordPlaceholder => 'Your password';

  @override
  String get loginScreenSubmit => 'Log in';

  @override
  String get loginScreenForgotPassword => 'Forgot your password?';

  @override
  String get loginScreenIdentifierRequired => 'This field is required';

  @override
  String get loginScreenPasswordRequired => 'Password is required';

  @override
  String get sellTitle => 'Sell an item';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get productTitle => 'Title';

  @override
  String get productTitleHint => 'Tell buyers what you\'re selling';

  @override
  String get productDescription => 'Describe your item';

  @override
  String get productDescriptionHint => 'Add useful information';

  @override
  String get category => 'Category';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get condition => 'Condition';

  @override
  String get conditionNew => 'New with tags';

  @override
  String get conditionExcellent => 'Excellent condition';

  @override
  String get conditionGood => 'Good condition';

  @override
  String get conditionFair => 'Fair';

  @override
  String get price => 'Price without shipping';

  @override
  String get priceHint => '0';

  @override
  String get publish => 'Publish';

  @override
  String get requiredField => 'This field is required';

  @override
  String get selectAtLeast1Photo => 'Select at least 1 photo';

  @override
  String get maxPhotosReached => 'Maximum 6 photos';

  @override
  String get brand => 'Brand';

  @override
  String get size => 'Size';

  @override
  String get color => 'Color';

  @override
  String get material => 'Material';

  @override
  String get length => 'Length';

  @override
  String get bagType => 'Bag type';

  @override
  String get jewelType => 'Jewelry type';

  @override
  String get movement => 'Movement';

  @override
  String get selectCondition => 'Select a condition';

  @override
  String get searchCategory => 'Search a category';

  @override
  String get selectSubcategory => 'Select a subcategory';

  @override
  String get publishing => 'Publishing...';

  @override
  String get priceWithoutShipping => 'Price without shipping';

  @override
  String get productPublishedSuccess => 'Product published successfully! 🎉';

  @override
  String get productPublishError => 'An error occurred while publishing';

  @override
  String get userNotConnected => 'User not connected';

  @override
  String get imageUploadError => 'Error uploading images';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get currency => 'FCFA';

  @override
  String selectAttributePlaceholder(String attributeName) {
    return 'Select $attributeName';
  }

  @override
  String enterAttributePlaceholder(String attributeName) {
    return 'Enter $attributeName';
  }

  @override
  String get indicateYourPrice => 'Indicate your price';

  @override
  String get priceFormatPlaceholder => '0.00 FCFA';

  @override
  String get validatePrice => 'Validate';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get categoryFemme => 'Women';

  @override
  String get categoryHomme => 'Men';

  @override
  String get seeAll => 'See all';

  @override
  String get subcategoryHaut => 'Top';

  @override
  String get subcategoryBas => 'Bottom';

  @override
  String get subcategoryChaussures => 'Shoes';

  @override
  String get subcategoryAccessoires => 'Accessories';

  @override
  String get subcategoryChemise => 'Shirt';

  @override
  String get subcategoryTshirt => 'T-shirt';

  @override
  String get subcategoryDebardeur => 'Tank top';

  @override
  String get subcategoryPull => 'Sweater';

  @override
  String get subcategoryVeste => 'Jacket';

  @override
  String get subcategoryPantalon => 'Pants';

  @override
  String get subcategoryJupe => 'Skirt';

  @override
  String get subcategoryShort => 'Shorts';

  @override
  String get subcategoryRobe => 'Dress';

  @override
  String get subcategoryBaskets => 'Sneakers';

  @override
  String get subcategorySandales => 'Sandals';

  @override
  String get subcategoryTalons => 'Heels';

  @override
  String get subcategorySac => 'Bag';

  @override
  String get subcategoryBijoux => 'Jewelry';

  @override
  String get subcategoryCasquette => 'Cap';

  @override
  String get subcategoryCeinture => 'Belt';

  @override
  String get subcategoryMontre => 'Watch';

  @override
  String get attributeEtat => 'Condition';

  @override
  String get attributeMarque => 'Brand';

  @override
  String get attributeTaille => 'Size';

  @override
  String get attributePointure => 'Shoe size';

  @override
  String get attributeCouleur => 'Color';

  @override
  String get attributeMatiere => 'Material';

  @override
  String get attributeLongueur => 'Length';

  @override
  String get attributeTypeSac => 'Bag type';

  @override
  String get attributeTypeBijou => 'Jewelry type';

  @override
  String get attributeMouvement => 'Movement';

  @override
  String get conditionNewWithTags => 'New with tags';

  @override
  String get conditionSatisfactory => 'Satisfactory';

  @override
  String get conditionUsed => 'Used';

  @override
  String conditionValue(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'newWithTags': 'New with tags',
      'excellent': 'Excellent',
      'good': 'Good',
      'satisfactory': 'Satisfactory',
      'worn': 'Used',
      'other': 'Good',
    });
    return '$_temp0';
  }

  @override
  String get helpTextCondition => 'General condition of the product';

  @override
  String get helpTextBrand => 'Select the product brand';

  @override
  String get helpTextSizeTop => 'Size for tops, shirts, sweaters, jackets';

  @override
  String get helpTextSizeBottom => 'Size for pants, shorts, skirts';

  @override
  String get helpTextShoeSize => 'Shoe size';

  @override
  String get helpTextColor => 'Main color of the product';

  @override
  String get helpTextMaterial => 'Main material of the product';

  @override
  String get helpTextLength => 'Length of dress or skirt';

  @override
  String get helpTextBagType => 'Bag type (handbag, backpack, etc.)';

  @override
  String get helpTextJewelryType =>
      'Jewelry type (necklace, ring, bracelet, etc.)';

  @override
  String get helpTextMovement => 'Watch movement type';

  @override
  String get lengthShort => 'Short';

  @override
  String get lengthMedium => 'Medium';

  @override
  String get lengthLong => 'Long';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorWhite => 'White';

  @override
  String get colorGray => 'Gray';

  @override
  String get colorBeige => 'Beige';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorNavyBlue => 'Navy blue';

  @override
  String get colorLightBlue => 'Light blue';

  @override
  String get colorRed => 'Red';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorKhakiGreen => 'Khaki green';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorMulticolor => 'Multicolor';

  @override
  String get colorGold => 'Gold';

  @override
  String get colorSilver => 'Silver';

  @override
  String get materialCotton => 'Cotton';

  @override
  String get materialPolyester => 'Polyester';

  @override
  String get materialWool => 'Wool';

  @override
  String get materialSilk => 'Silk';

  @override
  String get materialLinen => 'Linen';

  @override
  String get materialDenim => 'Denim';

  @override
  String get materialLeather => 'Leather';

  @override
  String get materialSuede => 'Suede';

  @override
  String get materialSynthetic => 'Synthetic';

  @override
  String get materialVelvet => 'Velvet';

  @override
  String get materialCashmere => 'Cashmere';

  @override
  String get materialViscose => 'Viscose';

  @override
  String get materialOther => 'Other';

  @override
  String get bagTypeHandbag => 'Handbag';

  @override
  String get bagTypeBackpack => 'Backpack';

  @override
  String get bagTypeClutch => 'Clutch';

  @override
  String get bagTypeTote => 'Tote bag';

  @override
  String get bagTypeCrossbody => 'Crossbody bag';

  @override
  String get bagTypeTravel => 'Travel bag';

  @override
  String get bagTypeSatchel => 'Satchel';

  @override
  String get jewelryTypeNecklace => 'Necklace';

  @override
  String get jewelryTypeBracelet => 'Bracelet';

  @override
  String get jewelryTypeEarrings => 'Earrings';

  @override
  String get jewelryTypeRing => 'Ring';

  @override
  String get jewelryTypeBrooch => 'Brooch';

  @override
  String get jewelryTypeWatchBracelet => 'Watch bracelet';

  @override
  String get watchMovementQuartz => 'Quartz';

  @override
  String get watchMovementAutomatic => 'Automatic';

  @override
  String get watchMovementManual => 'Manual';

  @override
  String get watchMovementDigital => 'Digital';

  @override
  String get brandOther => 'Other';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navSell => 'Sell';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String priceWithProtection(String price) {
    return '$price XOF incl.';
  }

  @override
  String get searchArticlesTab => 'Articles';

  @override
  String get searchMembersTab => 'Members';

  @override
  String get searchArticlesPlaceholder => 'Search for an article or member...';

  @override
  String get closeButton => 'Close';

  @override
  String get searchNoResults => 'No results found';

  @override
  String get searchTyping => 'Start typing to search...';

  @override
  String get filterTitle => 'Filter';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortRecent => 'Most recent';

  @override
  String get sortPriceAsc => 'Price: Low to High';

  @override
  String get sortPriceDesc => 'Price: High to Low';

  @override
  String get sortPopular => 'Most popular';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterSize => 'Size';

  @override
  String get filterBrand => 'Brand';

  @override
  String get filterCondition => 'Condition';

  @override
  String get filterColor => 'Color';

  @override
  String get filterPrice => 'Price';

  @override
  String get filterMaterial => 'Material';

  @override
  String get filterAll => 'All';

  @override
  String get filterAllCategories => 'All';

  @override
  String get filterCustomPrice => 'Custom';

  @override
  String get filterClear => 'Clear';

  @override
  String get filterShowResults => 'Show results';

  @override
  String get filterValidate => 'Validate';

  @override
  String resultsCount(int count) {
    return '$count results';
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
