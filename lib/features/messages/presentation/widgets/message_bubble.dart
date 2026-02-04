import 'package:flutter/material.dart';
import 'package:ablony/shared/widgets/buttons/buttons.dart';

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String? text;
  
  // Paramètres pour les offres
  final bool isOffer;
  final double? offerAmount;
  final String? offerStatus; // 'pending', 'accepted', 'rejected'
  final VoidCallback? onAccept;
  final VoidCallback? onRefuse;
  final VoidCallback? onCounterOffer;
  
  // Paramètre pour contre-offre envoyée (bulle noire avec prix barré)
  final double? originalOfferAmount;

  const MessageBubble({
    super.key,
    required this.isMe,
    this.text,
    this.isOffer = false,
    this.offerAmount,
    this.offerStatus,
    this.onAccept,
    this.onRefuse,
    this.onCounterOffer,
    this.originalOfferAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Couleurs basées sur les screenshots
    // Reçu: Transparent avec bordure
    // Envoyé: Noir pur sans bordure
    final backgroundColor = isMe 
        ? Colors.black 
        : Colors.transparent; 

    final borderRadius = BorderRadius.circular(10);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Espace augmenté
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          // Bordure pour les messages reçus (transparents)
          border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOffer && offerAmount != null)
              _buildOfferContent(context, theme)
            else if (originalOfferAmount != null && offerAmount != null)
              _buildCounterOfferContent(theme)
            else
              Text(
                text ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isMe ? Colors.white : theme.textTheme.bodyMedium?.color,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferContent(BuildContext context, ThemeData theme) {
    return Container(
       child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hey, epiphane-gedeonp t'a fait une offre",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "${offerAmount!.toStringAsFixed(0)} FCFA",
              style: theme.textTheme.bodyLarge?.copyWith( // Taille normale (bodyLarge ~16)
                fontWeight: FontWeight.bold,
                fontSize: 16, // Force 16
              ),
            ),
            const SizedBox(width: 8),
            if (offerStatus != null)
              Text(
                _getStatusText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        if (offerStatus == 'pending') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: PrimaryButton(
              text: "Accepter",
              fontSize: 12,
              borderRadius: 8,
              padding: EdgeInsets.zero,
              onPressed: onAccept ?? () {},
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: SecondaryButton(
                    text: "Refuser",
                    fontSize: 12,
                    borderRadius: 8,
                    padding: EdgeInsets.zero,
                    onPressed: onRefuse ?? () {},
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                   height: 38,
                   child: SecondaryButton(
                    text: "Faire une offre",
                    fontSize: 12,
                    borderRadius: 8,
                    padding: EdgeInsets.zero,
                    onPressed: onCounterOffer ?? () {},
                  ),
                ),
              ),
            ],
          ),
        ]
      ],
    ));
  }

  Widget _buildCounterOfferContent(ThemeData theme) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "${offerAmount!.toStringAsFixed(0)} FCFA",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const TextSpan(text: "  "),
          TextSpan(
            text: "${originalOfferAmount!.toStringAsFixed(0)} FCFA",
            style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (offerStatus) {
      case 'accepted': return 'Acceptée';
      case 'rejected': return 'Refusée';
      default: return 'En attente';
    }
  }

  Color _getStatusColor() {
     switch (offerStatus) {
      case 'accepted': return Colors.greenAccent;
      case 'rejected': return Colors.grey;
      default: return Colors.grey;
    }
  }
}
