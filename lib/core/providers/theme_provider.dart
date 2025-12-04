/// Fichier: theme_provider.dart
/// Description: Gestion du thème de l'application avec Riverpod.
/// Permet de basculer entre les thèmes clair/sombre et de persister le choix.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clé pour sauvegarder le mode de thème dans SharedPreferences
const String _themeModeKey = 'theme_mode';

/// Notifier pour gérer le mode de thème de l'application.
///
/// Supporte trois modes:
/// - `ThemeMode.system`: Suit le thème du système (par défaut)
/// - `ThemeMode.light`: Force le thème clair
/// - `ThemeMode.dark`: Force le thème sombre
///
/// Le choix de l'utilisateur est automatiquement sauvegardé et restauré.
class ThemeNotifier extends Notifier<ThemeMode> {
  /// Instance de SharedPreferences pour la persistance
  SharedPreferences? _prefs;

  @override
  ThemeMode build() {
    // Charger le thème sauvegardé de manière asynchrone
    _loadThemeMode();
    // Par défaut, suivre le thème système
    return ThemeMode.system;
  }

  /// Charge le mode de thème depuis SharedPreferences
  Future<void> _loadThemeMode() async {
    _prefs = await SharedPreferences.getInstance();
    final savedMode = _prefs?.getString(_themeModeKey);

    if (savedMode != null) {
      switch (savedMode) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        case 'system':
        default:
          state = ThemeMode.system;
          break;
      }
    }
  }

  /// Sauvegarde le mode de thème dans SharedPreferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    _prefs ??= await SharedPreferences.getInstance();
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await _prefs!.setString(_themeModeKey, modeString);
  }

  /// Définit le mode de thème et le sauvegarde
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _saveThemeMode(mode);
  }

  /// Bascule entre les thèmes clair et sombre
  /// (ignore le mode système)
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Retourne au mode système
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
}

/// Provider pour le ThemeNotifier
///
/// Utilisation:
/// ```dart
/// // Lire le mode actuel
/// final themeMode = ref.watch(themeProvider);
///
/// // Changer le thème
/// ref.read(themeProvider.notifier).toggleTheme();
/// ```
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
