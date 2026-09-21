# Dossier produit — Ablony

*Ce qui manque à l'application, comment le mettre en place, et ce qu'on
assume de ne pas faire.*

Rédigé les 15 et 16 septembre 2026, sur la branche `correc`. Tout ce qui est
affirmé ici a été vérifié dans le code, pas déduit des intentions.

---

## Le cadre

| | |
|---|---|
| **Objectif** | Un MVP permettant de démarrer les activités sereinement |
| **Délai visé** | 30 jours, publication sur les magasins comprise |
| **Backend** | Firebase. Le backend autonome n'est pas pour tout de suite. |
| **Charge à tenir** | 2 500 comptes sur les premiers mois |
| **Modération** | 3 personnes — 1 temps plein, 2 temps partiels |
| **Marché** | Togo et Bénin |

Ces six lignes expliquent chaque arbitrage du dossier. Si l'une change, le
périmètre change — c'est déjà arrivé deux fois.

---

## Par où commencer

**Si vous avez dix minutes** → [02-perimetre-mvp.md](02-perimetre-mvp.md).
C'est le document de décision : ce qui entre, ce qui sort, le calendrier, et
l'écart de onze jours qu'il faut combler.

**Si vous voulez comprendre où on en est** →
[00-etat-des-lieux.md](00-etat-des-lieux.md), puis
[01-comparaison-vinted.md](01-comparaison-vinted.md).

**Si vous développez** → chaque fiche numérotée se lit seule : le problème, la
décision, le parcours, les fichiers à créer et à modifier, les traductions,
et les critères d'acceptation.

**Commencez par [19-modele-annonce.md](19-modele-annonce.md).** La recherche,
la modération et les sanctions écrivent toutes dans ces champs.

---

## Sommaire

### Comprendre

| Fichier | Contenu |
|---|---|
| [00-etat-des-lieux.md](00-etat-des-lieux.md) | Ce que l'application fait aujourd'hui, vérifié fichier par fichier |
| [01-comparaison-vinted.md](01-comparaison-vinted.md) | Le tableau complet, et trois écarts qui méritent discussion |

### Décider

| Fichier | Contenu |
|---|---|
| [02-perimetre-mvp.md](02-perimetre-mvp.md) | **Le document de décision.** Deux lots, un calendrier, et l'arithmétique qui ne tombe pas juste |
| [03-corrections.md](03-corrections.md) | Huit défauts du code existant, classés par ce qu'il en coûte de ne rien faire |

### Faire — lot 1, les fondations et ce qui bloque *(22 jours)*

*Dans cet ordre : les trois premières fiches conditionnent les suivantes.*

| Fichier | Effort |
|---|---|
| [19-modele-annonce.md](19-modele-annonce.md) — `status`, `moderationStatus`, `isListable` | 3 j |
| [10-retraits.md](10-retraits.md) — un vendeur ne peut pas toucher son argent | 4 j |
| [18-recherche.md](18-recherche.md) — chaque recherche télécharge tout le catalogue | 3 j |
| [11-litige-acheteur.md](11-litige-acheteur.md) — aucun recours en cas de problème | 3 j |
| [21-taches-planifiees.md](21-taches-planifiees.md) — purge, suspensions, **et les horloges de livraison** | 2 j |
| [20-sanctions.md](20-sanctions.md) — avertissements, suspensions, bannissement | 2 j |
| [17-moderation.md](17-moderation.md) — **`ablony_admin`**, l'application d'administration | 4 j |
| [12-blocage-membre.md](12-blocage-membre.md) — personne ne peut couper court à un harcèlement | 1 j |
| [22-contrat-api.md](22-contrat-api.md) — **à figer le jour 1**, c'est ce qui rend les deux flux parallèles | — |

### Faire — lot 2, l'application cesse de mentir *(6,5 jours)*

| Fichier | Effort |
|---|---|
| [13-entrees-mortes.md](13-entrees-mortes.md) — 21 boutons qui ne font rien | 1,5 j |
| [14-boite-notifications.md](14-boite-notifications.md) — ce qui est envoyé n'est lisible nulle part | 1,5 j |
| [15-historique-commandes.md](15-historique-commandes.md) — on ne retrouve pas sa commande | 2 j |
| [16-pages-legales.md](16-pages-legales.md) — les CGU n'ont jamais été écrites | 1,5 j |

### Ensuite

| Fichier | Contenu |
|---|---|
| [99-apres-le-lancement.md](99-apres-le-lancement.md) | Les lots, les recherches sauvegardées, les avis réciproques… et le raccordement au backend autonome |

---

## Les trois choses à retenir

**1. Un vendeur ne peut pas récupérer son argent.** Aucune fonction de retrait
côté Firebase — zéro occurrence dans `functions/index.js`. Ça ne se voit pas à
l'installation : ça se découvre après la première vente, au moment exact où la
confiance venait de se construire. Et l'absence de clé d'API du prestataire
n'est pas bloquante : le virement se fait à la main, l'application encadre.

**2. La recherche ne tient pas votre cible.** À 6 000 annonces disponibles, le
quota Firestore gratuit est épuisé après **huit recherches par jour**, et la
facture atteint 270 à 470 $ par mois. L'écran gèle avant même de coûter cher.
C'est ce qui a fait passer [18](18-recherche.md) du lot 3 au lot 1.

**3. Rien n'expire tout seul.** Aucune fonction planifiée n'existe : une vente
attend indéfiniment la confirmation de l'acheteur, un colis jamais déposé ne
rembourse personne, une suspension de 10 jours ne se lève pas au onzième.
[21-taches-planifiees.md](21-taches-planifiees.md) règle les quatre cas d'un
coup — c'est la meilleure affaire du dossier.

---

## Ce que le dossier ne dit pas

Les estimations sont en jours de développement, pour quelqu'un qui connaît ce
code. Elles n'incluent ni la rédaction des contenus — CGU et aide, comptez une
journée d'écriture — ni les allers-retours avec les magasins d'applications.

**Le total dépasse le délai de onze jours**, ce qui a conduit à la décision du
16 septembre : **deux flux en parallèle**, une personne sur l'application
mobile et les Cloud Functions, une autre sur `ablony_admin`. Le calendrier de
[02-perimetre-mvp.md](02-perimetre-mvp.md) est écrit sur cette base, et
[22-contrat-api.md](22-contrat-api.md) est ce qui l'autorise.
