package com.example.finance_management

import android.app.Notification
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

class MBankNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "MBankListener"
        const val PREFS_KEY_PENDING_NOTIFICATIONS = "arc_pending_bank_notifications"
        const val ACTION_BANK_NOTIFICATION_RECEIVED = "com.example.finance_management.BANK_NOTIFICATION_RECEIVED"

        @Volatile
        var isListenerRunning = false
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isListenerRunning = true
        Log.i(TAG, "MBankNotificationListener connected")
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putBoolean("flutter.arc_listener_confirmed_enabled", true)
                .putBoolean("arc_listener_confirmed_enabled", true)
                .apply()
        } catch (_: Exception) {}
    }

    override fun onListenerDisconnected() {
        isListenerRunning = false
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        try {
            val pkg = sbn.packageName?.lowercase() ?: ""
            // CRITICAL: NEVER capture notifications from our own app!
            if (pkg.isEmpty() || pkg == packageName.lowercase() || pkg.contains("finance_management")) {
                return
            }

            val notification = sbn.notification ?: return
            val extras = notification.extras ?: return

            val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""

            val combined = "$title $text $bigText".trim()
            if (combined.isEmpty()) return

            // Filter for Kyrgyz bank or banking SMS notifications
            val isMBankPackage = pkg.contains("mbank") || pkg.contains("cbk")
            val containsMBankKeyword = combined.contains("mbank", ignoreCase = true) ||
                    title.contains("mbank", ignoreCase = true)

            val hasCurrency = combined.contains("сом", ignoreCase = true) ||
                    combined.contains("KGS", ignoreCase = true) ||
                    combined.contains("kgs", ignoreCase = true)

            val hasTransactionAction = combined.contains("пополнен", ignoreCase = true) ||
                    combined.contains("зачислен", ignoreCase = true) ||
                    combined.contains("списан", ignoreCase = true) ||
                    combined.contains("оплат", ignoreCase = true) ||
                    combined.contains("зарплат", ignoreCase = true) ||
                    combined.contains("перевод", ignoreCase = true) ||
                    combined.contains("покупк", ignoreCase = true) ||
                    combined.contains("popolnen", ignoreCase = true) ||
                    combined.contains("spisanie", ignoreCase = true)

            if (!isMBankPackage && !containsMBankKeyword && !(hasCurrency && hasTransactionAction)) {
                return
            }

            Log.d(TAG, "Captured bank transaction notification from [$pkg]: $title -> $text")

            val bestBody = if (text.isNotEmpty()) text else bigText
            savePendingNotification(title, bestBody, sbn.postTime)

            // Broadcast to MainActivity if active
            val broadcastIntent = Intent(ACTION_BANK_NOTIFICATION_RECEIVED).apply {
                putExtra("title", title)
                putExtra("body", bestBody)
                putExtra("timestamp", sbn.postTime)
                setPackage(packageName)
            }
            sendBroadcast(broadcastIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Error handling notification: ${e.message}", e)
        }
    }

    private fun savePendingNotification(title: String, body: String, timestamp: Long) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val existingJson = prefs.getString("flutter.$PREFS_KEY_PENDING_NOTIFICATIONS", null)
                ?: prefs.getString(PREFS_KEY_PENDING_NOTIFICATIONS, null)
                ?: "[]"

            val jsonArray = JSONArray(existingJson)
            // Prevent storing identical notification within short window
            if (jsonArray.length() > 0) {
                val lastObj = jsonArray.getJSONObject(jsonArray.length() - 1)
                val lastRaw = lastObj.optString("rawText", "")
                val lastTime = lastObj.optLong("timestamp", 0)
                if (lastRaw == "$title: $body" && Math.abs(timestamp - lastTime) < 3000) {
                    return // Duplicate within 3 seconds, ignore
                }
            }

            val newObj = JSONObject().apply {
                put("title", title)
                put("body", body)
                put("timestamp", timestamp)
                put("rawText", "$title: $body")
            }
            jsonArray.put(newObj)

            while (jsonArray.length() > 30) {
                jsonArray.remove(0)
            }

            prefs.edit()
                .putString("flutter.$PREFS_KEY_PENDING_NOTIFICATIONS", jsonArray.toString())
                .putString(PREFS_KEY_PENDING_NOTIFICATIONS, jsonArray.toString())
                .apply()

            Log.d(TAG, "Saved pending notification. Total count: ${jsonArray.length()}")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving notification to prefs: ${e.message}", e)
        }
    }
}
