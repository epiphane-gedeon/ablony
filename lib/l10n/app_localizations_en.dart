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
      'It must contain at least 7 letters, including at least one digit.';

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
}
