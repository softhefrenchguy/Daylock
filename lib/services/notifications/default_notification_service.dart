import 'notification_service.dart';
import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_android.dart'
    if (dart.library.js_interop) 'notification_service_web.dart'
    as platform;

NotificationService defaultNotificationService() =>
    platform.createNotificationService();
