# 17 — `ablony_admin`, l'application d'administration

**Lot 1 · 4 jours · projet séparé, sur ordinateur**

---

## La décision

Une application web à part, dans un dossier `ablony_admin`, connectée au même
projet Firebase. **Pas d'écrans d'administration dans l'application mobile.**

Trois raisons, et la troisième suffirait :

- un binaire plus gros pour tout le monde, alors que trois personnes s'en
  servent ;
- un examen de magasin sur des fonctions qui ne regardent ni Apple ni Google ;
- **un rôle qui voyage dans un client que n'importe qui peut décompiler.**

Le travail se fait sur ordinateur — c'est ce qui convient : trois files, des
photos à regarder en grand, du texte à lire, et beaucoup de va-et-vient.

**Volontairement moche.** Pas de charte graphique, pas d'animation, pas de
mise en page responsive. C'est un outil interne. Tout le temps épargné sur
l'apparence va dans la sûreté des actions — et c'est le bon arbitrage.

---

## Qui s'en sert

Trois personnes : un temps plein (8 h/jour) et deux temps partiels
(3 à 5 h/jour), soit **14 à 18 heures par jour**.

Au pire des cas — 2 500 comptes arrivant le premier mois, quatre annonces
chacun, soit 333 nouvelles annonces par jour — cela laisse **2,5 à 3 minutes
par annonce**. La file est tenable telle qu'elle est pensée : pas besoin
d'approbation automatique ni d'heuristiques.

Mais trois personnes au lieu d'une imposent trois choses qu'une personne seule
n'aurait pas nécessitées.

### Des rôles distincts

| Rôle | Peut | Ne peut pas |
|---|---|---|
| `moderator` | approuver, rejeter (deux degrés), traiter les signalements | rembourser, verser, bannir |
| `admin` | tout, plus les litiges, les retraits et le bannissement | |

Un modérateur ne touche pas à l'argent. C'est la séparation qui compte, et
elle ne coûte rien à poser dès le départ.

### Une trace de qui a décidé quoi

Chaque décision écrit `moderatorId`, la date et le motif. Sans cela :

- impossible de répondre à « pourquoi mon annonce a-t-elle été retirée ? » ;
- impossible de corriger une erreur, puisqu'on ignore qui l'a commise ;
- impossible de repérer le modérateur qui se trompe systématiquement de degré
  — et comme l'échelle des [sanctions](20-sanctions.md) est automatique, une
  erreur de degré suspend quelqu'un à tort.

### La gestion des collisions

Deux modérateurs ouvriront la même annonce plusieurs fois par jour.

**Le minimum** : le second reçoit « déjà traitée par {qui} » et la file se
rafraîchit. Jamais d'écrasement silencieux.

**Mieux, et ce n'est pas cher** : une réservation. À l'ouverture,
`claimedBy` et `claimedAt` sur le document ; les autres voient la ligne
grisée. La réservation expire au bout de 5 minutes — sinon un onglet fermé
bloque une annonce pour toujours.

---

## Les trois files

### 1. Annonces à examiner

Tri : les **signalées** d'abord, puis les **nouveaux vendeurs** (moins de
trois annonces publiées), puis par ancienneté. Ce n'est pas une question de
volume — la capacité suffit — mais de priorité : le risque doit être vu en
premier.

Chaque ligne : **l'image en grand** — une contrefaçon se reconnaît sur la
photo bien avant le titre —, le titre, le prix, la catégorie, le vendeur avec
son historique de sanctions.

Trois actions : **Approuver** · **Demander une correction** · **Manquement**.
Les deux dernières ouvrent une liste de motifs — jamais un champ libre, qui
ferait diverger trois modérateurs en une semaine.

### 2. Signalements

Groupés **par annonce** : douze personnes qui dénoncent la même contrefaçon
posent une question et appellent une réponse. La ligne montre le nombre et les
motifs distincts. Les mêmes trois actions, plus **Écarter** — qui ne dit rien
au vendeur : il n'a jamais su qu'on l'avait signalé, et l'apprendre pour rien
ne lui apporterait qu'une inquiétude.

### 3. Litiges *(administrateurs seulement)*

Voir [11-litige-acheteur.md](11-litige-acheteur.md). Le motif, la description,
les photos en grand, le montant, l'état du colis, et **si l'acheteur a scanné
son étiquette** — ce dernier point tranche l'essentiel des dossiers « jamais
reçu ». Deux boutons : rembourser l'acheteur, verser au vendeur. Motif
obligatoire.

### Et deux files de service

