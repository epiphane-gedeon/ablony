# 11 — Litige acheteur

**Lot 1 · bloquant · 3 jours**

---

## Le problème

L'acheteur reçoit un article qui ne correspond pas à l'annonce. Il ouvre
l'application. Il ne trouve rien.

Le reçu propose « Confirmer la réception » — c'est-à-dire *payer le vendeur*.
Il n'y a aucune autre issue. Pas de bouton « j'ai un problème », pas de
formulaire, pas d'adresse où écrire.

Côté serveur, `refundPurchase` existe depuis la branche `correc` et fonctionne.
**Mais rien ne permet de la déclencher depuis l'application**, et rien
n'apprend à l'administration qu'un acheteur a un problème. La capacité de
rembourser existe sans le chemin qui y mène.

C'est ce qui sépare une place de marché d'un site d'annonces : sur un site
d'annonces, en cas de problème, chacun se débrouille.

## La décision produit

**L'acheteur signale, l'administration tranche.** Pas d'automatisme.

Aucun algorithme ne peut décider si une robe correspond à sa photo. À votre
volume, un humain regarde les photos et décide — c'est plus juste et moins
cher qu'une règle qui se trompera dans les deux sens.

Ce que l'application doit apporter :

- **un chemin visible** depuis la commande, au moment où le problème se pose ;
- **des photos**, parce qu'une description seule ne permet de trancher ni dans
  un sens ni dans l'autre ;
- **le gel** : tant qu'un litige est ouvert, ni la confirmation de l'acheteur
  ni un versement d'administration ne déplacent l'argent ;
- **une réponse**, dans un délai annoncé.

**Ce qu'on ne fait pas :** pas de retour du colis, pas de remboursement
partiel, pas de médiation dans la messagerie. L'argent va à l'un ou à
l'autre, entièrement.

## Les règles

| Règle | Pourquoi |
|---|---|
| Ouvrable par l'acheteur **et** le vendeur | Le vendeur aussi peut contester — un acheteur qui réclame sans motif, par exemple. |
| Ouvrable tant que la vente n'est pas dénouée | Après confirmation ou remboursement, il n'y a plus rien à geler. |
| Un litige ouvert **gèle** la vente | `confirmDelivery` et `releasePurchase` le refusent. |
| Un seul litige ouvert par vente | Rouvrir n'apporte rien ; on répond dans le même fil. |
| Deux issues : remboursé, ou versé au vendeur | Ablony ne garde jamais l'argent d'une vente contestée. |
| Motif obligatoire à la décision | Il part aux deux parties. |

## Le parcours

