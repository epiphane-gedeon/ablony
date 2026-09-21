import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/app_notification.dart';

/// Une notification, en une ligne.
///
/// Non lue en gras avec une pastille : la distinction doit tenir au premier
/// coup d'œil, sans qu'on compare deux lignes pour la trouver.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nonLue = !notification.read;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: nonLue
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(
                _icone(notification.rawType),
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: nonLue ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.hintColor, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ilYA(context, notification.createdAt),
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (nonLue) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Une icône par famille, pas par type : quinze icônes différentes ne se
  /// distinguent plus les unes des autres.
  IconData _icone(String type) {
    if (type.startsWith('parcel_') || type == 'purchase_received') {
      return Icons.local_shipping_outlined;
    }
    if (type.startsWith('dispute_')) return Icons.gavel_outlined;
    if (type.startsWith('withdrawal_') ||
        type == 'refund_issued' ||
        type == 'sale_refunded' ||
        type == 'funds_released') {
      return Icons.account_balance_wallet_outlined;
    }
    if (type == 'new_message') return Icons.chat_bubble_outline;
    if (type == 'product_rejected') return Icons.edit_note;
    if (type == 'review_received') return Icons.star_outline;
    if (type == 'new_follower' || type == 'new_product_from_followed') {
      return Icons.person_outline;
    }
    return Icons.notifications_outlined;
  }

  String _ilYA(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final ecart = DateTime.now().difference(date);
    if (ecart.inMinutes < 1) return l10n.timeAgoNow;
    if (ecart.inHours < 1) return l10n.timeAgoMinutes(ecart.inMinutes);
    if (ecart.inDays < 1) return l10n.timeAgoHours(ecart.inHours);
    return l10n.timeAgoDays(ecart.inDays);
  }
}
