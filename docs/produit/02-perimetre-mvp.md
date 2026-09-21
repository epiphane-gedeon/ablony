# Périmètre du lancement — 30 jours

*Document de décision. Ce qui entre, ce qui sort, et pourquoi.*

**Cadre arrêté les 15 et 16 septembre 2026 :** lancement dans 30 jours
maximum, sur Firebase, pour « démarrer les activités de manière sereine ».
Cible de **2 500 comptes sur les premiers mois** — et l'application doit tenir
cette charge même si l'objectif n'est pas atteint. Trois modérateurs
disponibles. Le backend autonome n'est pas pour tout de suite.

---

## L'arithmétique, posée franchement

Trente jours calendaires, c'est environ **vingt à vingt-deux jours ouvrés**,
moins la publication sur les magasins : Apple met deux à sept jours à
examiner, Google un à trois. Prévoyez un premier refus, c'est courant.

**Le développement doit être terminé au jour 22.** Soit environ **dix-huit
jours ouvrés utiles**, tests compris.

Le périmètre ci-dessous totalise **29,5 jours**.

**Décision du 16 septembre : deux flux en parallèle.** Une personne sur
l'application mobile et les Cloud Functions, une autre sur `ablony_admin`.
C'est ce qui ramène les 29,5 jours de travail dans les dix-huit disponibles,
et c'est possible parce que l'administration est le seul morceau réellement
isolable — elle ne touche pas une ligne de l'application mobile.

**Ce que le parallélisme impose, et qui n'est pas gratuit :**

- **Le contrat d'API doit être figé dès le premier jour.** Sans lui, la
  personne sur `ablony_admin` attend celle qui écrit les fonctions. Il est
  dans [22-contrat-api.md](22-contrat-api.md), et il permet de travailler
  contre des réponses simulées jusqu'à ce que les vraies existent.
- **`functions/index.js` a un seul propriétaire** — le flux mobile. Deux
  personnes qui écrivent dans le même fichier de 2 400 lignes, c'est un
  conflit par jour.
- **Une recette croisée au jour 18.** Chacun essaie le travail de l'autre.
  C'est là que se découvrent les malentendus de contrat, et il faut du temps
  devant pour les corriger.

---

## Ce qui a changé depuis la première version

Deux de vos réponses ont déplacé le périmètre.

**Les 2 500 comptes ont fait remonter la recherche en lot 1.** Six mille
annonces disponibles, et la recherche actuelle les télécharge toutes à chaque
requête : le quota gratuit est épuisé après **huit recherches par jour**, et
la facture atteint 270 à 470 $ par mois. Avant même le coût, l'écran gèle
plusieurs secondes. Ce n'était pas une condition d'ouverture ; ça l'est
devenu.

**Le système de modération a fait apparaître trois chantiers.** Le modèle
d'annonce, l'échelle des sanctions et la tâche planifiée. Le premier était
jusque-là hors périmètre — il y entre parce que trois fonctionnalités veulent
toucher aux mêmes quatre index composites, et qu'il vaut mieux payer une fois.

---

## Lot 1 — les fondations et ce qui bloque *(22 jours)*

| # | Quoi | Pourquoi maintenant | Effort |
|---|---|---|---|
| [19](19-modele-annonce.md) | **Modèle d'annonce** | `status`, `moderationStatus`, `isListable`. Tout le reste écrit dedans. Le faire après, c'est le réécrire. | 3 j |
| [10](10-retraits.md) | **Retraits** | Un vendeur ne peut pas récupérer son argent. Une place de marché où l'argent entre sans pouvoir sortir n'en est pas une. | 4 j |
| [18](18-recherche.md) | **Réparer la recherche** | Inutilisable et coûteuse à 6 000 annonces. | 3 j |
| [11](11-litige-acheteur.md) | **Litige acheteur** | Aucun recours depuis l'application. Le remboursement existe côté serveur, **rien ne permet de le demander**. | 3 j |
| [21](21-taches-planifiees.md) | **Tâche planifiée** | Purge à 10 jours, levée des suspensions, **et les deux horloges de livraison**. Quatre usages, un chantier. | 2 j |
| [20](20-sanctions.md) | **Sanctions** | Avertissements, suspensions, bannissement. Deux degrés de gravité. | 2 j |
| [17](17-moderation.md) | **`ablony_admin`** | Trois files, trois rôles, la trace. Sans elle, les modérateurs n'ont pas d'outil. | 4 j |
| [12](12-blocage-membre.md) | **Bloquer un membre** | Sécurité, et motif de refus chez Apple. | 1 j |

