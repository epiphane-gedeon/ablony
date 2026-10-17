import '../../l10n/app_localizations.dart';

/// Utilitaire pour traduire les noms de catégories, sous-catégories et attributs
/// venant de la base de données.
///
/// ## Stratégie de traduction des noms de catégories
///
/// Les noms sont stockés en français dans Firestore (champ `name`).
/// Le champ optionnel `nameEn` stocke directement la traduction anglaise
/// dans le document Firestore, ce qui évite de maintenir une liste
/// hardcodée dans le code.
///
/// Usage typique (catégorie) :
/// ```dart
/// CategoryTranslator.translate(l10n, category.id,
///   nameFr: category.name,
///   nameEn: category.nameEn,
/// )
/// ```
///
/// Si `nameEn` n'est pas renseigné dans Firestore, on retourne `nameFr`
/// comme fallback — ce qui garantit que l'app est toujours affichable,
/// même sur des catégories créées avant l'introduction de `nameEn`.
class CategoryTranslator {
  /// Retourne le nom localisé d'une catégorie ou sous-catégorie.
  ///
  /// - En **français** (ou toute locale non anglaise) : retourne [nameFr].
  /// - En **anglais** : retourne [nameEn] si disponible, sinon [nameFr].
  ///
  /// Les quelques catégories de niveau 1 (`femme`, `homme`) conservent
  /// une traduction hardcodée pour la rétrocompatibilité avec les écrans
  /// qui n'ont pas encore accès aux entités (ex : chips de filtre sur la home).
  static String translate(
    AppLocalizations l10n,
    String id, {
    required String nameFr,
    String? nameEn,
  }) {
    final isEnglish = l10n.localeName == 'en';

    // Traductions hardcodées pour les catégories racine (rétrocompatibilité)
    switch (id) {
      case 'femme':
        return l10n.categoryFemme;
      case 'homme':
        return l10n.categoryHomme;
      case 'all':
        return l10n.seeAll;
    }

    // Pour toutes les autres catégories/sous-catégories :
    // utilise nameEn si disponible et si locale EN, sinon nameFr.
    if (isEnglish && nameEn != null && nameEn.isNotEmpty) {
      return nameEn;
    }
    return nameFr;
  }

  /// Traduit les valeurs d'attributs (état du produit, couleurs, matières…)
  static String translateAttributeValue(
    AppLocalizations l10n,
    String value, [
    String? attributeId,
  ]) {
    final normalizedValue = _normalizeKey(value);

    switch (normalizedValue) {
      // Conditions
      case 'neufavecetiquette':
        return l10n.conditionNewWithTags;
      case 'excellentetat':
        return l10n.conditionExcellent;
      case 'bonetat':
        return l10n.conditionGood;
      case 'satisfaisant':
        return l10n.conditionSatisfactory;
      case 'use':
        return l10n.conditionUsed;

      // Longueurs
      case 'court':
        return l10n.lengthShort;
      case 'milong':
        return l10n.lengthMedium;
      case 'long':
        return l10n.lengthLong;

      // Couleurs
      case 'noir':
        return l10n.colorBlack;
      case 'blanc':
        return l10n.colorWhite;
      case 'gris':
        return l10n.colorGray;
      case 'beige':
        return l10n.colorBeige;
      case 'marron':
        return l10n.colorBrown;
      case 'bleu':
        return l10n.colorBlue;
      case 'bleumarine':
        return l10n.colorNavyBlue;
      case 'bleuclair':
        return l10n.colorLightBlue;
      case 'rouge':
        return l10n.colorRed;
      case 'rose':
        return l10n.colorPink;
      case 'violet':
        return l10n.colorPurple;
      case 'vert':
        return l10n.colorGreen;
      case 'vertkaki':
        return l10n.colorKhakiGreen;
      case 'jaune':
        return l10n.colorYellow;
      case 'orange':
        return l10n.colorOrange;
      case 'multicolore':
        return l10n.colorMulticolor;
      case 'dore':
        return l10n.colorGold;
      case 'argente':
        return l10n.colorSilver;

      // Matières
      case 'coton':
        return l10n.materialCotton;
      case 'polyester':
        return l10n.materialPolyester;
      case 'laine':
        return l10n.materialWool;
      case 'soie':
        return l10n.materialSilk;
      case 'lin':
        return l10n.materialLinen;
      case 'jean':
        return l10n.materialDenim;
      case 'cuir':
        return l10n.materialLeather;
      case 'daim':
        return l10n.materialSuede;
      case 'synthetique':
        return l10n.materialSynthetic;
      case 'velours':
        return l10n.materialVelvet;
      case 'cachemire':
        return l10n.materialCashmere;
      case 'viscose':
        return l10n.materialViscose;

      // Types de sacs
      case 'sacamain':
        return l10n.bagTypeHandbag;
      case 'sacados':
        return l10n.bagTypeBackpack;
      case 'pochette':
        return l10n.bagTypeClutch;
      case 'totebag':
        return l10n.bagTypeTote;
      case 'sacbandouliere':
        return l10n.bagTypeCrossbody;
      case 'sacdevoyage':
        return l10n.bagTypeTravel;
      case 'sacoche':
        return l10n.bagTypeSatchel;

      // Types de bijoux
      case 'collier':
        return l10n.jewelryTypeNecklace;
      case 'bracelet':
        return l10n.jewelryTypeBracelet;
      case 'bouclesdoreilles':
        return l10n.jewelryTypeEarrings;
      case 'bague':
        return l10n.jewelryTypeRing;
      case 'broche':
        if (attributeId == 'book_format') {
          return l10n.localeName == 'en' ? 'Paperback' : 'Broché';
        }
        return l10n.jewelryTypeBrooch;
      case 'montrebracelet':
        return l10n.jewelryTypeWatchBracelet;

      // Mouvements de montre
      case 'quartz':
        return l10n.watchMovementQuartz;
      case 'automatique':
        return l10n.watchMovementAutomatic;
      case 'manuel':
        return l10n.watchMovementManual;
      case 'numerique':
        return l10n.watchMovementDigital;

      // Langues
      case 'francais':
        return l10n.localeName == 'en' ? 'French' : 'Français';
      case 'anglais':
        return l10n.localeName == 'en' ? 'English' : 'Anglais';
      case 'bilingue':
        return l10n.localeName == 'en' ? 'Bilingual' : 'Bilingue';

      // Niveaux scolaires
      case 'maternelle':
        return l10n.localeName == 'en' ? 'Preschool' : 'Maternelle';
      case 'primaire':
        return l10n.localeName == 'en' ? 'Elementary' : 'Primaire';
      case 'college':
        return l10n.localeName == 'en' ? 'Middle school' : 'Collège';
      case 'lycee':
        return l10n.localeName == 'en' ? 'High school' : 'Lycée';
      case 'universite':
        return l10n.localeName == 'en' ? 'University' : 'Université';
      case 'concoursexamens':
      case 'concours':
        return l10n.localeName == 'en' ? 'Exams & competitions' : 'Concours & examens';

      // Formats de livres
      case 'relie':
        return l10n.localeName == 'en' ? 'Hardcover' : 'Relié';
      case 'poche':
        return l10n.localeName == 'en' ? 'Pocket edition' : 'Poche';
      case 'grandformat':
        return l10n.localeName == 'en' ? 'Large format' : 'Grand format';

      // Autres conditions
      case 'neufsansetiquette':
        return l10n.localeName == 'en' ? 'New without tags' : 'Neuf sans étiquette';
      case 'pourpieces':
        return l10n.localeName == 'en' ? 'For parts' : 'Pour pièces';

      // Autres
      case 'autre':
        return l10n.brandOther;
    }

    // Si pas de traduction, retourner la valeur originale
    return value;
  }

