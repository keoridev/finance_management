package com.example.finance_management

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.util.regex.Pattern

class MBankNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "MBankListener"
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

            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim() ?: ""
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim() ?: ""
            val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.trim() ?: ""
            val infoText = extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString()?.trim() ?: ""
            val ticker = notification.tickerText?.toString()?.trim() ?: ""

            val combined = "$title $text $bigText $subText $infoText $ticker".trim()
            if (combined.isEmpty()) return

            // 1. Whitelist package check (Section 3.2)
            val isWhitelisted = BankPatternConfig.isWhitelistedPackage(pkg)
            val isSms = pkg.contains("messaging") || pkg.contains("mms") || pkg.contains("sms")
            if (!isWhitelisted && !isSms) {
                return
            }

            // 2. Stop-words filter (Section 3.2: Skip promo, login alerts, terms updates)
            if (BankPatternConfig.isStopWordPush(combined)) {
                Log.d(TAG, "Notification skipped by stop-word filter: $combined")
                return
            }

            // 3. Check for expense markers or currency
            val hasExpenseMarker = BankPatternConfig.PUSH_EXPENSE_MARKERS.any { combined.contains(it, ignoreCase = true) }
            val hasCurrency = combined.contains("сом", ignoreCase = true) ||
                    combined.contains("KGS", ignoreCase = true) ||
                    combined.contains("som", ignoreCase = true) ||
                    Pattern.compile("\\d+\\s*(?:с\\.|c\\.|[cс]\\b)", Pattern.CASE_INSENSITIVE).matcher(combined).find()

            if (!hasExpenseMarker && !hasCurrency) {
                return
            }

            // 4. Parse Amount via Section 3.1 regex
            val amountMatcher = BankPatternConfig.AMOUNT_REGEX.matcher(combined)
            val (amount, currency) = if (amountMatcher.find()) {
                val rawNum = amountMatcher.group(1)?.replace(" ", "")?.replace("\u00A0", "")?.replace(",", ".") ?: "0"
                val parsedAmt = rawNum.toDoubleOrNull() ?: 0.0
                val rawCurr = amountMatcher.group(2)?.uppercase() ?: "KGS"
                val normCurr = when {
                    rawCurr.contains("СОМ") || rawCurr.contains("KGS") || rawCurr.contains("SOM") ||
                            rawCurr == "C" || rawCurr == "С" || rawCurr.startsWith("C.") || rawCurr.startsWith("С.") -> "KGS"
                    rawCurr.contains("РУБ") || rawCurr.contains("RUB") -> "RUB"
                    rawCurr.contains("USD") || rawCurr.contains("$") -> "USD"
                    rawCurr.contains("EUR") -> "EUR"
                    rawCurr.contains("KZT") || rawCurr.contains("ТЕНГЕ") -> "KZT"
                    else -> "KGS"
                }
                Pair(parsedAmt, normCurr)
            } else {
                Pair(0.0, "KGS")
            }

            // 5. Extract Recipient / Target Identifier (Section 3.3)
            var targetIdentifier = "UNKNOWN"
            for (p in BankPatternConfig.RECIPIENT_PATTERNS) {
                val m = p.matcher(combined)
                if (m.find()) {
                    targetIdentifier = m.group(1)?.trim() ?: "UNKNOWN"
                    break
                }
            }

            val bestBody = when {
                bigText.isNotEmpty() && !bigText.equals(text, ignoreCase = true) -> {
                    if (bigText.contains(text, ignoreCase = true)) bigText else "$text. $bigText"
                }
                text.isNotEmpty() -> text
                else -> bigText
            }

            val finalBody = if (subText.isNotEmpty() && !bestBody.contains(subText, ignoreCase = true)) {
                "$bestBody ($subText)"
            } else {
                bestBody
            }

            val bankTitle = when {
                title == "1444" || title.contains("mbank", ignoreCase = true) || pkg.contains("maanavan") || pkg.contains("mb_kyrgyzstan") || pkg.contains("mbank") -> "MBank"
                title == "2424" || title.contains("optima", ignoreCase = true) || pkg.contains("optima") -> "Optima"
                title == "2929" || title.contains("bakai", ignoreCase = true) || pkg.contains("bakai") -> "Bakai Bank"
                title.isNotEmpty() && !title.equals("SMS", ignoreCase = true) -> title
                else -> "Банк"
            }

            // 6. Forward to TransactionDeduplicationManager with 15-minute sliding TTL window (Section 3.3)
            if (amount > 0.0) {
                TransactionDeduplicationManager.getInstance(this).onPushNotificationCaptured(
                    packageName = pkg,
                    amount = amount,
                    currency = currency,
                    targetIdentifier = targetIdentifier,
                    title = bankTitle,
                    body = finalBody,
                    timestamp = sbn.postTime
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling notification: ${e.message}", e)
        }
    }
}
