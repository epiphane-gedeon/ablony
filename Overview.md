# 📱 Ablony - Vue d'Ensemble du Projet

**Dernière mise à jour** : 11 janvier 2026  
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
- Communiquer avec les vendeurs/acheteurs via messagerie intégrée
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

### Structure des Dossiers

```
lib/
├── core/                          # Infrastructure partagée
│   ├── config/                    # Config Firebase, émulateurs
│   ├── constants/                 # Constantes globales
│   ├── exceptions/                # Hiérarchie d'exceptions personnalisées
│   ├── layout/                    # Layouts réutilisables (MainLayout, BottomNav)
│   ├── navigation/                # Configuration GoRouter
│   ├── presentation/              # Widgets partagés, gestion erreurs
│   ├── providers/                 # Providers globaux (locale, theme, auth)
│   ├── theme/                     # Thème Material (clair/sombre)
│   └── utils/                     # Fonctions utilitaires
│
├── features/                      # Modules fonctionnels
│   ├── auth/                      # Authentification & inscription
│   │   ├── application/           # Providers Riverpod
│   │   ├── data/                  # Modèles & implémentations
│   │   ├── domain/                # Entité User & interface AuthRepository
│   │   └── presentation/          # Pages d'authentification
│   │
│   ├── onboarding/                # Écran d'introduction (pré-connexion)
│   ├── splash/                    # Écran de démarrage initial
│   │
│   ├── home/                      # Feed d'accueil avec produits
│   ├── search/                    # Recherche de produits & utilisateurs
│   ├── messages/                  # Système de messagerie (placeholder)
│   ├── profile/                   # Gestion du profil utilisateur
│   │
│   ├── product/                   # Annonces de produits
│   │   ├── application/           # Providers produits
│   │   ├── data/                  # Modèles Product/Category
│   │   ├── domain/                # Entités & interfaces repositories
│   │   └── presentation/          # UI produits
│   │
│   ├── create_product/            # Flux de création d'annonce (vide)
│   └── sell/                      # Tableau de bord vendeur
│       └── presentation/
│           └── widgets/
│               └── sell_bottom_sheet.dart  # Bottom sheet de création d'annonce
│
├── shared/                        # Composants cross-features
│   └── widgets/                   # Widgets UI réutilisables
│       ├── buttons/               # Boutons personnalisés
│       ├── product_card.dart      # Carte produit (style Vinted)
│       ├── input.dart             # Champs de saisie
│       ├── filter_chip_list.dart  # Filtres par chips
│       └── ...
│
├── l10n/                          # Internationalisation
│   ├── app_en.arb                # Traductions anglais
│   ├── app_fr.arb                # Traductions français
│   └── generated/                # Fichiers auto-générés
│
├── scripts/                       # Scripts utilitaires
│   ├── seed_categories.dart       # Peupler Firestore avec catégories
│   ├── seed_to_firestore.dart     # Importer données de test
│   └── gen_l10n/                  # Génération localisation
│
└── main.dart                      # Point d'entrée de l'app
```

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
| **Firebase Storage** | 13.0.4 | Hébergement images produits |
| **Firebase App Check** | 0.4.1+3 | Protection anti-fraude API |
| **Cloud Functions** | - | Backend serverless (Node.js, dans `functions/`) |

### Authentification Sociale
| Package | Version | Plateformes |
|---------|---------|-------------|
| **Google Sign-In** | 6.2.1 | Android, iOS, Web |
| **Flutter Facebook Auth** | 6.0.4 | Android, iOS, Web |
| **Sign in with Apple** | 6.1.3 | iOS, macOS |

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
| **Image Picker** | 1.0.7 | Accès caméra & galerie photo |
| **WebView Flutter** | 4.10.0 | Intégration reCAPTCHA v2 |

### Données & Sécurité
| Package | Version | Usage |
|---------|---------|-------|
| **Shared Preferences** | 2.5.3 | Stockage local persistant |
| **Intl** | latest | Internationalisation (i18n) |
| **HTTP** | 1.2.0 | Client HTTP pour appels API |

