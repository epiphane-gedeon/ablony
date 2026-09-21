/// Liens externes affichés dans l'app (pages du site public).
///
/// Centralisé ici plutôt que dispersé dans chaque écran : un seul endroit à
/// modifier si l'URL d'une page change. Une variable d'environnement (.env)
/// n'apporterait rien ici — ce ne sont pas des secrets, elles finissent de
/// toute façon dans le binaire compilé, et un fichier Dart classique reste
/// plus simple (pas de package supplémentaire, pas d'étape de build en
/// plus) tout en gardant la modification centralisée demandée.
abstract final class AppUrls {
  /// **Le seul endroit à modifier quand le site déménage.**
  ///
  /// Toutes les adresses ci-dessous en découlent : changer cette ligne suffit
  /// à les déplacer toutes, sans avoir à en chercher une oubliée dans un coin
  /// de l'application.
  ///
  /// Hébergement actuel : Firebase Hosting, en attendant le retour de
  /// `https://ablony.net`. Pas de barre oblique finale.
  ///
  /// Le site est passé d'InfinityFree à Firebase parce qu'InfinityFree répond
  /// d'abord par un défi JavaScript anti-robot : un navigateur finit par
  /// afficher la page, mais un robot reçoit 880 octets de script. Or Google
  /// Play vérifie automatiquement l'adresse de la politique de confidentialité
  /// — une page qu'il ne peut pas lire bloque la publication.
  static const String siteBase = 'https://ablony-site.web.app';

  /// Conditions générales d'utilisation.
  static const String termsOfService = '$siteBase/cgu.html';

  /// Politique de confidentialité.
  static const String privacyPolicy =
      '$siteBase/politique_confidentialite.html';

  /// Mentions légales.
  static const String legalNotice = '$siteBase/mention_legal.html';

  /// Aide et guide d'utilisation — les six questions les plus fréquentes.
  static const String helpCenter = '$siteBase/aide.html';

  /// Présentation d'Ablony.
  static const String about = '$siteBase/#how';

  /// Sélecteurs du header/footer communs aux pages légales (CGU, politique
  /// de confidentialité), à masquer dans la WebView pour n'afficher que le
  /// contenu utile — voir [WebViewPage.hideSelectors].
  static const List<String> legalPageHideSelectors = ['nav.navbar', 'footer.footer'];
}
