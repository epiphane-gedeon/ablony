import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Bouton secondaire de l'application (OutlinedButton personnalisé).
///
/// Ce bouton utilise le style OutlinedButton du thème avec une bordure colorée
/// et un fond transparent. Il est utilisé pour les actions secondaires.
///
/// Paramètres :
/// - [text] : Le texte affiché sur le bouton (requis)
/// - [onPressed] : La fonction appelée lors du clic (requis)
/// - [isLoading] : Affiche un loader si true (optionnel, défaut: false)
/// - [isFullWidth] : Prend toute la largeur disponible si true (optionnel, défaut: true)
/// - [icon] : Icône à afficher avant le texte (optionnel)
/// - [customIcon] : Widget personnalisé à afficher avant le texte (optionnel, prioritaire sur icon)
/// - [borderColor] : Couleur de la bordure (optionnel, défaut: AppColors.primary)
/// - [textColor] : Couleur du texte (optionnel, défaut: AppColors.primary)
/// - [fontSize] : Taille du texte (optionnel, utilise le thème par défaut si non spécifié)
/// - [showBorder] : Affiche la bordure si true (optionnel, défaut: true)
///
/// Exemple d'utilisation :
/// ```dart
/// SecondaryButton(
///   text: 'J\'ai déjà un compte',
///   onPressed: () => print('Connexion'),
///   borderColor: AppColors.error,
///   textColor: AppColors.error,
///   fontSize: 14,
///   showBorder: false, // Pour un style TextButton
/// )
/// ```
class SecondaryButton extends StatelessWidget {
  /// Le texte affiché sur le bouton
  final String text;

  /// La fonction appelée lors du clic sur le bouton
  final VoidCallback? onPressed;

  /// Affiche un indicateur de chargement si true
  final bool isLoading;

  /// Si true, le bouton prend toute la largeur disponible
  final bool isFullWidth;

  /// Icône optionnelle à afficher avant le texte
  final IconData? icon;

  /// Widget personnalisé à afficher avant le texte (prioritaire sur icon)
  final Widget? customIcon;

  /// Couleur de la bordure (optionnel, défaut: couleur primaire du thème)
  final Color? borderColor;

  /// Couleur du texte et de l'icône (optionnel, défaut: couleur primaire du thème)
  final Color? textColor;

  /// Taille du texte (optionnel, utilise le thème par défaut si non spécifié)
  final double? fontSize;

  /// Affiche la bordure si true (optionnel, défaut: true)
  final bool showBorder;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.customIcon,
    this.borderColor,
    this.textColor,
    this.fontSize,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    // Couleur du texte (par défaut AppColors.primary, sinon celle fournie)
    final effectiveTextColor = textColor ?? AppColors.primary;
    // Couleur de la bordure (par défaut AppColors.primary, sinon celle fournie)
    final effectiveBorderColor = borderColor ?? AppColors.primary;

    // Contenu du bouton (texte ou loader)
    Widget buttonChild;

    if (isLoading) {
      // Mode chargement : affiche un petit loader circulaire
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
        ),
      );
    } else if (customIcon != null) {
      // Mode avec widget personnalisé : affiche le widget et le texte
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          customIcon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: effectiveTextColor, fontSize: fontSize),
          ),
        ],
      );
    } else if (icon != null) {
      // Mode avec icône : affiche l'icône et le texte
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: effectiveTextColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: effectiveTextColor, fontSize: fontSize),
          ),
        ],
      );
    } else {
      // Mode normal : affiche juste le texte
      buttonChild = Text(
        text,
        style: TextStyle(color: effectiveTextColor, fontSize: fontSize),
      );
    }

    // Construction du bouton avec style personnalisé
    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: (borderColor != null || textColor != null || !showBorder)
          ? OutlinedButton.styleFrom(
              foregroundColor: effectiveTextColor,
              side: showBorder
                  ? BorderSide(color: effectiveBorderColor)
                  : BorderSide.none, // Pas de bordure si showBorder = false
            )
          : null,
      child: buttonChild,
    );

    // Si fullWidth, on enveloppe dans un SizedBox avec width: double.infinity
    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