**Acheteur.** Reçu → « J'ai un problème avec cette commande » → choix du motif
(article non reçu · ne correspond pas à l'annonce · abîmé · autre) →
description → jusqu'à 4 photos → envoi. Le reçu affiche désormais « Litige en
cours d'examen », et le bouton de confirmation disparaît.

**Administration.** Une file des litiges ouverts. Pour chacun : le motif, la
description, les photos, le montant, l'état du colis, et **si l'acheteur a
scanné son étiquette** — ce dernier point tranche l'essentiel des dossiers
« jamais reçu ». Deux boutons : rembourser l'acheteur, ou verser au vendeur.

**Les deux parties** reçoivent la décision et son motif.

---

## Fichier par fichier

### Serveur — `functions/index.js`

**`openDispute`**

```
Entrée  : { transactionRef, reason, description, photoUrls[] }
Vérifie : jeton valide
          · l'appelant est acheteur OU vendeur de cette transaction
          · transaction.status == "completed"
          · pas de deliveryConfirmed, pas de refundedAt
          · pas de litige déjà ouvert
Écrit   : disputes/{transactionRef} = { transactionRef, buyerId, sellerId,
            openedBy, reason, description, photoUrls, status:"open", createdAt }
Notifie : l'autre partie
```

L'identifiant du document **est** la référence de transaction : une vente, un
litige. L'unicité est ainsi garantie par Firestore, sans vérification à
relire.

**`resolveDispute`** — administration.

```
Entrée  : { transactionRef, outcome: "refunded"|"released", note }
Vérifie : role == "admin" · litige encore "open"
Fait    : si refunded → appelle la logique de refundPurchase
          si released → appelle la logique de releasePurchase
          puis disputes/{ref}.status = outcome, resolvedAt, resolvedBy, note
Notifie : les deux parties, avec le motif
```

Réutiliser la logique existante plutôt que la recopier : sortir le corps de
`refundPurchase` et de `releasePurchase` dans deux fonctions internes
(`_refund(dbTx, tx, reason)`, `_release(dbTx, tx, reason)`) appelées par les
deux chemins. Deux implémentations du même mouvement d'argent finiraient par
diverger.

**`listDisputes`** — administration, les litiges `open`, plus anciens d'abord.
Appelée par [`ablony_admin`](17-moderation.md), pas par l'application mobile.

**Et surtout — le gel.** Dans `confirmDelivery`, dans `releasePurchase` **et
dans la libération automatique** de la [tâche planifiée](21-taches-planifiees.md),
ajouter au début de la transaction Firestore :

```js
const litige = await dbTx.get(db.collection("disputes").doc(transactionRef));
if (litige.exists && litige.data().status === "open") {
  throw new Error("Un litige est en cours d'examen sur cette commande");
}
```

Sans cette ligne, l'acheteur peut ouvrir un litige puis confirmer la
réception par mégarde, et payer le vendeur qu'il conteste.

### Règles — `firestore.rules`

```
match /disputes/{transactionRef} {
  // Les deux parties suivent leur dossier.
  allow read: if isAuthenticated()
    && (resource.data.buyerId == request.auth.uid
        || resource.data.sellerId == request.auth.uid);

  allow create, update, delete: if false;
}
```

Index : `disputes` → `status ASC, createdAt ASC`.

### Photos

Les photos de litige passent par Firebase Storage, dans
`disputes/{transactionRef}/{n}.jpg`. Ajouter à `storage.rules` : écriture par
l'acheteur ou le vendeur de la transaction, lecture par eux et par
l'administration. Réutiliser le sélecteur d'images existant
(`image_picker_grid.dart`) avec `maxImages: 4`.

### Application — fichiers à créer

| Fichier | Rôle |
|---|---|
| `lib/features/dispute/domain/models/dispute.dart` | Modèle + `enum DisputeReason` (`notReceived`, `notAsDescribed`, `damaged`, `other`) + `enum DisputeStatus`. |
| `lib/features/dispute/data/dispute_service.dart` | Les trois appels HTTP. |
| `lib/features/dispute/presentation/providers/dispute_provider.dart` | `disputeForTransactionProvider`, `openDisputesProvider` (administration). |
| `lib/features/dispute/presentation/pages/open_dispute_page.dart` | Motif, description (30 caractères minimum — « ça va pas » ne permet pas de trancher), photos, envoi. |
| ~~`disputes_admin_page.dart`~~ | **Plus dans l'application mobile.** La file des litiges vit dans [`ablony_admin`](17-moderation.md) — les modérateurs travaillent sur ordinateur, et un rôle qui voyage dans un client décompilable est une mauvaise idée. |

### Application — fichiers à modifier

| Fichier | Modification |
|---|---|
| `lib/features/receipt/presentation/pages/receipt_page.dart` | Sous le bouton de confirmation : « J'ai un problème avec cette commande ». Si un litige est ouvert, **masquer la confirmation** et afficher son état. |
| `lib/core/navigation/app_router.dart` | Route `open_dispute` (`/receipt/:receiptId/probleme`). |
| `storage.rules` | Le chemin `disputes/`. |
| `lib/l10n/*.arb` | Libellés ci-dessous. |

### Traductions

```
disputeOpen                J'ai un problème avec cette commande
disputeReason              Que s'est-il passé ?
disputeNotReceived         Je n'ai jamais reçu le colis
disputeNotAsDescribed      L'article ne correspond pas à l'annonce
disputeDamaged             L'article est arrivé abîmé
disputeOther               Autre
disputeDescription         Décrivez le problème
disputeDescriptionHint     Soyez précis : c'est ce qui permettra de trancher.
disputePhotos              Ajoutez des photos (jusqu'à 4)
disputePhotosHint          Une photo vaut mieux qu'une description.
disputeSubmitted           Votre signalement est enregistré. Réponse sous 48 heures.
disputeUnderReview         Litige en cours d'examen
disputeResolvedRefunded    Litige tranché : vous avez été remboursé
disputeResolvedReleased    Litige tranché en faveur du vendeur
disputesAdminTitle         Litiges ouverts
disputeRefundBuyer         Rembourser l'acheteur
disputeReleaseSeller       Verser au vendeur
disputeDecisionNote        Motif de la décision
```

---

## Critères d'acceptation

- [ ] Depuis un reçu non confirmé, l'acheteur ouvre un litige avec motif, description et photos.
- [ ] Le vendeur de la même vente peut aussi en ouvrir un.
- [ ] Un tiers ne peut pas : il reçoit « introuvable », pas « interdit ».
- [ ] Une fois le litige ouvert, le bouton « Confirmer la réception » disparaît du reçu.
- [ ] `confirmDelivery` sur une vente en litige échoue, même appelée directement avec un jeton valide.
- [ ] Un second litige sur la même vente est refusé.
- [ ] La file d'administration montre les photos et indique si l'acheteur a scanné son étiquette.
- [ ] « Rembourser » crédite l'acheteur, vide l'attente du vendeur, remet l'article en vente.
- [ ] « Verser » crédite le vendeur.
- [ ] Les deux parties reçoivent la décision **et son motif**.
- [ ] Un litige tranché ne se retranche pas.
- [ ] Un membre non administrateur reçoit 403 sur `resolveDispute`.

## Le point d'attention

Vous annoncez « réponse sous 48 heures ». C'est un engagement, pas un libellé.
Si personne ne regarde la file, l'acheteur qui a payé attend sans réponse, et
c'est pire que l'absence de bouton — il croyait avoir un recours.

Avec vos trois modérateurs, la file sera regardée. Décidez seulement **à
quelle heure**, et qui s'en charge le week-end.

*Note : la [tâche planifiée](21-taches-planifiees.md) supprime l'essentiel de
l'urgence — les colis non déposés se remboursent seuls, les remises constatées
se libèrent seules. Le litige redevient ce qu'il doit être : le cas
particulier, pas la soupape de tout le système.*