  /// Traduit les noms d'attributs (Marque, Taille, Couleur, Langue, Niveau…)
  static String translateAttributeName(AppLocalizations l10n, String name) {
    final normalizedKey = _normalizeKey(name);
    final isEn = l10n.localeName == 'en';

    switch (normalizedKey) {
      case 'etat':
      case 'condition':
        return l10n.attributeEtat;
      case 'marque':
      case 'brand':
      case 'techbrand':
        return l10n.attributeMarque;
      case 'taille':
      case 'size':
      case 'sizehaut':
      case 'sizebas':
      case 'sizeenfant':
        return l10n.attributeTaille;
      case 'pointure':
      case 'sizechaussures':
      case 'sizechaussuresenfant':
        return l10n.attributePointure;
      case 'couleur':
      case 'color':
        return l10n.attributeCouleur;
      case 'matiere':
      case 'material':
        return l10n.attributeMatiere;
      case 'longueur':
      case 'length':
      case 'dresslength':
      case 'hairlength':
        return l10n.attributeLongueur;
      case 'typedesac':
      case 'typesac':
      case 'bagtype':
        return l10n.attributeTypeSac;
      case 'typedebijou':
      case 'typebijou':
      case 'jewelrytype':
        return l10n.attributeTypeBijou;
      case 'mouvement':
      case 'watchmovement':
        return l10n.attributeMouvement;
      case 'langue':
      case 'language':
      case 'booklanguage':
        return isEn ? 'Language' : 'Langue';
      case 'niveau':
      case 'level':
      case 'schoollevel':
        return isEn ? 'Level' : 'Niveau';
      case 'format':
      case 'bookformat':
        return 'Format';
      case 'stockage':
      case 'storage':
        return isEn ? 'Storage' : 'Stockage';
      case 'type':
      case 'hairtype':
        return 'Type';
    }

    return name;
  }

  /// Traduit les help texts des attributs
  static String translateHelpText(
    AppLocalizations l10n,
    String attributeId,
    String? fallbackHelpText,
  ) {
    switch (attributeId) {
      case 'condition':
        return l10n.helpTextCondition;
      case 'brand':
        return l10n.helpTextBrand;
      case 'size_haut':
        return l10n.helpTextSizeTop;
      case 'size_bas':
        return l10n.helpTextSizeBottom;
      case 'size_chaussures':
        return l10n.helpTextShoeSize;
      case 'color':
        return l10n.helpTextColor;
      case 'material':
        return l10n.helpTextMaterial;
      case 'length':
        return l10n.helpTextLength;
      case 'bag_type':
        return l10n.helpTextBagType;
      case 'jewelry_type':
        return l10n.helpTextJewelryType;
      case 'movement':
        return l10n.helpTextMovement;
      default:
        return fallbackHelpText ?? '';
    }
  }

  /// Normalise une clé pour la recherche (minuscules, sans accents, sans espaces)
  static String _normalizeKey(String key) {
    return key
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('û', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll(' ', '');
  }
}
