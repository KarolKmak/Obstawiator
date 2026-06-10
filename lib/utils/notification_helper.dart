import 'notification_helper_stub.dart'
    if (dart.library.js) 'notification_helper_web.dart' as helper;

Future<void> requestWebNotificationPermission() async {
  await helper.requestWebNotificationPermission();
}

Future<void> syncPushToken() async {
  await helper.syncPushToken();
}
