# 22 — Contrat d'API entre les deux flux

**À figer le jour 1 · c'est ce qui rend le parallélisme possible**

---

## À quoi sert ce fichier

Deux personnes travaillent en même temps : l'une écrit les Cloud Functions et
l'application mobile, l'autre construit `ablony_admin`. Sans contrat écrit, la
seconde attend la première.

Ce document fige **les entrées, les sorties et les erreurs** de chaque
fonction appelée par l'administration. Il permet de développer l'interface
contre des réponses simulées, et de brancher les vraies sans rien réécrire.

**Il fait foi.** Si l'implémentation diverge, c'est l'implémentation qui a
tort — ou ce fichier est modifié explicitement, et l'autre personne est
prévenue le jour même.

---

## Conventions communes

**Transport.** HTTPS `onRequest`, méthode `POST`, corps JSON. Pas de
`onCall` : l'administration est une application web classique, et `onRequest`
se teste avec `curl`.

**Authentification.** En-tête `Authorization: Bearer <idToken>` — le jeton
Firebase de la personne connectée. Le rôle est **relu en base** à chaque
appel, jamais pris dans le jeton : un rôle retiré cesse d'agir immédiatement.

**Réponse en cas de succès**

```json
{ "success": true, "data": { … } }
```

**Réponse en cas d'échec**

```json
{ "success": false, "error": { "code": "…", "message": "…" } }
```

| Statut | Quand |
|---|---|
| `400` | Paramètre manquant ou invalide |
| `401` | Jeton absent ou invalide |
| `403` | Rôle insuffisant |
| `404` | Ressource inconnue — **ou qui ne concerne pas l'appelant** |
| `409` | Conflit : déjà traité, déjà réservé, état incompatible |

`404` plutôt que `403` pour une ressource qui existe mais ne concerne pas
l'appelant : un refus explicite confirmerait son existence.

**Dates.** Toujours en ISO 8601 UTC (`2026-09-16T08:30:00.000Z`). Jamais un
`Timestamp` Firestore brut : il ne traverse pas JSON proprement.

**Montants.** Entiers en francs CFA. Le XOF n'a pas de décimale, et un
flottant sur de l'argent finit toujours par coûter un centime à quelqu'un.

---

## Rôles

| Rôle | Valeur dans `users/{uid}.role` |
|---|---|
| Membre | absent, ou `"member"` |
| Modérateur | `"moderator"` |
| Administrateur | `"admin"` |

`admin` peut tout ce que peut `moderator`. Un rôle inconnu vaut `member` —
une valeur inattendue ne doit jamais ouvrir de portes.

---

## Modération — rôle `moderator`

### `moderationQueue`

Les annonces à examiner. Les signalées d'abord, puis les nouveaux vendeurs,
puis par ancienneté.

```
POST /moderationQueue
{ "limit": 50, "cursor": "…"? }

→ { "items": [ {
      "productId":     "abc123",
      "sellerId":      "uid",
      "sellerUsername":"amivi",
      "title":         "Robe wax taille M",
      "priceXof":      12000,
      "categoryPath":  "Femme › Robes",
      "imageUrl":      "https://…",
      "moderationStatus": "pending",
      "reportCount":   0,
      "reportReasons": [],
      "sellerWarnings":    1,
      "sellerSuspensions": 0,
      "isNewSeller":   true,
      "claimedBy":     null,
      "claimedByName": null,
      "createdAt":     "2026-09-16T08:30:00.000Z"
    } ],
    "nextCursor": "…" | null }
```

`sellerWarnings` et `sellerSuspensions` sont **sur la ligne**, pas derrière un
lien : c'est ce qui permet de décider sans ouvrir une seconde page.

### `reportsQueue`

Même forme, groupée par annonce, filtrée sur celles qui ont au moins un
signalement ouvert. `reportCount` et `reportReasons` sont alors renseignés.

`reportReasons` prend ses valeurs dans :
`prohibited_item` · `counterfeit` · `inappropriate` · `misleading` · `spam` · `other`

### `reviewProduct`

**La fonction centrale.** Une décision sur une annonce.

```
POST /reviewProduct
{ "productId": "abc123",
  "decision":  "approve" | "correction" | "violation",
  "reason":    "counterfeit",        // requis sauf pour approve
  "note":      "Logo et coutures."   // requis sauf pour approve, 10 à 500 car.
}

→ { "moderationStatus": "approved" | "rejected",
    "warningIssued":    false,
    "sellerSuspended":  false,
    "sellerWarnings":   1 }
```

