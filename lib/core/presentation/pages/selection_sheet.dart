import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/link.dart';
import '../../responsive/responsive.dart';

/// Bottom sheet générique pour les sélections dynamiques.
///
/// Équivalent de SelectionScreen mais en bottom sheet.
/// Affiche un header avec titre et bouton fermer, et un contenu dynamique.
///
/// **Exemple d'utilisation :**
/// ```dart
/// SelectionSheet.show(
///   context: context,
///   title: 'Marque',
///   content: DynamicSelectionView(
///     config: {
///       'type': 'list',
///       'dataSource': 'brands',
///       'itemKey': 'id',
///       'itemLabel': 'name',
///     },
///     dataSources: {
///       'brands': (_) async => [...],
///     },
///     onResult: (result) {
///       // Gérer le résultat
///     },
///   ),
/// );
/// ```
class SelectionSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onClose;
  final VoidCallback? onClear;

  const SelectionSheet({
    super.key,
    required this.title,
    required this.content,
    this.onClose,
    this.onClear,
  });

  /// Méthode statique pour afficher le bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String title,
    required Widget content,
    VoidCallback? onClose,
    VoidCallback? onClear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectionSheet(
        title: title,
        content: content,
        onClose: onClose,
        onClear: onClear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight, // Plein écran
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: context.layoutHeight() * 0.05,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                ),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Bouton "Effacer" ou espace vide
                if (onClear != null)
                  Link(
                    text: l10n.filterClear,
                    onTap: onClear!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),

          // Contenu dynamique
          Expanded(child: content),
        ],
      ),
    );
  }
}
