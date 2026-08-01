# 📱 Ablony - Vue d'Ensemble du Projet

**Dernière mise à jour** : 1 août 2026  
**Version** : 0.1.0 (Alpha)  
**Statut** : Développement actif

---

## 🎯 Vision du Projet

**Ablony** est une **marketplace mobile de seconde main** inspirée de **Vinted**, ciblant les marchés du **Togo 🇹🇬** et du **Bénin 🇧🇯**.

L'application permet aux utilisateurs de :
- Vendre et acheter des articles d'occasion (vêtements, accessoires, électronique, etc.)
- Créer un compte sécurisé via authentification sociale ou email
- Publier des annonces avec photos, description, prix et état du produit
- Parcourir des produits organisés par catégories et sous-catégories
- Rechercher des articles spécifiques avec filtres
- Communiquer avec les vendeurs/acheteurs via messagerie intégrée (texte, offres, photos)
- Suivre d'autres utilisateurs et être notifié de leurs nouvelles annonces
- Payer via GeniusPay (mobile money, carte) ou porte-monnaie interne
- Confirmer la réception d'un article par QR code pour débloquer le paiement du vendeur
- Construire une réputation de vendeur avec notes et avis

**Marché cible** : Marchés émergents d'Afrique de l'Ouest  
**Utilisateurs visés** : Consommateurs soucieux de leur budget, revendeurs, acheteurs éco-responsables  
**Inspiration** : Vinted (marketplace C2C de seconde main)

---

## 🏗️ Architecture du Projet

### Architecture Clean (Couches)

Le projet suit les principes de **Clean Architecture** avec une séparation stricte des responsabilités :

```
┌─────────────────────────────────────────────────────┐
│    PRESENTATION (UI/Widgets)                         │
│  Pages, écrans, dialogues, widgets personnalisés    │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│    APPLICATION (Gestion d'État)                      │
│  Providers Riverpod, logique métier                 │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│    DOMAIN (Règles Métier - Dart Pur)                │
│  Entités, interfaces des repositories               │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│    DATA (Détails d'Implémentation)                   │
│  Modèles, implémentations repositories, Firebase    │
└─────────────────────────────────────────────────────┘
```

Toutes les features ne comportent pas les 4 couches (certaines sont UI-only). `auth/` et `product/` restent les références les plus complètes ; `follow/`, `notifications/`, `receipt/`, `reviews/` suivent un format plus léger (data + presentation, sans couche domain séparée pour les repositories simples).

### Structure des Dossiers

```
lib/
├── core/                          # Infrastructure partagée
│   ├── config/                    # Config Firebase, émulateurs
│   ├── constants/                 # Constantes globales
│   ├── exceptions/                # Hiérarchie d'exceptions personnalisées
│   ├── layout/                    # Layouts réutilisables (MainLayout, BottomNav)
│   ├── navigation/                # Configuration GoRouter + navigatorKey global
│   ├── presentation/              # Widgets partagés, gestion erreurs
│   ├── providers/                 # Providers globaux (locale, theme, auth, push)
│   ├── services/                  # Services HTTP vers Cloud Functions (payment, delivery)
│   ├── theme/                     # Thème Material (clair/sombre)
│   └── utils/                     # Fonctions utilitaires
│
├── features/                      # 22 modules fonctionnels
│   ├── auth/                      # Authentification & inscription (référence)
│   ├── onboarding/ splash/        # Écrans pré-connexion
│   ├── home/ search/ profile/     # Navigation principale
│   ├── product/                   # Annonces de produits (référence)
│   ├── sell/                      # Création d'annonce (bottom sheet)
│   ├── product_fav/               # Favoris
│   ├── follow/                    # Abonnements entre utilisateurs
│   ├── reviews/                   # Notation des vendeurs (1-5 étoiles)
│   ├── messages/                  # Messagerie temps réel (texte, offres, photos)
│   ├── make_offer_feature/        # Bottom sheet de négociation de prix
│   ├── payment/ payment_method/   # Paiement GeniusPay + choix du moyen de paiement
│   ├── wallet/                    # Porte-monnaie (solde dispo/en attente)
│   ├── receipt/                   # Reçus d'achat (détail + export PDF)
│   ├── delivery_confirmation/     # Confirmation de réception par QR code
│   ├── notifications/             # Notifications in-app (onglet Messages)
│   ├── address/                   # Adresse de livraison (placeholder, non persisté)
│   ├── relay_point/                # Sélection point relais (placeholder)
│   └── location/                  # Géolocalisation (placeholder, packages commentés)
│
├── shared/                        # Composants cross-features
│   └── widgets/                   # Boutons, product_card, input, image_source_sheet...
│
├── l10n/                          # Internationalisation (FR/EN, ~250+ clés)
├── scripts/                       # Scripts utilitaires (seed Firestore)
└── main.dart                      # Point d'entrée (init Firebase, FCM background handler)

functions/
└── index.js                       # Cloud Functions Node.js (~940 lignes, 8 fonctions)
```

