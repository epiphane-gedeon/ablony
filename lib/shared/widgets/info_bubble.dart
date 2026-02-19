import 'package:flutter/material.dart';

/// Widget d'info-bulle personnalisable
///
/// Affiche une icône qui, lorsqu'on clique dessus, affiche une petite bulle
/// contextuelle avec un message et un lien optionnel.
///
/// Paramètres :
/// - [message] : Le texte à afficher dans l'info-bulle (requis)
/// - [link] : Widget de lien optionnel à afficher après le message
/// - [iconColor] : Couleur de l'icône (optionnel)
/// - [backgroundColor] : Couleur de fond de l'info-bulle (optionnel)
/// - [displayDuration] : Durée d'affichage en secondes (défaut: 5 secondes)
/// - [icon] : Icône à afficher (défaut: Icons.info_outline)
/// - [iconSize] : Taille de l'icône (défaut: 20)
/// - [maxWidth] : Largeur maximale de la bulle (défaut: 250)
///
/// Exemple d'utilisation :
/// ```dart
/// InfoBubble(
///   message: 'Ceci est un message d\'information',
///   link: TextButton(
///     onPressed: () => print('En savoir plus'),
///     child: Text('En savoir plus'),
///   ),
///   displayDuration: 5,
/// )
/// ```
class InfoBubble extends StatefulWidget {
  /// Le message à afficher dans l'info-bulle
  final String message;

  /// Widget de lien optionnel à afficher après le message
  final Widget? link;

  /// Couleur de l'icône
  final Color? iconColor;

  /// Couleur de fond de l'info-bulle
  final Color? backgroundColor;

  /// Durée d'affichage en secondes (défaut: 5 secondes)
  final int displayDuration;

  /// Icône à afficher
  final IconData icon;

  /// Taille de l'icône
  final double iconSize;

  /// Largeur maximale de la bulle
  final double maxWidth;

  const InfoBubble({
    super.key,
    required this.message,
    this.link,
    this.iconColor,
    this.backgroundColor,
    this.displayDuration = 5,
    this.icon = Icons.info_outline,
    this.iconSize = 20,
    this.maxWidth = 250,
  });

  @override
  State<InfoBubble> createState() => _InfoBubbleState();
}

class _InfoBubbleState extends State<InfoBubble> {
  OverlayEntry? _overlayEntry;

  void _showBubble() {
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideBubble,
        behavior: HitTestBehavior.translucent,
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                right:
                    MediaQuery.of(context).size.width - offset.dx - size.width,
                top: offset.dy + size.height + 5,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: widget.maxWidth,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          widget.backgroundColor ??
                          theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.link != null) ...[
                          const SizedBox(height: 8),
                          widget.link!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);

    // Fermer automatiquement après le délai
    Future.delayed(Duration(seconds: widget.displayDuration), () {
      _hideBubble();
    });
  }

  void _hideBubble() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideBubble();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        if (_overlayEntry == null) {
          _showBubble();
        } else {
          _hideBubble();
        }
      },
      child: Icon(
        widget.icon,
        size: widget.iconSize,
        color: widget.iconColor ?? theme.colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}
