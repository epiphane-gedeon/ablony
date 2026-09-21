import 'package:flutter/material.dart';

/// L'état vide d'un écran : une icône, un titre, une explication.
///
/// Une file vide n'est pas une panne — mais un écran nu s'y trompe. Ce widget
/// dit ce qu'il en est, et **au bon endroit** : sur un grand écran (web,
/// tablette), un contenu mobile étiré occupe toute la largeur et se retrouve
/// collé en haut à gauche. On le contraint donc à une largeur de lecture et on
/// le centre, horizontalement comme verticalement.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Un bouton facultatif — « Actualiser », le plus souvent.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.disabledColor),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
