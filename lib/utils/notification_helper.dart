import 'notification_helper_stub.dart'
    if (dart.library.js) 'notification_helper_web.dart' as helper;

void requestWebNotificationPermission() {
  helper.requestWebNotificationPermission();
}