| Décision | Effet |
|---|---|
| `approve` | `moderationStatus = "approved"`. **Aucune notification** — le vendeur n'a pas à savoir qu'on l'a regardé. |
| `correction` | `rejected`, notification avec le motif, **aucun avertissement**. Il peut republier corrigé. |
| `violation` | `rejected`, notification, **un avertissement**. Suspension automatique au deuxième. |

Motifs acceptés pour `correction` :
`blurry_photos` · `wrong_category` · `missing_description` · `wrong_price`

Pour `violation` :
`counterfeit` · `prohibited_item` · `inappropriate` · `fraud` · `off_platform_sale`

**Erreurs** — `409 moderation.already_reviewed` si un autre modérateur a
tranché depuis le chargement de la file ; `409 moderation.claimed_by_other`
si la réservation appartient à quelqu'un d'autre.

### `claimItem` et `releaseClaim`

La réservation, pour que deux modérateurs ne travaillent pas sur la même
annonce.

```
POST /claimItem      { "productId": "abc123" }
→ { "claimedUntil": "2026-09-16T08:35:00.000Z" }

POST /releaseClaim   { "productId": "abc123" }
→ { "released": true }
```

La réservation **expire au bout de 5 minutes**. Sans expiration, un onglet
fermé bloque une annonce pour toujours. L'interface la renouvelle tant que la
fiche est ouverte.

`409 moderation.claimed_by_other` si elle est déjà prise et non expirée.

### `sellerHistory`

```
POST /sellerHistory  { "sellerId": "uid" }

→ { "username": "amivi",
    "accountStatus": "active" | "suspended" | "banned",
    "suspendedUntil": null | "2026-09-26T…",
    "warnings":   [ { "reason": "counterfeit", "note": "…",
                      "productTitle": "…", "createdAt": "…" } ],
    "suspensions":[ { "reason": "…", "startedAt": "…", "endsAt": "…" } ],
    "productCount": 12,
    "salesCount":   3 }
```

---

## Litiges — rôle `admin`

### `listDisputes`

```
POST /listDisputes   { "limit": 50 }

→ { "items": [ {
      "transactionRef": "TX-ACH-20260916-A1B2",
      "openedBy":       "buyer" | "seller",
      "buyerId": "…",  "buyerUsername": "…",
      "sellerId":"…",  "sellerUsername":"…",
      "reason":  "not_as_described",
      "description": "…",
      "photoUrls":   [ "https://…" ],
      "amountXof":   12000,
      "productTitle":"Robe wax taille M",
      "parcelStatus":"delivered",
      "buyerScannedAt": "2026-09-14T…" | null,
      "createdAt": "…"
    } ] }
```

`buyerScannedAt` **tranche l'essentiel des dossiers « jamais reçu »** : si
l'acheteur a scanné l'étiquette du colis, il l'avait en main.

Motifs : `not_received` · `not_as_described` · `damaged` · `other`

### `resolveDispute`

```
POST /resolveDispute
{ "transactionRef": "TX-…",
  "outcome": "refunded" | "released",
  "note":    "Photos concluantes."      // 10 à 500 caractères, requis
}
→ { "outcome": "refunded", "amountXof": 12000 }
```

Deux issues seulement. L'argent va à l'un ou à l'autre — Ablony ne garde
jamais le montant d'une vente contestée.

`409 dispute.not_open` si le litige est déjà tranché.

---

## Retraits — rôle `admin`

### `listWithdrawals`

```
POST /listWithdrawals  { "limit": 50 }

→ { "items": [ {
      "id": "w_abc",
      "userId": "uid",  "username": "kodjo",
      "holderName": "Kodjo MENSAH",        // ce que le vendeur a déclaré
      "amountXof": 15000,
      "method": "tmoney" | "flooz" | "bank",
      "destination": "+22890123456",        // EN CLAIR — c'est là qu'on envoie
      "status": "requested",
      "createdAt": "…"
    } ] }
```

Le numéro est **en clair** : cette file sert à effectuer le virement à la
main. C'est aussi pourquoi elle est réservée à `admin`.

### `settleWithdrawal`

