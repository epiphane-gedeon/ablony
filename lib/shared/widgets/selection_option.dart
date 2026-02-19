import 'package:flutter/material.dart';

/// Widget pour une option de sélection avec icône et flèche
///
/// Utilisé pour afficher une option cliquable qui ouvre un détail ou une sélection.
/// L'icône de droite peut être un + ou un > selon le contexte.
///
/// Exemple d'utilisation :
/// ```dart
/// SelectionOption(
///   label: 'Ajouter l\'adresse de livraison',
///   icon: Icons.location_on_outlined,
///   trailingIcon: SelectionOptionIcon.plus,
///   onTap: () => print('Ajouter adresse'),
/// )
/// ```
enum SelectionOptionIcon {
  /// Icône plus (+)
  plus,

  /// Icône flèche droite (>)
  chevron,
}

class SelectionOption extends StatelessWidget {
  /// Le label principal à afficher
  final String label;

  /// Icône optionnelle à afficher à gauche
  final IconData? icon;

  /// Type d'icône à afficher à droite (+ ou >)
  final SelectionOptionIcon trailingIcon;

  /// Action au clic
  final VoidCallback onTap;

  /// Couleur de fond optionnelle
  final Color? backgroundColor;

  /// Couleur de la bordure optionnelle
  final Color? borderColor;

  /// Afficher ou non la bordure
  final bool showBorder;

  const SelectionOption({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon = SelectionOptionIcon.chevron,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          border: showBorder
              ? Border.all(color: borderColor ?? theme.dividerColor, width: 1)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Icône à gauche
            if (icon != null) ...[
              Icon(
                icon,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(width: 12),
            ],

            // Label
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),

            // Icône à droite (+ ou >)
            Icon(
              trailingIcon == SelectionOptionIcon.plus
                  ? Icons.add
                  : Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
