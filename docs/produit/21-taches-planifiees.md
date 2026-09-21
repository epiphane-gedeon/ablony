# 21 — La tâche planifiée

**Lot 1 · 2 jours · quatre usages pour un seul chantier**

---

## Pourquoi cette fiche vaut plus que son coût

Le projet n'a **aucune fonction planifiée** aujourd'hui. C'est la cause d'un
problème que le dossier signale partout : **rien n'expire tout seul**.

Une vente attend indéfiniment la confirmation de l'acheteur. Un colis jamais
déposé ne rembourse personne. Une suspension de 10 jours ne se lève pas au
onzième. Tout repose sur quelqu'un qui regarde, tous les jours.

Votre règle de purge à 10 jours impose d'en écrire une. **Une fois la
mécanique en place, trois autres usages ne coûtent presque rien** — et l'un
d'eux supprime votre plus gros risque d'exploitation.

## Les quatre usages

| Ce qu'elle fait | Sans elle |
|---|---|
| **Purge les annonces rejetées** après 10 jours | Elles s'accumulent indéfiniment |
| **Lève les suspensions** arrivées à terme | La suspension est perpétuelle |
| **Rembourse les colis jamais déposés** | L'acheteur attend jusqu'à ce que quelqu'un s'en aperçoive |
| **Libère les fonds** 3 jours après une remise constatée | Le vendeur attend un geste de l'acheteur qui ne viendra peut-être jamais |

Les deux derniers sont les **horloges de livraison** du backend autonome. Vous
les obtenez ici pour une demi-journée de plus.

---

## Le cadre technique

`onSchedule` de Firebase Functions v2, qui s'appuie sur Cloud Scheduler. Vous
êtes déjà en 2ᵉ génération et sur le plan Blaze : rien à activer.

**Toutes les heures.** Pas toutes les minutes — aucun de ces traitements n'est
urgent à la minute, et une exécution horaire coûte 720 déclenchements par mois,
soit rien.

**Idempotence obligatoire.** Cloud Scheduler peut déclencher deux fois. Chaque
traitement doit être rejouable sans dommage : un remboursement ne doit pas
partir deux fois, une suspension ne doit pas se lever deux fois. C'est le
point qui demande le plus d'attention, et il se vérifie en relançant la
fonction à la main deux fois de suite.

**Toujours un `limit()`.** Une requête sans limite sur une collection qui a
grossi, c'est une fonction qui dépasse son temps d'exécution et ne finit
jamais son travail — tout en le recommençant à chaque heure.

---

## Fichier par fichier

### `functions/index.js` — une fonction, quatre traitements

```js
exports.hourlyTasks = onSchedule("every 1 hours", async () => {
  const bilan = {
    archivees: await purgerAnnoncesRejetees(),
    levees:    await leverSuspensionsEchues(),
    rembourses:await rembourserDepotsNonFaits(),
    liberes:   await libererRemisesConfirmees(),
  };
  console.log("hourlyTasks", bilan);
});
```

Une seule fonction plutôt que quatre : un seul déclencheur à surveiller, un
seul journal à lire, et un bilan qui dit d'un coup d'œil ce qui s'est passé.

### 1. Purger les annonces rejetées

```
Cherche : products où moderationStatus == "rejected"
                  et rejectedAt <= maintenant - 10 jours
                  et status != "sold"          ← une vente reste une vente
Limite  : 200
Fait    : status = "archived"
```

**Archiver, pas supprimer** — voir [19](19-modele-annonce.md). Et la condition
`status != "sold"` importe : une annonce rejetée *après* avoir été vendue ne
doit pas être archivée sous les pieds d'un acheteur qui attend son colis.

### 2. Lever les suspensions échues

```
Cherche : users où accountStatus == "suspended"
                et suspendedUntil <= maintenant
Limite  : 100
Fait    : accountStatus = "active", suspendedUntil = null
          suspensions/{id}.liftedAt = maintenant
          recomputeListableForSeller(uid)   ← ses annonces reviennent
Notifie : « Votre compte est de nouveau actif »
```