**L'ordre compte.** [19](19-modele-annonce.md) d'abord — la recherche, la
modération et les sanctions en dépendent. Puis les retraits, qui n'en
dépendent pas et peuvent avancer en parallèle.

## Lot 2 — l'application cesse de mentir *(6,5 jours)*

| # | Quoi | Effort |
|---|---|---|
| [13](13-entrees-mortes.md) | 21 boutons qui ne font rien — dont **deux motifs de refus** : pas de suppression de compte, pas de blocage | 1,5 j |
| [14](14-boite-notifications.md) | Ce qui est envoyé n'est lisible nulle part | 1,5 j |
| [15](15-historique-commandes.md) | On ne retrouve pas sa commande | 2 j |
| [16](16-pages-legales.md) | CGU inexistantes, hébergement à renouveler | 1,5 j |

## Ce qui reste hors périmètre

Détaillé dans [99-apres-le-lancement.md](99-apres-le-lancement.md). Rien ici
ne bloque une ouverture.

| Quoi | Pourquoi ça attend |
|---|---|
| **Lots** (plusieurs articles, un envoi) | Le plus rentable de la liste — c'est **votre marge de livraison** qui part deux fois sans lui. Mais 6 à 8 jours qui touchent panier, paiement, colis et remboursement partiel. Premier après le lancement. |
| **Recherches sauvegardées** | Le meilleur outil de rétention. Inutile tant qu'il n'y a personne à faire revenir. |
| **Offre privée, mode vacances, avis réciproques, parrainage** | Confort et croissance. |
| **20 photos et vidéo** | Le coût n'est pas le curseur, c'est la bande passante. |

---

## Le calendrier proposé

En supposant **une personne sur l'application mobile et une sur
l'administration**, ce qui est l'hypothèse la plus réaliste pour tenir la date.

| Jours | Application mobile | `ablony_admin` |
|---|---|---|
| 1 – 3 | **Modèle d'annonce** (19) — index, reprise, déclencheur | Mise en place, connexion, rôles |
| 4 – 6 | **Recherche** (18) — s'appuie sur `isListable` | File des annonces |
| 7 – 10 | **Retraits** (10) | File des signalements |
| 11 – 12 | **Tâche planifiée** (21) | File des litiges et des retraits |
| 13 – 15 | **Litige acheteur** (11) | Réservation, raccourcis clavier, trace |
| 16 – 17 | **Sanctions** (20) | Historique des sanctions par vendeur |
| 18 | **Blocage** (12) | Recette croisée |
| 19 – 20 | Lot 2 — entrées mortes, notifications | |
| 21 – 22 | Lot 2 — commandes, pages légales | |
| 23 – 25 | **Recette de bout en bout sur les parcours d'argent**, sur appareil réel | |
| 26 – 27 | Corrections, versions de production, envoi aux magasins | |
| 28 – 35 | Examen des magasins, corrections de refus | |

**À une seule personne, ce calendrier fait 30 jours ouvrés**, soit six
semaines calendaires. C'est la mesure honnête de l'écart.

Les jours 23 à 25 ne sont pas négociables. Le projet n'a **aucun test** — voir
[C6](03-corrections.md#c6) — et vous ouvrez une application qui déplace de
l'argent.

---

## Ce qui est déjà tranché, et qu'il ne faut pas rouvrir

| Question | Décision |
|---|---|
| État d'une annonce | `status` + `moderationStatus` + `isListable` calculé — [19](19-modele-annonce.md) |
| Annonce vendue supprimée | **Refus**, avec explication |
| Annonce non vendue supprimée | **Archivage**, jamais d'effacement |
| Annonce rejetée | Invisible, archivée après 10 jours |
| Annonce rejetée **déjà vendue** | La vente n'est pas touchée ; un litige est ouvert d'office |
| Gravité | Deux degrés — correction *(sans avertissement)* et manquement |
| Échelle | 2 manquements → suspension 10 j · 3 suspensions → bannissement |
| Suspension | Bloque la vente. Laisse l'achat, la messagerie et **le retrait** |
| Bannissement | Statut `banned`, jamais de suppression. Refusé si solde non nul ou vente en cours |
| Administration | Application web séparée, sur ordinateur, volontairement sans style |
| Rôles | `moderator` *(examine)* et `admin` *(argent et bannissement)* |

---

## Les deux choses à lancer aujourd'hui

**Renouveler l'hébergement d'ablony.net.** Ce n'est pas du développement, et
le délai ne vous appartient pas entièrement.

**Décider comment vous comblez les onze jours manquants.** Plus tard vous
trancherez, moins vous aurez de marge — et l'option « décaler la date » coûte
d'autant plus cher qu'elle est prise tard.
