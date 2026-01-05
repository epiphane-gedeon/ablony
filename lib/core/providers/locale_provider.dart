import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour la gestion de la langue de l'application.
///
/// Ce provider stocke la locale actuelle (fr ou en) et permet de la changer.
/// Il persiste la langue choisie par l'utilisateur.
///
/// Utilisation :
/// ```dart
/// // Lire la langue actuelle
/// final locale = ref.watch(localeProvider);
///
/// // Changer la langue
/// ref.read(localeProvider.notifier).setLocale(const Locale('en'));
/// ```
class LocaleNotifier extends Notifier<Locale> {
  static const String _languageKey = 'selected_language';

  @override
  Locale build() {
    // Charger la langue enregistrée de manière synchrone n'est pas possible
    // avec les SharedPreferences. C'est pourquoi on retourne le français par défaut
    // et on charge la langue enregistrée au démarrage via loadSavedLanguage()
    return const Locale('fr'); // Français par défaut
  }

  /// Charge la langue sauvegardée au démarrage de l'app
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageKey);

    if (savedLanguageCode != null) {
      state = Locale(savedLanguageCode);
    }
  }

  /// Change la langue de l'application et la sauvegarde
  Future<void> setLocale(Locale locale) async {
    state = locale;

    // Sauvegarder dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }

  /// Change la langue en utilisant un code de langue (String)
  Future<void> setLanguage(String languageCode) async {
    await setLocale(Locale(languageCode));
  }
}

/// Provider pour accéder à la locale actuelle
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
