# 18 — Réparer la recherche

**Lot 1 · 3 jours · plus sautable depuis la cible de 2 500 comptes**

---

## Le problème

`lib/features/product/data/repositories/product_repository_impl.dart:278`

```dart
final snapshot = await _firestore
    .collection('products')
    .where('isSold', isEqualTo: false)
    .where('isReserved', isEqualTo: false)
    .where('isHidden', isEqualTo: false)
    .get();                                    // ← aucune limite

final results = snapshot.docs
    .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
    .where((product) { /* filtrage en mémoire */ })
    .toList();
```

Chaque recherche télécharge **toutes** les annonces disponibles, puis filtre
sur le téléphone. Aucune limite, aucune pagination, aucun index de texte.

À quoi s'ajoutent deux lectures complètes des collections `config/categories`
et `config/subcategories` — à chaque frappe si la recherche se déclenche au fil
de la saisie.

## Ce que ça coûte vraiment

Firestore facture **à la lecture de document**. Une recherche = une lecture par
annonce disponible.

| Annonces | Lectures par recherche | 200 recherches/jour | Sur un mois |
|---|---|---|---|
| 200 | 200 | 40 000 | 1,2 M |
| 1 000 | 1 000 | 200 000 | 6 M |
| 5 000 | 5 000 | 1 000 000 | **30 M** |

Le quota gratuit est de 50 000 lectures par jour. À mille annonces, vous le
dépassez avec cinquante recherches. À cinq mille, la facture devient un poste
de dépense — pour une fonctionnalité que vous n'avez pas encore.

Et avant la facture, il y a l'écran : télécharger cinq mille documents sur une
connexion mobile à Lomé prend plusieurs secondes, pendant lesquelles
l'application ne répond pas.

## Pourquoi ce n'est plus sautable

Cette fiche était en lot 3 tant que le volume attendu restait vague. La cible
de **2 500 comptes sur les premiers mois** l'a fait remonter.

2 500 comptes × 4 annonces × 60 % encore en vente ≈ **6 000 annonces
disponibles**. À ce volume :

```
Quota gratuit épuisé après 8 recherches par jour.
20 % des comptes qui cherchent 5×/jour → 15 000 000 lectures/jour → 269 $/mois
35 % des comptes qui cherchent 5×/jour → 26 250 000 lectures/jour → 472 $/mois
```

Et avant la facture, il y a l'écran : six mille documents sur une connexion
mobile à Lomé, c'est plusieurs secondes de gel à chaque recherche. **La
fonctionnalité devient inutilisable avant de devenir chère.**

Ce n'est plus une bombe à retardement, c'est une condition d'ouverture.

---

## La décision produit

**Un index de mots-clés dans le document, et une vraie pagination.** Pas de
moteur externe.

Algolia ou Typesense donneraient une bien meilleure recherche — tolérance aux
fautes, pertinence, facettes. Mais cela ajoute un service à exploiter, une
clé, une synchronisation, et un coût mensuel. Pour un catalogue de quelques
milliers d'articles où les gens cherchent « robe wax » ou « Nike 42 », un
tableau de mots-clés suffit largement.

**Ce qu'on ne fait pas :** pas de tolérance aux fautes de frappe, pas de
pertinence pondérée, pas de suggestions. La recherche restera littérale — et
c'est acceptable.

---

## Comment ça marche

### 1. Un champ `searchTokens` sur chaque annonce

À la création et à la modification, une Cloud Function calcule :

```js
function searchTokens(product, categoryName, subcategoryName) {
  const source = [
    product.title,
    product.attributes?.brand,
    product.attributes?.color,
    product.attributes?.material,
    product.size,
    categoryName,
    subcategoryName,
  ].filter(Boolean).join(" ");

  return [...new Set(
    source
      .toLowerCase()
      .normalize("NFD").replace(/[̀-ͯ]/g, "")   // « vêtement » → « vetement »
      .split(/[^a-z0-9]+/)
      .filter((mot) => mot.length >= 2)
  )].slice(0, 40);   // Firestore limite array-contains-any, et 40 suffit
}
```

La **suppression des accents** compte plus qu'il n'y paraît : personne ne tape
« vêtement » sur un clavier de téléphone.

La description est volontairement exclue : elle amène beaucoup de bruit pour
peu de trouvailles, et elle gonfle le tableau.