---

## 🌍 Plateformes Supportées

| Plateforme | Statut | Version Minimale |
|------------|--------|------------------|
| **Android** | ✅ Opérationnel | API 21 (Android 5.0) |
| **iOS** | ✅ Opérationnel | iOS 11.0+ |
| **Web** | ✅ Opérationnel | Navigateurs modernes (Chrome, Safari, Firefox) |
| **macOS** | ✅ Opérationnel | macOS 10.11+ |
| **Windows** | ✅ Opérationnel | Windows 10+ |
| **Linux** | ✅ Opérationnel | Ubuntu 18.04+ |

**Note** : L'application est entièrement cross-platform grâce à Flutter. Le backend Firebase fonctionne sur toutes les plateformes.

---

## ✅ Fonctionnalités Implémentées

### 1. 🔐 Authentification & Gestion Utilisateurs

#### ✅ Connexion Sociale
- **Google Sign-In** : Connexion via compte Google (Android, iOS, Web)
- **Facebook Login** : Connexion via compte Facebook (Android, iOS, Web)
- **Apple Sign-In** : Connexion via Apple ID (iOS, macOS)
- Gestion automatique du flux d'authentification
- Récupération des données de profil (email, nom, photo)

#### ✅ Authentification Email/Mot de passe
- Inscription classique avec email
- Connexion avec email/mot de passe
- Validation de format d'email
- Gestion des erreurs (email déjà utilisé, mot de passe faible, etc.)

#### ✅ Flux d'Inscription Complet
**Étapes du flow** :
1. **Écran d'onboarding** : Présentation de l'app avec animations
2. **Choix méthode connexion** : Google, Facebook, Apple ou Email
3. **Page Username** : Saisie nom d'utilisateur unique avec suggestion automatique
4. **Page Captcha** : Vérification anti-bot (structure en place)
5. **Sélection Pays** : Choix entre Togo 🇹🇬 et Bénin 🇧🇯
6. **Finalisation** : Sauvegarde dans Firestore et redirection vers accueil

#### ✅ Entité User Complète
L'entité utilisateur contient :
- **Identifiants** : `uid`, `email`, `username` (unique)
- **Informations profil** : `displayName`, `photoUrl`, `phoneNumber`
- **Localisation** : `country` (Togo/Bénin), `city`
- **Méthode auth** : `authProvider` (google/facebook/apple/email), `providerId`
- **Consentements** : `acceptedTerms`, `marketingEmailsEnabled`
- **Métadonnées** : `createdAt`, `updatedAt`, `isVerified`, `isActive`
- **Stats vendeur** : `productsCount`, `salesCount`, `rating`, `reviewsCount`

#### ✅ Validation & Sécurité
- Vérification username unique en temps réel (requête Firestore)
- Validation format username (3-30 caractères, alphanumérique + tirets/underscores)
- Acceptation conditions générales obligatoire
- Sauvegarde sécurisée dans Firestore avec transaction atomique
- Réservation du username dans collection dédiée (`usernames/{username}`)

#### ✅ Providers Riverpod
- `authStateProvider` : État global d'authentification (StreamProvider)
- `currentUserProvider` : Données utilisateur connecté
- `isProfileCompleteProvider` : Vérifie si profil complet
- `registrationProvider` : Gestion du state du flux d'inscription

---

### 2. 🗂️ Système de Catégories & Produits

#### ✅ Structure Hiérarchique de Catégories
- **Catégories niveau 1** : Vêtements, Accessoires, Électronique, etc.
- **Sous-catégories imbriquées** : Ex. Vêtements → Femme → Chemises
- **Attributs dynamiques** : Chaque catégorie finale a ses propres champs (Marque, Taille, Couleur, etc.)
- Stockage dans Firestore avec relations parent-child
- Ordre d'affichage personnalisable
- Icônes et descriptions pour chaque catégorie

