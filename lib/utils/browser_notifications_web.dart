import 'dart:js_interop';

@JS('eval')
external JSAny? _eval(String code);

class BrowserNotificationImpl {
  static Future<bool> requestPermission() async {
    try {
      _eval('''
        if ("Notification" in window) {
          Notification.requestPermission();
        }
      ''');
      return hasPermission();
    } catch (_) {
      return false;
    }
  }

  static bool hasPermission() {
    try {
      final res = _eval('("Notification" in window) && Notification.permission === "granted"');
      return (res as JSBoolean?)?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static String getPermissionStatus() {
    try {
      final res = _eval('("Notification" in window) ? Notification.permission : "unsupported"');
      return (res as JSString?)?.toDart ?? 'unsupported';
    } catch (_) {
      return 'unsupported';
    }
  }

  static void showNotification(String title, {String? body, String? icon}) {
    try {
      final safeTitle = title.replaceAll("'", "\\'").replaceAll('\n', ' ');
      final safeBody = (body ?? '').replaceAll("'", "\\'").replaceAll('\n', ' ');
      final safeIcon = (icon ?? 'icons/Icon-192.png').replaceAll("'", "\\'");
      _eval('''
        if (typeof window.arcNotify === "function") {
          window.arcNotify('$safeTitle', '$safeBody', '$safeIcon');
        } else if ("Notification" in window && Notification.permission === "granted") {
          new Notification('$safeTitle', {
            body: '$safeBody',
            icon: '$safeIcon'
          });
        }
      ''');
    } catch (_) {}
  }

  static void scheduleBackgroundPush(int seconds, String title, {String? body}) {
    try {
      final safeTitle = title.replaceAll("'", "\\'").replaceAll('\n', ' ');
      final safeBody = (body ?? '').replaceAll("'", "\\'").replaceAll('\n', ' ');
      _eval('''
        if (typeof window.arcScheduleBackgroundPush === "function") {
          window.arcScheduleBackgroundPush($seconds, '$safeTitle', '$safeBody');
        } else {
          setTimeout(function() {
            if (typeof window.arcNotify === "function") {
              window.arcNotify('$safeTitle', '$safeBody');
            }
          }, ($seconds || 5) * 1000);
        }
      ''');
    } catch (_) {}
  }
}
