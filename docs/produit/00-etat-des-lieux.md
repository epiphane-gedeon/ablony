# État des lieux — ce qu'Ablony fait aujourd'hui

*Inventaire du code, pas des intentions. Chaque ligne a été vérifiée dans le
dépôt le 15 septembre 2026, branche `correc`.*

---

## Comment lire ce document

Trois états, et un seul compte vraiment :

| | Signification |
|---|---|
| **Fait** | Un utilisateur peut s'en servir de bout en bout. |
| **Partiel** | Le code existe mais un maillon manque — écran absent, appel non branché, donnée jamais écrite. |
| **Écran mort** | L'entrée existe dans l'interface et ne fait rien. `onTap: () {}`. |

La dernière catégorie mérite d'être nommée à part. Un bouton qui ne fait rien
coûte plus cher qu'un bouton absent : l'utilisateur l'essaie, ne comprend pas,
et perd confiance dans le reste de l'application.

---

## Le volume, pour situer

```
auth                6 516 lignes   21 fichiers
product             4 270 lignes   20 fichiers
messages            2 854 lignes   16 fichiers
search              2 093 lignes    3 fichiers
sell                1 571 lignes    4 fichiers
delivery            1 547 lignes   12 fichiers
profile             1 391 lignes    4 fichiers
wallet              1 266 lignes    7 fichiers
payment               888 lignes    2 fichiers
…                                          24 fonctionnalités au total
```

L'écart entre `search` (2 093 lignes, 3 fichiers) et le reste est le premier
signal : toute la recherche tient dans trois écrans sans couche `data` ni
`domain`. C'est la fonctionnalité qui a été écrite le plus vite, et c'est
celle qui pose le problème le plus grave — voir
[03-corrections.md](03-corrections.md).

---

## Compte et identité — **fait**

Inscription par e-mail, Google, Facebook, Apple. Complétion de profil en deux
écrans (pseudonyme, pays) avec réservation transactionnelle du pseudonyme.
Réinitialisation de mot de passe. Sessions. Suppression de compte par
anonymisation.

Le routeur (`lib/core/navigation/app_router.dart`) gère correctement les trois
états : non connecté → `/onboarding`, connecté sans profil → `/auth/username`,
connecté complet → `/home`.

**Réserve.** `captcha_page.dart` porte un `TODO` et reCAPTCHA n'a jamais été
branché. La fonction `verifyRecaptcha` existe côté serveur mais personne ne
l'appelle.

## Annonces — **fait**

Publication avec jusqu'à 6 photos, arbre de catégories à profondeur variable,
attributs dynamiques par catégorie (marque, couleur, matière, taille),
état de l'article, prix. Brouillon conservé si l'on quitte l'écran
(`sell_draft_provider.dart`). Modification, masquage, suppression.

**Réserve.** Vinted accepte 20 photos et une vidéo. Six est un plafond bas
pour un marché où la photo *est* la description.

## Fil d'accueil — **fait**

Liste paginée (`paginatedProductsProvider`), annonces mises en avant en tête
(`activeBoostedProductsProvider`), catégories en bandeau.

**Réserve.** Aucune personnalisation. Tout le monde voit le même fil, dans le
même ordre. Vinted trie par affinité avec ce que vous regardez et suivez.

## Recherche — **partiel, et cassé à l'échelle**

L'écran existe, les filtres existent (catégorie, attributs, état), les
résultats s'affichent.

**Le problème est dans `product_repository_impl.dart:278`** :
`searchProducts()` télécharge **toutes** les annonces non vendues, puis filtre
en mémoire. Aucune limite, aucune pagination, aucun index. À mille annonces
c'est lent ; à dix mille c'est une facture et un écran figé.

