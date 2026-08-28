/// Liens externes affichés dans l'app (pages web hébergées sur ablony.net).
///
/// Centralisé ici plutôt que dispersé dans chaque écran : un seul endroit à
/// modifier si l'URL d'une page change. Une variable d'environnement (.env)
/// n'apporterait rien ici — ce ne sont pas des secrets, elles finissent de
/// toute façon dans le binaire compilé, et un fichier Dart classique reste
/// plus simple (pas de package supplémentaire, pas d'étape de build en
/// plus) tout en gardant la modification centralisée demandée.
abstract final class AppUrls {
  /// Conditions générales d'utilisation.
  static const String termsOfService = 'https://ablony.net/cgu.html';

  /// Politique de confidentialité.
  static const String privacyPolicy =
      'https://ablony.net/politique_confidentialite.html';
}
