# Seed Data - Catégories Ablony

Ce dossier contient les données de configuration pour les catégories, sous-catégories et attributs de produits.

## 📁 Fichiers

- **`categories.json`** : Catégories de niveau 1 (Femme, Homme)
- **`subcategories.json`** : Toutes les sous-catégories (hiérarchie complète)
- **`attributes.json`** : Attributs des produits avec leurs valeurs possibles

## 🚀 Utilisation

### 1. Générer les commandes d'import

```bash
cd /home/epiphane-gedeon/ablony
dart run tools/seed_categories.dart
```

### 2. Exécuter les commandes dans Firebase Console

Le script génère des commandes JavaScript que vous devez copier et exécuter dans la Firebase Console :

1. Ouvrez [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet Ablony
3. Allez dans **Firestore Database**
4. Ouvrez l'onglet **Règles** puis cliquez sur **Console JavaScript** (ou utilisez l'émulateur local)
5. Copiez-collez les commandes générées par le script

## 📝 Structure des données

### Categories (Niveau 1)

```json
{
  "id": "femme",
  "name": "Femme",
  "children": ["haut_femme", "bas_femme", ...],
  "order": 1,
  "isActive": true
}
```

### Subcategories (Tous niveaux)

```json
{
  "id": "chemise_femme",
  "name": "Chemise",
  "parentId": "haut_femme",
  "children": [],
  "attributes": ["brand", "size_haut", "color", "material"],
  "order": 1,
  "isActive": true
}
```

### Attributes

```json
{
  "id": "brand",
  "name": "Marque",
  "type": "select",
  "values": ["Nike", "Zara", ...],
  "isRequired": true,
  "order": 1,
  "isActive": true
}
```

## ✏️ Modification des données

Pour ajouter ou modifier des catégories :

1. Éditez les fichiers JSON dans ce dossier
2. Relancez le script `dart run tools/seed_categories.dart`
3. Exécutez les nouvelles commandes dans Firebase Console

## ⚠️ Important

- Ces fichiers JSON sont la **source de vérité** pour la configuration des catégories
- Ne modifiez **PAS** directement dans Firestore, modifiez ici puis réimportez
- Gardez une sauvegarde avant de faire des modifications importantes
