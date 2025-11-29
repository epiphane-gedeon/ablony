import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  Locale build() {
    return const Locale('fr'); // Français par défaut
  }

  /// Change la langue de l'application
  void setLocale(Locale locale) {
    state = locale;
    // TODO: Sauvegarder la préférence dans SharedPreferences pour la persistance
  }

  /// Change la langue en utilisant un code de langue (String)
  void setLanguage(String languageCode) {
    setLocale(Locale(languageCode));
  }
}

/// Provider pour accéder à la locale actuelle
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
