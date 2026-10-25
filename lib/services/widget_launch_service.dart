import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_type.dart';
import '../utils/formatters.dart';

typedef QuickActionCallback = void Function(TransactionType type);
typedef BankNotificationCallback = void Function(Map<String, dynamic> notification);
typedef BankBalanceScrapedCallback = void Function(Map<String, dynamic> balanceData);
typedef QuickShortcutCallback = void Function(String shortcutKey);

class WidgetLaunchService {
  static const MethodChannel _channel = MethodChannel('com.example.finance_management/widget');
  static QuickActionCallback? onQuickAction;
  static VoidCallback? onWinterCheckin;
  static VoidCallback? onDepositDream;
  static VoidCallback? onWorkoutPenalty;
  static BankNotificationCallback? onBankNotification;
  static BankBalanceScrapedCallback? onBankBalanceScraped;
  static QuickShortcutCallback? onQuickShortcut;

  /// Initialize channel listener for home screen widget clicks and bank notifications
  static Future<void> initialize({
    required QuickActionCallback onAddTransaction,
    VoidCallback? onWinterCheckinAction,
    VoidCallback? onDepositDreamAction,
    VoidCallback? onWorkoutPenaltyAction,
    BankNotificationCallback? onBankNotificationAction,
    BankBalanceScrapedCallback? onBankBalanceScrapedAction,
    QuickShortcutCallback? onQuickShortcutAction,
  }) async {
    onQuickAction = onAddTransaction;
    onWinterCheckin = onWinterCheckinAction;
    onDepositDream = onDepositDreamAction;
    onWorkoutPenalty = onWorkoutPenaltyAction;
    onBankNotification = onBankNotificationAction;
    onBankBalanceScraped = onBankBalanceScrapedAction;
    onQuickShortcut = onQuickShortcutAction;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onQuickAction') {
        final action = call.arguments as String?;
        _dispatchAction(action);
      } else if (call.method == 'onBankNotificationReceived') {
        final args = call.arguments;
        if (args is Map) {
          onBankNotification?.call(Map<String, dynamic>.from(args));
        }
      } else if (call.method == 'onBankBalanceScraped') {
        final args = call.arguments;
        if (args is Map) {
          onBankBalanceScraped?.call(Map<String, dynamic>.from(args));
        }
      }
    });

    // Notify native side that Dart handler is active and ready
    try {
      await _channel.invokeMethod('clientReady');
    } catch (_) {}

    // Check if the app was launched by tapping widget button while closed
    await _checkInitialAction();
  }

  static Future<void> _checkInitialAction() async {
    try {
      final initialAction = await _channel.invokeMethod<String>('getInitialQuickAction');
      if (initialAction != null) {
        _dispatchAction(initialAction);
      }
    } catch (_) {}
  }

  static void _dispatchAction(String? action) {
    if (action == 'add_expense') {
      onQuickAction?.call(TransactionType.expense);
    } else if (action == 'add_income') {
      onQuickAction?.call(TransactionType.income);
    } else if (action == 'winter_checkin') {
      onWinterCheckin?.call();
    } else if (action == 'deposit_dream') {
      onDepositDream?.call();
    } else if (action == 'workout_penalty') {
      onWorkoutPenalty?.call();
    } else if (action != null && action.startsWith('shortcut:')) {
      final key = action.substring('shortcut:'.length);
      onQuickShortcut?.call(key);
    }
  }

  /// Syncs current active balance and Winter Arc streak to Android SharedPreferences and AppWidget providers
  static Future<void> syncBalanceToWidget(
    double balance, {
    int streak = 0,
    bool isWinterChecked = false,
    String? accountName,
    String? todaySpent,
  }) async {
    final formatted = CurrencyFormatter.format(balance);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('arc_widget_balance_display', formatted);
      await prefs.setInt('arc_widget_winter_streak', streak);
      await prefs.setBool('arc_widget_winter_checked', isWinterChecked);
      if (accountName != null) {
        await prefs.setString('arc_widget_account_name', accountName);
      }
      if (todaySpent != null) {
        await prefs.setString('arc_widget_today_spent', todaySpent);
      }
    } catch (_) {}

    try {
      await _channel.invokeMethod('syncWidgetData', {
        'balance': formatted,
        'streak': streak,
        'isWinterChecked': isWinterChecked,
        'accountName': accountName ?? 'Все счета',
        'todaySpent': todaySpent ?? 'Сегодня: без спонтанных трат',
      });
    } catch (_) {}
  }

  /// Request system launcher to pin widget to Android home screen (Android 8.0+)
  static Future<bool> requestPinWidget(String widgetType) async {
    try {
      final res = await _channel.invokeMethod<bool>('pinWidget', {'type': widgetType});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Syncs Capybara wisdom/prediction to native Android widget
  static Future<void> syncCapyPrediction({
    required String title,
    required String body,
    String? statusTag,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('arc_widget_capy_title', title);
      await prefs.setString('arc_widget_capy_body', body);
      if (statusTag != null) {
        await prefs.setString('arc_widget_capy_tag', statusTag);
      }
    } catch (_) {}

    try {
      await _channel.invokeMethod('syncCapyData', {
        'title': title,
        'body': body,
        'tag': statusTag ?? 'ДЗЕН',
      });
    } catch (_) {}
  }

  /// Requests runtime notification permission on Android 13+ (POST_NOTIFICATIONS)
  static Future<bool> requestNotificationPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return granted ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Sends native system tray notification on Android
  static Future<void> showNativeNotification(String title, String body) async {
    try {
      await _channel.invokeMethod('showNativeNotification', {
        'title': title,
        'body': body,
      });
    } catch (_) {}
  }

  /// Schedule background notification via Android AlarmManager (fires even when app is killed)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int delaySeconds,
  }) async {
    try {
      await _channel.invokeMethod('scheduleNotification', {
        'id': id,
        'title': title,
        'body': body,
        'delaySeconds': delaySeconds,
      });
    } catch (_) {}
  }

  /// Cancel background scheduled alarm notification
  static Future<void> cancelScheduledNotification(int id) async {
    try {
      await _channel.invokeMethod('cancelScheduledNotification', {'id': id});
    } catch (_) {}
  }

  /// Check if Android Notification Listener Service permission is granted for MBank push parsing
  static Future<bool> isNotificationListenerEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isNotificationListenerEnabled');
      if (res == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('arc_listener_confirmed_enabled', true);
        return true;
      }
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('arc_listener_confirmed_enabled') ?? false;
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool('arc_listener_confirmed_enabled') ?? false;
      } catch (_) {
        return false;
      }
    }
  }

  /// Open Android system settings to enable notification access for this app
  static Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
  }

  /// Check if Android Accessibility Service is enabled for direct screen-level receipt reading
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      if (res == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('arc_accessibility_confirmed_enabled', true);
        return true;
      }
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('arc_accessibility_confirmed_enabled') ?? false;
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool('arc_accessibility_confirmed_enabled') ?? false;
      } catch (_) {
        return false;
      }
    }
  }

  /// Open Android system Accessibility settings so user can activate screen receipt scanning
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  /// Read queued bank notifications captured while app was closed or backgrounded
  static Future<String> getPendingBankNotifications() async {
    try {
      final res = await _channel.invokeMethod<String>('getPendingBankNotifications');
      return res ?? '[]';
    } catch (_) {
      return '[]';
    }
  }

  /// Clear the queue of captured bank notifications
  static Future<void> clearPendingBankNotifications() async {
    try {
      await _channel.invokeMethod('clearPendingBankNotifications');
    } catch (_) {}
  }

  /// Check if SYSTEM_ALERT_WINDOW (display over other apps) permission is granted
  static Future<bool> canDrawOverlays() async {
    try {
      final res = await _channel.invokeMethod<bool>('canDrawOverlays');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open system settings to grant SYSTEM_ALERT_WINDOW for Capybara filter
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  /// Get shadow scraped bank balance JSON string
  static Future<String> getPendingScrapedBalances() async {
    try {
      final res = await _channel.invokeMethod<String>('getPendingScrapedBalances');
      return res ?? '{}';
    } catch (_) {
      return '{}';
    }
  }

  /// Clear shadow scraped balance
  static Future<void> clearPendingScrapedBalances() async {
    try {
      await _channel.invokeMethod('clearPendingScrapedBalances');
    } catch (_) {}
  }

  /// Synchronize Capybara pre-transaction filter settings to Android SharedPreferences
  static Future<void> syncCapybaraFilterConfig({
    required bool enabled,
    required double threshold,
    required String dreamGoal,
    required double remainingGoal,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('arc_capybara_filter_enabled', enabled);
      await prefs.setDouble('arc_capybara_filter_threshold', threshold);
      await prefs.setString('arc_active_dream_goal', dreamGoal);
      await prefs.setDouble('arc_active_dream_remaining', remainingGoal);
    } catch (_) {}
  }

  /// Synchronize Floating Capy chat-head state to Android SharedPreferences & native service
  static Future<void> syncFloatingCapyConfig({required bool enabled}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('arc_floating_capy_enabled', enabled);
    } catch (_) {}

    try {
      await _channel.invokeMethod('syncFloatingCapy', {'enabled': enabled});
    } catch (_) {}
  }

  /// Synchronize Hardcore Social Media Blocker state to Android SharedPreferences
  static Future<void> syncSocialBlockerConfig({
    required bool enabled,
    required bool isBlocked,
    String? dreamGoal,
    int pullupsRequired = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('arc_social_blocker_enabled', enabled);
      await prefs.setBool('arc_social_blocker_active', isBlocked);
      await prefs.setInt('arc_blocker_pullups_required', pullupsRequired);
      if (dreamGoal != null) {
        await prefs.setString('arc_blocker_dream_goal', dreamGoal);
      }
    } catch (_) {}
  }

  /// Open battery optimization / background restrictions settings (for Xiaomi / Vivo / HyperOS)
  static Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod('openBatterySettings');
    } catch (_) {}
  }
}
