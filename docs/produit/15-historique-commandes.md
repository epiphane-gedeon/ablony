# 15 — Ventes et achats

**Lot 2 · 2 jours**

---

## Le problème

Après un achat, on ne retrouve sa commande par aucun chemin.

Le reçu existe et s'ouvre par `/receipt/{transactionRef}` — mais il faut
connaître la référence. Aucun écran ne liste les commandes. L'entrée « Ventes
et achats » du profil (`profile_page.dart:137`) est un `onTap: () {}`.

Pour un vendeur, c'est pire : il apprend sa vente par une notification, et si
elle passe inaperçue il n'a aucun moyen de découvrir qu'un colis l'attend.
Le colis reste non déposé, l'acheteur attend, et personne ne comprend pourquoi.

## La décision produit

**Un écran, deux onglets : Achats et Ventes.** C'est là qu'on va quand on se
demande « où en est ma commande ? » — et c'est la question la plus fréquente
sur une place de marché de seconde main, où l'attente dure plusieurs jours.

Chaque ligne doit répondre à la question sans qu'on ait à l'ouvrir : la photo,
le titre, le montant, et **l'action attendue de moi** quand il y en a une.

C'est ce dernier point qui fait la valeur de l'écran. Une liste d'historique
est une archive ; une liste qui dit « déposez ce colis avant vendredi » est un
outil de travail.

**Ce qu'on ne fait pas :** pas de filtres, pas de recherche, pas d'export. La
liste est courte au début.

---

## Ce que chaque ligne affiche

**Côté vendeur**, par état du colis :

| État | Ce que la ligne dit | Action |
|---|---|---|
| `awaiting_dropoff` | **À déposer avant le {date}** — en évidence | Imprimer l'étiquette |
| `dropped_off`, `in_transit`, `out_for_delivery` | En cours d'acheminement | Suivre |
| `ready_for_pickup` | Attend l'acheteur au point relais | — |
| `delivered`, non confirmé | Remis — paiement à venir | — |
| confirmé | **Payé : {montant} FCFA** | Voir le relevé |
| remboursé | Vente annulée — {motif} | — |

**Côté acheteur** :

| État | Ce que la ligne dit | Action |
|---|---|---|
| `awaiting_dropoff` | Le vendeur prépare votre colis | — |
| en transit | En route | Suivre |
| `ready_for_pickup` | **À retirer au point relais** | Voir le point relais |
| `delivered`, non confirmé | **Confirmez la réception** — en évidence | Confirmer · Signaler un problème |
| confirmé | Terminé | Noter le vendeur, si ce n'est pas fait |
| remboursé | Remboursé : {montant} FCFA | — |

Les deux lignes en gras sont les seules qui appellent un geste. Tout le reste
informe. Cette distinction doit se voir : une pastille, une couleur, un bouton
— pas seulement un libellé différent.

---

## Fichier par fichier

### Données

Aucune nouvelle collection. Les données existent :

- **achats** : `transactions` où `userId == moi` et `type == "purchase"` ;
- **ventes** : `receipts` où `sellerId == moi` ;
- **l'état du colis** : `parcels` où `transactionRef == …`.

Deux requêtes plus une lecture de colis par ligne. À vingt lignes par page,
c'est acceptable. Si cela devenait lourd, la solution serait de recopier
`parcelStatus` sur le reçu à chaque scan — **ne pas le faire d'emblée** : une
donnée dupliquée est une donnée qui se désynchronise.

Index à ajouter dans `firestore.indexes.json` :

```
transactions → userId ASC, type ASC, createdAt DESC
receipts     → sellerId ASC, createdAt DESC     (déjà prévu pour le relevé)
parcels      → transactionRef ASC               (lecture directe)
```

### À créer

| Fichier | Rôle |
|---|---|
| `lib/features/orders/domain/models/order_summary.dart` | Ce qu'une ligne affiche : référence, titre, image, montant, date, `OrderSide` (achat/vente), état du colis, état du règlement, et un `OrderAction?` — l'action attendue. |
| `lib/features/orders/data/order_repository.dart` | `watchPurchases()`, `watchSales()`. Chacune joint le colis. Pagination par `startAfter`. |
| `lib/features/orders/presentation/providers/order_provider.dart` | Les deux flux. |
| `lib/features/orders/presentation/pages/orders_page.dart` | `TabBar` à deux onglets. Écran vide explicite et différent selon l'onglet : « Vous n'avez rien acheté » ≠ « Vous n'avez rien vendu ». |
| `lib/features/orders/presentation/widgets/order_tile.dart` | La ligne. L'action en bouton, pas en texte. |

### À modifier

| Fichier | Modification |
|---|---|
| `lib/features/profile/presentation/pages/profile_page.dart` | Ligne 137 : `onTap: () => context.pushNamed('orders')`. |
| `lib/core/navigation/app_router.dart` | Route `orders` → `/profile/orders`, avec un paramètre de requête `?tab=sales` pour arriver directement sur les ventes depuis une notification. |
| `lib/features/notifications/application/notification_router.dart` | `purchase_received` peut pointer ici plutôt que sur l'étiquette — **à trancher** : l'étiquette est plus directe, la liste donne le contexte. Je recommande l'étiquette : le vendeur a une chose à faire, autant l'y mener. |
| `lib/l10n/*.arb` | Libellés ci-dessous. |

### Traductions

```
ordersTitle            Ventes et achats
ordersPurchases        Achats
ordersSales            Ventes
ordersNoPurchases      Vous n'avez encore rien acheté
ordersNoSales          Vous n'avez encore rien vendu
orderDropOffBy         À déposer avant le {date}
orderPrintLabel        Imprimer l'étiquette
orderInTransit         En cours d'acheminement
orderAwaitingPickup    À retirer au point relais
orderConfirmReception  Confirmez la réception
orderPaid              Payé : {amount} FCFA
orderRefunded          Remboursé : {amount} FCFA
orderCancelled         Vente annulée
orderRateSeller        Noter le vendeur
orderTrack             Suivre
```

---

## Critères d'acceptation

- [ ] L'entrée « Ventes et achats » du profil ouvre l'écran.
- [ ] Les deux onglets affichent les bonnes commandes, du plus récent au plus ancien.
- [ ] Un vendeur avec un colis non déposé voit la date limite **en évidence**, et le bouton mène à l'étiquette.
- [ ] Un acheteur dont le colis est remis voit « Confirmez la réception » en évidence.
- [ ] Les lignes sans action attendue ne portent aucun bouton.
- [ ] Une commande remboursée affiche le montant et le motif.
- [ ] La liste se pagine au défilement.
- [ ] Les écrans vides disent quoi faire, pas seulement qu'il n'y a rien.
- [ ] Depuis une notification de vente, on arrive directement sur l'onglet Ventes.

## Pourquoi cet écran vaut deux jours

C'est le seul endroit d'où un vendeur distrait peut rattraper un colis oublié.
Sans lui, une notification manquée devient un colis jamais déposé, un acheteur
qui attend, un remboursement, et deux personnes déçues — pour un push qui est
passé pendant que le téléphone était dans une poche.
