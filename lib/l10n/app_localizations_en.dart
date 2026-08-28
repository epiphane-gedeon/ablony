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
  String get clickToTranslate => 'Click here to translate';

  @override
  String get activelyPublishes => 'Actively publishes';

  @override
  String get sendsQuickly => 'Sends quickly';

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
  String get showDeliveryQrButton => 'Show QR code';

  @override
  String get confirmDeliveryButton => 'Confirm receipt';

  @override
  String get productAlreadySold => 'Item already sold';

  @override
  String get deliveryQrPageTitle => 'Handover code';

  @override
  String get deliveryQrInstructions =>
      'Have the buyer scan this code at handover to release the payment.';

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
}
