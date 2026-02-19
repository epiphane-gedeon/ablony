# Ablony - Marketplace Mobile Premium

Ablony est une application mobile de marketplace moderne et élégante, conçue pour faciliter l'achat et la vente de produits entre particuliers. L'application met l'accent sur une expérience utilisateur premium, une navigation fluide et des fonctionnalités de négociation avancées.

## 🚀 Stack Technique

L'application est bâtie sur les technologies les plus robustes de l'écosystème mobile actuel :
 
 - **Framework** : [Flutter](https://flutter.dev) (multi-plateforme : iOS / Android / Web)
 - **Gestionnaire d'État** : [Riverpod](https://riverpod.dev) (architecture réactive et testable)
 - **Backend & Temps Réel** : [Firebase](https://firebase.google.com)
   - **Cloud Firestore** : Base de données NoSQL.
   - **Firebase Authentication** : Connexions via Email, Google, Facebook et Apple (configuration plateforme requise).
   - **Cloud Storage** : Hébergement des photos de produits.
   - **App Check** : Sécurité contre les abus.
 - **Navigation** : [Go Router](https://pub.dev/packages/go_router)
 - **Interface Utilisateur** :
   - Design minimaliste.
   - Polices personnalisées via [Google Fonts](https://pub.dev/packages/google_fonts).
   - Icônes vectorielles via [Flutter SVG](https://pub.dev/packages/flutter_svg).

## ✨ Fonctionnalités Clés

### 1. Authentification & Profil
- **Multi-connexion** : Support complet des comptes Google, Facebook et Apple.
- **Onboarding** : Parcours d'introduction fluide pour les nouveaux utilisateurs.
- **Gestion du Profil** : Édition des informations personnelles et historique de vente.

### 2. Expérience de Marketplace
- **Flux de Produits** : Affichage dynamique des articles par catégories.
- **Recherche Avancée** : Filtres par prix, état, catégorie et localisation.
- **Détails Produits** : Visualisation complète avec galerie d'images, description détaillée et informations sur le vendeur.

### 3. Vente & Gestion des Articles
- **Mise en Vente** : Interface intuitive pour ajouter des photos (via `image_picker`), définir le prix, l'état et la catégorie.
- **Système de Brouillons** : (En cours) Sauvegarde automatique des annonces en cours de rédaction.

### 4. Messagerie & Négociation (Cœur de l'App)
- **Chat en Temps Réel** : Communication instantanée entre acheteur et vendeur via Firestore.
- **Système d'Offres** :
  - **Faire une offre** : L'acheteur peut proposer un prix inférieur au prix affiché.
  - **Gestion des offres** : Le vendeur peut Accepter, Refuser ou faire une Contre-offre directement dans le chat.
  - **Visualisation Clair** : Bulles de message distinctives pour les offres, avec statuts mis à jour en direct.

### 5. Paiement & Wallet
- **Portefeuille Intégré** : Suivi des fonds disponibles et historique des transactions.
- **Solutions Mobiles** : Intégration prévue des paiements mobiles locaux (ex: Mobile Money).

## 📁 Architecture du Projet

Le projet suit une structure modulaire par fonctionnalités ("feature-driven") pour une meilleure scalabilité :

- `lib/core` : Logique transverse (thèmes, navigation, utilitaires, exceptions).
- `lib/features` : Modules indépendants (auth, product, sell, messages, wallet).
- `lib/shared` : Composants UI réutilisables (boutons, inputs, cartes).
- `lib/l10n` : Support multi-langue (Internationalisation).

## 🛠️ Installation & Développement

1. **Prérequis** : Flutter SDK installé et configuré.
2. **Installation** :
   ```bash
   flutter pub get
   ```
3. **Lancement** :
   ```bash
   flutter run
   ```
4. **Génération de code** (Localisation) :
   ```bash
   flutter gen-l10n
   ```

---
*Ce projet est en cours de développement actif.*