#### ✅ Entité Product
Un produit contient :
- **Informations de base** : `id`, `title`, `description`, `price` (en FCFA)
- **Images** : `imageUrls` (liste de 1 à 6 photos)
- **État** : `condition` (neuf avec étiquette, excellent, bon, satisfaisant, usé)
- **Catégorisation** : `categoryId` (niveau 1), `subcategoryId` (catégorie finale)
- **Attributs dynamiques** : Map `attributes` (ex: `{'brand': 'Nike', 'size': 'M'}`)
- **Vendeur** : `sellerId` (référence vers collection `users`)
- **Statut** : `isSold`, `isActive`, `isBoosted`
- **Dates** : `createdAt`, `updatedAt`

#### ✅ Repositories Implémentés
- **ProductRepository** :
  - `createProduct()` : Créer une annonce avec génération ID auto
  - `updateProduct()` : Modifier une annonce existante
  - `deleteProduct()` : Supprimer une annonce
  - `getProductById()` : Récupérer un produit par ID
  - `getProducts()` : Liste paginée de produits (20 par page)
  - `getProductsBySeller()` : Produits d'un vendeur spécifique
  - `getProductsByCategory()` : Filtrer par catégorie
  - `searchProducts()` : Recherche textuelle
  
- **CategoryRepository** :
  - `getCategories()` : Toutes les catégories niveau 1
  - `getCategoryById()` : Une catégorie spécifique
  - `getSubcategories()` : Toutes les sous-catégories
  - `getSubcategoryById()` : Une sous-catégorie spécifique
  - `getSubcategoriesByParent()` : Enfants d'une catégorie
  - Streams pour écoute temps réel

#### ✅ Providers Riverpod
- `productRepositoryProvider` : Instance du repository produits
- `categoryRepositoryProvider` : Instance du repository catégories
- `allProductsProvider` : FutureProvider pour tous les produits
- `paginatedProductsProvider` : StateNotifier pour pagination infinie
- `productDetailProvider` : Produit par ID
- `categoriesProvider` : Toutes les catégories
- `subcategoriesProvider` : Toutes les sous-catégories

---

### 3. 🎨 Interface Utilisateur & Design

#### ✅ Écrans Implémentés

**Authentification**
- ✅ **SplashScreen** : Écran de démarrage avec logo et chargement
- ✅ **OnboardingPage** : Présentation de l'app avec grille d'images animées défilantes
- ✅ **LoginScreen** : Connexion email/mot de passe
- ✅ **EmailSignupScreen** : Inscription par email
- ✅ **UsernamePage** : Saisie du nom d'utilisateur avec suggestion auto
- ✅ **CaptchaPage** : Vérification anti-bot (WebView reCAPTCHA v2)
- ✅ **CountrySelectionPage** : Sélection Togo ou Bénin avec drapeaux

**Navigation Principale (Bottom Navigation Bar)**
- ✅ **HomePage** : Feed d'accueil avec :
  - Barre de recherche en haut
  - Filtres par catégories (chips horizontales)
  - Grille de produits paginée (2 colonnes)
  - Scroll infini avec chargement automatique
  - Refresh pull-to-refresh
  
