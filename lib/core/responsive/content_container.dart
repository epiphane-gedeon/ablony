import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Centre et borne la largeur de son contenu sur les grands écrans.
///
/// Sur téléphone, ce widget est quasiment transparent (il applique juste la
/// marge horizontale de page). Sur ordinateur, il empêche le contenu de
/// s'étirer sur toute la largeur : un formulaire ou un paragraphe étiré sur
/// 1900 px devient illisible et donne l'impression d'une page cassée.
///
/// ```dart
/// ContentContainer(
///   maxWidth: ContentWidth.form,
///   child: Column(children: [...]),
/// )
/// ```
class ContentContainer extends StatelessWidget {
  /// Contenu à contraindre.
  final Widget child;

  /// Largeur maximale — voir [ContentWidth] pour les valeurs usuelles.
  final double maxWidth;

  /// Applique la marge horizontale adaptative de page. Mettre à false quand
  /// le contenu gère déjà son propre padding (listes, grilles).
  final bool applyPadding;

  /// Padding vertical optionnel.
  final double verticalPadding;

  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = ContentWidth.standard,
    this.applyPadding = true,
    this.verticalPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: applyPadding ? context.pagePadding : 0,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
