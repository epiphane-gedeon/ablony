import 'package:flutter/material.dart';
import 'package:ablony/shared/widgets/buttons/buttons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String? text;

  // Paramètres pour les offres
  final bool isOffer;
  final double? offerAmount;
  final String? offerStatus; // 'pending', 'accepted', 'rejected'
  final String? senderName; // Nom de l'expéditeur pour afficher dans l'offre
  final VoidCallback? onAccept;
  final VoidCallback? onRefuse;
  final VoidCallback? onCounterOffer;
  final VoidCallback? onBuy;

  // Paramètre pour contre-offre envoyée (bulle noire avec prix barré)
  final double? originalOfferAmount;

  const MessageBubble({
    super.key,
    required this.isMe,
    this.text,
    this.isOffer = false,
    this.offerAmount,
    this.offerStatus,
    this.senderName,
    this.onAccept,
    this.onRefuse,
    this.onCounterOffer,
    this.onBuy,
    this.originalOfferAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Couleurs définies dans le thème (MessageBubbleColors extension)
    // Messages envoyés: background noir, texte blanc (clair et sombre)
    // Messages reçus: background transparent, texte noir (clair) / blanc (sombre)
    final backgroundColor = isMe
        ? theme.colorScheme.bubbleSentBackground
        : theme.colorScheme.bubbleReceivedBackground;

    final textColor = isMe
        ? theme.colorScheme.bubbleSentText
        : theme.colorScheme.bubbleReceivedText;

    final borderRadius = BorderRadius.circular(10);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: isMe
              ? null
              : Border.all(color: theme.dividerColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOffer && offerAmount != null)
              _buildOfferContent(context, theme, textColor)
            else if (originalOfferAmount != null && offerAmount != null)
              _buildCounterOfferContent(theme, textColor)
            else
              Text(
                text ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferContent(
    BuildContext context,
    ThemeData theme,
    Color textColor,
  ) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Afficher l'en-tête seulement pour celui qui reçoit l'offre (!isMe)
          if (!isMe) ...[
            Text(
              AppLocalizations.of(context)!.heyUserMadeOffer(senderName ?? AppLocalizations.of(context)!.defaultUser),
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${offerAmount!.toStringAsFixed(0)} FCFA",
                style: theme.textTheme.bodyLarge?.copyWith(
                  // Taille normale (bodyLarge ~16)
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Force 16
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              if (offerStatus != null)
                Text(
                  _getStatusText(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          // Afficher les boutons seulement si les callbacks sont fournis (= vendeur)
          if (offerStatus == 'pending' &&
              onAccept != null &&
              onRefuse != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: PrimaryButton(
                text: AppLocalizations.of(context)!.acceptButton,
                fontSize: 12,
                borderRadius: 8,
                padding: EdgeInsets.zero,
                onPressed: onAccept!,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: SecondaryButton(
                      text: AppLocalizations.of(context)!.rejectButton,
                      fontSize: 12,
                      borderRadius: 8,
                      padding: EdgeInsets.zero,
                      onPressed: onRefuse!,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: SecondaryButton(
                      text: AppLocalizations.of(context)!.makeOffer,
                      fontSize: 12,
                      borderRadius: 8,
                      padding: EdgeInsets.zero,
                      onPressed: onCounterOffer ?? () {},
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Bouton "Acheter" apparaît dans deux cas :
          // 1. L'acheteur voit son offre acceptée par le vendeur (isMe = true)
          // 2. L'acheteur a accepté la contre-offre du vendeur (isMe = false, mais il a cliqué sur Accepter)
          // Dans tous les cas, si l'offre est acceptée et onBuy existe, on affiche le bouton
          if (offerStatus == 'accepted' && onBuy != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: PrimaryButton(
                text: AppLocalizations.of(context)!.buyNow,
                fontSize: 12,
                borderRadius: 8,
                padding: EdgeInsets.zero,
                onPressed: onBuy!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterOfferContent(ThemeData theme, Color textColor) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "${offerAmount!.toStringAsFixed(0)} FCFA",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const TextSpan(text: "  "),
          TextSpan(
            text: "${originalOfferAmount!.toStringAsFixed(0)} FCFA",
            style: const TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(BuildContext context) {
    switch (offerStatus) {
      case 'accepted':
        return AppLocalizations.of(context)!.offerStatusAccepted;
      case 'rejected':
        return AppLocalizations.of(context)!.offerStatusRejected;
      default:
        return AppLocalizations.of(context)!.offerStatusPending;
    }
  }

  Color _getStatusColor() {
    switch (offerStatus) {
      case 'accepted':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
