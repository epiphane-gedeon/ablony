# 10 — Retraits

**Lot 1 · bloquant · 4 jours**

---

## Le problème

Le bouton « Retirer » de l'écran porte-monnaie affiche une bulle
« bientôt disponible » (`wallet_page.dart:180`). Il n'existe **aucune**
fonction de retrait côté Firebase — zéro occurrence dans
`functions/index.js`.

Un vendeur peut donc encaisser, voir son solde monter, et n'a aucun moyen de
toucher cet argent. C'est le défaut le plus grave de l'application : il ne se
voit pas à l'installation, il se découvre après la première vente, et il
détruit la confiance exactement au moment où elle vient de se construire.

## La décision produit

**Le versement se fait à la main, l'application ne fait que l'encadrer.**

Vous n'avez pas la clé d'API du prestataire de versement. Ce n'est pas un
obstacle : à vos premiers volumes, quelques virements mobile money par semaine
se font en quelques minutes. Ce que l'application doit apporter, c'est le
reste — et c'est le reste qui est difficile à faire à la main :

- **retenir la somme dès la demande**, pour qu'elle ne puisse pas être
  dépensée deux fois ;
- **garder une trace** de qui a demandé quoi, quand, et vers quel numéro ;
- **rendre l'argent** si le versement échoue ou est refusé.

C'est exactement ce que fait le backend autonome. On reproduit sa logique, pas
son ampleur.

**Ce qu'on ne fait pas :** aucun appel au prestataire, aucun versement
automatique, aucune vérification d'identité au-delà de ce que le porte-monnaie
collecte déjà (prénom, nom, nationalité, date de naissance).

## Les règles

| Règle | Pourquoi |
|---|---|
| Montant minimum : **1 000 FCFA** | En dessous, les frais de transfert dépassent l'intérêt. |
| Le porte-monnaie doit être activé | Les informations d'identité servent au virement. |
| La somme quitte `availableAmount` **à la demande** | Sinon on peut demander deux retraits du même argent. |
| Le solde en attente n'est pas retirable | Il appartient à une vente non dénouée. |
| Un refus **rend** la somme | Et le motif est dit à la personne. |
| Une demande tranchée ne se retranche pas | Deux clics de l'administration ne doivent pas payer deux fois. |

## Le parcours

**Côté vendeur.** Porte-monnaie → « Retirer » → montant, moyen (T-Money,
Flooz, virement), numéro de destination → confirmation. Le solde baisse
immédiatement. La demande apparaît dans le relevé, à l'état « en cours ».

