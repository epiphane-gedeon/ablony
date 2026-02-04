import 'package:flutter/material.dart';

/// Widget générique pour une carte de choix (style Radio ou Checkbox).
///
/// Affiche une carte avec un titre principal et un sous-titre optionnel.
/// Change d'apparence lorsqu'elle est sélectionnée.
class ChoiceCardWidget extends StatelessWidget {
  /// Titre principal (ex: Montant)
  final String title;

  /// Sous-titre (ex: "% de réduction")
  final String? subTitle;

  /// Indique si la carte est sélectionnée
  final bool isSelected;

  /// Action au clic
  final VoidCallback onTap;

  /// Si true, le style peut suggérer une sélection multiple (pas de changement majeur visuel 
  /// pour l'instant, mais prêt pour évolution future si besoin de checkbox explicites)
  final bool isMultiple;
  
  /// Hauteur fixe optionnelle pour uniformiser les cartes dans une Row
  final double? height;

  const ChoiceCardWidget({
    super.key,
    required this.title,
    this.subTitle,
    required this.isSelected,
    required this.onTap,
    this.isMultiple = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          // Fond : légèrement teinté si sélectionné, sinon couleur de la carte/surface
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : theme.cardColor,
          // Bordure : primaire si sélectionné, sinon diviseur standard
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                // Couleur : primaire si sélectionné
                color: isSelected ? colorScheme.primary : theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (subTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subTitle!,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