Le `recomputeListableForSeller` est ce qui remet ses annonces en vente. Sans
lui, la suspension est levée sur le papier et ses annonces restent invisibles.

### 3. Rembourser les colis jamais déposés

```
Cherche : parcels où status == "awaiting_dropoff"
                   et dropoffDeadline <= maintenant
Limite  : 100
Fait    : appelle refundPurchase(transactionRef,
            "Le vendeur n'a pas déposé le colis dans le délai imparti")
          parcels.status = "returned"
Notifie : les deux parties
```

`refundPurchase` existe déjà sur la branche `correc` : la somme revient au
disponible de l'acheteur, l'attente du vendeur est vidée, l'article repart en
vente, et une transaction `refund` est écrite. Rien à réécrire.

**Un rappel d'abord.** Deux et quatre jours après l'achat, une notification au
vendeur — « il vous reste N jours pour déposer ». Un compteur
`remindersSent` sur le colis évite de renvoyer le même rappel toutes les
heures. Rembourser sans avoir relancé, c'est sanctionner une distraction.

### 4. Libérer les fonds après une remise constatée

```
Cherche : parcels où status == "delivered"
                   et deliveredAt <= maintenant - 3 jours
                   et settledAt == null
Limite  : 100
Vérifie : aucun litige ouvert sur cette vente   ← impératif
Fait    : appelle releasePurchase(transactionRef,
            "Délai de contestation écoulé après remise constatée")
Notifie : le vendeur
```

**C'est le traitement le plus important de la fiche**, et le seul qui demande
une justification.

Libérer automatiquement l'argent d'un acheteur qui n'a rien confirmé n'est
défendable que parce que **la remise a été constatée par un de vos agents**,
pas déclarée par le vendeur. Sans ce constat, on choisirait entre pénaliser un
vendeur honnête dont l'acheteur ne confirme jamais, et payer un vendeur qui
n'a rien envoyé. Le scan du colis tranche.

Le contrôle du litige n'est pas optionnel : sans lui, un acheteur qui signale
un problème se fait payer son vendeur sous le nez trois jours plus tard.

### Journalisation

Chaque traitement écrit dans `scheduledRuns/{id}` : l'heure, le bilan, les
erreurs. Cinq lignes de code, et c'est ce qui permet de répondre à « pourquoi
ce remboursement est-il parti ? » trois semaines plus tard.

### Index — `firestore.indexes.json`

```
products → moderationStatus, rejectedAt
users    → accountStatus, suspendedUntil
parcels  → status, dropoffDeadline
parcels  → status, deliveredAt
```

---

## Critères d'acceptation

- [ ] La fonction tourne toutes les heures et journalise son bilan.
- [ ] Une annonce rejetée depuis 10 jours passe en `archived` ; une annonce rejetée depuis 9 jours ne bouge pas.
- [ ] Une annonce rejetée **mais vendue** n'est jamais archivée.
- [ ] Une suspension échue est levée, et les annonces du vendeur **reviennent** dans les listes.
- [ ] Un colis non déposé passé l'échéance rembourse l'acheteur, et l'article repart en vente.
- [ ] Le vendeur a reçu deux rappels avant, pas quinze.
- [ ] Un colis remis depuis 3 jours libère les fonds.
- [ ] **Un litige ouvert empêche la libération** — le test à écrire en premier.
- [ ] Relancer la fonction deux fois de suite ne rembourse ni ne libère deux fois.
- [ ] Chaque traitement est limité : aucune requête sans `limit()`.

## Comment l'éprouver sans attendre dix jours

Les dates sont dans les documents : il suffit de les reculer. Un petit script
qui écrit `rejectedAt = maintenant - 11 jours` sur une annonce de test, puis
un déclenchement manuel de la fonction depuis la console. C'est exactement
ainsi que les horloges du backend autonome sont testées, et ça prend quelques
minutes.

## Pourquoi c'est en lot 1

Parce que sans elle, votre exploitation quotidienne dépend d'un humain qui
n'oublie jamais. Un colis non déposé un vendredi soir, c'est un acheteur qui
attend jusqu'à lundi — ou jusqu'à ce qu'il écrive, en colère.
