import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