- ✅ **SearchPage** : Recherche avancée (structure existante)
- ✅ **MessagesPage** : Page messagerie (placeholder pour l'instant)
- ✅ **ProfilePage** : Profil utilisateur avec :
  - Avatar et informations
  - Toggle thème clair/sombre
  - Sélecteur de langue (FR/EN)
  - Bouton déconnexion

**Produits**
- ✅ **ProductDetailPage** : Page détail d'un produit avec :
  - Carrousel d'images (swipe horizontal)
  - Titre, prix, état du produit
  - Description expandable (lire plus/moins)
  - Informations vendeur (avatar, nom, note)
  - Onglets "Produits du vendeur" et "Produits similaires"
  - Bouton "Acheter" ou "Contacter le vendeur"

**Vente**
- ✅ **SellBottomSheet** : Bottom sheet plein écran pour créer une annonce avec :
  - Grille de sélection d'images (1-6 photos, caméra ou galerie)
  - Champ titre (obligatoire)
  - Champ description (obligatoire)
  - Sélection catégorie hiérarchique (navigation imbriquée)
  - Sélection état du produit (neuf, excellent, bon, etc.)
  - Champ prix en FCFA
  - Formulaire dynamique d'attributs selon catégorie
  - Bouton de publication
  - Upload des images vers Firebase Storage
  - Sauvegarde dans Firestore

#### ✅ Widgets Réutilisables
- **ProductCard** : Carte produit style Vinted (image, titre, prix, cœur favoris)
- **Input** : Champ de saisie personnalisé avec validation
- **CustomButton** : Boutons primaires/secondaires
- **FilterChipList** : Liste horizontale de filtres (catégories)
- **SelectionTile** : Tuile de sélection pour listes
- **Link** : Liens textuels cliquables
- **CustomCheckbox** : Checkbox avec label personnalisé
- **RecaptchaWidget** : WebView pour reCAPTCHA

#### ✅ Navigation
- **GoRouter** configuré avec routes déclaratives
- **Redirections automatiques** basées sur l'état auth :
  - Non connecté → `/onboarding`
  - Connecté sans profil complet → `/auth/username`
  - Connecté avec profil complet → `/home`
- **StatefulShellRoute** pour bottom navigation (persistance état)
- **Deep linking** supporté
- Routes nommées pour navigation facile (`context.go('/home')`)

---

### 4. 🎨 Thème & Localisation

#### ✅ Système de Thème
- **Mode clair** : Thème Material 3 avec palette personnalisée
- **Mode sombre** : Thème sombre adapté
- **Toggle dynamique** : Changement thème en temps réel sans redémarrage
- **Persistance** : Préférence sauvegardée localement (Shared Preferences)
- **ThemeProvider** : StateNotifier Riverpod pour gestion du state

#### ✅ Internationalisation (i18n)
- **Langues supportées** :
  - 🇫🇷 **Français** (par défaut)
  - 🇬🇧 **Anglais**
- **Fichiers ARB** : `app_fr.arb` et `app_en.arb` avec toutes les traductions
- **Génération automatique** : `flutter gen-l10n` génère `AppLocalizations`
- **Changement langue** : Sélection dans ProfilePage avec effet immédiat
- **Persistance** : Langue sauvegardée localement
- **LocaleProvider** : StateNotifier Riverpod pour gestion

**Utilisation dans le code** :
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.welcome); // Affiche "Bienvenue" ou "Welcome"
```

---

### 5. 🔐 Sécurité & Règles Firestore

#### ✅ Firestore Security Rules
Fichier `firestore.rules` complet avec :
- **Collection `users`** :
  - Lecture publique (tous peuvent voir les profils)
  - Création uniquement par le propriétaire (vérification UID)
  - Mise à jour uniquement par le propriétaire
  - Validation des champs obligatoires (username, email, country)
  - Protection des champs sensibles (uid, email non modifiables)
  
- **Collection `products`** :
  - Lecture publique (tous peuvent voir les annonces)
  - Création uniquement par utilisateurs authentifiés
  - Mise à jour/suppression uniquement par le vendeur
  - Validation des champs (prix > 0, 1-6 images, etc.)
  
- **Collections `categories` et `subcategories`** :
  - Lecture publique
  - Écriture réservée aux admins
  
- **Collection `messages`** :
  - Lecture/écriture uniquement par participants de la conversation
  
- **Collection `reviews`** :
  - Lecture publique
  - Écriture uniquement par acheteurs vérifiés

#### ✅ Validation des Données
- Validation côté client (formulaires Flutter)
- Validation côté serveur (Security Rules Firestore)
- Types de données vérifiés (string, number, boolean)
- Longueurs de champs vérifiées (ex: username 3-30 caractères)
- Valeurs requises vérifiées (ex: acceptedTerms must be true)

#### ✅ Firebase App Check
- Protection anti-fraude activée
- Validation des requêtes API
- Prévention des abus et spam

---

### 6. 🛠️ Gestion des Erreurs

#### ✅ Système d'Exceptions Personnalisées
Hiérarchie complète d'exceptions typées dans `lib/core/exceptions/` :

```
AppException (classe de base)
├── AuthException
│   ├── NotAuthenticatedException
│   ├── InvalidCredentialsException
│   ├── UsernameTakenException
│   ├── EmailAlreadyUsedException
│   ├── WeakPasswordException
│   ├── UserDisabledException
│   └── IncompleteProfileException
│
├── ProductException
│   ├── ProductNotFoundException
│   ├── ProductAccessDeniedException
│   ├── InvalidProductDataException
│   ├── InvalidPriceException
│   ├── InvalidImagesException
│   ├── CategoryNotFoundException
│   └── ProductAlreadySoldException
│
├── DatabaseException
│   ├── NetworkException
│   ├── TimeoutException
│   ├── PermissionDeniedException
│   └── QuotaExceededException
│
└── StorageException
    ├── UploadFailedException
    └── DownloadFailedException
