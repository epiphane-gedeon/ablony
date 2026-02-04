import 'package:flutter/material.dart';

/// Bouton principal de l'application (ElevatedButton personnalisé).
///
/// Ce bouton utilise le style ElevatedButton du thème avec un fond coloré.
/// Il est utilisé pour les actions principales (inscription, connexion, etc.).
///
/// Paramètres :
/// - [text] : Le texte affiché sur le bouton (requis)
/// - [onPressed] : La fonction appelée lors du clic (requis)
/// - [isLoading] : Affiche un loader si true (optionnel, défaut: false)
/// - [isFullWidth] : Prend toute la largeur disponible si true (optionnel, défaut: true)
/// - [icon] : Icône à afficher avant le texte (optionnel)
/// - [backgroundColor] : Couleur de fond du bouton (optionnel, défaut: Theme.of(context).colorScheme.primary)
/// - [textColor] : Couleur du texte (optionnel, défaut: Colors.white)
/// - [fontSize] : Taille du texte (optionnel, utilise le thème par défaut si non spécifié)
///
/// Exemple d'utilisation :
/// ```dart
/// PrimaryButton(
///   text: 'S\'inscrire',
///   onPressed: () => print('Inscription'),
///   backgroundColor: Theme.of(context).colorScheme.error,
///   textColor: Colors.white,
///   fontSize: 14,
/// )
/// ```
class PrimaryButton extends StatelessWidget {
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

  /// Couleur de fond du bouton (optionnel, défaut: couleur primaire du thème)
  final Color? backgroundColor;

  /// Couleur du texte et de l'icône (optionnel, défaut: blanc)
  final Color? textColor;

  /// Taille du texte (optionnel, utilise le thème par défaut si non spécifié)
  /// Taille du texte (optionnel, utilise le thème par défaut si non spécifié)
  final double? fontSize;

  /// Rayon de la bordure (optionnel)
  final double? borderRadius;

  /// Padding interne (optionnel)
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Couleur du texte (par défaut blanc, sinon celle fournie)
    final effectiveTextColor = textColor ?? Colors.white;

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

    // Construction du bouton avec style personnalisé si des couleurs sont fournies
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: effectiveTextColor,
              padding: padding,
              shape: borderRadius != null
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius!),
                    )
                  : null,
            )
          : ElevatedButton.styleFrom(
              padding: padding,
              shape: borderRadius != null
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius!),
                    )
                  : null,
            ),
      child: buttonChild,
    );

    // Si fullWidth, on enveloppe dans un SizedBox avec width: double.infinity
    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