**148 fichiers Dart** au total, répartis sur 22 modules `features/`.

---

## 📦 Stack Technologique

### Framework & Langage
| Outil | Version | Usage |
|-------|---------|-------|
| **Flutter** | ^3.10.0 | Framework UI multi-plateforme |
| **Dart** | ^3.10.0 | Langage de programmation |

### Backend & Services Cloud
| Service | Version | Usage |
|---------|---------|-------|
| **Firebase Core** | 4.2.1 | Infrastructure cloud Google |
| **Cloud Firestore** | 6.1.0 | Base de données NoSQL temps réel |
| **Firebase Auth** | 6.1.2 | Gestion authentification utilisateurs |
| **Firebase Storage** | 13.0.4 | Hébergement images produits, profils, chat |
| **Firebase Messaging** | 16.2.0 | Notifications push (FCM) |
| **Firebase App Check** | 0.4.1+3 | Protection anti-fraude API |
| **Cloud Functions** | Node 22, firebase-functions v6 | Backend serverless, région `us-central1` (8 fonctions dans `functions/index.js`) |

### Authentification Sociale
| Package | Version | Plateformes |
|---------|---------|-------------|
| **Google Sign-In** | 6.3.0 | Android, iOS, Web |
| **Flutter Facebook Auth** | 6.0.4 | Android, iOS, Web |
| **Sign in with Apple** | 6.1.4 | iOS, macOS |

### Gestion d'État & Navigation
| Package | Version | Usage |
|---------|---------|-------|
| **Flutter Riverpod** | 3.0.3 | State management réactif |
| **Go Router** | 17.0.0 | Routing déclaratif avec redirections |
| **Equatable** | 2.0.7 | Égalité de valeur pour les entités |

### UI & Design
| Package | Version | Usage |
|---------|---------|-------|
| **Google Fonts** | 6.3.2 | Polices personnalisées |
| **Flutter SVG** | 2.0.10+1 | Support des assets SVG |
| **Image Picker** | 1.2.1 | Photos produits + photos de chat (caméra/galerie) |
| **WebView Flutter** | 4.13.0 | Paiement GeniusPay hébergé + reCAPTCHA (page non routée) |
| **Google Maps Flutter / Geolocator / Geocoding** | - | Présents mais non branchés (voir Limitations) |

### Paiement, Reçus & QR
| Package | Version | Usage |
|---------|---------|-------|
| **pdf / printing** | 3.12.0 / 5.14.3 | Génération et partage du reçu en PDF |
| **qr_flutter** | 4.1.0 | Génération du QR de confirmation de réception (rendu à la volée, jamais stocké en image) |
| **mobile_scanner** | 7.4.0 | Scan du QR côté acheteur |

