/// Widget de dialogue pour la sélection de langue.
///
/// Ce dialogue affiche une liste de langues disponibles avec des radio buttons.
/// L'utilisateur peut sélectionner une langue et valider ou fermer le dialogue.
///
/// Exemple d'utilisation :
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => LanguageSelectorDialog(
///     currentLocale: Locale('fr'),
///     onLocaleChanged: (newLocale) {
///       ref.read(localeProvider.notifier).setLocale(newLocale);
///     },
///   ),
/// );
/// ```

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/buttons.dart';

/// Dialogue de sélection de langue avec style Material Design 3.
///
/// Affiche les langues disponibles avec des radio buttons et permet
/// de valider ou annuler la sélection.
class LanguageSelectorDialog extends StatefulWidget {
  /// La locale actuellement sélectionnée
  final Locale currentLocale;

  /// Callback appelé quand une nouvelle langue est validée
  final ValueChanged<Locale> onLocaleChanged;

  const LanguageSelectorDialog({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  State<LanguageSelectorDialog> createState() => _LanguageSelectorDialogState();
}

class _LanguageSelectorDialogState extends State<LanguageSelectorDialog> {
  // Stocke la locale temporairement sélectionnée (avant validation)
  late Locale _selectedLocale;

  @override
  void initState() {
    super.initState();
    // Initialise avec la locale actuelle
    _selectedLocale = widget.currentLocale;
  }

  /// Map des noms de langues pour chaque code de langue
  /// Utilisé pour afficher le nom de la langue dans sa propre langue
  ///
  /// Note: Ajoutez ici les traductions pour de nouvelles langues quand vous créez
  /// les fichiers ARB correspondants (ex: app_es.arb, app_nl.arb, etc.)
  static const Map<String, _LanguageOption> _languageNames = {
    'fr': _LanguageOption(locale: Locale('fr'), name: 'Français'),
    'en': _LanguageOption(locale: Locale('en'), name: 'English'),
  };

  /// Récupère la liste des langues disponibles depuis AppLocalizations
  List<_LanguageOption> _getAvailableLanguages(BuildContext context) {
    return AppLocalizations.supportedLocales
        .where((locale) => _languageNames.containsKey(locale.languageCode))
        .map((locale) => _languageNames[locale.languageCode]!)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Récupère uniquement les langues disponibles dans l'application
    final availableLanguages = _getAvailableLanguages(context);

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          16,
        ), // Coins arrondis standard (16px au lieu de 28px)
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // TITRE DU DIALOGUE
            // ============================================================
            Text(
              AppLocalizations.of(context)!.changeLanguage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // ============================================================
            // LISTE DES LANGUES AVEC RADIO BUTTONS (uniquement celles disponibles)
            // ============================================================
            ...(availableLanguages.map(
              (language) => _buildLanguageOption(language),
            )),

            const SizedBox(height: 32),

            // ============================================================
            // BOUTON VALIDER
            // ============================================================
            PrimaryButton(
              text: AppLocalizations.of(context)!.validate,
              onPressed: () {
                // Applique la langue sélectionnée
                widget.onLocaleChanged(_selectedLocale);
                // Ferme le dialogue
                Navigator.of(context).pop();
              },
              fontSize: 14, // Taille réduite pour le dialogue
            ),

            const SizedBox(height: 12),

            // ============================================================
            // BOUTON FERMER
            // ============================================================
            SecondaryButton(
              text: AppLocalizations.of(context)!.close,
              onPressed: () {
                // Ferme le dialogue sans rien changer
                Navigator.of(context).pop();
              },
              showBorder: false, // Style TextButton sans bordure
              textColor: Theme.of(context).colorScheme.secondary,
              fontSize: 14, // Taille réduite pour le dialogue
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une option de langue avec un radio button
  Widget _buildLanguageOption(_LanguageOption language) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLocale = language.locale;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            // Nom de la langue (ex: "Français", "English")
            Expanded(
              child: Text(
                language.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // Radio button
            Radio<Locale>(
              value: language.locale,
              groupValue: _selectedLocale,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (Locale? value) {
                if (value != null) {
                  setState(() {
                    _selectedLocale = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Classe représentant une option de langue
class _LanguageOption {
  final Locale locale;
  final String
  name; // Nom de la langue dans sa propre langue (ex: "Français", "English")

  const _LanguageOption({required this.locale, required this.name});
}
