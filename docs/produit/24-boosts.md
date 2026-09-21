# 24 — Boosts accumulables

**Après le premier flux de boost. Conception validée avec l'utilisateur le 17 septembre 2026.**

---

## Ce qui existe aujourd'hui

Un boost s'**achète et s'applique en un seul geste** : depuis une annonce, le
vendeur paie 500 F (porte-monnaie ou mobile money), et `finalizeBoost` pose
`isBoosted` + `boostExpiresAt` (48 h) directement sur ce produit. Il n'y a
**aucun solde** : on ne peut pas acheter d'avance, ni cumuler.

## Ce qu'on veut

- **Un solde de boosts** par utilisateur : on en achète plusieurs, on les garde
  pour plus tard.
- **Acheter** et **utiliser** deviennent deux gestes séparés.
- L'onglet **« Outils de promotion »** du profil devient le centre : voir son
  solde, en acheter, les dépenser sur ses annonces.
- Plus tard, un **abonnement premium** créditera des boosts dans le même solde
  — l'abonnement n'est pas construit maintenant, mais le solde l'attend.

## Le modèle

**Un champ `boostCredits` (entier) sur l'utilisateur.** Posé côté serveur
uniquement, gelé par les règles Firestore — comme le rôle et les badges. Un
client ne peut pas se créditer des boosts.

Deux mouvements, découplés :

### 1. Acheter — l'argent devient des crédits

`initiatePayment(type: "boost", quantity: N)` → montant = N × 500 F. À la
finalisation, **`boostCredits += N`**. Le produit n'est pas touché : on a
seulement rempli le solde. Fonctionne par porte-monnaie ou mobile money, comme
aujourd'hui.

### 2. Utiliser — un crédit met une annonce en avant

Nouvelle fonction `applyBoost({productId})`, **sans paiement** :

```
Vérifie : l'appelant est le vendeur du produit
          · le produit n'est pas vendu
          · boostCredits >= 1
Fait    : boostCredits -= 1
          produit.isBoosted = true, boostExpiresAt = maintenant + 48 h
```

Atomique : le crédit n'est débité que si le boost est posé.

## Les parcours

**Depuis une annonce (le bouton « Booster ») :**
- s'il reste des boosts → « Utiliser un boost (il vous en reste N) », instantané,
  gratuit ;
- sinon → « Acheter des boosts », qui mène à l'achat.

**Depuis « Outils de promotion » :**
- en tête : « Vous avez N boosts » ;
- « Acheter des boosts » — packs (1, 5, 10) ;
- la liste de ses annonces, chacune avec « Utiliser un boost » (si solde > 0)
  ou « En avant jusqu'au {date} » si déjà boostée.

## Compatibilité

- Les annonces déjà boostées gardent leur boost (on ne touche pas `isBoosted`
  existant).
- Les utilisateurs actuels démarrent à `boostCredits = 0` — rien à reprendre.
- L'ancien chemin « payer et booster ce produit tout de suite » est remplacé
  par « acheter un boost puis l'utiliser » — deux clics au lieu d'un, mais on
  peut enchaîner « acheter 1 » puis « utiliser » sans quitter l'écran.

## À construire

| Morceau | Où |
|---|---|
| Champ `boostCredits` + gel dans les règles | entité User, `firestore.rules` |
| `applyBoost` (nouvelle fonction, sans paiement) | `functions/index.js` |
| Achat → crédite le solde (au lieu de booster direct) | `finalizeBoost` → crédite `boostCredits` |
| `quantity` dans le paiement de type boost | `initiatePayment`, `boost_config` |
| Bouton « Booster » : utiliser un crédit ou en acheter | `boost_bottom_sheet.dart` |
| « Outils de promotion » : solde + achat de packs + application | `promotion_page.dart` |
| Tests | `applyBoost` consomme un crédit, refuse à zéro ; achat crédite |

## Décision d'attention

Le boost dure **48 h à partir du moment où on l'utilise**, pas de l'achat.
C'est tout l'intérêt d'accumuler : on achète en gros, on dépense au bon moment.
