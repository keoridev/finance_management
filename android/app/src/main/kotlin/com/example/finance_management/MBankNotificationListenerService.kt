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

import java.util.regex.Pattern

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

            // 1. Bank & NFC Wallet packages
            val isBankOrWalletPackage = pkg.contains("mbank") || pkg.contains("cbk") ||
                    pkg.contains("optima") || pkg.contains("bakai") ||
                    pkg.contains("demir") || pkg.contains("finca") ||
                    pkg.contains("rsk") || pkg.contains("kompanion") ||
                    pkg.contains("walletnfcrel") || pkg.contains("wallet") ||
                    pkg.contains("gms") || pkg.contains("pay")

            // 2. SMS packages
            val isSmsPackage = pkg.contains("messaging") || pkg.contains("mms") ||
                    pkg.contains("sms") || pkg.contains("message")

            // 3. Keyword checks
            val containsBankOrWalletKeyword = combined.contains("mbank", ignoreCase = true) ||
                    combined.contains("optima", ignoreCase = true) ||
                    combined.contains("bakai", ignoreCase = true) ||
                    combined.contains("demir", ignoreCase = true) ||
                    combined.contains("finca", ignoreCase = true) ||
                    combined.contains("rsk", ignoreCase = true) ||
                    combined.contains("kompanion", ignoreCase = true) ||
                    combined.contains("google pay", ignoreCase = true) ||
                    combined.contains("google wallet", ignoreCase = true) ||
                    combined.contains("gpay", ignoreCase = true)

            val hasCurrency = combined.contains("сом", ignoreCase = true) ||
                    combined.contains("KGS", ignoreCase = true) ||
                    combined.contains("kgs", ignoreCase = true) ||
                    combined.contains("som", ignoreCase = true) ||
                    Pattern.compile("\\d+\\s*(?:с\\.|c\\.|[cс]\\b)", Pattern.CASE_INSENSITIVE).matcher(combined).find()

            val hasTransactionAction = combined.contains("пополнен", ignoreCase = true) ||
                    combined.contains("зачислен", ignoreCase = true) ||
                    combined.contains("списан", ignoreCase = true) ||
                    combined.contains("оплат", ignoreCase = true) ||
                    combined.contains("зарплат", ignoreCase = true) ||
                    combined.contains("перевод", ignoreCase = true) ||
                    combined.contains("покупк", ignoreCase = true) ||
                    combined.contains("сняти", ignoreCase = true) ||
                    combined.contains("чек", ignoreCase = true) ||
                    combined.contains("platezh", ignoreCase = true) ||
                    combined.contains("popolnen", ignoreCase = true) ||
                    combined.contains("spisanie", ignoreCase = true) ||
                    combined.contains("oplata", ignoreCase = true) ||
                    combined.contains("paid", ignoreCase = true) ||
                    combined.contains("spent", ignoreCase = true) ||
                    combined.contains("purchase", ignoreCase = true)

            val shouldCapture = when {
                isBankOrWalletPackage && (hasCurrency || hasTransactionAction || containsBankOrWalletKeyword) -> true
                isSmsPackage && (containsBankOrWalletKeyword || (hasCurrency && hasTransactionAction)) -> true
                hasCurrency && hasTransactionAction -> true
                else -> false
            }

            if (!shouldCapture) {
                return
            }

            Log.d(TAG, "Captured bank transaction notification from [$pkg]: $title -> $text | $bigText")

            val bestBody = when {
                bigText.isNotEmpty() && !bigText.equals(text, ignoreCase = true) -> {
                    if (bigText.contains(text, ignoreCase = true)) bigText else "$text. $bigText"
                }
                text.isNotEmpty() -> text
                else -> bigText
            }
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
            // Prevent storing identical notification within 5 minutes
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.optJSONObject(i)
                if (obj != null) {
                    val prevRaw = obj.optString("rawText", "")
                    val prevTime = obj.optLong("timestamp", 0)
                    if ((prevRaw == "$title: $body" || prevRaw.contains(body) || body.contains(prevRaw)) && Math.abs(timestamp - prevTime) < 300_000L) {
                        return // Duplicate within 5 minutes, ignore
                    }
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