Détaillé dans [03-corrections.md](03-corrections.md#c1).

## Favoris et abonnements — **fait**

Mise en favori, liste des favoris, suivre un vendeur, listes d'abonnés et
d'abonnements, profil public.

## Messagerie — **fait**

Conversations, messages texte et image, offres et contre-offres dans le fil,
acceptation d'une offre. Le modèle `Offer` et `OfferStatus` sont complets.

## Paiement et porte-monnaie — **fait**

Achat via GeniusPay (carte, T-Money, Flooz) ou solde. Séquestre : le vendeur
est crédité en attente, libéré à la confirmation de réception. Rechargement.
Mise en avant payante d'une annonce. Relevé du porte-monnaie.

**Réserve.** Le retrait affiche « bientôt disponible » : la logique serveur
existe (`approve`, `mark_paid`, `reject`) mais aucune route ne l'expose, et la
clé d'API du prestataire de versement n'est pas encore disponible.

## Livraison — **fait**, corrigé récemment

Choix du mode (point relais ou domicile) transmis au serveur, colis ouvert
automatiquement à l'achat, étiquette `AB-XXXXX-XXXXX` imprimable par le
vendeur, scan par le personnel à chaque étape, suivi pour l'acheteur,
confirmation de réception, file des colis bloqués pour l'administration.

Tout ceci a été mis en place dans la branche `correc` — voir
[CORRECTION_LIVRAISON.md](../../CORRECTION_LIVRAISON.md).

## Reçus et avis — **partiel**

Reçu consultable, téléchargeable. Notation du vendeur après un achat
(`rate_seller_page.dart`).

**Manque.** L'avis ne va que dans un sens. Sur Vinted, les deux parties se
notent — c'est ce qui permet à un vendeur de savoir à qui il vend.

## Signalements — **partiel**

On peut signaler une annonce. Le traitement existe côté nouveau backend
(file de modération, retrait, rejet) mais **pas côté Firebase**, qui est le
backend que l'application utilise aujourd'hui.

**Manque entièrement.** Bloquer un membre. Il n'y a aucune occurrence de
`block` dans le code.

## Notifications — **partiel**

Le modèle, le dépôt et le fournisseur existent
(`lib/features/notifications/`, 141 lignes en tout). Les notifications sont
écrites en base et le push part.

**Manque.** L'écran. Il n'y a **aucune page** de notifications, et aucune
route vers elle. Ce qui est envoyé n'est consultable nulle part dans
l'application.

---

## Les écrans morts

Treize entrées du profil et huit des réglages sont des `onTap: () {}`.

**Profil** (`lib/features/profile/presentation/pages/profile_page.dart`) :

| Entrée | Ligne | État |
|---|---|---|
| Inviter des amis | 109 | mort |
| Ventes et achats | 137 | mort |
| Outils de promotion | 144 | mort |
| Personnalisation | 151 | mort |
| Remise sur lot | 159 | mort |
| Mode vacances | 166 | mort |
| Dons | 174 | mort |
| Guide Ablony | 183 | mort |
| Centre d'aide | 190 | mort |
| Paramètres des cookies | 204 | mort |
| À propos | 211 | mort |
| Informations légales | 218 | mort |
| Notre plateforme | 225 | mort |

**Réglages** (`settings_page.dart`) : huit entrées, mêmes symptômes
(lignes 39, 44, 49, 54, 59, 71, 76, 109).

Ces libellés sont repris de Vinted. Le squelette de l'interface a été copié
avant que les fonctionnalités n'existent — ce qui est une façon légitime de
travailler, à condition de ne pas livrer les entrées vides.

---

## Ce qui n'existe pas du tout

Aucun fichier, aucune route, aucun modèle :

- **Lots** (acheter plusieurs articles d'un même vendeur en un envoi)
- **Remise sur lot** automatique
- **Recherches sauvegardées** et alertes
- **Offre privée** à qui a mis en favori
- **Mode vacances**
- **Historique des ventes et des achats**
- **Litige côté acheteur** (« j'ai un problème avec ma commande »)
- **Blocage d'un membre**
- **Parrainage**
- **Centre d'aide**, guide, pages légales dans l'application
- **Tests** — le projet n'a pas de dossier `test/`

---

## Une divergence à connaître

L'application Flutter représente l'état d'une annonce par **trois booléens** —
`isSold`, `isReserved`, `isHidden`. Le nouveau backend utilise **un champ
`status`** à cinq valeurs (`active`, `reserved`, `sold`, `hidden`, `blocked`).

Les deux modèles ne sont pas équivalents : trois booléens permettent des états
impossibles (vendu *et* réservé), et ne savent pas exprimer « retiré par la
modération ». La réconciliation est traitée dans
[03-corrections.md](03-corrections.md#c5).