**Retraits en attente** (administrateurs) — voir
[10-retraits.md](10-retraits.md). Le numéro en clair, le nom du titulaire,
« versé » ou « refusé ».

**Colis bloqués** (administrateurs) — la fonction `stuckParcels` existe déjà
sur la branche `correc`. Avec la [tâche planifiée](21-taches-planifiees.md),
cette file se vide largement toute seule ; elle reste utile pour les cas que
l'automatisme ne couvre pas.

---

## Fichier par fichier

### Technologie

**Vite + React, en TypeScript**, avec le SDK Firebase web. Pas de serveur à
exploiter, pas de déploiement compliqué : Firebase Hosting, sur un sous-domaine
séparé. L'authentification est celle de Firebase — les mêmes comptes, avec un
rôle.

Pourquoi pas Flutter web, puisque le code existe ? Parce que le partage serait
illusoire : aucun écran n'est commun, et vous porteriez le poids d'un binaire
Flutter web pour trois utilisateurs internes.

### Structure

```
ablony_admin/
├── src/
│   ├── firebase.ts              configuration et initialisation
│   ├── auth/
│   │   ├── LoginPage.tsx        connexion par e-mail
│   │   └── useRole.ts           lit users/{uid}.role, refuse si member
│   ├── queues/
│   │   ├── ProductsQueue.tsx    annonces à examiner
│   │   ├── ReportsQueue.tsx     signalements groupés par annonce
│   │   ├── DisputesQueue.tsx    litiges          (admin)
│   │   ├── WithdrawalsQueue.tsx retraits         (admin)
│   │   └── StuckParcelsQueue.tsx colis bloqués   (admin)
│   ├── components/
│   │   ├── ProductCard.tsx      image en grand, prix, vendeur, sanctions
│   │   ├── DecisionButtons.tsx  les trois actions, motifs en liste
│   │   ├── ClaimBadge.tsx       la réservation
│   │   └── SellerHistory.tsx    avertissements et suspensions du vendeur
│   ├── api/
│   │   └── functions.ts         appels aux Cloud Functions, jeton en en-tête
│   └── App.tsx                  navigation par onglets, filtrée par rôle
├── firebase.json                hébergement, cible `admin`
└── package.json
```

### Serveur — `functions/index.js`

Les fonctions appelées, dont la plupart sont spécifiées ailleurs :

| Fonction | Rôle requis | Fiche |
|---|---|---|
| `moderationQueue` | moderator | ici |
| `reportsQueue` | moderator | ici |
| `reviewProduct` | moderator | ici + [20](20-sanctions.md) |
| `claimItem` / `releaseClaim` | moderator | ici |
| `listDisputes` / `resolveDispute` | admin | [11](11-litige-acheteur.md) |
| `listWithdrawals` / `settleWithdrawal` | admin | [10](10-retraits.md) |
| `stuckParcels` | admin | *(existe déjà)* |
| `banUser` | admin | [20](20-sanctions.md) |

**`reviewProduct`** est la fonction centrale :

```
Entrée  : { productId, decision: "approve"|"correction"|"violation",
            reason?, note? }
Vérifie : role in ["moderator","admin"]
          · l'annonce n'est pas déjà traitée par quelqu'un d'autre
Fait    : approve    → moderationStatus = "approved"
          correction → moderationStatus = "rejected", pas d'avertissement
          violation  → moderationStatus = "rejected" + avertissement
                       + suspension si le seuil est atteint
          dans tous les cas : reviewedBy, reviewedAt, reason
          recalcule isListable
Notifie : le vendeur, sauf pour "approve" — il n'a pas à savoir qu'on l'a
          regardé
```

### La boucle de correction

C'est ici que la distinction entre les deux degrés cesse d'être théorique.
« Demander une correction » ne veut rien dire si le vendeur ne peut pas
corriger — et c'était le cas au départ : la règle Firestore bloquait toute
modification d'une annonce rejetée, quelle qu'en soit la raison. Le vendeur
recevait « corrigez-la » et se heurtait à un refus.

Le parcours complet, désormais :

```
1. Le modérateur renvoie pour correction
   → moderationStatus = "rejected", reviewDecision = "correction"
   → l'annonce sort des listes, aucun avertissement

2. Le vendeur reçoit « Annonce à corriger », avec le motif et le mot du
   modérateur. L'appui mène droit au formulaire de modification.

3. Il retouche. Les règles l'y autorisent parce que reviewDecision vaut
   "correction" — et seulement pour cette raison.

4. `onProductWritten` voit qu'un champ visible a changé et remet
   moderationStatus à "pending" : l'annonce repart en ligne et retourne en
   file d'examen. `rejectedAt` est effacé (l'horloge de purge à dix jours
   s'arrête), `resubmittedAt` est inscrit.

5. Le modérateur la retrouve dans sa file avec « Corrigée et renvoyée — on
   avait demandé : mauvaise catégorie ». Il ne relit pas à l'aveugle.
```

