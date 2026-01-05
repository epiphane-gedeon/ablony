import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher une option sélectionnable avec une flèche.
///
/// Utilisé pour la sélection de catégorie, condition, prix, etc.
/// Affiche un label, une valeur optionnelle, et une flèche de navigation.
///
/// **Exemple d'utilisation :**
/// ```dart
/// SelectionTile(
///   label: 'Catégorie',
///   value: 'Chemise',
///   onTap: () => Navigator.push(...),
///   isRequired: true,
///   trailingIcon: Icons.arrow_forward_ios, // Icône personnalisée
/// )
/// ```
class SelectionTile extends StatelessWidget {
  /// Label affiché en haut (ex: "Catégorie")
  final String label;

  /// Valeur sélectionnée (ex: "Chemise"), null si rien n'est sélectionné
  final String? value;

  /// Callback appelé lors du tap
  final VoidCallback onTap;

  /// Indique si le champ est obligatoire (affiche une astérisque)
  final bool isRequired;

  /// Placeholder affiché quand aucune valeur n'est sélectionnée
  final String? placeholder;

  /// Icône personnalisée à afficher à droite (par défaut: chevron_right)
  final IconData? trailingIcon;

  const SelectionTile({
    super.key,
    required this.label,
    this.value,
    required this.onTap,
    this.isRequired = false,
    this.placeholder,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Label + valeur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label avec astérisque si requis
                  Row(
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Valeur ou placeholder
                  Text(
                    hasValue ? value! : (placeholder ?? ''),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: hasValue
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Flèche personnalisable
            Icon(
              trailingIcon ?? Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
