package com.example.finance_management

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.example.finance_management/widget"
    private val NOTIFICATION_CHANNEL_ID = "arc_finance_channel"
    private val PERMISSION_REQUEST_CODE = 1001

    private var pendingQuickAction: String? = null
    private var methodChannel: MethodChannel? = null
    private var isDartReady: Boolean = false
    private var bankReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        handleIntent(intent)
        preloadWidgetFromCache()
    }

    private fun preloadWidgetFromCache() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val balance = prefs.getString("flutter.arc_widget_balance_display", null)
                ?: prefs.getString("arc_widget_balance_display", null) ?: "0,00 сом"
            val streak = prefs.getInt("flutter.arc_widget_winter_streak", -1)
                .takeIf { it >= 0 }
                ?: prefs.getInt("arc_widget_winter_streak", 0)
            val isChecked = prefs.getBoolean("flutter.arc_widget_winter_checked", false)
                || prefs.getBoolean("arc_widget_winter_checked", false)
            updateWidgetData(balance, streak, isChecked)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onResume() {
        super.onResume()
        setupBankNotificationReceiver()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        if (isDartReady) {
            sendPendingQuickAction()
        }
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.getStringExtra("quick_action")
        if (action != null) {
            pendingQuickAction = action
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "ARC Finance Уведомления"
            val descriptionText = "Напоминания о расходах, Winter Arc и целях"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableLights(true)
                enableVibration(true)
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "clientReady" -> {
                    isDartReady = true
                    sendPendingQuickAction()
                    result.success(true)
                }
                "getInitialQuickAction" -> {
                    val action = pendingQuickAction
                    pendingQuickAction = null
                    result.success(action)
                }
                "syncWidgetData" -> {
                    val balance = call.argument<String>("balance") ?: "0.00 сом"
                    val streak = call.argument<Int>("streak") ?: 0
                    val isWinterChecked = call.argument<Boolean>("isWinterChecked") ?: false
                    val accountName = call.argument<String>("accountName")
                    val todaySpent = call.argument<String>("todaySpent")
                    updateWidgetData(balance, streak, isWinterChecked, accountName, todaySpent)
                    result.success(true)
                }
                "requestNotificationPermission" -> {
                    requestRuntimeNotificationPermission()
                    result.success(hasNotificationPermission())
                }
                "hasNotificationPermission" -> {
                    result.success(hasNotificationPermission())
                }
                "showNativeNotification" -> {
                    val title = call.argument<String>("title") ?: "ARC Finance"
                    val body = call.argument<String>("body") ?: ""
                    showNotification(title, body)
                    result.success(true)
                }
                "scheduleNotification" -> {
                    val id = call.argument<Int>("id") ?: 101
                    val title = call.argument<String>("title") ?: "ARC Finance"
                    val body = call.argument<String>("body") ?: ""
                    val delaySeconds = (call.argument<Number>("delaySeconds") ?: 60).toLong()
                    scheduleNotification(id, title, body, delaySeconds)
                    result.success(true)
                }
                "cancelScheduledNotification" -> {
                    val id = call.argument<Int>("id") ?: 101
                    cancelScheduledNotification(id)
                    result.success(true)
                }
                "pinWidget" -> {
                    val type = call.argument<String>("type") ?: "winter"
                    val success = pinWidgetToHomeScreen(type)
                    result.success(success)
                }
                "syncCapyData" -> {
                    val title = call.argument<String>("title") ?: "Капибара советует"
                    val body = call.argument<String>("body") ?: "Деньги любят тишину и покой."
                    val tag = call.argument<String>("tag") ?: "МУДРОСТЬ"
                    updateCapyData(title, body, tag)
                    result.success(true)
                }
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerPermissionGranted())
                }
                "openNotificationListenerSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "canDrawOverlays" -> {
                    result.success(canDrawOverlays())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "getPendingBankNotifications" -> {
                    result.success(getPendingBankNotificationsJson())
                }
                "clearPendingBankNotifications" -> {
                    clearPendingBankNotifications()
                    result.success(true)
                }
                "getPendingScrapedBalances" -> {
                    result.success(getPendingScrapedBalancesJson())
                }
                "clearPendingScrapedBalances" -> {
                    clearPendingScrapedBalances()
                    result.success(true)
                }
                "openBatterySettings" -> {
                    openBatterySettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        setupBankNotificationReceiver()
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestRuntimeNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (!hasNotificationPermission()) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    private fun updateWidgetData(
        balance: String,
        streak: Int = 0,
        isWinterChecked: Boolean = false,
        accountName: String? = null,
        todaySpent: String? = null
    ) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val editor = prefs.edit()
                .putString("flutter.arc_widget_balance_display", balance)
                .putString("arc_widget_balance_display", balance)
                .putInt("flutter.arc_widget_winter_streak", streak)
                .putInt("arc_widget_winter_streak", streak)
                .putBoolean("flutter.arc_widget_winter_checked", isWinterChecked)
                .putBoolean("arc_widget_winter_checked", isWinterChecked)

            if (!accountName.isNullOrEmpty()) {
                editor.putString("flutter.arc_widget_account_name", accountName)
                editor.putString("arc_widget_account_name", accountName)
            }
            if (!todaySpent.isNullOrEmpty()) {
                editor.putString("flutter.arc_widget_today_spent", todaySpent)
                editor.putString("arc_widget_today_spent", todaySpent)
            }
            editor.apply()

            val appWidgetManager = AppWidgetManager.getInstance(this)

            // 1. Update Classic Quick Actions Widget
            val classicComponent = ComponentName(this, ArcFinanceWidgetProvider::class.java)
            val classicIds = appWidgetManager.getAppWidgetIds(classicComponent)
            for (appWidgetId in classicIds) {
                ArcFinanceWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
            }

            // 2. Update Winter Arc & Quick Plaques Widget
            val winterComponent = ComponentName(this, ArcWinterWidgetProvider::class.java)
            val winterIds = appWidgetManager.getAppWidgetIds(winterComponent)
            for (appWidgetId in winterIds) {
                ArcWinterWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
            }

            // 3. Update Capybara Predictions Widget
            val capyComponent = ComponentName(this, ArcCapyWidgetProvider::class.java)
            val capyIds = appWidgetManager.getAppWidgetIds(capyComponent)
            for (appWidgetId in capyIds) {
                ArcCapyWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
            }

            // 4. Update Mini Balance Widget
            val miniComponent = ComponentName(this, ArcMiniWidgetProvider::class.java)
            val miniIds = appWidgetManager.getAppWidgetIds(miniComponent)
            for (appWidgetId in miniIds) {
                ArcMiniWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
            }

            // 5. Update Quick 1-Tap Payments Widget
            val quickComponent = ComponentName(this, ArcQuickWidgetProvider::class.java)
            val quickIds = appWidgetManager.getAppWidgetIds(quickComponent)
            for (appWidgetId in quickIds) {
                ArcQuickWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun pinWidgetToHomeScreen(type: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val appWidgetManager = getSystemService(AppWidgetManager::class.java)
            if (appWidgetManager != null && appWidgetManager.isRequestPinAppWidgetSupported) {
                val provider = when (type) {
                    "finance" -> ComponentName(this, ArcFinanceWidgetProvider::class.java)
                    "capy" -> ComponentName(this, ArcCapyWidgetProvider::class.java)
                    "mini" -> ComponentName(this, ArcMiniWidgetProvider::class.java)
                    "quick" -> ComponentName(this, ArcQuickWidgetProvider::class.java)
                    else -> ComponentName(this, ArcWinterWidgetProvider::class.java)
                }
                val successCallback = PendingIntent.getActivity(
                    this,
                    999,
                    Intent(this, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                return appWidgetManager.requestPinAppWidget(provider, null, successCallback)
            }
        }
        return false
    }

    private fun updateCapyData(title: String, body: String, tag: String) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("flutter.arc_widget_capy_title", title)
                .putString("arc_widget_capy_title", title)
                .putString("flutter.arc_widget_capy_body", body)
                .putString("arc_widget_capy_body", body)
                .putString("flutter.arc_widget_capy_tag", tag)
                .putString("arc_widget_capy_tag", tag)
                .apply()

            val appWidgetManager = AppWidgetManager.getInstance(this)
            val capyComponent = ComponentName(this, ArcCapyWidgetProvider::class.java)
            val capyIds = appWidgetManager.getAppWidgetIds(capyComponent)
            for (appWidgetId in capyIds) {
                ArcCapyWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showNotification(title: String, body: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(System.currentTimeMillis().toInt(), builder.build())
    }

    private fun scheduleNotification(id: Int, title: String, body: String, delaySeconds: Long) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                putExtra("title", title)
                putExtra("body", body)
                putExtra("id", id)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val triggerAt = System.currentTimeMillis() + (delaySeconds * 1000)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun cancelScheduledNotification(id: Int) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, AlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                id,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun sendPendingQuickAction() {
        val action = pendingQuickAction
        if (action != null && isDartReady && methodChannel != null) {
            methodChannel?.invokeMethod("onQuickAction", action)
            pendingQuickAction = null
        }
    }

    private fun isNotificationListenerPermissionGranted(): Boolean {
        if (MBankNotificationListenerService.isListenerRunning) {
            return true
        }

        try {
            val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(this)
            if (enabledListeners.contains(packageName)) return true

            val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
            if (flat != null && flat.contains(packageName)) return true

            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            return prefs.getBoolean("flutter.arc_listener_confirmed_enabled", false) ||
                    prefs.getBoolean("arc_listener_confirmed_enabled", false)
        } catch (e: Exception) {
            return false
        }
    }

    private fun openNotificationListenerSettings() {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            } else {
                Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
            }
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        if (MBankScreenAccessibilityService.isServiceRunning) {
            return true
        }

        try {
            val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as? android.view.accessibility.AccessibilityManager
            if (am != null) {
                val enabledServices = am.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
                if (enabledServices != null) {
                    for (service in enabledServices) {
                        val sInfo = service.resolveInfo?.serviceInfo
                        if (sInfo != null && (sInfo.packageName == packageName ||
                            sInfo.name.contains("MBankScreenAccessibilityService", ignoreCase = true))) {
                            return true
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            val expectedServiceName = "${packageName}/${MBankScreenAccessibilityService::class.java.canonicalName}"
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (!enabledServices.isNullOrEmpty()) {
                val colonSplitter = android.text.TextUtils.SimpleStringSplitter(':')
                colonSplitter.setString(enabledServices)
                while (colonSplitter.hasNext()) {
                    val componentName = colonSplitter.next()
                    if (componentName.equals(expectedServiceName, ignoreCase = true) ||
                        componentName.contains("MBankScreenAccessibilityService", ignoreCase = true) ||
                        componentName.contains(packageName, ignoreCase = true)
                    ) {
                        return true
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            return prefs.getBoolean("flutter.arc_accessibility_confirmed_enabled", false) ||
                    prefs.getBoolean("arc_accessibility_confirmed_enabled", false)
        } catch (_: Exception) {
            return false
        }
    }

    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getPendingBankNotificationsJson(): String {
        return try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.getString("flutter.arc_pending_bank_notifications", null)
                ?: prefs.getString("arc_pending_bank_notifications", null)
                ?: "[]"
        } catch (e: Exception) {
            "[]"
        }
    }

    private fun clearPendingBankNotifications() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("flutter.arc_pending_bank_notifications", "[]")
                .putString("arc_pending_bank_notifications", "[]")
                .apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:$packageName")
                ).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun getPendingScrapedBalancesJson(): String {
        return try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.getString("flutter.arc_scraped_bank_balances", null)
                ?: prefs.getString("arc_scraped_bank_balances", null)
                ?: "{}"
        } catch (e: Exception) {
            "{}"
        }
    }

    private fun clearPendingScrapedBalances() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("flutter.arc_scraped_bank_balances", "{}")
                .putString("arc_scraped_bank_balances", "{}")
                .apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setupBankNotificationReceiver() {
        if (bankReceiver != null) return
        bankReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    MBankNotificationListenerService.ACTION_BANK_NOTIFICATION_RECEIVED -> {
                        val title = intent.getStringExtra("title") ?: ""
                        val body = intent.getStringExtra("body") ?: ""
                        val source = intent.getStringExtra("source") ?: "notification"
                        val timestamp = intent.getLongExtra("timestamp", System.currentTimeMillis())
                        val payload = mapOf(
                            "title" to title,
                            "body" to body,
                            "timestamp" to timestamp,
                            "rawText" to "$title: $body",
                            "source" to source
                        )
                        methodChannel?.invokeMethod("onBankNotificationReceived", payload)
                    }
                    MBankScreenAccessibilityService.ACTION_BANK_BALANCE_SCRAPED -> {
                        val bank = intent.getStringExtra("bank") ?: "MBank"
                        val balance = intent.getDoubleExtra("balance", 0.0)
                        val timestamp = intent.getLongExtra("timestamp", System.currentTimeMillis())
                        val payload = mapOf(
                            "bank" to bank,
                            "balance" to balance,
                            "timestamp" to timestamp
                        )
                        methodChannel?.invokeMethod("onBankBalanceScraped", payload)
                    }
                    MBankScreenAccessibilityService.ACTION_SCREEN_TX_CAPTURED -> {
                        val title = intent.getStringExtra("title") ?: ""
                        val body = intent.getStringExtra("body") ?: ""
                        val source = intent.getStringExtra("source") ?: "accessibility_screen"
                        val timestamp = intent.getLongExtra("timestamp", System.currentTimeMillis())
                        val payload = mapOf(
                            "title" to title,
                            "body" to body,
                            "timestamp" to timestamp,
                            "rawText" to (intent.getStringExtra("rawText") ?: "$title: $body"),
                            "source" to source
                        )
                        methodChannel?.invokeMethod("onBankNotificationReceived", payload)
                    }
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(MBankNotificationListenerService.ACTION_BANK_NOTIFICATION_RECEIVED)
            addAction(MBankScreenAccessibilityService.ACTION_BANK_BALANCE_SCRAPED)
            addAction(MBankScreenAccessibilityService.ACTION_SCREEN_TX_CAPTURED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(bankReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(bankReceiver, filter)
        }
    }

    private fun openBatterySettings() {
        try {
            val intent = Intent().apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    action = Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
                } else {
                    action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                    data = Uri.parse("package:$packageName")
                }
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            } catch (_: Exception) {}
        }
    }

    override fun onDestroy() {
        bankReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {}
            bankReceiver = null
        }
        super.onDestroy()
    }
}