### 2. La requête

```dart
Future<List<Product>> searchProducts(String query, {String? startAfter}) async {
  final mots = normaliser(query).take(10).toList();   // limite Firestore
  if (mots.isEmpty) return const [];

  var q = _firestore
      .collection('products')
      .where('searchTokens', arrayContainsAny: mots)
      .where('isListable', isEqualTo: true)      // voir 19-modele-annonce.md
      .orderBy('createdAt', descending: true)
      .limit(20);
  // … startAfter
}
```

`arrayContainsAny` renvoie les annonces contenant **au moins un** des mots.
Pour « robe wax », cela ramène les robes *et* les articles en wax. Reclasser
en mémoire sur les vingt résultats — combien de mots correspondent — donne un
ordre satisfaisant pour un coût nul.

### 3. Ce qu'il faut ne pas oublier

**Les annonces existantes n'ont pas de `searchTokens`.** Il faut un script de
reprise qui parcourt la collection et le calcule. Le dépôt contient déjà
`functions/scripts/backfill_product_visibility.js` — prendre le même modèle.
Tant que la reprise n'est pas passée, les anciennes annonces sont
introuvables : **la faire avant de publier la nouvelle version**.

---

## Fichier par fichier

### Serveur — `functions/index.js`

| Quoi | Détail |
|---|---|
| `searchTokens()` | La fonction ci-dessus, en utilitaire. |
| `onProductWritten` | Déclencheur `onDocumentWritten("products/{id}")` qui recalcule `searchTokens` si le titre, les attributs, la taille ou la catégorie ont changé. Un déclencheur plutôt qu'un calcul côté client : le client pourrait mentir, et une annonce publiée hors de l'application serait introuvable. |

### Script — `functions/scripts/backfill_search_tokens.js`

Même compte de service et même invocation que le précédent, **depuis la
racine du dépôt** :

```bash
node functions/scripts/backfill_search_tokens.js --dry-run
node functions/scripts/backfill_search_tokens.js
```

`--force` recalcule même les annonces déjà pourvues — utile après un
changement de la tokenisation. Le script **signale les annonces sans aucun
mot-clé** : elles seraient introuvables, et c'est ce qu'on veut voir avant de
publier.

### Index — `firestore.indexes.json`

```
products → searchTokens ARRAY, isListable ASC, createdAt DESC
```

À déployer **avant** la nouvelle version de l'application, et laisser le temps
de la construction.

### Application — à modifier

| Fichier | Modification |
|---|---|
| `product_repository_impl.dart:278` | Remplacer `searchProducts` en entier. Ajouter `startAfter` et renvoyer aussi le curseur. |
| `lib/features/search/presentation/pages/search_results_page.dart` | Pagination au défilement. Charger les catégories **une fois** — pas à chaque recherche. |
| `lib/features/search/presentation/pages/searching_page.dart` | Déclencher après 300 ms de pause dans la frappe, pas à chaque lettre. |

---

## Critères d'acceptation

- [ ] Une recherche lit au plus 20 documents, vérifié dans la console Firebase.
- [ ] « vetement » trouve « Vêtement » ; « ROBE » trouve « robe ».
- [ ] La recherche par marque, couleur et taille fonctionne.
- [ ] Les résultats se paginent au défilement.
- [ ] Les catégories ne sont chargées qu'une fois par session.
- [ ] Taper « robe wax taille m » ne déclenche qu'une requête, pas quinze.
- [ ] Après la reprise, **toutes** les annonces existantes sont trouvables.
- [ ] Une annonce modifiée voit ses mots-clés recalculés.

## À faire après [19-modele-annonce.md](19-modele-annonce.md)

L'index de recherche s'appuie sur `isListable`. Le construire sur les trois
booléens obligerait à le reconstruire ensuite — et un index sur six mille
documents n'est pas instantané.

## Le piège de l'ordre des opérations

1. Déployer l'index — attendre sa construction.
2. Déployer le déclencheur.
3. Lancer la reprise — vérifier sur quelques annonces.
4. **Seulement ensuite**, publier l'application.

Inversé, vous livrez une recherche qui ne trouve rien, et vous ne pouvez pas
revenir en arrière tant que le magasin n'a pas examiné la version suivante.
