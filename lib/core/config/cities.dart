import '../../features/auth/domain/entities/country.dart';

/// Une ville proposée à l'inscription.
///
/// [key] est la forme **normalisée** (minuscule, sans accent, sans espace) —
/// c'est ce qu'on stocke et compare (ex. géo-restriction « est-ce Lomé ? »).
/// [label] est l'affichage (ex. « Lomé »).
class CityOption {
  const CityOption(this.key, this.label);
  final String key;
  final String label;
}

/// Normalise un libellé de ville en clé comparable : minuscule, sans accent,
/// sans espace ni caractère spécial. « Lomé » → « lome », « Grand-Popo » →
/// « grandpopo ». Utilisée aussi bien pour bâtir les clés de la liste que pour
/// normaliser une saisie ou une valeur existante avant comparaison.
String normalizeCityKey(String input) {
  var s = input.trim().toLowerCase();
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ñ': 'n',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
    'œ': 'oe', 'æ': 'ae',
  };
  final buffer = StringBuffer();
  for (final ch in s.split('')) {
    buffer.write(accents[ch] ?? ch);
  }
  s = buffer.toString();
  // Ne garder que a-z et 0-9.
  return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Clé réservée à « Autre » (ville hors liste). Jamais couverte par la
/// livraison au lancement.
const String kCityOther = 'autre';

/// Villes où Ablony assure lui-même la livraison au lancement (mode « beg »).
/// Au démarrage : Lomé seulement. Extensible plus tard (admin/Firestore).
const Set<String> kCoveredCityKeys = {'lome'};

/// `true` si la ville (clé normalisée) est couverte par la livraison Ablony.
bool isCoveredCity(String? cityKey) {
  return cityKey != null && kCoveredCityKeys.contains(cityKey);
}

/// Villes proposées, par pays. Liste curée des principales villes ; « Autre »
/// couvre le reste. Extensible plus tard (admin/Firestore) sans changer le
/// reste du code.
const Map<Country, List<CityOption>> citiesByCountry = {
  Country.togo: [
    CityOption('lome', 'Lomé'),
    CityOption('sokode', 'Sokodé'),
    CityOption('kara', 'Kara'),
    CityOption('kpalime', 'Kpalimé'),
    CityOption('atakpame', 'Atakpamé'),
    CityOption('dapaong', 'Dapaong'),
    CityOption('tsevie', 'Tsévié'),
    CityOption('aneho', 'Aného'),
    CityOption('bassar', 'Bassar'),
    CityOption('notse', 'Notsé'),
    CityOption('tchamba', 'Tchamba'),
    CityOption('niamtougou', 'Niamtougou'),
    CityOption('sotouboua', 'Sotouboua'),
    CityOption('vogan', 'Vogan'),
    CityOption('badou', 'Badou'),
    CityOption(kCityOther, 'Autre'),
  ],
  Country.benin: [
    CityOption('cotonou', 'Cotonou'),
    CityOption('portonovo', 'Porto-Novo'),
    CityOption('parakou', 'Parakou'),
    CityOption('djougou', 'Djougou'),
    CityOption('bohicon', 'Bohicon'),
    CityOption('abomey', 'Abomey'),
    CityOption('abomeycalavi', 'Abomey-Calavi'),
    CityOption('kandi', 'Kandi'),
    CityOption('natitingou', 'Natitingou'),
    CityOption('lokossa', 'Lokossa'),
    CityOption('ouidah', 'Ouidah'),
    CityOption(kCityOther, 'Autre'),
  ],
};

/// Les villes d'un pays (repli : liste vide → au moins « Autre »).
List<CityOption> citiesForCountry(Country country) {
  return citiesByCountry[country] ?? const [CityOption(kCityOther, 'Autre')];
}

/// Le libellé d'affichage d'une clé de ville, pour un pays donné. Repli sur la
/// clé capitalisée si introuvable.
String cityLabelFromKey(Country country, String? key) {
  if (key == null || key.isEmpty) return '';
  for (final c in citiesForCountry(country)) {
    if (c.key == key) return c.label;
  }
  return key;
}