### Données & Sécurité
| Package | Version | Usage |
|---------|---------|-------|
| **Shared Preferences** | 2.5.3 | Stockage local persistant |
| **Intl** | latest | Internationalisation (i18n) |
| **HTTP** | 1.2.0 | Client HTTP vers les Cloud Functions (payment, delivery) |

---

## 🌍 Plateformes Supportées

| Plateforme | Statut | Note |
|------------|--------|------|
| **Android** | ✅ Opérationnel | Permissions caméra/notifications configurées |
| **iOS** | ⚠️ Code prêt, config manuelle requise | Push nécessite l'activation de la capability "Push Notifications" + upload d'une clé APNs dans la console Firebase (accès Apple Developer requis, non automatisable) |
| **Web / macOS / Windows / Linux** | ✅ Build possible | Fonctionnalités caméra/push non testées sur ces cibles |

---

## ✅ Fonctionnalités Implémentées

### 1. 🔐 Authentification & Gestion Utilisateurs — solide
- **Connexion sociale** : Google, Facebook, Apple — réellement implémentées (pas juste des boutons UI)
- **Email/mot de passe** : inscription, connexion, validation, gestion d'erreurs
- **Flux d'inscription** : onboarding → choix méthode → username (suggestion + unicité temps réel) → pays (Togo/Bénin) → sauvegarde transactionnelle Firestore
- ⚠️ L'étape Captcha existe encore en code (`captcha_page.dart`) mais **a été retirée du flux de routage** — page non utilisée, candidate à suppression
- **Entité User** complète avec stats vendeur (`productsCount`, `salesCount`, `rating`, `reviewsCount`, `followersCount`, `followingCount`)

### 2. 🗂️ Produits & Catégories — solide
- Structure hiérarchique de catégories avec attributs dynamiques par sous-catégorie
- CRUD complet (`ProductRepository`), pagination infinie, favoris (`product_fav`)
- Recherche par catégorie, filtres basiques

