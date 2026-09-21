import '../../features/auth/domain/entities/country.dart';

/// Interrupteurs de lancement.
///
/// Ce que l'on choisit de ne pas montrer **pour le moment**, sans rien
/// supprimer : le code reste en place et se rallume en changeant une ligne.
/// À distinguer des indisponibilités techniques, qui se déduisent de la
/// plateforme — comme `boostsDisponibles` dans
/// `features/product/domain/boost_config.dart`, imposé par les règles des
/// magasins et non par un choix de calendrier.
abstract final class FeatureFlags {
  /// Propose-t-on de choisir son pays à l'inscription ?
  ///
  /// Au lancement, Ablony s'adresse d'abord au Togo : demander le pays donnerait
  /// le choix entre une bonne réponse et une mauvaise. Tant que ce drapeau est
  /// à `false`, l'inscription retient [paysParDefaut] sans rien demander.
  ///
  /// À rallumer le jour de l'ouverture au Bénin — l'écran de choix existe
  /// toujours et reprendra sa place dans le parcours, sans autre modification.
  static const bool choixPaysActif = false;

  /// Le pays retenu quand on ne le demande pas.
  ///
  /// Le champ `country` reste renseigné en base exactement comme avant : rien
  /// dans le reste de l'application n'a à savoir que la question n'a pas été
  /// posée. Le jour où [choixPaysActif] repasse à `true`, les comptes créés
  /// entre-temps restent valides.
  static const Country paysParDefaut = Country.togo;
}