```

#### ✅ Affichage des Erreurs
Chaque exception a des méthodes intégrées :
- `.showAsSnackBar(context)` : Affiche un snackbar en bas de l'écran
- `.showAsDialog(context)` : Affiche un dialogue modal
- `.userMessage` : Message localisé pour l'utilisateur
- `.technicalMessage` : Message technique pour les logs

#### ✅ Gestion dans les Repositories
- Exceptions Firebase automatiquement converties en `AppException`
- Stack traces préservées pour debugging
- Erreurs réseau gérées spécifiquement
- Timeouts détectés et signalés

#### ✅ Logging
- `ErrorLogger` service pour centraliser les logs
- Affichage en console en mode debug
- (Future: intégration Firebase Crashlytics pour production)

**Documentation** : Voir [GESTION_EXCEPTIONS.md](GESTION_EXCEPTIONS.md) pour guide complet.

---

### 7. 🗄️ Base de Données Firestore

#### ✅ Collections Implémentées

**`users/{userId}`**
```dart
{
  uid: string,                    // Firebase Auth UID
  email: string,                  // Email utilisateur
  username: string,               // Nom d'utilisateur unique
  displayName?: string,           // Nom complet (optionnel)
  photoUrl?: string,              // URL photo de profil
  phoneNumber?: string,           // Téléphone (optionnel)
  authProvider: string,           // 'google', 'facebook', 'apple', 'email'
  providerId?: string,            // ID du provider social
  country: string,                // 'togo' ou 'benin'
  city?: string,                  // Ville (optionnel)
  acceptedTerms: boolean,         // Acceptation CGU
  acceptedTermsDate: timestamp,   // Date acceptation
  marketingEmailsEnabled: boolean,// Consentement emails
  createdAt: timestamp,           // Date création compte
  updatedAt: timestamp,           // Dernière mise à jour
  isVerified: boolean,            // Email vérifié
  isActive: boolean,              // Compte actif/suspendu
  productsCount: int,             // Nombre d'annonces
  salesCount: int,                // Nombre de ventes
  rating: double,                 // Note moyenne vendeur (0-5)
  reviewsCount: int,              // Nombre d'avis reçus
}
```

**`products/{productId}`**
```dart
{
  id: string,                     // ID Firestore auto-généré
  title: string,                  // Titre de l'annonce
  description: string,            // Description détaillée
  price: double,                  // Prix en FCFA
  imageUrls: [string],           // URLs des photos (1-6)
  condition: string,              // 'newWithTags', 'excellent', 'good', 'satisfactory', 'worn'
  sellerId: string,               // Référence vers users/{sellerId}
  categoryId: string,             // Catégorie niveau 1
  subcategoryId: string,          // Sous-catégorie finale
  attributes: {                   // Attributs dynamiques
    brand?: string,
    size?: string,
    color?: string,
    // ... autres selon catégorie
  },
  isBoosted: boolean,            // Annonce promue
  isSold: boolean,               // Produit vendu
  isActive: boolean,              // Annonce active
  createdAt: timestamp,           // Date publication
  updatedAt: timestamp,           // Dernière modification
}
```

**`categories/{categoryId}`**
```dart
{
  id: string,                     // ID catégorie
  name: string,                   // Nom catégorie
  iconUrl?: string,              // URL icône
  description?: string,           // Description
  order: int,                     // Ordre d'affichage
  children: [string],             // IDs des sous-catégories
  isActive: boolean,              // Activée/désactivée
  createdAt: timestamp,
  updatedAt: timestamp,
}
```

**`subcategories/{subcategoryId}`**
```dart
{
  id: string,                     // ID sous-catégorie
  name: string,                   // Nom sous-catégorie
  parentId: string,               // ID catégorie parente
  children: [string],             // IDs enfants (hiérarchie)
  attributes: [string],           // Noms des attributs (ex: ['brand', 'size', 'color'])
  order: int,                     // Ordre d'affichage
  iconUrl?: string,
  isActive: boolean,
  createdAt: timestamp,
  updatedAt: timestamp,
}
```

**`usernames/{username}`** (Collection de réservation)
```dart
{
  uid: string,                    // UID du propriétaire
  createdAt: timestamp,           // Date réservation
}
```

**`messages/{conversationId}`** (Structure prête, pas encore utilisée)
```dart
{
  participants: [string],         // UIDs des participants
  lastMessage: string,            // Aperçu dernier message
  lastMessageTime: timestamp,     // Date dernier message
  unreadCount: {                  // Compteur non-lus par user
    userId: int
  },
  createdAt: timestamp,
  // Sous-collection messages/{messageId}
}
```

**`reviews/{reviewId}`** (Structure prête, pas encore utilisée)
```dart
{
  sellerId: string,               // Vendeur évalué
  buyerId: string,                // Acheteur qui évalue
  rating: int,                    // Note 1-5 étoiles
  text: string,                   // Commentaire
  productId: string,              // Produit lié
  createdAt: timestamp,
}
```

#### ✅ Index Firestore
Fichier `firestore.indexes.json` avec indexes pour :
- Requêtes sur `products` par `createdAt` descendant
- Requêtes sur `products` par `categoryId` + `createdAt`
- Requêtes sur `products` par `sellerId` + `createdAt`
- Recherche textuelle (à optimiser avec Algolia ou ElasticSearch)

---

### 8. 🔧 Configuration Firebase

#### ✅ Projet Firebase
- **Projet** : `ablony-a5db9`
- **Région** : `europe-west1` (Belgique)
- **Console** : https://console.firebase.google.com/project/ablony-a5db9

#### ✅ Services Activés
- ✅ **Authentication** : Email, Google, Facebook, Apple
- ✅ **Cloud Firestore** : Base de données
- ✅ **Firebase Storage** : Stockage images
- ✅ **Firebase App Check** : Sécurité API
- ✅ **Cloud Functions** : Backend serverless (Node.js dans `functions/`)

#### ✅ Configuration Multi-Plateforme
- ✅ **Android** : `android/app/google-services.json`
- ✅ **iOS** : Configuration dans Xcode
- ✅ **Web** : Variables d'environnement dans code
- ✅ **Toutes plateformes** : `lib/firebase_options.dart` (auto-généré via FlutterFire CLI)

#### ✅ Émulateurs Locaux
Configuration dans `lib/core/config/firebase_config.dart` :
- **Auth Emulator** : `localhost:9099`
- **Firestore Emulator** : `localhost:8080`
- **Storage Emulator** : `localhost:9199`
- Activation conditionnelle en mode debug uniquement
- Commande de lancement : `firebase emulators:start`

**Documentation** : Voir [FIREBASE_SETUP.md](FIREBASE_SETUP.md) pour guide complet.

---

### 9. 📊 Providers Riverpod (State Management)

#### ✅ Providers Globaux (dans `lib/core/providers/`)
- **`themeProvider`** : StateNotifier<ThemeMode>
  - Gère le thème clair/sombre/système
  - Persistance locale avec Shared Preferences
  
- **`localeProvider`** : StateNotifier<Locale>
  - Gère la langue FR/EN
  - Persistance locale avec Shared Preferences
  
- **`authStateProvider`** : StreamProvider<User?>
  - Écoute les changements d'état auth Firebase
  - null si déconnecté, User si connecté
  
- **`currentUserProvider`** : FutureProvider<User?>
  - Charge les données complètes de l'utilisateur depuis Firestore
  
- **`isProfileCompleteProvider`** : Provider<bool>
  - Vérifie si profil utilisateur complet (username + country)

#### ✅ Providers Authentification (dans `lib/features/auth/application/`)
- **`authRepositoryProvider`** : Provider<AuthRepository>
  - Instance du repository d'authentification
  
- **`registrationProvider`** : StateNotifierProvider<RegistrationState>
  - Gère le state du flow d'inscription (données collectées)
  
- **`suggestedUsernameProvider`** : FutureProvider<String>
  - Génère une suggestion de username automatique
  
- **`usernameAvailabilityProvider`** : FutureProvider<bool>
  - Vérifie disponibilité d'un username en temps réel

#### ✅ Providers Produits (dans `lib/features/product/presentation/providers/`)
- **`productRepositoryProvider`** : Provider<ProductRepository>
- **`categoryRepositoryProvider`** : Provider<CategoryRepository>
- **`allProductsProvider`** : FutureProvider<List<Product>>
  - Charge tous les produits (limite 20)
  
- **`paginatedProductsProvider`** : StateNotifierProvider
  - Gestion pagination infinie avec scroll
  - Chargement automatique au scroll
  
- **`productDetailProvider(productId)`** : FutureProvider<Product>
  - Produit par ID avec mise en cache
  
- **`categoriesProvider`** : FutureProvider<List<Category>>
- **`subcategoriesProvider`** : FutureProvider<List<Subcategory>>

---

### 10. 🚀 Scripts & Outils

#### ✅ Scripts Dart (dans `lib/scripts/`)
- **`seed_categories.dart`** : Script pour peupler Firestore avec catégories de test
- **`seed_to_firestore.dart`** : Script d'import de données JSON vers Firestore

#### ✅ Commandes Utiles
```bash
# Installation des dépendances
flutter pub get