Un manquement, lui, ne suit pas cette boucle : `reviewDecision` vaut
`"violation"`, les règles refusent toute modification, et changer le titre
d'une contrefaçon ne la remet pas en vente.

Deux garde-fous dans le déclencheur :

- **Seul un changement de contenu compte** — titre, description, prix,
  photos, catégorie, état, attributs. Les écritures techniques du déclencheur
  lui-même (`isListable`, mots-clés, compteur de vues) ne relancent rien,
  sans quoi la boucle serait infinie.
- **Le client n'écrit jamais `reviewDecision`.** S'il l'effaçait en
  enregistrant sa correction, le déclencheur ne verrait plus la décision et
  l'annonce resterait retirée pour toujours.

### Règles — `firestore.rules`

La modification d'une annonce rejetée est autorisée **si et seulement si**
`reviewDecision == 'correction'`. Le vendeur ne touche toujours ni à
`moderationStatus` ni à `isListable` : c'est le serveur qui remet en file.

Pour le reste, les modérateurs passent par les Cloud Functions, qui
utilisent l'Admin SDK et contournent les règles. Les collections restent
fermées en écriture au client.

C'est délibéré : donner un accès direct à Firestore à trois comptes
modérateurs, c'est trois occasions d'écrire à côté, et aucune trace.

### Déploiement

La console a sa propre configuration Firebase, dans `ablony_admin/` — le CLI
refuse un dossier `public` situé hors du projet, et c'est tant mieux : la
console est autonome, elle n'a pas à dépendre du dépôt de l'application.

```bash
cd ../ablony_admin && npm run deploy
```

Site `ablony-admin` → **https://ablony-admin.web.app** · déployé.

Elle tourne aussi en conteneur, et c'est ce qui compte pour la bascule vers
le backend maison : l'image ne contient aucune adresse de serveur figée, la
configuration entre par des variables d'environnement au démarrage.

```bash
cd ../ablony_admin && docker compose up -d --build   # http://localhost:8090
```

Les mêmes protections des deux côtés — `X-Frame-Options: DENY`, CSP,
`noindex` : elles sont dans `ablony_admin/firebase.json` pour l'hébergement,
et dans `docker/default.conf.template` pour nginx.

Sur un sous-domaine — `admin.ablony.net`. Et **restreindre l'accès** : le rôle
suffit fonctionnellement, mais une page de connexion publique invite à être
essayée. App Check sur le domaine, ou une règle d'hébergement.

---

## Critères d'acceptation

- [ ] Un compte `member` qui se connecte est refusé avec un message clair.
- [ ] Un `moderator` voit trois onglets ; un `admin` en voit six.
- [ ] La file des annonces montre les signalées d'abord, puis les nouveaux vendeurs.
- [ ] L'image s'affiche en grand, sans clic supplémentaire.
- [ ] L'historique de sanctions du vendeur est visible **sur la ligne**, pas derrière un lien.
- [ ] Deux modérateurs sur la même annonce : le second est prévenu, aucune décision n'est écrasée.
- [ ] Une réservation abandonnée se libère au bout de 5 minutes.
- [ ] Chaque décision écrit qui, quand et pourquoi.
- [ ] Un modérateur ne voit ni les litiges, ni les retraits, ni le bannissement — **vérifié côté serveur**, avec un vrai jeton, pas seulement par les onglets masqués.
- [ ] Rejeter en « correction » n'inscrit pas d'avertissement ; en « manquement », si.
- [ ] Le raccourci clavier pour approuver existe *(trois cents annonces par jour à la souris, c'est long)*.

## Ce qui n'est pas dans les 4 jours

Les statistiques, l'export, la recherche dans les files, la modération des
messages, la gestion des comptes modérateurs depuis l'interface — ils se
créent dans la console Firebase, en mettant `role` à `moderator`.

## Le raccourci clavier

Ce n'est pas un détail de confort. Trois cents annonces par jour à trois
personnes, c'est cent décisions chacune. `A` pour approuver, `C` pour
correction, `V` pour manquement, flèches pour naviguer : une demi-journée de
travail qui fait gagner des heures chaque semaine à trois personnes.
