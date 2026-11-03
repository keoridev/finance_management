package com.example.finance_management

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.util.Locale

/**
 * Transaction Deduplication & Sliding Window Manager implementing Section 3.3.
 * Resolves race conditions and merges UI screen captures with asynchronous push notifications.
 */
class TransactionDeduplicationManager private constructor(private val context: Context) {

    companion object {
        private const val TAG = "TxDedupManager"
        const val PREFS_KEY_PENDING_TXS = "arc_pending_bank_notifications"
        const val ACTION_TRANSACTION_EVENT = "com.example.finance_management.BANK_NOTIFICATION_RECEIVED"
        private const val NOTIFICATION_CHANNEL_ID = "arc_finance_channel"

        @Volatile
        private var instance: TransactionDeduplicationManager? = null

        fun getInstance(context: Context): TransactionDeduplicationManager {
            return instance ?: synchronized(this) {
                instance ?: TransactionDeduplicationManager(context.applicationContext).also {
                    instance = it
                }
            }
        }

        fun generateFingerprint(
            packageName: String,
            amount: Double,
            targetIdentifier: String,
            timestamp: Long = System.currentTimeMillis()
        ): String {
            val dayBucket = timestamp / (24 * 60 * 60 * 1000L) // Uniquely partitioned per day
            val canonicalAmount = String.format(Locale.US, "%.2f", amount)
            val normalizedTarget = targetIdentifier.trim().lowercase(Locale.ROOT)
            val raw = "${packageName.trim().lowercase(Locale.ROOT)}|$canonicalAmount|$normalizedTarget|$dayBucket"
            return sha256(raw)
        }

        private fun sha256(input: String): String {
            val bytes = MessageDigest.getInstance("SHA-256").digest(input.toByteArray(Charsets.UTF_8))
            return bytes.joinToString("") { "%02x".format(it) }
        }
    }

    private val dbHelper = TransactionDatabaseHelper(context)

    /**
     * Resolves transaction captured from the Screen (AccessibilityService).
     * Implements Section 3.3:
     * - Check buffer for last 15 minutes.
     * - If no match -> status = CONFIRMED_UI, record and notify Flutter.
     * - If duplicate within TTL -> ignore.
     */
    @Synchronized
    fun onUiTransactionCaptured(
        packageName: String,
        amount: Double,
        currency: String = "KGS",
        targetIdentifier: String = "UNKNOWN",
        title: String = "Перевод",
        rawText: String = "",
        timestamp: Long = System.currentTimeMillis(),
        isIncome: Boolean = false
    ): StoredTransaction? {
        val windowStart = timestamp - BankPatternConfig.DEFAULT_TTL_MS

        val existing = dbHelper.findMatchingRecentTransaction(
            amount = amount,
            currency = currency,
            targetIdentifier = targetIdentifier,
            windowStartTime = windowStart
        )

        if (existing != null) {
            Log.d(TAG, "UI duplicate detected for fingerprint [${existing.fingerprint}] within TTL. Ignoring.")
            return null
        }

        val fingerprint = generateFingerprint(packageName, amount, targetIdentifier, timestamp)
        val id = dbHelper.insertTransaction(
            fingerprint = fingerprint,
            amount = amount,
            currency = currency,
            packageName = packageName,
            sourceType = "UI",
            status = "CONFIRMED_UI",
            isVerified = false,
            targetIdentifier = targetIdentifier,
            title = title,
            rawText = rawText,
            createdAt = timestamp
        )

        if (id == -1L) {
            Log.w(TAG, "Failed to insert UI transaction: $fingerprint")
            return null
        }

        val tx = StoredTransaction(
            id = id,
            fingerprint = fingerprint,
            amount = amount,
            currency = currency,
            packageName = packageName,
            sourceType = "UI",
            status = "CONFIRMED_UI",
            isVerified = false,
            targetIdentifier = targetIdentifier,
            title = title,
            rawText = rawText,
            createdAt = timestamp,
            isIncome = isIncome
        )

        saveToFlutterPendingQueue(tx)
        broadcastTransactionEvent(tx)
        postSystemNotification(tx)

        Log.i(TAG, "CONFIRMED_UI transaction recorded: ${if (isIncome) "+" else "-"}$amount $currency to $targetIdentifier ($title)")
        return tx
    }