# Génération des traductions
flutter gen-l10n

# Lancer l'app (avec émulateurs Firebase)
firebase emulators:start  # Terminal 1
flutter run               # Terminal 2

# Build production
flutter build apk         # Android
flutter build ios         # iOS
flutter build web         # Web

# Analyse du code
flutter analyze           # Linter
dart fix --apply          # Corrections automatiques

# Firebase CLI
firebase deploy --only firestore:rules  # Déployer rules
firebase deploy --only firestore:indexes # Déployer indexes
firebase functions:log                   # Voir logs Cloud Functions
```

---

## 📂 Fichiers de Configuration

### ✅ Fichiers Clés
- **`pubspec.yaml`** : Dépendances Flutter et configuration package
- **`firebase.json`** : Configuration Firebase CLI
- **`firestore.rules`** : Règles de sécurité Firestore
- **`firestore.indexes.json`** : Index Firestore pour requêtes
- **`storage.rules`** : Règles Firebase Storage
- **`l10n.yaml`** : Configuration localisation (ARB files)
- **`analysis_options.yaml`** : Règles du linter Dart
- **`android/app/build.gradle.kts`** : Configuration build Android
- **`ios/Runner.xcodeproj`** : Configuration Xcode iOS
- **`functions/index.js`** : Cloud Functions Node.js

---

## 📈 Statistiques du Projet

| Métrique | Valeur |
|----------|--------|
| **Lignes de code** | ~8000+ |
| **Fichiers Dart** | ~60+ |
| **Modules features** | 10 (auth, product, home, search, profile, etc.) |
| **Widgets réutilisables** | 15+ |
| **Pages implémentées** | 12+ |
| **Providers Riverpod** | 25+ |
| **Entities (Domain)** | 8 (User, Product, Category, Subcategory, etc.) |
| **Repositories** | 3 (Auth, Product, Category) |
| **Langues supportées** | 2 (Français, Anglais) |
| **Plateformes** | 6 (Android, iOS, Web, macOS, Windows, Linux) |

---

## 🚧 État Actuel & Limitations

### Ce qui fonctionne parfaitement
✅ Authentification complète (social + email)  
✅ Flux d'inscription de bout en bout  
✅ Création et affichage de produits  
✅ Navigation avec bottom bar  
✅ Pagination et filtres basiques  
✅ Thème clair/sombre  
✅ Localisation FR/EN  
✅ Upload d'images vers Firebase Storage  
✅ Sécurité Firestore complète  

### Ce qui est en cours ou incomplet
🔄 **Messagerie** : Structure Firestore prête mais UI placeholder  
🔄 **Recherche avancée** : Structure existante mais filtres non implémentés  
🔄 **Profil utilisateur** : Page basique sans édition complète  
🔄 **Avis/Notes** : Structure Firestore prête mais UI non implémentée  
🔄 **Notifications** : Non implémenté  
🔄 **Paiements** : Non implémenté (mobile money prévu)  
🔄 **Tests** : Aucun test unitaire/widget/e2e pour l'instant  

---

## 🔄 Configuration Développement

### Prérequis
```bash
# Flutter SDK 3.10.0+
flutter doctor

