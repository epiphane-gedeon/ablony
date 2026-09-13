# Correction du parcours de livraison

Branche `correc`. Cette correction répare une erreur de modèle : l'application
traitait la remise comme une **remise en main propre** entre le vendeur et
l'acheteur, alors qu'Ablony **achemine lui-même les colis**, en point relais
ou à domicile.

## Les quatre défauts

### 1. Le choix de livraison n'atteignait jamais le serveur

L'écran de paiement collectait le mode de livraison, le point relais et
l'adresse. Puis les jetait : `initiatePayment` ne les transmettait pas, et
`functions/index.js` ne mentionnait ni `relay`, ni `deliveryMethod`, ni
`address`. **L'article était vendu et attendu nulle part.**

C'est le défaut central : tout le reste en découle.

### 2. Seuls les libellés étaient conservés, pas les identifiants

```dart
_selectedRelayPoint = result.name;   // le nom, pas l'id
_selectedAddress = result.toString(); // une chaîne mise en forme
```

Même en voulant les envoyer, il n'y avait rien d'exploitable à envoyer. Les
objets entiers sont désormais conservés — `RelayPoint` et `DeliveryAddress`.

### 3. L'adresse était exigée pour un retrait en point relais

L'achat était bloqué sur une information qui ne sert à personne quand
l'acheteur vient chercher son colis lui-même. La destination dépend maintenant
du mode : un point relais, **ou** une adresse.

### 4. Le QR était à l'envers

Le vendeur affichait un QR, l'acheteur le scannait. Ce geste suppose que les
deux personnes se rencontrent — ce qui n'arrive jamais : le colis passe par un
point relais ou par un livreur.

Pire, ce modèle ne pouvait pas fonctionner. Un acheteur qui ne scanne jamais
bloque indéfiniment l'argent du vendeur, et rien ne permet de départager :
personne n'était là pour constater la remise.

## Ce que fait la version corrigée

```
Achat ─► le choix de livraison part avec le paiement, validé avant tout débit
  │
  ├─► un colis est ouvert, avec son code  AB-XXXXX-XXXXX
  │
  ├─► le vendeur imprime le code, le colle sur le carton, le dépose
  │     en point relais.  Son travail s'arrête là.
  │
  ├─► Ablony achemine — chaque étape scannée par un agent
  │
  └─► l'acheteur confirme depuis son reçu, ou la confirmation vient d'elle-même
```

### Le code du colis est le même partout

Un seul code par vente, de l'étiquette à la remise. Le vendeur l'imprime une
fois, nos agents le scannent à chaque étape, l'acheteur le suit. Il n'y a pas
un code par étape ni un code par rôle.

L'alphabet exclut `O`/`0` et `I`/`1` : un agent doit pouvoir le dicter au
téléphone sans que son interlocuteur se trompe en le recopiant.

### Le code n'autorise rien

Il est imprimé sur un carton que tout le monde peut voir. **Ce n'est donc pas
le code qui déclenche une étape, mais l'agent qui le scanne.** La collection
`parcels` est en lecture seule pour les deux parties : un vendeur capable
d'écrire déclarerait son colis remis et se ferait payer sans avoir rien
envoyé — ce qui viderait le séquestre de son sens.

### Le serveur ne fait plus confiance au client sur les montants

`initiatePayment` lit le prix de l'annonce — jamais celui envoyé dans la
requête — puis recalcule le total : prix + protection + frais de port. Un écart
est refusé. Les constantes de `DeliveryPricing` servent à *afficher* le
récapitulatif, pas à fixer le prix : un client qui fixe ses propres frais n'en
paie aucun.

Le contrôle porte sur `amount + walletDeduction`, et non sur `amount` seul : en
paiement mixte, `amount` ne porte que la part réglée hors porte-monnaie.
Comparer `amount` seul ferait échouer tout paiement mixte ; le remplacer par le
total débiterait l'acheteur deux fois.

## Un défaut trouvé en chemin

Le bouton « Confirmer la réception » de la fiche produit appelait
`context.push('/delivery/scan-qr')` **sans aucun paramètre**, alors que la
route faisait `state.extra as Map<String, dynamic>`. Il plantait à chaque
appui. Il mène désormais au reçu, où la confirmation se fait.

## Limite connue de cette pile

La confirmation de l'acheteur reste le **seul** signal : il n'existe pas encore
d'application agent pour scanner le colis pendant le transport. Tant que c'est
le cas, un acheteur qui ne confirme jamais bloque les fonds du vendeur.

La libération automatique suppose une remise **constatée par un tiers**. Elle
arrive avec le service `delivery` du nouveau backend (`ablony_back`), qui
enregistre chaque scan d'agent et tient les deux horloges : cinq jours pour
déposer, trois jours après la remise pour contester.

## Fichiers

| Fichier | Rôle |
|---|---|
| `lib/features/delivery/domain/models/delivery_choice.dart` | le choix, tel qu'il part au serveur |
| `lib/features/delivery/domain/models/parcel.dart` | le colis et son état |
| `lib/features/delivery/domain/models/delivery_pricing.dart` | frais affichés, imposés par le serveur |
| `lib/features/delivery/data/parcel_repository.dart` | suivi du colis, en lecture seule |
| `lib/features/delivery/presentation/pages/parcel_label_page.dart` | l'étiquette que le vendeur imprime |
| `functions/index.js` | validation de la destination, ouverture du colis |
| `firestore.rules` | `parcels` remplace `qrcodes` |

Supprimés : `show_delivery_qr_page.dart`, `scan_delivery_qr_page.dart`, et la
dépendance `mobile_scanner` — l'application ne scanne plus rien. La caméra
reste utilisée pour les photos d'annonce.

## Vérifié

```
flutter analyze     0 erreur, 0 avertissement introduit
flutter gen-l10n    498 clés, fr et en alignées
```

`npm run lint` sur `functions/` n'a pas pu être lancé : Node.js n'est pas
installé sur la machine de développement. Le fichier a été contrôlé
structurellement, mais **à relancer avant tout déploiement**.