    /**
     * Resolves transaction captured from incoming Push/SMS (NotificationListenerService).
     * Implements Section 3.3:
     * - Check buffer for last 15 minutes.
     * - If match found -> mark as VERIFIED_BY_PUSH, do NOT deduct balance twice!
     * - If no match (screen missed/FLAG_SECURE) -> status = CONFIRMED_PUSH, record new transaction.
     */
    @Synchronized
    fun onPushNotificationCaptured(
        packageName: String,
        amount: Double,
        currency: String = "KGS",
        targetIdentifier: String = "UNKNOWN",
        title: String = "MBank",
        body: String = "",
        timestamp: Long = System.currentTimeMillis(),
        isIncome: Boolean = false
    ): StoredTransaction {
        val windowStart = timestamp - BankPatternConfig.DEFAULT_TTL_MS
        val rawText = "$title: $body".trim()

        val matchingUiTx = dbHelper.findMatchingRecentTransaction(
            amount = amount,
            currency = currency,
            targetIdentifier = targetIdentifier,
            windowStartTime = windowStart
        )

        if (matchingUiTx != null) {
            // Already captured by UI screen! Upgrade to VERIFIED_BY_PUSH
            dbHelper.markVerifiedByPush(matchingUiTx.id, rawText)
            val updatedTx = matchingUiTx.copy(
                status = "VERIFIED_BY_PUSH",
                isVerified = true,
                rawText = rawText,
                isIncome = if (isIncome) true else matchingUiTx.isIncome
            )

            // Update queue so if Flutter is opened later it won't duplicate
            saveToFlutterPendingQueue(updatedTx)
            // Broadcast verification to Flutter (does not charge balance twice!)
            broadcastTransactionEvent(updatedTx)
            Log.i(TAG, "Push verified existing UI transaction #${matchingUiTx.id} ($amount $currency). No duplicate charge.")
            return updatedTx
        }

        // Screen was not captured (e.g. FLAG_SECURE or background transfer). Record as CONFIRMED_PUSH.
        val fingerprint = generateFingerprint(packageName, amount, targetIdentifier, timestamp)
        val id = dbHelper.insertTransaction(
            fingerprint = fingerprint,
            amount = amount,
            currency = currency,
            packageName = packageName,
            sourceType = "PUSH",
            status = "CONFIRMED_PUSH",
            isVerified = false,
            targetIdentifier = targetIdentifier,
            title = title,
            rawText = rawText,
            createdAt = timestamp
        )

        val tx = StoredTransaction(
            id = id,
            fingerprint = fingerprint,
            amount = amount,
            currency = currency,
            packageName = packageName,
            sourceType = "PUSH",
            status = "CONFIRMED_PUSH",
            isVerified = false,
            targetIdentifier = targetIdentifier,
            title = title,
            rawText = rawText,
            createdAt = timestamp,
            isIncome = isIncome
        )

        saveToFlutterPendingQueue(tx)
        broadcastTransactionEvent(tx)
        postSystemNotification(tx)

        Log.i(TAG, "CONFIRMED_PUSH recorded: ${if (isIncome) "+" else "-"}$amount $currency ($title)")
        return tx
    }