# Firebase CLI
npm install -g firebase-tools
firebase login

# Node.js pour Cloud Functions
node --version  # v18+
```

### Installation
```bash
# Cloner le repo
git clone <repo-url>
cd ablony

# Installer dépendances Flutter
flutter pub get

# Générer localizations
flutter gen-l10n

# Configurer Firebase (si première fois)
firebase use ablony-a5db9

# Lancer émulateurs Firebase (optionnel)
firebase emulators:start
```

### Lancer l'App
```bash
# Avec émulateurs (recommandé en dev)
flutter run

# Sur un appareil spécifique
flutter devices              # Lister les appareils
flutter run -d <device-id>

# En mode release
flutter run --release
```

---

## 📝 Notes pour Développeurs & LLMs

### Comprendre rapidement le projet
1. **Point d'entrée** : [lib/main.dart](lib/main.dart)
2. **Configuration routes** : [lib/core/navigation/app_router.dart](lib/core/navigation/app_router.dart)
3. **Feature de référence** : [lib/features/auth/](lib/features/auth/) (la plus complète)
4. **Structure produit** : [lib/features/product/](lib/features/product/)
5. **Règles de sécurité** : [firestore.rules](firestore.rules)

### Patterns Architecturaux
**Clean Architecture stricte** :
- Domain layer = Dart pur (entities, repository interfaces)
- Data layer = Implémentations Firebase (models, repository impl)
- Application layer = Riverpod providers (state management)
- Presentation layer = Widgets Flutter (pages, composants)

**Gestion des Erreurs** :
- Les repositories lancent des `AppException` typées
- L'UI catch et affiche avec `.showAsSnackBar()` ou `.showAsDialog()`
- Jamais de `Exception()` générique

**Navigation** :
- Utiliser `context.go('/route')` pour navigation
- Utiliser `context.push('/route')` pour empiler
- Routes nommées définies dans `app_router.dart`

**State Management** :
- Riverpod pour tout le state
- `FutureProvider` pour data async one-shot
- `StreamProvider` pour data temps réel
- `StateNotifierProvider` pour state mutable complexe
- `Provider` pour dépendances (repositories)

**Localisation** :
- Toujours utiliser `AppLocalizations.of(context)!.key`
- Ajouter nouvelles clés dans `app_fr.arb` ET `app_en.arb`
- Exécuter `flutter gen-l10n` après modification

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
**Dernière révision** : 11 janvier 2026  
**Prochaine révision** : Recommandée après chaque fonctionnalité majeure complétée
