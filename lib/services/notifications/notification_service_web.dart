import 'dart:js_interop';

import 'notification_service.dart';

@JS('globalThis.Notification')
external JSAny? get _notificationApi;
@JS('globalThis.isSecureContext')
external JSBoolean? get _secureContext;
NotificationService createNotificationService() => WebNotificationService();

/// There is no backend/push worker. Detect capabilities without prompting.
class WebNotificationService extends NotificationService {
  @override
  Future<void> start() async {
    status.value = webNotificationStatus(
      browserApiAvailable:
          _notificationApi != null && (_secureContext?.toDart ?? false),
    );
  }
}