```
POST /settleWithdrawal
{ "withdrawalId": "w_abc",
  "outcome": "paid" | "rejected",
  "reason":  "Numéro incorrect."      // requis si rejected
}
→ { "status": "paid" | "rejected", "amountXof": 15000, "refunded": false }
```

`refunded` vaut `true` sur un refus : la somme est revenue au solde du
vendeur. `409 withdrawal.not_pending` si la demande est déjà tranchée.

---

## Bannissement — rôle `admin`

### `banUser`

```
POST /banUser  { "userId": "uid", "reason": "…" }   // 10 à 500 caractères

→ { "status": "banned" }
```

**Deux refus possibles, et ils sont impératifs :**

| Code | Quand |
|---|---|
| `409 user.has_balance` | Solde disponible ou en attente non nul. Bannir quelqu'un qui détient 40 000 FCFA, c'est se les approprier. |
| `409 user.has_active_sale` | Une vente est en cours. Un acheteur a payé et attend son article. |

Dans les deux cas, la réponse porte le détail :

```json
{ "success": false,
  "error": { "code": "user.has_balance",
             "message": "Ce compte détient 40 000 FCFA.",
             "details": { "availableXof": 40000, "pendingXof": 0 } } }
```

L'interface propose alors une **suspension prolongée** à la place.

---

## Colis bloqués — rôle `admin`

### Renvois après correction

`moderationQueue` et `reportsQueue` ajoutent deux champs sur chaque ligne :

```
resubmittedAt   : "2026-09-16T…"  — nul si l'annonce n'a jamais été corrigée
previousReason  : "wrong_category" — ce qu'on avait demandé
```

Et la notification `product_rejected` porte désormais `decision`
(`"correction"` ou `"violation"`) : c'est ce qui permet à l'application
d'ouvrir le formulaire de modification plutôt que la simple fiche.

`stuckParcels` existait déjà sur la branche `correc`, mais divergeait de ce
contrat sur deux points, corrigés depuis : elle renvoyait un tableau nu au
lieu de `{ items: [...] }`, et son préliminaire CORS n'annonçait que `GET`,
ce qui faisait refuser par le navigateur le POST de la console. Les deux
appelants — l'application mobile en GET, la console en POST — sont désormais
servis.

```
POST /stuckParcels   (corps vide)

→ { "items": [ { "code": "AB-K7M2P-X4R9T",
                 "transactionRef": "TX-…",
                 "productTitle": "…",
                 "status": "awaiting_dropoff",
                 "method": "relay",
                 "reason": "never_dropped_off" | "in_transit_too_long"
                           | "waiting_at_relay",
                 "buyerScannedAt": null,
                 "createdAt": "…" } ] }
```

Avec la [tâche planifiée](21-taches-planifiees.md), cette file se vide
largement seule. Elle reste utile pour ce que l'automatisme ne couvre pas.

---

## Développer sans attendre les vraies fonctions

Un fichier de réponses simulées, une bascule par variable d'environnement :

```ts
// src/api/functions.ts
const SIMULE = import.meta.env.VITE_MOCK === "1";

export async function moderationQueue(limit = 50) {
  if (SIMULE) return (await import("./mocks/moderationQueue.json")).default;
  return post("moderationQueue", { limit });
}
```

Les fichiers de simulation reprennent **exactement** les formes ci-dessus, y
compris les cas limites : une file vide, une annonce déjà réservée, un vendeur
avec deux avertissements, un bannissement refusé pour solde non nul. Ce sont
ces cas-là qui révèlent les malentendus, pas le cas nominal.

---

## Ce qui reste à trancher entre vous

- **La pagination** : curseur ou décalage ? Le curseur est proposé ci-dessus
  parce qu'une file qui bouge pendant qu'on la parcourt saute des lignes avec
  un décalage. À confirmer.
- **Le rafraîchissement** : l'interface relit-elle toutes les 30 secondes, ou
  écoute-t-elle Firestore en direct ? L'écoute directe est plus agréable mais
  contourne les Cloud Functions — donc les rôles. **Je recommande le
  rafraîchissement périodique**, plus simple et sans faille.
- **Le journal des décisions** : une collection `moderationLog` à part, ou les
  champs `reviewedBy` / `reviewedAt` sur chaque document ? Les champs
  suffisent au lancement ; une collection à part devient utile le jour où
  l'on veut mesurer l'activité de chacun.
