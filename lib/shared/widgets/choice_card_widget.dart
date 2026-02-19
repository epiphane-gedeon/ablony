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

  /// Largeur optionnelle pour contrôler la largeur de la carte
  final double? width;

  /// Icône optionnelle à afficher avant le titre
  final IconData? icon;

  /// Afficher ou non le rond de sélection à droite
  final bool showSelectionCircle;

  const ChoiceCardWidget({
    super.key,
    required this.title,
    this.subTitle,
    required this.isSelected,
    required this.onTap,
    this.isMultiple = false,
    this.height,
    this.width,
    this.icon,
    this.showSelectionCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          // Fond : légèrement teinté si sélectionné, sinon couleur de la carte/surface
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : theme.cardColor,
          // Bordure : primaire si sélectionné, sinon diviseur standard
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icône optionnelle à gauche
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
            ],

            // Contenu principal (titre et sous-titre)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      // Couleur : primaire si sélectionné
                      color: isSelected
                          ? colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  if (subTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subTitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Rond de sélection à droite
            if (showSelectionCircle) ...[
              const SizedBox(width: 12),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : Colors.grey,
                    width: 2,
                  ),
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