    private fun postSystemNotification(tx: StoredTransaction) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    "ARC Finance Уведомления",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Автоматический шлюз банковских операций"
                    enableVibration(true)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = if (launchIntent != null) {
                PendingIntent.getActivity(
                    context,
                    (tx.id % 50000).toInt(),
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else null

            val cleanAmt = String.format(Locale.US, "%.2f", tx.amount)
            val sign = if (tx.isIncome) "+" else "−"
            val titleText = if (tx.title.isNotEmpty() && tx.title != "MBank" && tx.title != "Банк") {
                tx.title
            } else {
                if (tx.isIncome) "Пополнение зафиксировано: +$cleanAmt сом" else "Платеж зафиксирован: −$cleanAmt сом"
            }

            val targetDesc = if (tx.targetIdentifier.isNotEmpty() && tx.targetIdentifier != "UNKNOWN") {
                tx.targetIdentifier
            } else {
                "MBank"
            }
            val bodyText = "$targetDesc • $sign$cleanAmt сом зафиксировано в фоне"

            val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(titleText)
                .setContentText(bodyText)
                .setStyle(NotificationCompat.BigTextStyle().bigText(bodyText))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)

            if (pendingIntent != null) {
                builder.setContentIntent(pendingIntent)
            }

            notificationManager.notify((tx.id % 10000).toInt() + 8000, builder.build())
        } catch (e: Exception) {
            Log.e(TAG, "Failed to post system notification: ${e.message}")
        }
    }

    private fun saveToFlutterPendingQueue(tx: StoredTransaction) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val existingJson = prefs.getString("flutter.$PREFS_KEY_PENDING_TXS", null)
                ?: prefs.getString(PREFS_KEY_PENDING_TXS, null)
                ?: "[]"

            val jsonArray = JSONArray(existingJson)
            var updatedExisting = false
            for (i in 0 until jsonArray.length()) {
                val item = jsonArray.getJSONObject(i)
                if (item.optLong("id") == tx.id || item.optString("fingerprint") == tx.fingerprint) {
                    item.put("status", tx.status)
                    item.put("isVerified", tx.isVerified)
                    item.put("rawText", tx.rawText)
                    item.put("body", tx.rawText)
                    item.put("isIncome", tx.isIncome)
                    item.put("type", if (tx.isIncome) "income" else "expense")
                    updatedExisting = true
                    break
                }
            }

            if (!updatedExisting) {
                val obj = JSONObject().apply {
                    put("id", tx.id)
                    put("fingerprint", tx.fingerprint)
                    put("amount", tx.amount)
                    put("currency", tx.currency)
                    put("packageName", tx.packageName)
                    put("sourceType", tx.sourceType)
                    put("status", tx.status)
                    put("isVerified", tx.isVerified)
                    put("targetIdentifier", tx.targetIdentifier)
                    put("title", tx.title)
                    put("rawText", tx.rawText)
                    put("body", tx.rawText)
                    put("timestamp", tx.createdAt)
                    put("isIncome", tx.isIncome)
                    put("type", if (tx.isIncome) "income" else "expense")
                }
                jsonArray.put(obj)
            }

            while (jsonArray.length() > 40) {
                jsonArray.remove(0)
            }

            prefs.edit()
                .putString("flutter.$PREFS_KEY_PENDING_TXS", jsonArray.toString())
                .putString(PREFS_KEY_PENDING_TXS, jsonArray.toString())
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving to Flutter queue: ${e.message}")
        }
    }

    private fun broadcastTransactionEvent(tx: StoredTransaction) {
        val intent = Intent(ACTION_TRANSACTION_EVENT).apply {
            putExtra("id", tx.id)
            putExtra("fingerprint", tx.fingerprint)
            putExtra("amount", tx.amount)
            putExtra("currency", tx.currency)
            putExtra("packageName", tx.packageName)
            putExtra("sourceType", tx.sourceType)
            putExtra("status", tx.status)
            putExtra("isVerified", tx.isVerified)
            putExtra("targetIdentifier", tx.targetIdentifier)
            putExtra("title", tx.title)
            putExtra("body", tx.rawText)
            putExtra("rawText", tx.rawText)
            putExtra("timestamp", tx.createdAt)
            putExtra("isIncome", tx.isIncome)
            putExtra("type", if (tx.isIncome) "income" else "expense")
            setPackage(context.packageName)
        }
        context.sendBroadcast(intent)
    }
}