**Côté administration.** Une file des demandes en attente. Pour chacune : le
montant, le moyen, le numéro **en clair** (c'est là qu'on envoie l'argent), le
nom du titulaire. Deux actions : « versé » ou « refusé, avec motif ».

**Retour au vendeur.** Une notification dans les deux cas. En cas de refus, la
somme est de retour sur le solde, et le motif est lisible.

---

## Fichier par fichier

### Serveur — `functions/index.js`

Ajouter à la suite des fonctions existantes.

**`requestWithdrawal`** — appelée par le vendeur.

```
Entrée  : { amountXof, method: "tmoney"|"flooz"|"bank", destination }
Sortie  : { id, status: "requested" }
Vérifie : jeton valide · porte-monnaie activé · montant ≥ 1000
          · availableAmount ≥ montant
Écrit   : (dans une même db.runTransaction)
          users/{uid}.wallet.availableAmount -= montant
          withdrawals/{id} = { userId, amountXof, method, destination,
                               destinationMasked, holderName, status:"requested",
                               createdAt }
          transactions/{ref} = { type:"withdrawal", status:"pending", … }
Notifie : « Demande de retrait enregistrée »
```

Le masquage de la destination (`+228 90 ** ** 56`) sert l'affichage côté
vendeur ; le numéro complet reste sur le document, lisible seulement par
l'administration et par les Cloud Functions.

**`listWithdrawals`** — administration. Les demandes `requested`, les plus
anciennes d'abord. Vérifie `role == "admin"`.

**`settleWithdrawal`** — administration.

```
Entrée  : { withdrawalId, outcome: "paid"|"rejected", reason? }
Vérifie : role == "admin" · statut encore "requested"
Si paid     : withdrawals/{id}.status = "paid", paidAt, settledBy
              transactions/{ref}.status = "completed"
Si rejected : withdrawals/{id}.status = "rejected", reason
              users/{uid}.wallet.availableAmount += montant   ← on rend
              transactions/{ref}.status = "cancelled"
              + une transaction { type:"withdrawal_refund" } pour la trace
Notifie : « Retrait versé » ou « Retrait refusé : {motif} »
```

Le remboursement d'un refus doit être **dans la même transaction Firestore**
que le changement de statut. Séparés, un plantage entre les deux laisse une
somme nulle part.

### Règles — `firestore.rules`

```
match /withdrawals/{withdrawalId} {
  // Le demandeur lit les siennes. Le document porte le numéro complet :
  // c'est le sien, il peut le voir.
  allow read: if isAuthenticated()
    && resource.data.userId == request.auth.uid;

  // Rien ne s'écrit d'ici : un client capable de poser « paid »
  // s'offrirait un virement.
  allow create, update, delete: if false;
}
```

Et un index composite dans `firestore.indexes.json` :
`withdrawals` → `userId ASC, createdAt DESC`, plus
`withdrawals` → `status ASC, createdAt ASC` pour la file d'administration.

### Application — fichiers à créer

| Fichier | Rôle |
|---|---|
| `lib/features/wallet/domain/models/withdrawal.dart` | Modèle : id, montant, moyen, destination masquée, statut, motif, dates. Un `enum WithdrawalStatus` avec `fromWire`. |
| `lib/features/wallet/data/withdrawal_service.dart` | Les trois appels HTTP, sur le modèle de `parcel_scan_service.dart` (jeton Bearer, erreurs typées). |
| `lib/features/wallet/presentation/providers/withdrawal_provider.dart` | `withdrawalsProvider` (les siennes), `pendingWithdrawalsProvider` (administration). |
| `lib/features/wallet/presentation/pages/withdraw_page.dart` | Le formulaire : montant, moyen, numéro. Valide le minimum et le solde **avant** d'appeler — une erreur serveur sur un montant évident est une mauvaise expérience. |
| ~~`withdrawals_admin_page.dart`~~ | **Plus dans l'application mobile.** La file des retraits vit dans [`ablony_admin`](17-moderation.md). |

### Application — fichiers à modifier

| Fichier | Modification |
|---|---|
| `lib/features/wallet/presentation/pages/wallet_page.dart` | Ligne 176-184 : remplacer la bulle « bientôt disponible » par `context.pushNamed('withdraw')`. Garder le bouton désactivé si le porte-monnaie n'est pas activé, avec un libellé qui le dit. |
| `lib/core/navigation/app_router.dart` | Deux routes : `withdraw` sous `/profile/wallet`, et `withdrawals_admin` sous `/admin` (visible seulement si `user.role == UserRole.admin`). |
| `lib/features/profile/presentation/pages/profile_page.dart` | Retirer l'entrée « Espace personnel Ablony » : les files partent dans [`ablony_admin`](17-moderation.md). L'écran de scan des colis, lui, **reste dans l'application mobile** — un agent scanne avec son téléphone. |
| `lib/features/wallet/domain/models/wallet_entry.dart` | Ajouter `withdrawal` et `withdrawalRefund` à `WalletEntryKind`, et les traiter dans `fromTransaction`. Sans ça, un retrait n'apparaît pas au relevé — et c'est le premier endroit où on le cherchera. |
| `lib/l10n/app_fr.arb` et `app_en.arb` | Les libellés ci-dessous, puis `flutter gen-l10n`. |

### Traductions à ajouter

```
withdrawTitle              Retirer de l'argent
withdrawAmount             Montant à retirer
withdrawMethod             Moyen de réception
withdrawDestination        Numéro ou compte de destination
withdrawMinimum            Le minimum est de 1 000 FCFA
withdrawInsufficient       Votre solde disponible ne couvre pas ce montant
withdrawActivateFirst      Activez votre porte-monnaie pour pouvoir retirer
withdrawRequested          Demande enregistrée. Vous serez prévenu du versement.
withdrawPending            En cours de versement
withdrawPaid               Versé
withdrawRejected           Refusé
withdrawalsAdminTitle      Retraits en attente
withdrawMarkPaid           Marquer comme versé
withdrawReject             Refuser
withdrawRejectReason       Motif du refus
```

---

## Critères d'acceptation

- [ ] Un vendeur à 20 000 FCFA demande 15 000 : son solde passe à 5 000 **immédiatement**, avant tout versement.
- [ ] Il ne peut pas en demander 15 000 une seconde fois.
- [ ] Un vendeur à 20 000 en attente (vente non confirmée) et 0 disponible ne peut rien retirer.
- [ ] Une demande sous 1 000 FCFA est refusée, avec le minimum affiché.
- [ ] Un porte-monnaie non activé n'affiche pas le formulaire, et dit pourquoi.
- [ ] La file d'administration montre le numéro **en clair** et le nom du titulaire.
- [ ] Un refus rend la somme au solde et envoie le motif.
- [ ] Une demande déjà versée ne peut pas être versée une seconde fois.
- [ ] Le retrait apparaît au relevé du porte-monnaie, avec sa référence.
- [ ] Un membre non administrateur reçoit 403 sur `listWithdrawals` et `settleWithdrawal` — vérifié avec un vrai jeton, pas seulement en masquant le bouton.

## Ce qui reste à faire plus tard

Le branchement sur l'API de versement du prestataire, quand vous aurez la clé.
La structure ne changera pas : `settleWithdrawal` appellera le prestataire au
lieu d'attendre votre clic, et passera par un état `processing` entre
`requested` et `paid`.
