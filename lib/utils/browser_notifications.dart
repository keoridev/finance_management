import 'browser_notifications_stub.dart'
    if (dart.library.js_interop) 'browser_notifications_web.dart';

abstract class BrowserNotifications {
  static Future<bool> requestPermission() => BrowserNotificationImpl.requestPermission();
  static bool hasPermission() => BrowserNotificationImpl.hasPermission();
  static String getPermissionStatus() => BrowserNotificationImpl.getPermissionStatus();
  static void showNotification(String title, {String? body, String? icon}) =>
      BrowserNotificationImpl.showNotification(title, body: body, icon: icon);
  static void scheduleBackgroundPush(int seconds, String title, {String? body}) =>
      BrowserNotificationImpl.scheduleBackgroundPush(seconds, title, body: body);
}
