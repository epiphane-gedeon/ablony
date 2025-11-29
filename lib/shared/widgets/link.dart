/// Widget Link réutilisable qui se comporte comme un lien web HTML.
///
/// Ce widget affiche du texte cliquable sans effet splash/ripple,
/// exactement comme un lien <a> en HTML.
///
/// Exemple d'utilisation simple (utilise le thème par défaut) :
/// ```dart
/// Link(
///   text: 'Ignorer',
///   onTap: () => Navigator.push(...),
/// )
/// ```
///
/// Exemple avec style personnalisé :
/// ```dart
/// Link(
///   text: 'Ignorer',
///   onTap: () => Navigator.push(...),
///   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
///     color: AppColors.textSecondary,
///   ),
/// )
/// ```
///
/// Exemple avec soulignement :
/// ```dart
/// Link(
///   text: 'Notre plateforme',
///   onTap: () => Navigator.push(...),
///   underline: true,
///   style: TextStyle(color: Colors.blue),
/// )
/// ```
///
/// Note : Pour un texte avec plusieurs styles (ex: "À propos : Notre plateforme"),
/// utilisez directement GestureDetector avec RichText.

import 'package:flutter/material.dart';

/// Widget de lien cliquable sans effet visuel au clic.
///
/// Utilise [GestureDetector] au lieu de [TextButton] pour éviter
/// l'effet splash/ripple et imiter le comportement d'un lien web.
class Link extends StatelessWidget {
  /// Le texte à afficher dans le lien
  final String text;

  /// La fonction appelée lors du clic sur le lien
  final VoidCallback onTap;

  /// Si true, le texte sera souligné (par défaut: false)
  final bool underline;

  /// Le style du texte (optionnel, utilise bodyMedium du thème si null)
  /// Vous pouvez passer un TextStyle complet ou utiliser copyWith pour personnaliser
  final TextStyle? style;

  const Link({
    super.key,
    required this.text,
    required this.onTap,
    this.underline = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Récupère le style bodyMedium du thème comme base
    final defaultStyle = Theme.of(context).textTheme.bodyMedium;

    // Fusionne avec le style personnalisé et ajoute le soulignement si nécessaire
    final effectiveStyle = (style ?? defaultStyle)?.copyWith(
      decoration: underline ? TextDecoration.underline : null,
    );

    return GestureDetector(
      onTap: onTap,
      child: Text(text, style: effectiveStyle),
    );
  }
}
