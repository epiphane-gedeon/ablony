import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_repository.dart';
import '../../domain/models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationsProvider = StreamProvider.family<List<AppNotification>, String>((
  ref,
  userId,
) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications(userId);
});

final unreadNotificationsCountProvider = Provider.family<int, String>((
  ref,
  userId,
) {
  final notifications = ref.watch(notificationsProvider(userId)).value;
  if (notifications == null) return 0;
  return notifications.where((n) => !n.read).length;
});

extension NotificationHelpers on WidgetRef {
  Future<void> markNotificationAsRead(String notificationId) async {
    final repository = read(notificationRepositoryProvider);
    await repository.markAsRead(notificationId);
  }
}
