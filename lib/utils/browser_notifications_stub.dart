class BrowserNotificationImpl {
  static Future<bool> requestPermission() async {
    return true;
  }

  static bool hasPermission() {
    return true;
  }

  static String getPermissionStatus() {
    return 'granted';
  }

  static void showNotification(String title, {String? body, String? icon}) {
    // Non-web platforms or stub: in-app banner handles display
  }

  static void scheduleBackgroundPush(int seconds, String title, {String? body}) {
    // Non-web platforms or stub
  }
}
