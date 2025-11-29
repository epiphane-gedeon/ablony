# Guide d'utilisation du thème Ablony

Ce document explique comment utiliser correctement le thème dans toute l'application.

## 🎨 Principe de base

**TOUJOURS utiliser le thème défini dans `app_theme.dart` au lieu de définir des styles manuellement.**

## ✅ Bon usage

```dart
// Utiliser directement le style du thème
Text(
  'Mon texte',
  style: Theme.of(context).textTheme.bodyLarge,
)

// Personnaliser uniquement ce qui est nécessaire
Text(
  'Mon texte',
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    decoration: TextDecoration.underline, // Ajout spécifique
  ),
)
```

## ❌ Mauvais usage

```dart
// Ne PAS redéfinir des propriétés déjà dans le thème
Text(
  'Mon texte',
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: AppColors.textPrimary, // ❌ Déjà défini dans le thème !
    fontSize: 16, // ❌ Déjà défini dans le thème !
  ),
)

// Ne PAS créer des styles manuellement
Text(
  'Mon texte',
  style: TextStyle( // ❌ Ignore complètement le thème
    fontSize: 16,
    color: Colors.black,
  ),
)
```

## 📝 Hiérarchie des styles de texte

Voici les styles disponibles dans le thème et quand les utiliser :

### Display (Très grands titres)
- **displayLarge** (57px, Bold) - Titres héros, écrans d'onboarding
- **displayMedium** (45px, Bold) - Grands titres d'accueil
- **displaySmall** (36px, SemiBold) - Titres importants de pages

### Headline (Titres de sections)
- **headlineLarge** (32px, SemiBold) - Titres de sections principales ✨ *Utilisé pour le slogan onboarding*
- **headlineMedium** (28px, SemiBold) - Titres de sous-sections
- **headlineSmall** (24px, SemiBold) - Titres de catégories

### Title (Titres de composants)
- **titleLarge** (22px, Medium) - Titres de dialogues, bottom sheets
- **titleMedium** (16px, Medium) - Titres de cartes, éléments de liste
- **titleSmall** (14px, Medium) - Petits titres, labels importants

### Body (Texte de contenu)
- **bodyLarge** (16px, Regular) - Paragraphes principaux, texte important ✨ *Utilisé pour le sélecteur de langue*
- **bodyMedium** (14px, Regular) - Texte standard, descriptions
- **bodySmall** (12px, Regular, Gris) - Petits textes, notes, métadonnées ✨ *Utilisé pour "Ignorer" et "À propos"*

### Label (Texte de boutons et badges)
- **labelLarge** (14px, Medium) - Boutons principaux, actions importantes
- **labelMedium** (12px, Medium) - Chips, tags, badges
- **labelSmall** (11px, Medium, Gris) - Petits labels, timestamps

## 🎯 Couleurs définies dans le thème

Les couleurs sont automatiquement appliquées par les styles :
- **textPrimary** (noir) - Texte principal
- **textSecondary** (gris) - Texte secondaire, moins important

## 🔧 Widgets qui utilisent déjà le thème

### Boutons
Les widgets de boutons utilisent automatiquement le thème :
```dart
// PrimaryButton - Utilise automatiquement le thème des ElevatedButton
PrimaryButton(text: 'S\'inscrire', onPressed: () {})

// SecondaryButton - Utilise automatiquement le thème des OutlinedButton
SecondaryButton(text: 'Se connecter', onPressed: () {})
```

### Liens
Le widget Link utilise `bodyMedium` par défaut :
```dart
// Utilise bodyMedium du thème
Link(text: 'Ignorer', onTap: () {})

// Personnalisation si nécessaire
Link(
  text: 'Lien',
  onTap: () {},
  style: Theme.of(context).textTheme.bodySmall, // Utilise un autre style
)
```

## 📋 Checklist avant de valider du code

- [ ] Utilise `Theme.of(context).textTheme.xxx` pour les textes
- [ ] N'utilise `.copyWith()` que pour les propriétés non définies dans le thème
- [ ] Utilise `AppColors` pour les couleurs (ne pas mettre des couleurs en dur)
- [ ] Les widgets réutilisables (boutons, liens) utilisent le thème par défaut

## 🚀 Avantages de cette approche

✅ **Maintenabilité** - Changez le thème une fois, ça s'applique partout
✅ **Cohérence** - Design uniforme dans toute l'application
✅ **Performance** - Pas de création de styles inutiles
✅ **Évolutivité** - Facile d'ajouter un mode sombre ou des variantes
✅ **Accessibilité** - Les tailles et contrastes sont gérés centralement

## 📚 Ressources

- Fichier du thème : `/lib/core/theme/app_theme.dart`
- Couleurs : `/lib/core/theme/app_colors.dart`
- Documentation Material Design 3 : https://m3.material.io/styles/typography/type-scale-tokens
