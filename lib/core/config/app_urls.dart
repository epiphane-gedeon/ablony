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

  /// **L'adresse publique de l'application web elle-même.**
  ///
  /// À distinguer de [siteBase], qui désigne le site vitrine. Celle-ci est
  /// l'adresse à laquelle un utilisateur ouvre Ablony — et surtout celle qui
  /// part dans les liens partagés et les e-mails de réinitialisation. Un
  /// lien d'annonce envoyé sur WhatsApp porte cette adresse : c'est la plus
  /// visible de toutes.
  ///
  /// Surchargeable au build sans toucher au code :
  /// ```
  /// flutter build web --dart-define=APP_PUBLIC_URL=https://app.ablony.net
  /// ```
  /// Compilé plutôt que lu à l'exécution : ce n'est pas un secret, et cela
  /// évite d'ajouter un paquet et une étape de démarrage pour une valeur qui
  /// ne change qu'au déménagement.
  ///
  /// Pas de barre oblique finale.
  static const String appBase = String.fromEnvironment(
    'APP_PUBLIC_URL',
    defaultValue: 'https://ablony-a5db9.web.app',
  );

  /// Base des liens d'annonce partagés (`$appBase/product/<id>`).
  static const String productShareBase = '$appBase/product';

  /// Page d'atterrissage du lien de réinitialisation de mot de passe.
  static const String passwordReset = '$appBase/auth/reset-password';

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
