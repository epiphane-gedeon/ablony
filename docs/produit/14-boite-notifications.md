# 14 — Boîte de notifications

**Lot 2 · 1,5 jour**

---

## Le problème

Les notifications sont écrites en base et le push part. Le modèle, le dépôt et
le fournisseur existent — 141 lignes en tout dans
`lib/features/notifications/`.

**Il n'y a aucun écran.** Aucune page, aucune route, aucun accès. Ce qui est
envoyé n'est consultable nulle part dans l'application.

Concrètement : un vendeur dont le téléphone était éteint au moment d'une vente
ne l'apprend jamais. Le push est passé, il n'a laissé aucune trace. Or
c'est la notification la plus importante de toute l'application — c'est elle
qui déclenche le dépôt du colis, et donc tout le reste.

## La décision produit

**Le push est le signal, la boîte est la mémoire.** Les deux sont
indispensables et ne servent pas à la même chose : le push interrompt, la
boîte se consulte. Une notification qui n'existe que sous forme de push est
perdue dès qu'on regarde ailleurs.

Et surtout : **une notification mène quelque part**. Une ligne « Votre article
a été vendu » qui n'est pas cliquable ne sert à rien — le vendeur doit
atterrir sur l'écran où il imprime son étiquette. C'est le routage qui donne
sa valeur à la boîte, pas la liste.

**Ce qu'on ne fait pas :** pas de réglages de notifications par catégorie
(hors périmètre), pas de groupement, pas de suppression individuelle.

---

## Le routage — la partie qui compte

Chaque notification porte un `type` et un `data`. La boîte s'en sert pour
ouvrir le bon écran. Le tableau ci-dessous est à construire depuis les
appels existants dans `functions/index.js` :

| `type` | Destination | Écrit par |
|---|---|---|
| `purchase_received` | Étiquette du colis — `/delivery/label/{parcelCode}` | `confirmPayment` |
| `purchase_confirmed` | Le reçu — `/receipt/{transactionRef}` | `confirmPayment` |
| `parcel_on_its_way` | Le reçu | `recordParcelCheckpoint` |
| `parcel_ready_for_pickup` | Le reçu | `recordParcelCheckpoint` |
| `parcel_delivered` | Le reçu | `recordParcelCheckpoint` |
| `refund_issued` | Le relevé — `/profile/wallet/statement` | `refundPurchase` |
| `sale_refunded` | Le relevé | `refundPurchase` |
| `funds_released` | Le relevé | `releasePurchase` |
| `new_message` | La conversation — `/chat/{conversationId}` | messagerie |
| `new_follower` | Le profil public | `notifyFollowersOnNewProduct` |
| `review_received` | Son profil public | `onReviewCreated` |
| *(à ajouter)* `withdrawal_paid`, `withdrawal_rejected` | Le relevé | [10](10-retraits.md) |
| *(à ajouter)* `dispute_opened`, `dispute_resolved` | Le reçu | [11](11-litige-acheteur.md) |

Un type inconnu ne doit pas planter : il ouvre la boîte et ne navigue nulle
part. Les notifications survivent aux versions de l'application, et une
ancienne notification ne doit pas casser une nouvelle version.

---

## Fichier par fichier

### Ce qui existe déjà

| Fichier | État |
|---|---|
| `lib/features/notifications/domain/models/app_notification.dart` | 68 lignes. Vérifier qu'il porte bien `type`, `data`, `read`, `createdAt`. |
| `lib/features/notifications/data/notification_repository.dart` | 41 lignes. Vérifier la présence d'un flux filtré sur `userId` et trié par date. |
| `lib/features/notifications/presentation/providers/notification_provider.dart` | 32 lignes. |

Les règles Firestore sont **déjà correctes** (`firestore.rules`, collection
`notifications`) : lecture par le destinataire seul, écriture réservée aux
Cloud Functions, et le destinataire peut changer `read` — et uniquement `read`.
Rien à faire de ce côté.

### À créer

| Fichier | Rôle |
|---|---|
| `lib/features/notifications/presentation/pages/notifications_page.dart` | La liste, du plus récent au plus ancien. Non lues en gras avec une pastille. Appui → marque comme lue **et** navigue. « Tout marquer comme lu » en haut. Écran vide explicite. |
| `lib/features/notifications/presentation/widgets/notification_tile.dart` | Une ligne : icône par type, titre, corps sur deux lignes, date relative (« il y a 2 h »). |
| `lib/features/notifications/application/notification_router.dart` | La fonction `destinationOf(AppNotification)` qui applique le tableau ci-dessus et renvoie une route, ou `null`. Isolée pour être relue d'un coup d'œil — c'est le fichier qu'on rouvrira à chaque nouveau type. |

### À modifier

| Fichier | Modification |
|---|---|
| `notification_repository.dart` | Ajouter `markAsRead(id)`, `markAllAsRead()`, et `unreadCount()` — un flux, pour la pastille. |
| `lib/core/layout/` *(la coquille à navigation basse)* | Une pastille sur l'onglet profil, ou une icône cloche dans la barre d'accueil. **Décider où** : Vinted met une cloche dans l'en-tête de l'accueil ; c'est plus visible qu'un badge d'onglet. |
| `lib/core/navigation/app_router.dart` | Route `notifications` → `/notifications`. |
| `lib/core/services/push_notification_service.dart` | Sur appui d'un push, réutiliser `destinationOf()` au lieu d'une logique parallèle. **C'est le point à ne pas rater** : deux routages qui divergent, c'est un push qui mène ailleurs que la ligne correspondante. |
| `lib/l10n/*.arb` | Libellés ci-dessous. |
| `firestore.indexes.json` | `notifications` → `userId ASC, createdAt DESC` — vérifier qu'il existe déjà. |

### Traductions

```
notificationsTitle       Notifications
notificationsEmpty       Aucune notification pour l'instant
notificationsEmptyHint   Vos ventes, vos achats et vos messages apparaîtront ici.
notificationsMarkAllRead Tout marquer comme lu
notificationsToday       Aujourd'hui
notificationsEarlier     Plus tôt
```

---

## Critères d'acceptation

- [ ] Un point d'entrée visible depuis l'accueil, avec le nombre de non lues.
- [ ] La liste montre les notifications du plus récent au plus ancien.
- [ ] Une non lue se distingue d'une lue au premier coup d'œil.
- [ ] Appuyer marque comme lue **et** ouvre le bon écran.
- [ ] Une notification de vente ouvre l'étiquette du colis, pas l'accueil.
- [ ] Un `type` inconnu n'ouvre rien et ne plante pas.
- [ ] « Tout marquer comme lu » vide la pastille.
- [ ] Un push appuyé depuis l'extérieur ouvre **le même écran** que la ligne correspondante.
- [ ] Les notifications d'autrui sont inaccessibles — vérifié par les règles, avec un jeton.

## Le détail qui fait la différence

La date relative. « il y a 2 h » se lit ; « 14/09/2026 08:31 » se déchiffre.
`timeago` avec la locale française, ou une fonction de vingt lignes — mais pas
une date brute.