### 3. 👥 Abonnements (`follow`) — solide
- Collection `follows/{followerId}_{followedId}` (queryable, pas de tableau sur `users` — évite la contention d'écriture sur les comptes populaires)
- Compteurs `followersCount`/`followingCount` dénormalisés sur `users`, tenus à jour par transaction à chaque toggle
- Pages abonnés/abonnements, bouton Suivre réactif (`StreamProvider`, pas de cache figé)
- Nouvelle annonce d'un vendeur suivi → notification automatique (trigger Firestore `notifyFollowersOnNewProduct`)

### 4. ⭐ Notation (`reviews`) — solide
- Un avis = un achat réellement complété : l'id du document `reviews` = `transactionRef`, vérifié côté règles Firestore contre la transaction réelle (impossible de fabriquer un faux avis)
- Après un achat, l'acheteur est redirigé vers une page de notation (1-5 étoiles + commentaire optionnel)
- Moyenne recalculée côté serveur (trigger `onReviewCreated`) et affichée sur le profil (en-tête + onglet Évaluations) et la fiche produit

### 5. 💬 Messagerie (`messages`) — solide (n'est plus un placeholder)
- Conversations temps réel (`conversations/{id}/messages`), création automatique liée à un produit
- Système d'offres complet : offre initiale, acceptation/refus, contre-offre
- **Envoi de photos** : bouton caméra → choix caméra/galerie → prévisualisation au-dessus du champ de saisie (pas d'envoi immédiat) → envoi avec légende optionnelle sur le même message
- Onglet Notifications de la page Messages branché sur la collection `notifications` (temps réel)

### 6. 💰 Paiement & Porte-monnaie — majoritairement solide
- **GeniusPay** : paiement externe (mobile money, carte) via Cloud Functions (`initiatePayment`/`confirmPayment`/`geniusPayWebhook`), et paiement 100% porte-monnaie avec finalisation immédiate
- `finalizePurchase()` est le point unique de finalisation (transaction Firestore atomique : débit wallet acheteur, crédit `pendingAmount` vendeur, produit marqué vendu) — idempotent, appelé par les 3 chemins de paiement
- 🔄 **Retrait du porte-monnaie** : bouton présent, non implémenté
- 🔄 **Sélection moyen de paiement / adresse de livraison** : UI complète mais non persistée (`// TODO: Sauvegarder`)

### 7. 🧾 Reçus & Confirmation de réception par QR — solide
- Reçu généré automatiquement à chaque achat (`receipts/{transactionRef}`), consultable en détail + export PDF (`pdf`/`printing`, aucune image de reçu stockée)
- **QR de remise en main propre** : le vendeur affiche un QR (rendu à la volée, jamais une image stockée) contenant uniquement un id opaque vers la collection `qrcodes` (jamais la transactionRef, le sellerId ou le buyerId directement)
- L'acheteur scanne (caméra intégrée, `mobile_scanner`) → Cloud Function `confirmDelivery` résout l'id, vérifie que le scanneur est bien l'acheteur authentifié de cette transaction précise, puis bascule `pendingAmount → availableAmount` du vendeur (uniquement le montant de cette transaction, pas une remise à zéro globale — un vendeur peut avoir plusieurs ventes en attente simultanément)
- Bouton "Confirmer la réception" également disponible directement sur la page reçu

### 8. 🔔 Notifications Push & In-App — solide
- FCM : permission, enregistrement/rafraîchissement du token (`users/{uid}.fcmTokens`), bannière in-app au premier plan, navigation au tap (arrière-plan et lancement à froid)
- Déclenchées côté serveur pour : achat confirmé (acheteur + vendeur), nouvelle annonce d'un vendeur suivi, réception confirmée (déblocage de fonds)
- Nettoyage automatique des tokens FCM invalides côté serveur

### 9. 🎨 UI, Thème & Localisation — solide
- Thème clair/sombre, persistance locale, FR/EN complet (~250+ clés `.arb`)
- Navigation GoRouter avec redirections auto selon état auth/profil, `StatefulShellRoute` pour la bottom nav

### 10. 🔒 Sécurité — Règles Firestore & Storage
- Chaque nouvelle collection a été conçue avec un souci explicite de non-exploitabilité (voir section Notes ci-dessous pour les pièges rencontrés)
- Collections entièrement server-managed (Admin SDK, aucun accès client) : `transactions`, `qrcodes`
- Collections avec lecture scoping strict par propriétaire : `receipts`, `notifications`
- `reviews` : création vérifiée par lookup croisé vers `transactions` (empêche les faux avis)

### 🚧 Encore en placeholder / non fait
- **Géolocalisation/carte** (`location/`) : code `geolocator`/`geocoding` commenté, en attente de configuration
- **Point relais** (`relay_point/`) : liste statique, pas de vraie sélection cartographique
- **Adresse & moyen de paiement** : formulaires non persistés
- **Retrait du porte-monnaie** : non implémenté
- **Tests** : toujours aucun test unitaire/widget/e2e
- **Boost produit / Partage / Signaler / Masquer une annonce** : boutons présents, non implémentés

---

## 🗄️ Base de Données Firestore

### Collections principales

**`users/{userId}`** — profil, stats vendeur, `wallet` (map), `fcmTokens` (array), `followersCount`/`followingCount`, `rating`/`reviewsCount`

**`products/{productId}`** — annonce (titre, prix, images, condition, catégorie, `isSold`)

**`categories/{categoryId}`**, **`subcategories/{subcategoryId}`** — hiérarchie + attributs dynamiques

**`usernames/{username}`** — réservation d'unicité

**`fav/{uid}_{productId}`** — favoris (doc composite, transaction avec `products.favoritesCount`)

**`follows/{followerId}_{followedId}`** — relation d'abonnement, lecture publique

**`conversations/{id}`** + sous-collection **`messages/{id}`** — messagerie (types : `text`, `image`, `offer`, `counter_offer`, `system`)

**`transactions/{transactionRef}`** — 100% server-managed (Admin SDK), source de vérité d'un paiement (`status`, `deliveryConfirmed`)

**`receipts/{transactionRef}`** — vue client-safe d'une transaction complétée, lecture restreinte acheteur/vendeur

**`qrcodes/{id auto}`** — lien opaque `transactionRef`/`sellerId`/`buyerId`, 100% server-managed, aucun accès client

**`reviews/{transactionRef}`** — avis, id = transactionRef (unicité + vérification), lecture publique

**`notifications/{id}`** — notifications in-app, lecture/update (marquer lu) restreints au destinataire

### Index composites
`firestore.indexes.json` couvre : `products` (par vendeur/catégorie/statut vendu + date), `follows` (par follower/followed + date), `notifications` (par userId + date), `reviews` (par sellerId + date). Les requêtes à double égalité (ex. `receipts` par `productId`+`sellerId`) n'ont pas besoin d'index composite explicite (géré automatiquement par Firestore).

---

## ☁️ Cloud Functions (`functions/index.js`, ~940 lignes)

| Fonction | Type | Rôle |
|----------|------|------|
| `initiatePayment` | HTTPS | Démarre un paiement GeniusPay ou finalise directement un paiement 100% porte-monnaie |
| `confirmPayment` | HTTPS | Confirme un paiement externe après retour de la WebView |
| `geniusPayWebhook` | HTTPS | Callback serveur-à-serveur GeniusPay (backup au retour WebView) |
| `confirmDelivery` | HTTPS (auth par ID token) | Résout le QR scanné → débloque `pendingAmount → availableAmount` |
| `notifyFollowersOnNewProduct` | Trigger Firestore (`products/{id}` create) | Notifie in-app + push tous les abonnés du vendeur |
| `onReviewCreated` | Trigger Firestore (`reviews/{id}` create) | Recalcule la moyenne `users.rating`/`reviewsCount` |
| `finalizePurchase` / `notifyPurchase` / `sendPushToUser` | Fonctions internes partagées | Cœur commun de finalisation d'achat, notifications et push (pas des `exports`) |

**⚠️ Piège de déploiement** : `firebase deploy --only functions:nomDeLaFonction` ne redéploie **que** cette fonction — les autres fonctions du même fichier restent sur leur ancienne version tant qu'elles ne sont pas explicitement redéployées, même si leur code source a changé entre-temps. Toujours faire un `firebase deploy --only functions` (sans cibler) après plusieurs sessions de modifications pour resynchroniser.

---

## 🔧 Configuration Firebase

- **Projet** : `ablony-a5db9` — [Console](https://console.firebase.google.com/project/ablony-a5db9)
- **Firestore** : région `europe-west1`
- **Cloud Functions** : région `us-central1`
- **Services activés** : Authentication, Firestore, Storage, App Check, Cloud Functions, Cloud Messaging (FCM)
- **Config multi-plateforme** : `android/app/google-services.json`, Xcode (iOS), `lib/firebase_options.dart` (FlutterFire CLI)
- **Émulateurs** : configurés dans `lib/core/config/firebase_config.dart` mais actuellement désactivés (`useEmulators => false`, code d'activation commenté dans `main.dart`)

---

## 🚀 Commandes Utiles

```bash
# Installation & développement
flutter pub get
flutter gen-l10n
flutter analyze
flutter run

# Build
flutter build apk / ios / web

# Firebase — déploiement complet recommandé après plusieurs changements
firebase deploy --only firestore:rules,firestore:indexes,storage,functions

# Cloud Functions
cd functions && npm run lint
firebase functions:log --only <nomFonction>
```

---

## 📝 Notes pour Développeurs & LLMs

### Comprendre rapidement le projet
1. **Point d'entrée** : `lib/main.dart` (init Firebase + FCM background handler)
2. **Routes** : `lib/core/navigation/app_router.dart`
3. **Feature de référence (couches complètes)** : `lib/features/auth/`, `lib/features/product/`
4. **Backend serverless** : `functions/index.js` — un seul fichier, toutes les fonctions
5. **Règles de sécurité** : `firestore.rules`, `storage.rules`

### Pièges rencontrés (à ne pas reproduire)

**1. `FutureProvider.family` se fige si la donnée change pendant que la page reste en cache.**  
Riverpod met en cache un `FutureProvider.family(param)` indéfiniment tant qu'il n'est pas explicitement invalidé. Deux bugs de ce type corrigés dans ce projet : le compteur d'abonnés (`userByIdProvider`) et la disponibilité du bouton QR vendeur (`receiptForProductProvider`). **Règle** : toute donnée Firestore qui peut changer pendant qu'un écran reste affiché doit être un `StreamProvider`, pas un `FutureProvider`.

**2. Une requête Firestore (`.where()`) n'est autorisée par les règles que si ses filtres correspondent exactement aux champs vérifiés par la règle.**  
Une requête `receipts.where('productId'==X)` a été refusée en bloc par une règle vérifiant `resource.data.sellerId == request.auth.uid`, même quand l'unique document trouvé appartenait bien à l'utilisateur — Firestore ne peut pas le prouver statiquement à partir du seul filtre `productId`. Symptôme typique : requête lente (aller-retour réseau) puis échec silencieux. **Fix** : ajouter le champ vérifié par la règle directement dans le `.where()` (ex. `.where('productId'==X).where('sellerId'==monUid)`), quitte à dupliquer la requête par rôle (vendeur/acheteur).

**3. Les règles Firebase Storage ne peuvent PAS référencer Firestore.**  
`firestore.get(...)` utilisé dans `storage.rules` compile sans erreur mais échoue à l'exécution et refuse tout accès par défaut. Pour scoper l'accès Storage (ex. photos de chat par participant), encoder l'info directement dans le chemin (`chat_images/{conversationId}/{senderId}/...`) et vérifier uniquement `request.auth.uid` contre un segment de chemin — jamais de lookup croisé vers Firestore depuis Storage.

**4. `firebase deploy --only functions:X` ne redéploie que `X`.** Voir section Cloud Functions ci-dessus.

### Patterns Architecturaux
- **Erreurs** : `AppException` typées, jamais d'`Exception()` générique, `.showAsSnackBar()`/`.showAsDialog()`
- **Navigation** : `context.go()` pour remplacer la pile, `context.push()` pour empiler
- **State** : `StreamProvider` pour le temps réel, `FutureProvider` pour du one-shot **qui ne change pas pendant que l'écran est ouvert**, `StateNotifierProvider` pour du state mutable complexe
- **Sécurité serveur** : toute opération qui déplace de l'argent (finalisation d'achat, déblocage de fonds) passe par une Cloud Function avec transaction Firestore atomique — jamais côté client
- **Localisation** : `AppLocalizations.of(context)!.key`, clés ajoutées dans `app_fr.arb` ET `app_en.arb`, puis `flutter gen-l10n`

---

## 📞 Ressources & Liens

- **Firebase Console** : https://console.firebase.google.com/project/ablony-a5db9
- **Documentation Flutter** : https://docs.flutter.dev
- **Documentation Firebase** : https://firebase.google.com/docs
- **Documentation Riverpod** : https://riverpod.dev
- **Documentation GoRouter** : https://pub.dev/packages/go_router
- **Guide Exceptions** : [GESTION_EXCEPTIONS.md](GESTION_EXCEPTIONS.md)
- **Guide Firebase** : [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

---

**Maintenu par** : Équipe de développement Ablony  
**Dernière révision** : 1 août 2026  
**Prochaine révision** : Recommandée après chaque fonctionnalité majeure complétée
