import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Widget réutilisable pour les checkboxes avec texte personnalisable.
///
/// Ce widget encapsule une Checkbox avec un texte/message associé qui peut
/// contenir des liens cliquables ou être simple.
///
/// **Fonctionnalités :**
/// - Checkbox personnalisable (couleur, forme)
/// - Message texte ou riche (avec des widgets enfants)
/// - Support des erreurs de validation
/// - Gestion de l'état activé/désactivé
/// - Alignement flexible
///
/// **Exemple d'utilisation simple :**
/// ```dart
/// CustomCheckbox(
///   value: _acceptedTerms,
///   onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
///   message: 'J\'accepte les conditions d\'utilisation',
/// )
/// ```
///
/// **Exemple avec message riche (liens) :**
/// ```dart
/// CustomCheckbox(
///   value: _acceptedTerms,
///   onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
///   richMessage: Wrap(
///     children: [
///       Text('En t\'inscrivant, tu acceptes les '),
///       Link(text: 'CGU', onTap: () => openCGU()),
///       Text(' et la '),
///       Link(text: 'Politique de confidentialité', onTap: () => openPolicy()),
///     ],
///   ),
/// )
/// ```
class CustomCheckbox extends StatelessWidget {
  /// Valeur actuelle de la checkbox (cochée ou non).
  final bool value;

  /// Callback appelé quand l'utilisateur coche/décoche.
  /// Retourne la nouvelle valeur (true/false/null).
  final void Function(bool?)? onChanged;

  /// Message texte simple à afficher à côté de la checkbox.
  /// Utilisez soit [message] soit [richMessage], pas les deux.
  final String? message;

  /// Message riche (avec plusieurs widgets) à afficher à côté de la checkbox.
  /// Permet d'inclure des liens cliquables, du texte formaté, etc.
  /// Utilisez soit [message] soit [richMessage], pas les deux.
  final Widget? richMessage;

  /// Message d'erreur à afficher sous la checkbox si validation échoue.
  final String? errorMessage;

  /// Couleur de la checkbox quand elle est cochée.
  final Color? activeColor;

  /// Couleur de la bordure de la checkbox.
  final Color? checkColor;

  /// Forme de la checkbox (coins arrondis ou carrés).
  final OutlinedBorder? shape;

  /// Active ou désactive la checkbox.
  final bool enabled;

  /// Style du texte du message simple.
  final TextStyle? messageStyle;

  /// Style du texte du message d'erreur.
  final TextStyle? errorStyle;

  /// Espacement entre la checkbox et le message.
  final double spacing;

  /// Padding autour du widget entier.
  final EdgeInsets? padding;

  /// Alignement vertical du contenu.
  final CrossAxisAlignment crossAxisAlignment;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.message,
    this.richMessage,
    this.errorMessage,
    this.activeColor,
    this.checkColor,
    this.shape,
    this.enabled = true,
    this.messageStyle,
    this.errorStyle,
    this.spacing = 8.0,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : assert(
         message == null || richMessage == null,
         'Vous ne pouvez pas fournir à la fois message et richMessage. '
         'Utilisez l\'un ou l\'autre.',
       );

  @override
  Widget build(BuildContext context) {
    // Couleurs par défaut depuis le thème
    final defaultActiveColor = activeColor ?? Theme.of(context).colorScheme.primary;
    final defaultMessageStyle =
        messageStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: enabled ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).textTheme.bodySmall?.color,
        );
    final defaultErrorStyle =
        errorStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // CHECKBOX + MESSAGE
          // ============================================================
          Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              // Checkbox
              Checkbox(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeColor: defaultActiveColor,
                checkColor: checkColor ?? Theme.of(context).colorScheme.onPrimary,
                shape:
                    shape ??
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
              ),

              SizedBox(width: spacing),

              // Message (texte simple ou riche)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildMessage(context, defaultMessageStyle),
                ),
              ),
            ],
          ),

          // ============================================================
          // MESSAGE D'ERREUR (SI PRÉSENT)
          // ============================================================
          if (errorMessage != null && errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 48), // Aligner avec le texte
              child: Text(errorMessage!, style: defaultErrorStyle),
            ),
          ],
        ],
      ),
    );
  }

  /// Construit le message à afficher (simple ou riche).
  Widget _buildMessage(BuildContext context, TextStyle? defaultStyle) {
    if (richMessage != null) {
      // Message riche (avec widgets personnalisés)
      return richMessage!;
    } else if (message != null) {
      // Message texte simple
      return Text(message!, style: defaultStyle);
    } else {
      // Aucun message fourni
      return const SizedBox.shrink();
    }
  }
}
