# 19 — Le modèle d'une annonce

**Lot 1 · 3 jours · à faire en premier — tout le reste s'appuie dessus**

---

## Pourquoi cette fiche existe

Elle n'était pas prévue. Elle est née d'une question simple : *un vendeur qui
supprime son annonce, on archive aussi ?*

En cherchant la réponse, j'ai compté ce que coûte chaque modification de
l'état d'une annonce :

```
4 index composites, tous bâtis sur les trois booléens
   products → isSold, isReserved, isHidden, createdAt
   products → categoryId, isSold, isReserved, isHidden, createdAt
   products → categoryId, subcategoryId, isSold, isReserved, isHidden, createdAt
   products → isBoosted, isSold, isReserved, isHidden, boostExpiresAt

33 références dans le code — 19 côté Flutter, 14 côté fonctions.
```

Or trois chantiers du dossier veulent y toucher : la **modération**
(`moderationStatus`), l'**archivage** (suppression par le vendeur ou rejet),
et la **suspension** (masquer les annonces d'un vendeur sanctionné).

Trois passages, trois reconstructions d'index, et des composites à six champs.
Autant le faire une fois avec le bon modèle.

---

## Le modèle retenu

Trois champs, dont un seul est interrogé par les listes.

### `status` — le cycle de vie

| Valeur | Sens | Qui l'écrit |
|---|---|---|
| `active` | en vente | le vendeur, à la publication |
| `reserved` | réservée | le système, pendant un paiement |
| `sold` | vendue | le système, à la finalisation |
| `hidden` | retirée par son auteur | le vendeur |
| `archived` | supprimée par son auteur, ou rejetée et périmée | le vendeur, ou la tâche planifiée |

Un seul champ, donc **un seul état possible à la fois**. Les trois booléens en
permettaient huit combinaisons, dont « vendu et réservé » et « masqué et
vendu », que rien n'empêchait d'écrire.

### `moderationStatus` — ce que la modération décide

| Valeur | Sens |
|---|---|
| `pending` | jamais examinée — **l'annonce est en ligne malgré tout** |
| `approved` | examinée et conforme |
| `rejected` | non conforme, retirée de la vente |

Orthogonal au cycle de vie : une annonce peut être `sold` **et** `approved`.
Les mélanger dans un seul champ ferait perdre l'un des deux à chaque
changement de l'autre.

**Toujours écrit, jamais absent.** C'est le piège Firestore à connaître :
`where('approved', '==', false)` ne remonte **pas** les documents où le champ
manque, et `!=` les exclut également. Une file « jamais examinée » bâtie sur
un champ absent serait impossible à construire. Le champ vaut `pending` dès la
création.

### `isListable` — ce que les listes interrogent

Un booléen **calculé**, jamais écrit à la main :

```js
isListable = status === "active"
          && moderationStatus !== "rejected"
          && !vendeurSuspendu
```

Toutes les requêtes de liste passent alors de trois égalités à une :

```dart
.where('isListable', isEqualTo: true)
.orderBy('createdAt', descending: true)
```

Les quatre index rétrécissent, et la suspension d'un vendeur devient une
simple mise à jour de ses annonces au lieu d'une condition supplémentaire
partout.

**Une duplication assumée.** Le dossier dit ailleurs qu'une donnée dupliquée
est une donnée qui se désynchronise — c'est vrai. Elle se justifie ici parce
qu'**un seul écrivain la maintient** (le déclencheur) et qu'elle est lue par
*toutes* les requêtes de liste. C'est le cas d'école où la dénormalisation se
paie. Le jour où elle dérive, un script la recalcule à partir des trois
sources : rien n'est perdu.

---

## Les deux règles de suppression

| Cas | Comportement | Pourquoi |
|---|---|---|
| Annonce **vendue** | **Refus**, avec explication | Elle est liée à un reçu, une transaction, un colis. Elle n'apparaît déjà plus dans les listes : il n'y a rien à gagner à l'effacer, et un reçu d'acheteur qui pointe dans le vide à tout perdre. |
| Annonce **non vendue** | `status = "archived"` | Elle peut être en favori, citée dans une conversation, ou **signalée**. Un vendeur de contrefaçons qui efface son annonce efface la pièce à conviction. |

Le vendeur voit « Supprimer » dans les deux cas. Dans le premier il reçoit un
message clair ; dans le second l'annonce disparaît de partout où il la voyait.

---

## Fichier par fichier

### Correspondance des données

| Aujourd'hui | Demain |
|---|---|
| tout à `false` | `status: "active"` |
| `isReserved: true` | `status: "reserved"` |
| `isSold: true` | `status: "sold"` |
| `isHidden: true` | `status: "hidden"` |
| *(n'existe pas)* | `status: "archived"` |
| *(n'existe pas)* | `moderationStatus: "pending"` |

Les annonces existantes reçoivent `moderationStatus: "pending"` : elles
n'ont jamais été examinées, c'est la vérité.

### Script — `functions/scripts/backfill_product_status.js`

Sur le modèle de `backfill_product_visibility.js` qui existe déjà : même
compte de service (`tools/service-account.json`), même invocation **depuis la
racine du dépôt**.

```bash
node functions/scripts/backfill_product_status.js --dry-run
node functions/scripts/backfill_product_status.js
```

Parcourt `products` par lots de 400, écrit `status`, `moderationStatus` et
`isListable`. **Idempotent** : les annonces déjà reprises sont sautées, ce qui
le rend relançable après une interruption.

Il **conserve** les trois booléens dans un premier temps. On ne les retire
qu'une fois l'application publiée et adoptée — sinon une version ancienne
encore installée ne voit plus aucune annonce.

### Déclencheur — `functions/index.js`

```
onDocumentWritten("products/{id}")
  → recalcule isListable si status, moderationStatus
    ou la suspension du vendeur ont changé
```

Côté serveur et non côté client : un client pourrait mentir, et une annonce
écrite hors de l'application n'aurait pas le champ.

**Et une fonction `recomputeListableForSeller(uid)`**, appelée à la
suspension et à sa levée. Quelques écritures par vendeur — négligeable.

### Index — `firestore.indexes.json`

Remplacer les quatre :

```
products → isListable, createdAt DESC
products → categoryId, isListable, createdAt DESC
products → categoryId, subcategoryId, isListable, createdAt DESC
products → isBoosted, isListable, boostExpiresAt DESC
```

Plus, pour la file de modération :

```
products → moderationStatus, createdAt ASC
products → status, moderationStatus, updatedAt ASC   (pour la purge à 10 jours)
```

### Règles — `firestore.rules`

Dans `match /products/{productId}` :

```
// Le vendeur ne touche ni à son état de modération, ni au champ calculé.
allow update: if isOwner(resource.data.sellerId)
  && resource.data.status != 'sold'
  && resource.data.get('moderationStatus', 'pending') != 'rejected'
  && request.resource.data.get('moderationStatus', 'pending')
       == resource.data.get('moderationStatus', 'pending')
  && request.resource.data.get('isListable', false)
       == resource.data.get('isListable', false)
  && … (conditions existantes)

// On n'efface plus : on archive, par une mise à jour.
allow delete: if false;
```

`allow delete: if false` est la ligne qui fait le travail. L'archivage passe
par une mise à jour, donc par les conditions ci-dessus — et une annonce vendue
y est refusée.

### Application — fichiers à modifier

| Fichier | Modification |
|---|---|
| `lib/features/product/domain/entities/product.dart` | Remplacer les trois booléens par `ProductStatus status` et `ModerationStatus moderationStatus`. Garder des accesseurs `isSold`, `isHidden` dérivés du statut : **les 19 références du code continuent de compiler**, et on les nettoie ensuite tranquillement. |
| `lib/features/product/domain/entities/product_status.dart` | À créer : les deux énumérations, avec `fromWire` qui retombe sur une valeur sûre — une valeur inconnue ne doit jamais rendre une annonce visible. |
| `lib/features/product/data/models/product_model.dart` | Lire `status` si présent, sinon déduire des trois booléens *(les deux versions de l'application coexistent le temps de l'adoption)*. Écrire les deux formes. |
| `product_repository_impl.dart` | Les 19 requêtes : `.where('isListable', isEqualTo: true)` à la place des trois `.where(...)`. |
| `functions/index.js` | Les 14 références. Les vérifications d'achat deviennent `status == "active"`. |
| `lib/features/sell/…` | Le bouton « Supprimer » : message explicite si l'annonce est vendue. |

---

## L'ordre des opérations — à ne pas intervertir

1. **Déployer les nouveaux index** et attendre leur construction. Les anciens
   restent en place : les deux jeux coexistent.
2. **Déployer le déclencheur et la reprise**, lancer la reprise, vérifier sur
   quelques annonces que `isListable` vaut ce qu'on attend.
3. **Publier l'application** qui lit `status` et interroge `isListable`.
4. **Attendre l'adoption** — deux à quatre semaines.
5. **Seulement alors**, retirer les trois booléens et les anciens index.

Inversé, vous publiez une application qui n'affiche aucune annonce, et vous
attendez l'examen du magasin pour la corriger.

---

## Le piège de la transition, et le filet

*Constaté en production le 16 septembre 2026, sur un achat d'essai.*

Une fois la reprise passée, **toutes** les annonces portent `status`. Or le
déclencheur le calculait ainsi :

```js
const status = produit.status || statusFromLegacy(produit);
```

`produit.status` existant toujours, `statusFromLegacy` ne s'appliquait plus
jamais. Conséquence : **toute écriture qui ne basculait qu'un booléen hérité
était purement ignorée**. L'achat marquait `isSold: true`, `status` restait
`active`, et l'annonce vendue restait visible dans les listes — affichée « en
vente » à son vendeur, qui ne voyait donc pas son étiquette à imprimer.

Un seul défaut, deux symptômes qui n'avaient pas l'air liés.

Trois écrivains contournaient ainsi `status` : la finalisation d'achat, la
suppression de compte, et le « marquer comme vendu » de l'application. Tous
trois écrivent désormais les deux formes.

**Mais les corriger ne suffit pas.** L'application installée sur les
téléphones reste l'ancienne pendant des semaines, et c'est elle qui écrit.
`onProductWritten` rapproche donc les deux formes lui-même : si un booléen
hérité **change** dans une écriture et contredit `status`, c'est le booléen
qui exprime l'intention.

Deux précautions dans ce rattrapage :

- **Seul un booléen qui change compte.** Le déclencheur réécrit les trois à
  chaque passage ; les prendre en compte tels quels créerait une boucle.
- **La vente l'emporte.** Masquer une annonce vendue ne la remet pas en
  vente — l'ordre des tests le garantit.

Pour ce qui s'était déjà écrit, `functions/scripts/reconcilier_status.js`
répare : il n'y a pas d'écriture rétroactive. Idempotent, et `--dry-run`
montre ce qu'il changerait.

---

## Critères d'acceptation

- [ ] Après la reprise, chaque annonce a `status`, `moderationStatus` et `isListable`.
- [ ] Le fil d'accueil, la recherche et les listes par catégorie affichent exactement ce qu'ils affichaient avant.
- [ ] Une annonce vendue ne peut pas être supprimée — message explicite, et refus **vérifié par les règles** avec un jeton, pas seulement dans l'interface.
- [ ] Une annonce non vendue supprimée passe en `archived` et disparaît de toutes les listes, y compris de celles du vendeur.
- [ ] Une annonce archivée reste consultable depuis un reçu, une conversation et un signalement.
- [ ] Un vendeur ne peut modifier ni `moderationStatus` ni `isListable`.
- [ ] Une annonce `rejected` n'apparaît nulle part, même si `status == "active"`.
- [ ] Suspendre un vendeur fait disparaître ses annonces des listes en une opération.
- [ ] Une version ancienne de l'application continue de fonctionner tant que les booléens sont là.

## Pourquoi cette fiche est en premier

La [modération](17-moderation.md), les [sanctions](20-sanctions.md) et les
[tâches planifiées](21-taches-planifiees.md) écrivent toutes dans ces champs.
Les construire avant le modèle, c'est les réécrire après.
