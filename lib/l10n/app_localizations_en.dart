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
  String get cityPickTitle => 'Your city';

  @override
  String get cityPickSubtitle =>
      'Choose your city. It helps us offer delivery where it\'s available.';

  @override
  String get citySearchHint => 'Search a city';

  @override
  String get cityErrorGeneric => 'Could not save your city. Please try again.';

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
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordDescription =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get resetPasswordEmailPlaceholder => 'Your email address';

  @override
  String get sendResetLink => 'Send link';

  @override
  String get resetEmailSentMessage =>
      'If an account exists with this email, a reset link has just been sent.';

  @override
  String get resetPasswordPageTitle => 'Reset password';

  @override
  String get resetPasswordPageDescription => 'Choose a new password.';

  @override
  String get resetPasswordNewPasswordPlaceholder => 'New password';

  @override
  String get resetPasswordConfirmPasswordPlaceholder => 'Confirm password';

  @override
  String get resetPasswordMismatch => 'Passwords don\'t match';

  @override
  String get resetPasswordSubmitButton => 'Reset';

  @override
  String get resetPasswordSuccessMessage =>
      'Password reset successfully. You can now log in.';

  @override
  String get resetLinkInvalidMessage =>
      'This reset link is invalid or has expired. Request a new one from the login page.';

  @override
  String get loginScreenForgotPassword => 'Forgot your password?';

  @override
  String get loginScreenIdentifierRequired => 'This field is required';

  @override
  String get loginScreenPasswordRequired => 'Password is required';

  @override
  String get sellTitle => 'Sell an item';

  @override
  String get clearDraft => 'Clear';

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
  String get searchArticlesPlaceholder => 'Search';

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
  String get noMessages => 'No messages';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get makeOfferTitle => 'Make an offer';

  @override
  String itemPrice(String price) {
    return 'Item price: $price';
  }

  @override
  String reductionLabel(int percent) {
    return '$percent% off';
  }

  @override
  String get otherOffer => 'Other';

  @override
  String get otherOfferHint => 'Suggest a price';

  @override
  String proposeButton(String amount) {
    return 'Propose $amount';
  }

  @override
  String get proposeButtonSimple => 'Propose';

  @override
  String offerLimitError(String minAmount, int limit) {
    return 'Your offer must be at least $minAmount (-$limit%)';
  }

  @override
  String suggestionsRemaining(int count) {
    return '$count suggestion(s) remaining today';
  }

  @override
  String get whyLink => 'Why?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileInfo => 'Profile information';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get payments => 'Payments';

  @override
  String get shipping => 'Shipping';

  @override
  String get security => 'Security';

  @override
  String get notifications => 'Notifications';

  @override
  String get mobile => 'Mobile';

  @override
  String get email => 'Email';

  @override
  String get appLanguage => 'App language';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get privacySettings => 'Privacy settings';

  @override
  String get logout => 'Log out';

  @override
  String appVersion(String version) {
    return 'App version: $version';
  }

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get cancel => 'CANCEL';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmMessage =>
      'This deletion is permanent: all your personal information will be replaced with generic data and you won\'t be able to sign back into this account. You can create a new account with the same credentials if you want to.';

  @override
  String get deleteAccountConfirmAction => 'DELETE';

  @override
  String get deleteAccountDoneTitle => 'Account deleted';

  @override
  String get deleteAccountDoneMessage =>
      'Your account has been deleted. You can create a new account with the same credentials at any time.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get favorites => 'Favorites';

  @override
  String get inviteFriends => 'Invite friends';

  @override
  String get myWallet => 'My wallet';

  @override
  String get salesAndPurchases => 'Sales and purchases';

  @override
  String get promotionTools => 'Promotion tools';

  @override
  String get personalization => 'Personalization';

  @override
  String get bundleDiscount => 'Bundle discount';

  @override
  String get vacationMode => 'Vacation mode';

  @override
  String get donations => 'Donations';

  @override
  String get ablonyGuide => 'Your Ablony guide';

  @override
  String get helpCenter => 'Help center';

  @override
  String get cookieSettings => 'Cookie settings';

  @override
  String get aboutUs => 'About us';

  @override
  String get legalInfo => 'Legal information';

  @override
  String get viewMyListings => 'View my listings';

  @override
  String get productNotFound => 'Product not found';

  @override
  String get markAsSold => 'Mark as sold';

  @override
  String get markAsReserved => 'Mark as reserved';

  @override
  String get cancelReservation => 'Cancel reservation';

  @override
  String get edit => 'Edit';

  @override
  String get hide => 'Hide';

  @override
  String get unhide => 'Republish';

  @override
  String get productHidden => 'Listing hidden';

  @override
  String get productUnhidden => 'Listing republished';

  @override
  String get productUnavailable => 'Product unavailable';

  @override
  String get soldBadge => 'Sold';

  @override
  String get reservedBadge => 'Reserved';

  @override
  String get hiddenBadge => 'Hidden';

  @override
  String get productMarkedAsSold => 'Product marked as sold';

  @override
  String get productMarkedAsReserved => 'Product marked as reserved';

  @override
  String get reservationCancelled => 'Reservation cancelled';

  @override
  String get productReserved => 'Product reserved';

  @override
  String get deleteProductConfirm => 'Delete product?';

  @override
  String get deleteProductBtn => 'DELETE';

  @override
  String get productDeletedSuccess => 'Product deleted successfully';

  @override
  String errorGenericMsg(String error) {
    return 'Error: $error';
  }

  @override
  String get walletConfig => 'Wallet configuration';

  @override
  String get enterFirstName => 'Please enter your first name';

  @override
  String get enterLastName => 'Please enter your last name';

  @override
  String get selectNationality => 'Please select a nationality';

  @override
  String get selectBirthDate => 'Please select your birth date';

  @override
  String get walletActivatedSuccess => 'Wallet successfully activated!';

  @override
  String get helpPageComingSoon => 'Help page coming soon';

  @override
  String get topUpComingSoon => 'Top-up feature coming soon';

  @override
  String get withdrawalComingSoon => 'Withdrawal feature coming soon';

  @override
  String get activatedStr => 'Activated';

  @override
  String get deactivatedStr => 'Deactivated';

  @override
  String get listings => 'Listings';

  @override
  String get reviews => 'Reviews';

  @override
  String get aboutTab => 'About';

  @override
  String get addItems => 'Add items...';

  @override
  String get verifiedInfo => 'Verified info:';

  @override
  String get pendingAmount => 'Pending Amount';

  @override
  String get pendingAmountInfo =>
      'When a buyer validates a purchase, the amount is put on hold until the reception and confirmation of the product.';

  @override
  String get learnMore => 'Learn more';

  @override
  String get availableAmount => 'Available Amount';

  @override
  String get activateWallet => 'Activate Wallet';

  @override
  String get topUpWallet => 'Top up';

  @override
  String get withdrawWallet => 'Withdraw';

  @override
  String get accountHolderFirstName => 'Account holder\'s first name(s)';

  @override
  String get accountHolderLastName => 'Account holder\'s last name';

  @override
  String get nationality => 'Nationality';

  @override
  String get selectNationalityPlaceholder => 'Select a nationality';

  @override
  String get birthDate => 'Birth Date';

  @override
  String get productDescriptionTitle => 'Description';

  @override
  String get readMore => 'more';

  @override
  String get readLess => 'less';

  @override
  String get productCategory => 'Category';

  @override
  String get productSize => 'Size';

  @override
  String get productCondition => 'Condition';

  @override
  String get productColor => 'Color';

  @override
  String get productAddedDate => 'Added';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get membersWardrobe => 'Member\'s wardrobe';

  @override
  String get similarItems => 'Similar items';

  @override
  String get boostProduct => 'Boost';

  @override
  String get boostedBadge => 'Boosted';

  @override
  String get boostSheetTitle => 'Boost this product';

  @override
  String boostSheetDescription(int hours) {
    return 'Your product will appear in featured slots for ${hours}h.';
  }

  @override
  String boostAlreadyActive(String date) {
    return 'This product is already boosted until $date.';
  }

  @override
  String get boostPay => 'Pay';

  @override
  String get boostSuccess => 'Product boosted successfully!';

  @override
  String get boostInsufficientBalance =>
      'Insufficient balance. Choose another payment method.';

  @override
  String boostCreditsBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts in reserve',
      one: '1 boost in reserve',
      zero: 'No boosts in reserve',
    );
    return '$_temp0';
  }

  @override
  String get boostUseCredit => 'Use a boost';

  @override
  String get boostUseCreditSubtitle => 'From your reserve, no payment';

  @override
  String boostPayOccasional(int price) {
    return 'Boost now · $price FCFA';
  }

  @override
  String get boostBuyPacks => 'Buy boosts';

  @override
  String boostCreditApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts',
      one: '1 boost',
      zero: 'no boosts',
    );
    return 'Boost applied! You have $_temp0 left.';
  }

  @override
  String get boostPackTitle => 'Buy boosts';

  @override
  String boostPackDescription(int hours) {
    return 'Buy boosts ahead of time and use them whenever you want, on any listing. Each boost features an item for ${hours}h.';
  }

  @override
  String get boostPackQuantity => 'Number of boosts';

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
    return 'Buy $_temp0 · $price FCFA';
  }

  @override
  String boostPackSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts added',
      one: '1 boost added',
    );
    return '$_temp0 to your reserve!';
  }

  @override
  String get promotionCreditsTitle => 'Your boosts in reserve';

  @override
  String get promotionUnavailable => 'Coming soon';

  @override
  String get promotionUnavailableHint =>
      'Listing promotion is coming to mobile soon. It is already available on the Ablony website.';

  @override
  String get promotionCreditsHint =>
      'Use them on any listing, whenever you want.';

  @override
  String get locationSearchHint => 'Search for a place or neighbourhood…';

  @override
  String locationSearchNoResult(String query) {
    return 'No place found for “$query”';
  }

  @override
  String get locationSearchFailed => 'Search failed. Check your connection.';

  @override
  String get shareProduct => 'Share';

  @override
  String shareProductSubtitle(String price, String condition) {
    return '$price FCFA ($condition)';
  }

  @override
  String get priceIncl => 'incl.';

  @override
  String get subtotalForBuyer => '(buyer subtotal)';

  @override
  String get deleteProductConfirmationMessage =>
      'Are you sure you want to delete this product? This action is irreversible.';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get minPrice => 'Minimum price';

  @override
  String get maxPrice => 'Maximum price';

  @override
  String get apply => 'Apply';

  @override
  String get resetFilter => 'Reset';

  @override
  String get priceFilterDevelopment => 'Price filter in development';

  @override
  String get noReviewsSubtitle =>
      'Ask the person you completed a successful transaction with to leave you a review.';

  @override
  String get messageButton => 'Message';

  @override
  String get buyerProtectionTitle => 'Buyer protection fees';

  @override
  String get buyerProtectionDescription =>
      'For any purchase made through the Buy button, we apply fees covering our Buyer Protection.';

  @override
  String get deleteProduct => 'Delete';

  @override
  String get makeOffer => 'Make an offer';

  @override
  String get buyNow => 'Buy';

  @override
  String get noProductsAvailable => 'No products available';

  @override
  String get timeAgoYear => '1 year ago';

  @override
  String timeAgoYears(int count) {
    return '$count years ago';
  }

  @override
  String timeAgoMonths(int count) {
    return '$count months ago';
  }

  @override
  String get timeAgoDay => '1 day ago';

  @override
  String timeAgoDays(int count) {
    return '$count days ago';
  }

  @override
  String get timeAgoHour => '1 hour ago';

  @override
  String timeAgoHours(int count) {
    return '$count hours ago';
  }

  @override
  String get timeAgoMinute => '1 minute ago';

  @override
  String timeAgoMinutes(int count) {
    return '$count minutes ago';
  }

  @override
  String get timeAgoJustNow => 'Just now';

  @override
  String get followButton => 'Follow';

  @override
  String get unfollowButton => 'Following';

  @override
  String followersCountLabel(int count) {
    return '$count followers';
  }

  @override
  String followingCountLabel(int count) {
    return '$count following';
  }

  @override
  String get followersPageTitle => 'Followers';

  @override
  String get followingPageTitle => 'Following';

  @override
  String get noFollowersYet => 'No followers yet';

  @override
  String get noFollowingYet => 'Not following anyone yet';

  @override
  String get receiptPageTitle => 'Receipt';

  @override
  String get receiptReference => 'Reference';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptSeller => 'Seller';

  @override
  String get receiptBuyer => 'Buyer';

  @override
  String get receiptPaymentMethod => 'Payment method';

  @override
  String get receiptProductPrice => 'Item price';

  @override
  String get receiptTotalPaid => 'Total paid';

  @override
  String get receiptDownloadButton => 'Download receipt';

  @override
  String get rateSellerPageTitle => 'Rate your seller';

  @override
  String rateSellerHeadline(String productTitle) {
    return 'How was your purchase of \"$productTitle\"?';
  }

  @override
  String get rateSellerCommentHint => 'Add a comment (optional)';

  @override
  String get rateSellerSubmitButton => 'Send my review';

  @override
  String get confirmDeliveryButton => 'I received my parcel';

  @override
  String get productAlreadySold => 'Item already sold';

  @override
  String get deliveryAlreadyConfirmed => 'Receipt confirmed';

  @override
  String get scanQrPageTitle => 'Scan code';

  @override
  String get scanQrInstructions =>
      'Scan the QR code shown by the seller to confirm receipt';

  @override
  String get deliveryConfirmedTitle => 'Receipt confirmed!';

  @override
  String get deliveryConfirmedMessage =>
      'Thank you! The payment has been released to the seller.';

  @override
  String get scanQrManualEntryButton => 'Enter receipt reference';

  @override
  String get scanQrManualEntryDialogTitle => 'Confirm with reference';

  @override
  String get scanQrManualEntryHint => 'Receipt reference';

  @override
  String get scanQrManualEntryError => 'Please enter a reference';

  @override
  String get reportProduct => 'Report this item';

  @override
  String get reportDialogTitle => 'Why are you reporting this item?';

  @override
  String get reportReasonCounterfeit => 'Counterfeit';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonScam => 'Potential scam';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportCommentHint => 'Details (optional)';

  @override
  String get reportSubmitButton => 'Send report';

  @override
  String get reportSuccessMessage =>
      'Report sent, thanks for keeping the community safe.';

  @override
  String get imageSourceCameraOption => 'Take a photo';

  @override
  String get imageSourceGalleryOption => 'Choose from gallery';

  @override
  String get photoMessage => '📷 Photo';

  @override
  String get sendMessagePlaceholder => 'Send a message';

  @override
  String get offerAcceptedSuccess => 'Offer accepted!';

  @override
  String get offerRejectedSuccess => 'Offer rejected';

  @override
  String get chatTitle => 'Chat';

  @override
  String get conversationNotFound => 'Conversation not found';

  @override
  String chatWelcomeMessage(String username) {
    return 'Hi! I\'m $username';
  }

  @override
  String memberSinceYear(int year) {
    return 'Member since $year';
  }

  @override
  String get systemMessage => 'System message';

  @override
  String heyUserMadeOffer(String name) {
    return 'Hey, $name made you an offer';
  }

  @override
  String get defaultUser => 'a user';

  @override
  String get offerStatusAccepted => 'Accepted';

  @override
  String get offerStatusRejected => 'Rejected';

  @override
  String get offerStatusPending => 'Pending';

  @override
  String get acceptButton => 'Accept';

  @override
  String get rejectButton => 'Reject';

  @override
  String get counterOffer => 'Counter offer';

  @override
  String get errorLoading => 'Error loading';

  @override
  String get pleaseLogin => 'Please log in';

  @override
  String get parcelLabelButton => 'View parcel label';

  @override
  String get receiptParcelCode => 'Parcel code';

  @override
  String get confirmDeliveryTitle => 'Confirm receipt';

  @override
  String get confirmDeliveryQuestion =>
      'Did your parcel arrive? Payment goes to the seller right away, and this cannot be undone.';

  @override
  String get confirmDeliveryConfirm => 'Yes, I got it';

  @override
  String get deliveryConfirmedSuccess =>
      'Receipt confirmed. The seller has been paid.';

  @override
  String get walletStatement => 'Statement';

  @override
  String get walletStatementEmpty => 'No activity yet';

  @override
  String get walletStatementEmptyDetail =>
      'Your purchases, sales and top-ups will show up here.';

  @override
  String get walletStatementError => 'Could not load your statement.';

  @override
  String get walletEntryTopUp => 'Top-up';

  @override
  String get walletEntryPurchase => 'Purchase';

  @override
  String get walletEntryBoost => 'Boost';

  @override
  String get walletEntrySale => 'Sale';

  @override
  String get walletEntryOnHold => 'on hold';

  @override
  String get scanParcelStaff => 'Scan a parcel';

  @override
  String get scanParcelBuyer => 'Scan my parcel';

  @override
  String get scanHintStaff => 'Point at the label stuck on the parcel.';

  @override
  String get scanHintBuyer =>
      'Point at your parcel\'s label to confirm you received it.';

  @override
  String get scanTorch => 'Torch';

  @override
  String get scanFailed => 'The scan failed. Try again.';

  @override
  String get checkpointRecorded => 'Step recorded.';

  @override
  String get parcelStatusLabel => 'Status';

  @override
  String get parcelDestinationRelay => 'Relay point';

  @override
  String get parcelDestinationHome => 'Home delivery';

  @override
  String get parcelRecordStep => 'Record a step';

  @override
  String get parcelNoStepLeft => 'This parcel has completed its journey.';

  @override
  String get parcelAwaitingDropoff => 'Awaiting drop-off';

  @override
  String get parcelDroppedOff => 'Dropped off';

  @override
  String get parcelInTransit => 'In transit';

  @override
  String get parcelReadyForPickup => 'Ready for pickup';

  @override
  String get parcelOutForDelivery => 'Out for delivery';

  @override
  String get parcelDelivered => 'Delivered';

  @override
  String get parcelReturned => 'Returned';

  @override
  String get parcelLost => 'Lost';

  @override
  String get stepDroppedOff => 'Drop-off';

  @override
  String get stepInTransit => 'Departure';

  @override
  String get stepArrived => 'Arrived at relay';

  @override
  String get stepOutForDelivery => 'Out for delivery';

  @override
  String get stepDelivered => 'Delivered';

  @override
  String get stepReturned => 'Return';

  @override
  String get stepLost => 'Lost';

  @override
  String get stuckParcelsTitle => 'Stuck parcels';

  @override
  String get stuckParcelsEmpty => 'Nothing pending. All moving.';

  @override
  String get stuckNeverDroppedOff => 'Never dropped off — deadline passed';

  @override
  String get stuckInTransitTooLong => 'In transit for too long';

  @override
  String get stuckWaitingAtRelay => 'Waiting at relay point';

  @override
  String get stuckBuyerScanned => 'scanned by buyer';

  @override
  String get staffTools => 'Ablony staff tools';

  @override
  String get walletEntryRefund => 'Refund';

  @override
  String get refundBuyer => 'Refund the buyer';

  @override
  String get refundReasonHint =>
      'This reason is sent to both buyer and seller. Explain, don\'t summarise.';

  @override
  String get refundReasonLabel => 'Reason';

  @override
  String get refundConfirm => 'Refund';

  @override
  String get refundDone => 'The buyer has been refunded.';

  @override
  String get parcelNoTrackingYet =>
      'Being prepared — detailed tracking appears at the first scan';

  @override
  String get releaseSeller => 'Pay the seller';

  @override
  String get releaseDone => 'The seller has been paid.';

  @override
  String get withdrawTitle => 'Withdraw money';

  @override
  String get withdrawAmount => 'Amount to withdraw';

  @override
  String get withdrawAll => 'Withdraw all';

  @override
  String get withdrawMethod => 'Payout method';

  @override
  String get withdrawDestination => 'Where to send the money';

  @override
  String get withdrawDestinationPhoneHint => '+228 90 00 00 00';

  @override
  String get withdrawDestinationBankHint => 'Account number or IBAN';

  @override
  String get withdrawAmountRequested => 'Requested amount';

  @override
  String get withdrawFee => 'Transfer fee';

  @override
  String get withdrawYouReceive => 'You receive';

  @override
  String get withdrawFeeExplained =>
      'This fee covers the transfer to your mobile money account. Withdrawing a larger amount at once costs proportionally less.';

  @override
  String get withdrawInsufficient =>
      'Your available balance does not cover this amount.';

  @override
  String get withdrawAlreadyPending =>
      'A request is already being processed. You can make another, but they will be paid out separately.';

  @override
  String get withdrawConfirm => 'Request withdrawal';

  @override
  String get withdrawManualNotice =>
      'Payouts are made manually, within 24 to 48 business hours.';

  @override
  String get withdrawActivateFirst => 'Activate your wallet to withdraw';

  @override
  String get withdrawPending => 'Being paid out';

  @override
  String get withdrawPaid => 'Paid';

  @override
  String get withdrawRejected => 'Declined';

  @override
  String withdrawMinimum(String amount) {
    return 'Minimum: $amount FCFA';
  }

  @override
  String withdrawRequested(String amount) {
    return 'Request recorded. You will receive $amount FCFA.';
  }

  @override
  String get walletEntryWithdrawal => 'Withdrawal';

  @override
  String get walletEntryWithdrawalRefund => 'Withdrawal declined';

  @override
  String get moderationCorrectionTitle => 'Listing needs fixing';

  @override
  String get moderationRemovedTitle => 'Listing removed';

  @override
  String get moderationCorrectionHint =>
      'Fix it and it goes back online automatically.';

  @override
  String get moderationRemovedHint => 'This listing cannot be put back online.';

  @override
  String get moderationCorrectionAction => 'Fix the listing';

  @override
  String get moderationReasonBlurryPhotos => 'Blurry or unusable photos';

  @override
  String get moderationReasonWrongCategory => 'Wrong category';

  @override
  String get moderationReasonMissingDescription => 'Description too thin';

  @override
  String get moderationReasonWrongPrice => 'Inconsistent price';

  @override
  String get moderationReasonCounterfeit => 'Counterfeit';

  @override
  String get moderationReasonProhibitedItem => 'Item not allowed for sale';

  @override
  String get moderationReasonInappropriate => 'Inappropriate content';

  @override
  String get moderationReasonFraud => 'Attempted fraud';

  @override
  String get moderationReasonOffPlatformSale => 'Off-platform sale';

  @override
  String get moderationReasonOther => 'Reason not specified';

  @override
  String get disputeOpen => 'I have a problem with this order';

  @override
  String get disputeTitle => 'Report a problem';

  @override
  String get disputeReason => 'What happened?';

  @override
  String get disputeNotReceived => 'I never received the parcel';

  @override
  String get disputeNotAsDescribed => 'The item does not match the listing';

  @override
  String get disputeDamaged => 'The item arrived damaged';

  @override
  String get disputeBuyerNotConfirming => 'The buyer isn\'t confirming receipt';

  @override
  String get disputeBuyerNoValidReason =>
      'The buyer is claiming without valid grounds';

  @override
  String get disputeOther => 'Other';

  @override
  String get disputeDescription => 'Describe the problem';

  @override
  String get disputeDescriptionHint => 'Be specific: this is what settles it.';

  @override
  String disputeDescriptionTooShort(int count) {
    return '$count more characters';
  }

  @override
  String get disputePhotos => 'Add photos (up to 4)';

  @override
  String get disputePhotosHint => 'A photo beats a description.';

  @override
  String get disputeSubmit => 'Send the report';

  @override
  String get disputeSubmitted =>
      'Your report is recorded. Answer within 48 hours.';

  @override
  String get disputeUnderReview => 'Dispute under review';

  @override
  String get disputeUnderReviewHint =>
      'We are reviewing your case. Answer within 48 hours.';

  @override
  String get disputeResolvedRefunded => 'Dispute settled: you were refunded';

  @override
  String get disputeResolvedReleased =>
      'Dispute settled in the seller\'s favour';

  @override
  String get disputeOpenedByOther =>
      'The other party opened a dispute on this order.';

  @override
  String get disputeSending => 'Sending…';

  @override
  String get blockUser => 'Block';

  @override
  String get unblockUser => 'Unblock';

  @override
  String blockConfirmTitle(String username) {
    return 'Block $username?';
  }

  @override
  String get blockConfirmBody =>
      'Neither of you will be able to write to the other. This person is not notified. An ongoing sale carries on as normal.';

  @override
  String blockDone(String username) {
    return '$username has been blocked.';
  }

  @override
  String get blockAlsoReport => 'Do you also want to report them to Ablony?';

  @override
  String get blockedUsersTitle => 'Blocked people';

  @override
  String get blockedUsersEmpty => 'You have not blocked anyone.';

  @override
  String get blockedUsersHint =>
      'Blocking someone closes messaging between you, both ways. Nobody is notified.';

  @override
  String get blockedConversation => 'You have blocked this person.';

  @override
  String get blockedByOther => 'You can no longer write in this conversation.';

  @override
  String get unblockDone => 'Unblocked.';

  @override
  String get reportUser => 'Report';

  @override
  String get later => 'Later';

  @override
  String get ordersTitle => 'Sales and purchases';

  @override
  String get ordersPurchases => 'Purchases';

  @override
  String get ordersSales => 'Sales';

  @override
  String get ordersNoPurchases => 'You have not bought anything yet';

  @override
  String get ordersNoPurchasesHint =>
      'What you buy shows up here, with delivery progress.';

  @override
  String get ordersNoSales => 'You have not sold anything yet';

  @override
  String get ordersNoSalesHint =>
      'List an item: as soon as it sells, you track it from here.';

  @override
  String orderDropOffBy(String date) {
    return 'Drop off before $date';
  }

  @override
  String get orderDropOffLate => 'Deadline passed — refund under way';

  @override
  String get orderPrintLabel => 'Print the label';

  @override
  String get orderInTransit => 'On its way';

  @override
  String get orderAwaitingPickup => 'Ready at the relay point';

  @override
  String get orderSellerPreparing => 'The seller is preparing your parcel';

  @override
  String get orderDeliveredWaiting => 'Delivered — payment to come';

  @override
  String get orderConfirmReception => 'Confirm receipt';

  @override
  String orderPaid(String amount) {
    return 'Paid: $amount FCFA';
  }

  @override
  String get orderReceived => 'Done';

  @override
  String orderRefunded(String amount) {
    return 'Refunded: $amount FCFA';
  }

  @override
  String get orderCancelled => 'Sale cancelled';

  @override
  String get orderTrack => 'Track';

  @override
  String get orderSee => 'View';

  @override
  String get ordersLoadMore => 'See more';

  @override
  String get promotionEmpty => 'No listing to promote';

  @override
  String get promotionEmptyHint =>
      'List an item: you can then push it up the listings.';

  @override
  String get promotionBoost => 'Promote';

  @override
  String promotionActiveUntil(String date) {
    return 'Promoted until $date';
  }

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get legalNotice => 'Legal notice';

  @override
  String get editProfileTitle => 'Profile information';

  @override
  String get editProfilePhoto => 'Profile photo';

  @override
  String get editProfileDisplayName => 'Display name';

  @override
  String get editProfileCity => 'City';

  @override
  String get editProfileSave => 'Save';

  @override
  String get editProfileSaved => 'Profile updated.';

  @override
  String get securityTitle => 'Security';

  @override
  String get securityCurrentPassword => 'Current password';

  @override
  String get securityNewPassword => 'New password';

  @override
  String get securityConfirmPassword => 'Confirm new password';

  @override
  String get securityChangePassword => 'Change password';

  @override
  String get securityPasswordChanged => 'Password changed.';

  @override
  String get securityMismatch => 'The two entries do not match.';

  @override
  String get securityTooShort => 'At least 8 characters.';

  @override
  String get securityWrongPassword => 'Current password is incorrect.';

  @override
  String securitySocialAccount(String provider) {
    return 'You sign in with $provider';
  }

  @override
  String get securitySocialHint =>
      'Your password is handled by that service. There is nothing to change here.';

  @override
  String get emailSettingsTitle => 'Email address';

  @override
  String get emailVerified => 'Address verified';

  @override
  String get emailNotVerified => 'Address not verified';

  @override
  String get emailNotVerifiedHint =>
      'Verify your address: sale and withdrawal alerts go through it.';

  @override
  String get emailResendLink => 'Resend the verification link';

  @override
  String get emailLinkSent => 'Link sent. Check your inbox.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'Nothing yet';

  @override
  String get notificationsEmptyHint =>
      'Your sales, purchases and messages will show up here.';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get timeAgoNow => 'just now';

  @override
  String get receiptPurchaseTitle => 'Purchase receipt';

  @override
  String get receiptSaleTitle => 'Sale summary';

  @override
  String get receiptTotalPaidLabel => 'Total paid';

  @override
  String get receiptYouReceive => 'You receive';

  @override
  String get receiptYouReceiveHint =>
      'The item price. Delivery and buyer-protection fees are paid by the buyer.';

  @override
  String get receiptDetails => 'Details';

  @override
  String get receiptParties => 'Parties';

  @override
  String get receiptDeliverySection => 'Delivery';

  @override
  String get receiptActions => 'Actions';

  @override
  String get founderBadge => 'Founder';

  @override
  String get starBadge => 'Star';

  @override
  String get paymentMethodSelectPrompt => 'Please select a payment method';

  @override
  String get paymentMethodTmoneyPrompt => 'Please enter your T-Money number';

  @override
  String get paymentMethodFloozPrompt => 'Please enter your Flooz number';

  @override
  String get paymentMethodTmoneyLabel => 'T-Money phone number';

  @override
  String get paymentMethodFloozLabel => 'Flooz phone number';

  @override
  String get locationCurrentFailed => 'Could not get your location';

  @override
  String get locationSelectPrompt => 'Please select a location';

  @override
  String get locationPickTitle => 'Choose a location';

  @override
  String get parcelLabelTitle => 'Parcel label';

  @override
  String get parcelLabelCopyCode => 'Copy code';

  @override
  String get parcelLabelCodeCopied => 'Code copied';

  @override
  String get notificationDeleted => 'Notification deleted';

  @override
  String get viewPublicProfile => 'View my public profile';

  @override
  String get boostBuyOnWeb =>
      'Boosts are purchased on the Ablony website (ablony.app).';

  @override
  String get parcelLabelDownload => 'Download label';

  @override
  String get parcelLabelError => 'Could not generate the label';

  @override
  String get addressFullName => 'Full name';

  @override
  String get deliveryPhoneLabel => 'Phone';

  @override
  String get deliveryPhoneRequired => 'Please enter a phone number';

  @override
  String get deliveryPhoneInvalid => 'Invalid phone number';

  @override
  String get deliveryContactLabel => 'Name and phone';

  @override
  String get deliveryContactPlaceholder => 'Add your contact details';

  @override
  String get deliveryContactTitle => 'Contact details';

  @override
  String get marketingEmailToggleTitle => 'Marketing emails';

  @override
  String get marketingEmailToggleSubtitle => 'Offers, news and promotions';

  @override
  String get addressEditLocation => 'Change location';

  @override
  String get paymentHomeDelivery => 'Home delivery';

  @override
  String get paymentPayDifference => 'Pay the difference';

  @override
  String get paymentInvoiceDetail => 'Invoice details';

  @override
  String get dynamicMissingSource => 'Missing data source';

  @override
  String get dynamicNoItems => 'No items found';

  @override
  String get walletTopUpTitle => 'Top up wallet';

  @override
  String get walletTopUpPrompt => 'Enter the amount to top up (min. 200 FCFA):';

  @override
  String get itemAlreadySold => 'This item has already been sold';

  @override
  String get offerSentSuccess => 'Offer sent successfully!';

  @override
  String get relayPointPickTitle => 'Choose a pickup point';

  @override
  String get captchaIncomplete => 'Please complete the captcha';

  @override
  String get favoritesSearchHint => 'Search favourites…';

  @override
  String get chatSafetyWarning =>
      'Never share an SMS code, a password or your bank details here. The Ablony team will never ask for them.';

  @override
  String get chatNotEncrypted => 'Messages are not end-to-end encrypted.';

  @override
  String get paymentWaitingTitle => 'Payment in progress in another tab';

  @override
  String get paymentWaitingBody =>
      'Complete the payment in the tab that just opened. This page updates by itself as soon as the payment is confirmed.';

  @override
  String get paymentWaitingBodyManual =>
      'Complete the payment in the tab that just opened, then come back here.';

  @override
  String get paymentReopen => 'Reopen the payment page';

  @override
  String get paymentCancel => 'Cancel payment';

  @override
  String get paymentOpenFailed =>
      'Could not open the payment page. Your browser may have blocked the window — allow it, then try again.';

  @override
  String get paymentOpenPage => 'Open the payment page';

  @override
  String get paymentVerifyingTitle => 'Payment being verified';

  @override
  String get paymentVerifyingBody =>
      'If your account was debited, the amount will be credited automatically as soon as we receive confirmation. There is nothing more to do, and nothing is lost.';

  @override
  String get paymentVerifyingDelay =>
      'Confirmation sometimes takes a few minutes, and up to an hour when the operator is slow.';

  @override
  String paymentReference(String reference) {
    return 'Reference: $reference';
  }

  @override
  String get paymentKeepReference => 'Keep this reference if you contact us.';

  @override
  String get paymentClose => 'Close';

  @override
  String get supportTitle => 'Ablony Support';

  @override
  String get supportHint => 'Describe your problem…';

  @override
  String get supportAttach => 'Attach a screenshot';

  @override
  String get supportWelcomeTitle => 'You are writing to the Ablony team';

  @override
  String get supportWelcomeEmpty =>
      'Explain what happened and attach a screenshot if you were debited — that is what settles things fastest. We reply within 24 working hours.';

  @override
  String get supportWelcomeDelay => 'We reply within 24 working hours.';

  @override
  String get supportOpen => 'Contact support';

  @override
  String supportPaymentPrefill(String reference) {
    return 'Hello, I was debited but my payment still shows as pending.\n\nReference: $reference\n\n(Attach the debit screenshot here.)';
  }

  @override
  String get paymentCardRedirectNotice =>
      'You will enter your card on our payment provider\'s secure page. Ablony never sees or stores your card details.';

  @override
  String get paymentMethodCardName => 'Name on card';

  @override
  String get paymentMethodCardNumber => 'Card number';

  @override
  String get paymentMethodCardCvv => 'Security code';
}
