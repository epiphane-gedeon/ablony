/// Barrel file pour les pages d'authentification.
///
/// Ce fichier permet d'importer toutes les pages d'authentification
/// en une seule ligne au lieu de plusieurs imports.
///
/// **Exemple d'utilisation :**
/// ```dart
/// // Au lieu de :
/// import '../pages/username_page.dart';
/// import '../pages/captcha_page.dart';
/// import '../pages/country_selection_page.dart';
///
/// // On peut faire :
/// import '../pages/pages.dart';
/// ```

export 'username_page.dart';
export 'email_signup_screen.dart';
export 'login_screen.dart';
export 'captcha_page.dart';
export 'country_selection_page.dart';
