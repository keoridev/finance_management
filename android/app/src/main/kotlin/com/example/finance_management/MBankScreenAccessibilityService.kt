package com.example.finance_management

import android.accessibilityservice.AccessibilityService
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import androidx.core.app.NotificationCompat
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.text.InputType
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale
import java.util.regex.Pattern

/**
 * High-reliability screen-level banking & financial gateway via AccessibilityService.
 * Features:
 * 1. Post-transaction receipt capture (100% reliability, zero dependence on pushes).
 * 2. Pre-transaction "Capybara-Filter" (SYSTEM_ALERT_WINDOW overlay prompt to prevent impulse buys).
 * 3. Shadow balance scraping (quietly reads card/account balances from bank home screens).
 * 4. Smart on-the-fly categorization (instant merchant recognition for Globus, Faiza, Yandex, etc.).
 * 5. Floating Capybara Chat Head & quick entry sheet over banking apps.
 */
class MBankScreenAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "MBankAccessibility"
        const val PREFS_KEY_PENDING_SCREEN_TXS = "arc_pending_bank_notifications"
        const val PREFS_KEY_SCRAPED_BALANCES = "arc_scraped_bank_balances"
        const val ACTION_SCREEN_TX_CAPTURED = "com.example.finance_management.BANK_NOTIFICATION_RECEIVED"
        const val ACTION_BANK_BALANCE_SCRAPED = "com.example.finance_management.BANK_BALANCE_SCRAPED"

        // In-memory deduplication cache: signature -> timestamp
        private val recentSignatures = mutableMapOf<String, Long>()
        private const val DEDUPLICATION_WINDOW_MS = 60_000L // 60s window for receipts

        // Pre-transaction alert rate limiting: amount -> timestamp
        private var lastPreTxAlertTime = 0L
        private var lastPreTxAlertAmount = 0.0
        private var userBypassedCapybaraTime = 0L
        private var userBypassedAmount = 0.0

        // Shadow balance cache: bankName -> lastBalance
        private val lastScrapedBalances = mutableMapOf<String, Double>()
        private val lastScrapedTimestamps = mutableMapOf<String, Long>()
        private const val BALANCE_SCRAPE_INTERVAL_MS = 30_000L // 30 seconds throttle for fresh balance sync

        @Volatile
        var isServiceRunning = false

        @Volatile
        var instance: MBankScreenAccessibilityService? = null

        fun dismissFloatingBubbleIfRunning() {
            instance?.let { service ->
                service.mainHandler.post { service.hideFloatingBubble() }
            }
        }
    }

    private var lastProcessTimestamp = 0L
    private val mainHandler = Handler(Looper.getMainLooper())
    private var activeOverlayView: View? = null
    private var floatingBubbleView: View? = null
    private var bubbleParams: WindowManager.LayoutParams? = null
    private var quickEntrySheetView: View? = null
    private var socialBlockerOverlayView: View? = null
    private var lastSocialBlockTimestamp = 0L

    data class PendingTransferIntent(
        val amount: Double,
        val currency: String,
        val target: String,
        val timestamp: Long,
        val rawText: String,
        val packageName: String
    )

    private var activePendingTransfer: PendingTransferIntent? = null
    private var pendingTransferConfirmRunnable: Runnable? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        instance = this
        Log.i(TAG, "MBankScreenAccessibilityService connected and ready")
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putBoolean("flutter.arc_accessibility_confirmed_enabled", true)
                .putBoolean("arc_accessibility_confirmed_enabled", true)
                .apply()
        } catch (_: Exception) {}
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        try {
            val packageNameStr = event.packageName?.toString()?.lowercase(Locale.ROOT) ?: ""
            // Ignore events from our own application
            if (packageNameStr.isEmpty() ||
                packageNameStr == packageName.lowercase(Locale.ROOT) ||
                packageNameStr.contains("finance_management")
            ) {
                return
            }

            // Check Hardcore Social Media Blocker for overspending (Instagram, TikTok, YouTube, etc.)
            if (isBlockedSocialApp(packageNameStr)) {
                if (isSocialBlockerActive()) {
                    handleSocialAppBlocked(packageNameStr)
                    return
                }
            } else {
                if (socialBlockerOverlayView != null && !isTransientSystemPackage(packageNameStr)) {
                    mainHandler.post { dismissSocialBlockerOverlay() }
                }
            }

            // Ignore transient system UI packages (keyboard, system UI, biometric, launcher search)
            // so they don't hide the floating Capybara bubble while inside a banking app!
            if (isTransientSystemPackage(packageNameStr)) {
                return
            }

            // Check Messenger apps for transfer/debt mentions (e.g. "скинь 200 сом", "переведи 500")
            if (isMessengerApp(packageNameStr)) {
                mainHandler.post { hideFloatingBubble() }
                handleMessengerChatScan(event, packageNameStr)
                return
            }

            // Target bank apps or marketplaces
            if (!isTargetApp(packageNameStr)) {
                mainHandler.post { hideFloatingBubble() }
                return
            }

            // Keep floating bubble dismissed per user preference (prevents blocking bank UI)
            if (floatingBubbleView != null) {
                mainHandler.post { hideFloatingBubble() }
            }

            // Fast intercept for user click on transfer action buttons ("Перевести", "Оплатить", "Подтвердить")
            if (event.eventType == AccessibilityEvent.TYPE_VIEW_CLICKED) {
                handleViewClicked(event, packageNameStr)
                return
            }

            // Rate-limit processing to avoid excessive CPU usage during UI transitions
            val now = System.currentTimeMillis()
            if (now - lastProcessTimestamp < 200) {
                return
            }
            lastProcessTimestamp = now

            // Extract visible text hierarchy (optimized to 250 nodes for deep Compose/hybrid layouts)
            val rootNode = rootInActiveWindow ?: event.source ?: return
            val texts = mutableListOf<String>()
            extractVisibleTexts(rootNode, texts, 0, 250)

            if (texts.isEmpty()) return

            val fullCombined = texts.joinToString(" ").lowercase(Locale.ROOT)

            // Check 0: Banking error screen cancels pending transfer intent
            if (BankPatternConfig.isErrorScreen(fullCombined)) {
                if (activePendingTransfer != null) {
                    Log.w(TAG, "Bank screen displayed error, cancelling pending transfer: $fullCombined")
                    pendingTransferConfirmRunnable?.let { mainHandler.removeCallbacks(it) }
                    activePendingTransfer = null
                }
                return
            }

            // ПРИОРИТЕТ 1: Экран дашборда банка (Главный экран, баланс, карты, счета)
            // Всегда обрабатываем дашборд первым, чтобы кнопки меню/QR и промо-баннеры не считались чеками!
            val isDashboard = isDashboardScreenFast(fullCombined) || isDashboardScreen(fullCombined)
            if (isTargetBankingApp(packageNameStr) && isDashboard) {
                pendingTransferConfirmRunnable?.let { mainHandler.removeCallbacks(it) }
                activePendingTransfer = null
                analyzeDashboardBalances(texts, packageNameStr, fullCombined)
                return
            }

            // ПРИОРИТЕТ 2: Экран завершенного перевода / чек операции
            val isReceipt = isReceiptScreenText(fullCombined)
            if (isReceipt) {
                pendingTransferConfirmRunnable?.let { mainHandler.removeCallbacks(it) }
                val pending = activePendingTransfer
                activePendingTransfer = null
                analyzeReceiptScreen(texts, packageNameStr, fullCombined, pending)
                return
            }

            // ПРИОРИТЕТ 3: Экран ввода суммы / подтверждения перевода (Capybara-Filter)
            val isPreConfirmation = isTransferScreen(fullCombined) || isPreTransactionScreen(fullCombined)
            if (isPreConfirmation) {
                analyzePreTransactionCheckout(texts, packageNameStr, fullCombined)
                return
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in onAccessibilityEvent: ${e.message}", e)
        }
    }

    private fun isTransientSystemPackage(pkg: String): Boolean {
        if (pkg.isEmpty()) return true
        val lower = pkg.lowercase(Locale.ROOT)
        return lower == "android" ||
                lower.contains("systemui") ||
                lower.contains("inputmethod") ||
                lower.contains("keyboard") ||
                lower.contains("latin") ||
                lower.contains("gboard") ||
                lower.contains("swiftkey") ||
                lower.contains("samsung.ime") ||
                lower.contains("biometric") ||
                lower.contains("credentials") ||
                lower.contains("autofill") ||
                lower.contains("permissioncontroller")
    }

    private fun isMessengerApp(pkg: String): Boolean {
        val lower = pkg.lowercase(Locale.ROOT)
        return lower.contains("whatsapp") ||
                lower.contains("telegram") ||
                lower.contains("challegram") ||
                lower.contains("plus.messenger") ||
                lower.contains("messaging") ||
                lower.contains("mms") ||
                lower.contains("sms")
    }

    private var lastMessengerScanTime = 0L
    private val scheduledDebtReminders = mutableMapOf<String, Long>()

    private fun handleMessengerChatScan(event: AccessibilityEvent, pkg: String) {
        val now = System.currentTimeMillis()
        if (now - lastMessengerScanTime < 600) return
        lastMessengerScanTime = now

        val rootNode = rootInActiveWindow ?: event.source ?: return
        val texts = mutableListOf<String>()
        extractVisibleTexts(rootNode, texts, 0, 40)
        if (texts.isEmpty()) return

        // Pattern matching transfer/debt mentions like:
        // "скинь 200 сом", "скинь 200", "переведи 500 сом", "закинь 1000", "скинул 300 сом", "верни 200"
        val debtPattern = Pattern.compile(
            "(?:скинь|переведи|закинь|скинул|перевел|отправь|верни|одолжи|займи)\\s*(?:мне|нам|на\\s+мбанк|на\\s+mbank)?\\s*(\\d{1,5})\\s*(?:сом|c|с|kgs)?",
            Pattern.CASE_INSENSITIVE
        )

        for (text in texts) {
            val matcher = debtPattern.matcher(text)
            if (matcher.find()) {
                val amountStr = matcher.group(1) ?: continue
                val amount = amountStr.toDoubleOrNull() ?: continue
                if (amount <= 0 || amount > 100_000) continue
                if (BankPatternConfig.isLikelyPhoneNumberPrefix(amount, text)) continue

                val matchedPhrase = matcher.group(0)?.trim() ?: "скинь $amountStr сом"
                val signature = "${amount.toInt()}_${matchedPhrase.lowercase(Locale.ROOT)}"

                // Rate-limit: don't schedule multiple alarms for the same phrase within 30 minutes
                val lastScheduled = scheduledDebtReminders[signature]
                if (lastScheduled != null && now - lastScheduled < 30 * 60 * 1000L) {
                    continue
                }
                scheduledDebtReminders[signature] = now

                Log.i(TAG, "Messenger debt/transfer detected: '$matchedPhrase' ($amount SOM). Scheduling 15-minute reminder.")

                // Schedule alarm in 15 minutes (900 seconds)
                try {
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val alarmId = (now % 100000).toInt() + 7000
                    val intent = Intent(this, AlarmReceiver::class.java).apply {
                        putExtra("id", alarmId)
                        putExtra("title", "Капибара помнит: ${amount.toInt()} сом")
                        putExtra("body", "15 минут назад в переписке было: «$matchedPhrase». Деньги пришли? Запишите в доходы или долг.")
                        putExtra("quick_action", "debt_reminder:${amount.toInt()}:$matchedPhrase")
                    }
                    val pendingIntent = PendingIntent.getBroadcast(
                        this,
                        alarmId,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    val triggerAt = now + (15 * 60 * 1000L) // 15 minutes!
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                    } else {
                        alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                    }

                    // Scheduled reminder safely without intrusive toast interruption
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to schedule messenger debt reminder: ${e.message}", e)
                }
                break
            }
        }
    }

    private fun isTargetApp(pkg: String): Boolean {
        return isTargetBankingApp(pkg) || isTargetMarketplaceApp(pkg)
    }

    private fun isTargetBankingApp(pkg: String): Boolean {
        return BankPatternConfig.isWhitelistedPackage(pkg)
    }

    private fun isTargetMarketplaceApp(pkg: String): Boolean {
        return pkg.contains("wildberries") ||
                pkg.contains("ozon") ||
                pkg.contains("aliexpress") ||
                pkg.contains("glovo") ||
                pkg.contains("wolt") ||
                pkg.contains("yandex.taxi") ||
                pkg.contains("yango")
    }

    private fun extractVisibleTexts(
        node: AccessibilityNodeInfo?,
        result: MutableList<String>,
        depth: Int,
        maxNodes: Int
    ) {
        if (node == null || node.isPassword || result.size >= maxNodes || depth > 28) return

        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty() && text.length > 1) {
            result.add(text)
        }

        val contentDesc = node.contentDescription?.toString()?.trim()
        if (!contentDesc.isNullOrEmpty() && contentDesc.length > 1 && contentDesc != text) {
            result.add(contentDesc)
        }

        for (i in 0 until node.childCount) {
            if (result.size >= maxNodes) break
            val child = try {
                node.getChild(i)
            } catch (e: Exception) {
                null
            }
            if (child != null) {
                extractVisibleTexts(child, result, depth + 1, maxNodes)
            }
        }
    }

    // =========================================================================
    // FEATURE 1: POST-TRANSACTION RECEIPT CAPTURE + SMART AUTOCATEGORIZATION
    // =========================================================================

    private fun isHistoryScreen(fullCombined: String): Boolean {
        // Если экран содержит явные маркеры истории транзакций / выписки
        val hasHistoryTitle = fullCombined.contains("история") ||
                fullCombined.contains("история операций") ||
                fullCombined.contains("история платежей") ||
                fullCombined.contains("история переводов") ||
                fullCombined.contains("выписка") ||
                fullCombined.contains("все операции") ||
                fullCombined.contains("архив операций") ||
                fullCombined.contains("тарых") || // кыргызский: тарых (история)
                fullCombined.contains("акыркы аракеттер")

        if (!hasHistoryTitle) return false

        // Чек/квитанция обычно НЕ содержат слова фильтров истории: "все", "за месяц", "фильтр", "период"
        val hasHistoryControls = fullCombined.contains("фильтр") ||
                fullCombined.contains("период") ||
                fullCombined.contains("за месяц") ||
                fullCombined.contains("за сегодня") ||
                fullCombined.contains("за неделю") ||
                fullCombined.contains("категории") ||
                fullCombined.contains("поиск по операциям")

        return hasHistoryControls || hasHistoryTitle
    }

    private fun isDashboardScreenFast(fullCombined: String): Boolean {
        // Явные маркеры главного экрана банка, экрана карт/счетов или витрины
        return fullCombined.contains("главная") ||
                fullCombined.contains("башкы") ||
                fullCombined.contains("мой банк") ||
                fullCombined.contains("счета и карты") ||
                fullCombined.contains("карты и счета") ||
                fullCombined.contains("мои карты") ||
                fullCombined.contains("мои счета") ||
                fullCombined.contains("мои продукты") ||
                fullCombined.contains("драгоценные металлы") ||
                fullCombined.contains("манипол") ||
                fullCombined.contains("события недели") ||
                fullCombined.contains("покупайте авто") ||
                fullCombined.contains("эксклюзив:") ||
                fullCombined.contains("эксклюзив") ||
                (fullCombined.contains("сервисы") && fullCombined.contains("платежи")) ||
                (fullCombined.contains("mmarket") && fullCombined.contains("mbank"))
    }

    private fun isReceiptScreenText(fullCombined: String): Boolean {
        // Никогда не парсим экран истории операций или дашборд как отдельный чек
        if (isDashboardScreenFast(fullCombined) || isHistoryScreen(fullCombined)) {
            return false
        }

        // Оплата по QR (в MBank: "Оплата по QR", "QR төлөм", "Чек операции" + обязательный статус успеха)
        val isQrPaymentReceipt = (fullCombined.contains("оплата по qr") ||
                fullCombined.contains("оплата через qr") ||
                fullCombined.contains("qr төлөм") ||
                fullCombined.contains("чек qr")) &&
                (fullCombined.contains("успешно") || fullCombined.contains("проведена") ||
                 fullCombined.contains("выполнена") || fullCombined.contains("чек операции") ||
                 fullCombined.contains("электронный чек") || fullCombined.contains("поделиться чеком") ||
                 fullCombined.contains("сохранить чек") || fullCombined.contains("акча которулду") ||
                 fullCombined.contains("төлөм аткарылды"))

        if (isQrPaymentReceipt) return true

        // Чек ОБЯЗАН иметь однозначный заголовок завершения операции или кнопки чека
        return BankPatternConfig.isSuccessScreen(fullCombined) ||
                fullCombined.contains("перевод выполнен") ||
                fullCombined.contains("перевод отправлен") ||
                fullCombined.contains("деньги отправлены") ||
                fullCombined.contains("перевод успешен") ||
                fullCombined.contains("перевод совершен") ||
                fullCombined.contains("платеж выполнен") ||
                fullCombined.contains("платеж проведен") ||
                fullCombined.contains("платеж совершен") ||
                fullCombined.contains("оплата проведена") ||
                fullCombined.contains("оплата прошла") ||
                fullCombined.contains("поделиться чеком") ||
                fullCombined.contains("сохранить чек") ||
                fullCombined.contains("чек операции") ||
                fullCombined.contains("электронный чек") ||
                fullCombined.contains("квитанция по операции") ||
                fullCombined.contains("квитанция об оплате") ||
                fullCombined.contains("акча которулду") ||
                fullCombined.contains("төлөм аткарылды") ||
                (fullCombined.contains("успешно") && (fullCombined.contains("перевод") || fullCombined.contains("платеж") || fullCombined.contains("оплачен") || fullCombined.contains("отправлен")))
    }

    private fun isTransferInputScreen(fullCombined: String): Boolean {
        if (isDashboardScreenFast(fullCombined) || isReceiptScreenText(fullCombined)) return false

        // Экран ввода реквизитов / подтверждения перед отправкой (деньги еще НЕ отправлены!)
        val hasInputMarkers = fullCombined.contains("введите сумму") ||
                fullCombined.contains("введите номер") ||
                fullCombined.contains("сумма перевода") ||
                fullCombined.contains("комиссия") ||
                fullCombined.contains("откуда:") ||
                fullCombined.contains("куда:") ||
                fullCombined.contains("со счета") ||
                fullCombined.contains("на счет") ||
                fullCombined.contains("кошелек получателя") ||
                fullCombined.contains("подтвердить перевод") ||
                fullCombined.contains("к оплате")

        return hasInputMarkers
    }

    private fun isTransferScreen(fullCombined: String): Boolean {
        if (isDashboardScreenFast(fullCombined) || isReceiptScreenText(fullCombined) || isHistoryScreen(fullCombined)) {
            return false
        }

        val hasTransferTitle = fullCombined.contains("перевод клиенту") ||
                fullCombined.contains("перевод по номеру") ||
                fullCombined.contains("перевод на карту") ||
                fullCombined.contains("перевод на счет") ||
                fullCombined.contains("между своими счетами") ||
                fullCombined.contains("переводы") ||
                fullCombined.contains("акча которуу") ||
                fullCombined.contains("которуу")

        val hasTransferFields = fullCombined.contains("сумма") ||
                fullCombined.contains("введите сумму") ||
                fullCombined.contains("сумма перевода") ||
                fullCombined.contains("номер получателя") ||
                fullCombined.contains("получатель") ||
                fullCombined.contains("кому") ||
                fullCombined.contains("откуда") ||
                fullCombined.contains("со счета") ||
                fullCombined.contains("на счет") ||
                fullCombined.contains("комиссия")

        val hasTransferAction = fullCombined.contains("перевести") ||
                fullCombined.contains("отправить") ||
                fullCombined.contains("оплатить") ||
                fullCombined.contains("подтвердить")

        return (hasTransferTitle && (hasTransferFields || hasTransferAction)) ||
                (hasTransferFields && hasTransferAction) ||
                isTransferInputScreen(fullCombined)
    }

    private fun isDashboardScreen(fullCombined: String): Boolean {
        // Никогда не считаем дашбордом экран истории операций или чек
        if (isHistoryScreen(fullCombined) || isReceiptScreenText(fullCombined)) {
            return false
        }

        if (isDashboardScreenFast(fullCombined)) {
            return true
        }

        // Маркеры главного экрана / дашборда банка (MBank, Optima, Bakai, Demir и др.)
        val hasDashboardCore = fullCombined.contains("главная") ||
                fullCombined.contains("башкы") ||
                fullCombined.contains("мои карты") ||
                fullCombined.contains("карты и счета") ||
                fullCombined.contains("карт-счет") ||
                fullCombined.contains("мои счета") ||
                fullCombined.contains("мой банк") ||
                fullCombined.contains("mbank") ||
                fullCombined.contains("mmarket") ||
                fullCombined.contains("все сервисы") ||
                fullCombined.contains("карталар") ||
                fullCombined.contains("эсеп") ||
                fullCombined.contains("доступно") ||
                fullCombined.contains("баланс") ||
                fullCombined.contains("калдык")

        // Типичные элементы дашборда банка
        val hasDashboardElements = (fullCombined.contains("пополнить") || fullCombined.contains("толуктоо")) ||
                fullCombined.contains("сканировать qr") ||
                fullCombined.contains("мой qr") ||
                fullCombined.contains("маниполия") ||
                fullCombined.contains("события недели") ||
                fullCombined.contains("покупайте авто") ||
                fullCombined.contains("эксклюзив") ||
                (fullCombined.contains("сервисы") && fullCombined.contains("платежи"))

        return hasDashboardCore && (hasDashboardElements || fullCombined.contains("главная") || fullCombined.contains("башкы"))
    }

    private fun handleViewClicked(event: AccessibilityEvent, pkg: String) {
        try {
            val clickedText = (event.text?.joinToString(" ") ?: event.contentDescription?.toString() ?: "").lowercase(Locale.ROOT)
            val isTransferAction = BankPatternConfig.TRANSFER_ACTION_BUTTONS.any { clickedText.contains(it) }
            if (!isTransferAction) return

            val rootNode = rootInActiveWindow ?: event.source ?: return
            val texts = mutableListOf<String>()
            extractVisibleTexts(rootNode, texts, 0, 250)
            if (texts.isEmpty()) return

            val fullCombined = texts.joinToString(" ").lowercase(Locale.ROOT)
            if (isDashboardScreenFast(fullCombined)) {
                // Нажатия на дашборде (табы "Платежи", "Сервисы", "Главная", промо-карточки) не являются отправкой денег!
                return
            }
            val amount = extractTransferInputAmount(texts, fullCombined)
                ?: extractAmountFromTexts(texts, fullCombined)
                ?: 0.0

            val merchantInfo = extractMerchantAndCategory(texts, fullCombined, false)
            val target = merchantInfo.first

            val displayAmt = if (amount > 0.0) "${amount.toInt()}" else ""
            updateBubbleStatus("-$displayAmt с", "Отправка...", isAlert = true)
            Log.i(TAG, "Transfer click detected ($clickedText). Staging transfer: $amount SOM to $target")

            pendingTransferConfirmRunnable?.let { mainHandler.removeCallbacks(it) }
            activePendingTransfer = PendingTransferIntent(
                amount = amount,
                currency = "KGS",
                target = target,
                timestamp = System.currentTimeMillis(),
                rawText = fullCombined,
                packageName = pkg
            )

            // Stage in memory for correlation when the actual receipt screen appears.
            // Automatically clear after 30 seconds if user cancels or leaves (NO auto-commit!)
            pendingTransferConfirmRunnable = Runnable {
                activePendingTransfer = null
                Log.d(TAG, "Pending transfer intent timed out without receipt.")
            }
            mainHandler.postDelayed(pendingTransferConfirmRunnable!!, 30000L)

            // Trigger Capybara-Filter warning on transfer click!
            val now = System.currentTimeMillis()
            if (now - userBypassedCapybaraTime < 30_000L) {
                Log.i(TAG, "Capybara filter bypassed by user consent within 30s")
                return
            }

            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isFilterEnabled = if (prefs.contains("flutter.arc_capybara_filter_enabled")) {
                prefs.getBoolean("flutter.arc_capybara_filter_enabled", true)
            } else {
                prefs.getBoolean("arc_capybara_filter_enabled", true)
            }

            if (isFilterEnabled) {
                val threshold = try {
                    prefs.getFloat("flutter.arc_capybara_filter_threshold", 50.0f).toDouble()
                } catch (_: Exception) {
                    50.0
                }
                if (amount >= threshold || amount == 0.0) {
                    val dreamGoal = prefs.getString("flutter.arc_active_dream_goal", "MacBook Pro M3") ?: "MacBook Pro M3"
                    val remainingGoal = try {
                        prefs.getFloat("flutter.arc_active_dream_remaining", 120_000.0f).toDouble()
                    } catch (_: Exception) {
                        120_000.0
                    }
                    Log.i(TAG, "Triggering Capybara Pre-Transaction Filter from click for amount: $amount SOM")
                    mainHandler.post {
                        showCapybaraOverlay(amount, dreamGoal, remainingGoal)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in handleViewClicked: ${e.message}", e)
        }
    }

    private fun analyzeReceiptScreen(
        texts: List<String>,
        pkg: String,
        fullCombined: String,
        pending: PendingTransferIntent? = null
    ) {
        var amount = extractAmountFromTexts(texts, fullCombined)
        if (amount == null || amount <= 0.0) {
            amount = pending?.amount
        }
        if (amount == null || amount <= 0.0) return

        val isIncome = BankPatternConfig.isIncomeTransaction(fullCombined)
        val isQr = fullCombined.contains("оплата по qr") || fullCombined.contains("qr төлөм") || fullCombined.contains("оплата через qr")

        val merchantInfo = extractMerchantAndCategory(texts, fullCombined, isIncome)
        var title = merchantInfo.first
        if ((title == "Платеж MBank" || title == "MBank" || title.isEmpty()) && pending != null && pending.target.isNotEmpty() && pending.target != "MBank") {
            title = pending.target
        }

        // Remaining balance if visible
        val balanceAfter = extractBalanceAfter(fullCombined)

        val sign = if (isIncome) "+" else "-"
        updateBubbleStatus("$sign с", "Записано!", isAlert = false)
        Log.i(TAG, "Receipt captured! Amount: $amount, Title: $title, isIncome: $isIncome, isQr: $isQr")
        commitTransfer(amount, title, pkg, fullCombined, isIncome, balanceAfter, isQr = isQr)
    }

    private fun commitTransfer(
        amount: Double,
        title: String,
        pkg: String,
        fullCombined: String,
        isIncome: Boolean,
        balanceAfter: Double? = null,
        isLagFallback: Boolean = false,
        isQr: Boolean = false
    ) {
        val cleanAmount = String.format(Locale.US, "%.2f", amount)
        val currentTime = System.currentTimeMillis()
        val notificationTitle = if (isIncome) "Зачисление: $title" else (if (isQr) "Оплата по QR: $title" else "Оплата: $title")
        val suffix = if (isQr) "Чек QR-оплаты" else (if (isLagFallback) "Зафиксировано при подтверждении" else "Электронный чек")
        val notificationBody = "${if (isIncome) "+" else "−"}$cleanAmount сом • $suffix"
        val rawText = "$notificationTitle: $notificationBody"

        val recordedTx = TransactionDeduplicationManager.getInstance(this).onUiTransactionCaptured(
            packageName = pkg,
            amount = amount,
            currency = "KGS",
            targetIdentifier = title,
            title = notificationTitle,
            rawText = rawText,
            timestamp = currentTime,
            isIncome = isIncome
        )

        if (recordedTx == null) {
            Log.d(TAG, "UI transaction ignored by TransactionDeduplicationManager as duplicate within TTL window")
            return
        }

        if (balanceAfter != null && balanceAfter > 0) {
            broadcastScrapedBalance("MBank", balanceAfter, currentTime)
        }

        mainHandler.post {
            try {
                Toast.makeText(
                    applicationContext,
                    "ARC Finance: ${if (isIncome) "+" else "−"}$cleanAmount сом ($title)",
                    Toast.LENGTH_SHORT
                ).show()
            } catch (_: Exception) {}
        }
    }

    // =========================================================================
    // FEATURE 2: PRE-TRANSACTION "CAPYBARA-FILTER" OVERLAY
    // =========================================================================

    private fun isPreTransactionScreen(fullCombined: String): Boolean {
        if (isDashboardScreenFast(fullCombined) || isReceiptScreenText(fullCombined) || isHistoryScreen(fullCombined)) {
            return false
        }
        if (isTransferScreen(fullCombined)) {
            return true
        }

        return fullCombined.contains("подтвердить") ||
                fullCombined.contains("подтвердите") ||
                fullCombined.contains("подтверждение") ||
                fullCombined.contains("к оплате") ||
                fullCombined.contains("оплатить") ||
                fullCombined.contains("перевести") ||
                fullCombined.contains("оформить заказ") ||
                fullCombined.contains("сумма перевода") ||
                fullCombined.contains("введите сумму")
    }

    private fun analyzePreTransactionCheckout(texts: List<String>, pkg: String, fullCombined: String) {
        val amount = extractTransferInputAmount(texts, fullCombined)
            ?: extractAmountFromTexts(texts, fullCombined)
            ?: return
        if (amount <= 0.0) return

        // Обновляем плавающую капибару в реальном времени: она видит сумму перевода!
        val displayAmount = if (amount == amount.toInt().toDouble()) "${amount.toInt()}" else String.format(Locale.US, "%.2f", amount)
        updateBubbleStatus("-$displayAmount с", "Перевод?", isAlert = true)

        val now = System.currentTimeMillis()
        if (now - userBypassedCapybaraTime < 30_000L) {
            return
        }

        // Read user config from SharedPreferences (default true!)
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isFilterEnabled = if (prefs.contains("flutter.arc_capybara_filter_enabled")) {
            prefs.getBoolean("flutter.arc_capybara_filter_enabled", true)
        } else {
            prefs.getBoolean("arc_capybara_filter_enabled", true)
        }
        if (!isFilterEnabled) return

        val threshold = try {
            prefs.getFloat("flutter.arc_capybara_filter_threshold", 50.0f).toDouble()
        } catch (_: Exception) {
            50.0
        }
        if (amount < threshold) return

        if (now - lastPreTxAlertTime < 25_000L && Math.abs(amount - lastPreTxAlertAmount) < 1.0) {
            return // Don't spam alert for same checkout within 25 seconds
        }
        lastPreTxAlertTime = now
        lastPreTxAlertAmount = amount

        val dreamGoal = prefs.getString("flutter.arc_active_dream_goal", "MacBook Pro M3") ?: "MacBook Pro M3"
        val remainingGoal = try {
            prefs.getFloat("flutter.arc_active_dream_remaining", 120_000.0f).toDouble()
        } catch (_: Exception) {
            120_000.0
        }

        Log.i(TAG, "Triggering Capybara Pre-Transaction Filter for amount: $amount SOM")

        mainHandler.post {
            showCapybaraOverlay(amount, dreamGoal, remainingGoal)
        }
    }

    private fun showCapybaraOverlay(amount: Double, dreamGoal: String, remainingGoal: Double) {
        try {
            dismissCapybaraOverlay()

            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

            val rootLayout = FrameLayout(this).apply {
                setBackgroundColor(Color.parseColor("#99000000")) // Semi-transparent black scrim
                setOnClickListener {
                    dismissCapybaraOverlay()
                }
            }

            val cardContainer = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                val bg = GradientDrawable().apply {
                    setColor(Color.parseColor("#1C1C1E"))
                    cornerRadius = dpToPx(20).toFloat()
                    setStroke(dpToPx(1.5f), Color.parseColor("#FF9F0A")) // Capybara Amber accent border
                }
                background = bg
                setPadding(dpToPx(22), dpToPx(20), dpToPx(22), dpToPx(20))
                elevation = dpToPx(16).toFloat()
                isClickable = true
            }

            val cardParams = FrameLayout.LayoutParams(
                dpToPx(330),
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
            }
            rootLayout.addView(cardContainer, cardParams)

            // 0. Capybara Avatar & Header
            val capyHeader = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, 0, 0, dpToPx(10))
            }
            val capyAvatar = TextView(this).apply {
                text = "ARC"
                setTextColor(Color.parseColor("#FF9F0A"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, 0, dpToPx(10), 0)
            }
            capyHeader.addView(capyAvatar)

            val tagAndTitle = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
            }
            val tagText = TextView(this).apply {
                text = "ФИНАНСОВЫЙ КОНТРОЛЬ"
                setTextColor(Color.parseColor("#FF9F0A")) // Amber
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
                typeface = Typeface.DEFAULT_BOLD
                letterSpacing = 0.08f
            }
            tagAndTitle.addView(tagText)

            val titleText = TextView(this).apply {
                text = "Точно переводим?"
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 19f)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, dpToPx(2), 0, 0)
            }
            tagAndTitle.addView(titleText)
            capyHeader.addView(tagAndTitle)

            cardContainer.addView(capyHeader)

            // 3. Amount
            val amountText = TextView(this).apply {
                text = if (amount > 0.0) "Сумма: ${amount.toInt()} сом" else "Внимание: перевод средств"
                setTextColor(Color.parseColor("#FF9F0A"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, dpToPx(2), 0, dpToPx(10))
            }
            cardContainer.addView(amountText)

            // 4. Mascot Philosophy Body
            val bodyText = TextView(this).apply {
                text = "А как же цель на «$dreamGoal»? До цели осталось собрать ${remainingGoal.toInt()} сом.\n\nКапибара советует: импульсивные покупки разрушают стрик дисциплины. Сделай паузу на 10 секунд перед оплатой."
                setTextColor(Color.parseColor("#D0D0D2"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setLineSpacing(dpToPx(3).toFloat(), 1.0f)
                setPadding(0, 0, 0, dpToPx(16))
            }
            cardContainer.addView(bodyText)

            // 5. Action Buttons (Horizontal)
            val btnRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                weightSum = 2.0f
            }

            // Button 1: Cancel & Go Back (Physically stops impulse purchase!)
            val btnCancel = Button(this).apply {
                text = "Подумать ещё"
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
                typeface = Typeface.DEFAULT_BOLD
                val btnBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#FF453A")) // Apple Red
                    cornerRadius = dpToPx(12).toFloat()
                }
                background = btnBg
                setOnClickListener {
                    dismissCapybaraOverlay()
                    // Perform back action to safely close checkout screen in banking app!
                    performGlobalAction(GLOBAL_ACTION_BACK)
                }
            }
            val btnCancelParams = LinearLayout.LayoutParams(0, dpToPx(44), 1.0f).apply {
                marginEnd = dpToPx(8)
            }
            btnRow.addView(btnCancel, btnCancelParams)

            // Button 2: Proceed Anyway
            val btnProceed = Button(this).apply {
                text = "Перевести"
                setTextColor(Color.parseColor("#98989D"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
                typeface = Typeface.DEFAULT_BOLD
                val btnBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#2C2C2E"))
                    cornerRadius = dpToPx(12).toFloat()
                }
                background = btnBg
                setOnClickListener {
                    userBypassedCapybaraTime = System.currentTimeMillis()
                    userBypassedAmount = amount
                    dismissCapybaraOverlay()
                }
            }
            val btnProceedParams = LinearLayout.LayoutParams(0, dpToPx(44), 1.0f)
            btnRow.addView(btnProceed, btnProceedParams)

            cardContainer.addView(btnRow)

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                layoutType,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            try {
                windowManager.addView(rootLayout, params)
                activeOverlayView = rootLayout
            } catch (e: Exception) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        params.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                        windowManager.addView(rootLayout, params)
                        activeOverlayView = rootLayout
                    } catch (e2: Exception) {
                        Log.e(TAG, "Fallback to TYPE_APPLICATION_OVERLAY also failed: ${e2.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error displaying Capybara overlay: ${e.message}", e)
        }
    }

    private fun dismissCapybaraOverlay() {
        activeOverlayView?.let {
            try {
                val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                windowManager.removeView(it)
            } catch (_: Exception) {}
            activeOverlayView = null
        }
    }

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            resources.displayMetrics
        ).toInt()
    }

    private fun dpToPx(dp: Int): Int = dpToPx(dp.toFloat())

    // =========================================================================
    // FEATURE 3: SHADOW BALANCE SCRAPING
    // =========================================================================

    private fun analyzeDashboardBalances(texts: List<String>, pkg: String, fullCombined: String) {
        val bankName = getBankDisplayName(pkg)
        val balance = extractCardBalanceFromTexts(texts, fullCombined) ?: return
        if (balance <= 0.0) return

        val now = System.currentTimeMillis()
        val lastSeenBalance = lastScrapedBalances[bankName]
        val lastSeenTime = lastScrapedTimestamps[bankName] ?: 0L

        // If balance unchanged and scraped recently within 30s, update bubble but skip redundant broadcasts
        if (lastSeenBalance != null && Math.abs(lastSeenBalance - balance) < 0.05 && (now - lastSeenTime) < BALANCE_SCRAPE_INTERVAL_MS) {
            val displayBalance = if (balance == balance.toInt().toDouble()) "${balance.toInt()}" else String.format(Locale.US, "%.2f", balance)
            updateBubbleStatus("$displayBalance с", "Баланс OK", isAlert = false)
            return
        }

        lastScrapedBalances[bankName] = balance
        lastScrapedTimestamps[bankName] = now

        val displayBalance = if (balance == balance.toInt().toDouble()) "${balance.toInt()}" else String.format(Locale.US, "%.2f", balance)
        updateBubbleStatus("$displayBalance с", "Баланс OK", isAlert = false)
        Log.i(TAG, "Shadow balance scraped! Bank: $bankName, Balance: $balance SOM")

        broadcastScrapedBalance(bankName, balance, now)

        mainHandler.post {
            try {
                Toast.makeText(
                    applicationContext,
                    "ARC Finance: Баланс $bankName ($displayBalance сом) синхронизирован",
                    Toast.LENGTH_SHORT
                ).show()
            } catch (_: Exception) {}
        }
    }

    private fun broadcastScrapedBalance(bankName: String, balance: Double, now: Long) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val balanceObj = JSONObject().apply {
                put("bank", bankName)
                put("balance", balance)
                put("timestamp", now)
            }
            prefs.edit()
                .putString("flutter.$PREFS_KEY_SCRAPED_BALANCES", balanceObj.toString())
                .putString(PREFS_KEY_SCRAPED_BALANCES, balanceObj.toString())
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving scraped balance: ${e.message}")
        }

        // Broadcast to MainActivity
        val broadcastIntent = Intent(ACTION_BANK_BALANCE_SCRAPED).apply {
            putExtra("bank", bankName)
            putExtra("balance", balance)
            putExtra("timestamp", now)
            setPackage(packageName)
        }
        sendBroadcast(broadcastIntent)
    }

    private fun getBankDisplayName(pkg: String): String {
        val lower = pkg.lowercase(Locale.ROOT)
        return when {
            lower.contains("mbank") || lower.contains("cbk") || lower.contains("maanavan") || lower.contains("mb_kyrgyzstan") -> "MBank"
            lower.contains("optima") -> "Optima"
            lower.contains("demir") -> "Demir Bank"
            lower.contains("bakai") -> "Bakai Bank"
            lower.contains("finca") -> "Finca Bank"
            lower.contains("o.dengi") || lower.contains("dengi") -> "O! Деньги"
            lower.contains("megapay") -> "MegaPay"
            lower.contains("doscredo") || lower.contains("simbank") -> "DosCredo Bank"
            lower.contains("eldik") || lower.contains("rsk") -> "РСК / Элдик Банк"
            else -> "Банк"
        }
    }

    // =========================================================================
    // FEATURE 4: SMART MERCHANT EXTRACTION & CATEGORIZATION
    // =========================================================================

    private fun extractMerchantAndCategory(
        texts: List<String>,
        fullCombined: String,
        isIncome: Boolean
    ): Pair<String, String> {
        if (isIncome) {
            if (fullCombined.contains("зарплат") || fullCombined.contains("з/п") || fullCombined.contains("salary")) {
                return Pair("Зарплата", "cat_salary")
            }
            return Pair("Пополнение счета", "cat_other_income")
        }

        // 1. Recipient extraction via regular expressions
        for (pattern in BankPatternConfig.RECIPIENT_PATTERNS) {
            val matcher = pattern.matcher(fullCombined)
            if (matcher.find()) {
                val candidate = matcher.group(1)?.trim() ?: ""
                if (candidate.length > 2 && !candidate.contains("сом", ignoreCase = true) && !candidate.contains("успешно", ignoreCase = true)) {
                    val cat = mapMerchantToCategory(candidate.lowercase(Locale.ROOT))
                    return Pair(candidate, cat)
                }
            }
        }

        // 2. Check for explicit neighbor nodes with or without colons: "Получатель", "Кому", "Клиент", "Оплата по QR"
        for (i in texts.indices) {
            val lower = texts[i].lowercase(Locale.ROOT).trimEnd(':', ' ', '-')
            if (lower == "получатель" || lower == "кому" || lower == "клиент" || lower == "магазин" ||
                lower == "торговая точка" || lower == "назначение" || lower == "перевод клиенту" ||
                lower == "перевод на карту" || lower == "фио" || lower == "продавец" ||
                lower == "мерчант" || lower == "заведение" || lower == "оплата по qr" || lower == "qr төлөм"
            ) {
                if (i + 1 < texts.size && texts[i + 1].length > 1) {
                    val rawName = texts[i + 1].trim()
                    if (!rawName.contains("сом", ignoreCase = true) && !rawName.contains("успешно", ignoreCase = true)) {
                        val cat = mapMerchantToCategory(rawName.lowercase(Locale.ROOT))
                        return Pair(rawName, cat)
                    }
                }
            }
        }

        // 3. Check for phone or card in text
        val phoneRegex = Regex("""(\+?996\s*[\d\s-]{9,13})""")
        val phoneMatch = phoneRegex.find(fullCombined)?.value
        if (phoneMatch != null) {
            return Pair("Перевод: $phoneMatch", "cat_transfers")
        }

        // 2. Scan text for known Kyrgyz vendors
        val vendorDict = listOf(
            // Groceries
            "Глобус" to "cat_groceries", "Globus" to "cat_groceries",
            "Фрунзе" to "cat_groceries", "Frunze" to "cat_groceries",
            "Народный" to "cat_groceries", "Narodnyi" to "cat_groceries",
            "Азия" to "cat_groceries", "Достор" to "cat_groceries",
            "Корзинка" to "cat_groceries", "Гипермаркет" to "cat_groceries",

            // Cafes & Food
            "Фаиза" to "cat_restaurants", "Faiza" to "cat_restaurants",
            "Нават" to "cat_restaurants", "Navat" to "cat_restaurants",
            "Бублик" to "cat_restaurants", "Bublik" to "cat_restaurants",
            "Куликовский" to "cat_restaurants", "Kulikov" to "cat_restaurants",
            "Додо" to "cat_restaurants", "Dodo" to "cat_restaurants",
            "KFC" to "cat_restaurants", "Burger" to "cat_restaurants",
            "Coffee" to "cat_restaurants", "Кофейня" to "cat_restaurants",

            // Transport & Fuel
            "Яндекс" to "cat_transport", "Yandex" to "cat_transport",
            "Такси" to "cat_transport", "Taxi" to "cat_transport",
            "Газпром" to "cat_transport", "Gazprom" to "cat_transport",
            "Bishkek Petroleum" to "cat_transport", "Red Petroleum" to "cat_transport",
            "Маршрутка" to "cat_transport", "Тулпар" to "cat_transport",

            // Shopping & Marketplaces
            "Wildberries" to "cat_shopping", "Вайлдберриз" to "cat_shopping",
            "Ozon" to "cat_shopping", "Озон" to "cat_shopping",
            "Дордой" to "cat_shopping", "ЦУМ" to "cat_shopping",
            "Asia Mall" to "cat_shopping", "Zara" to "cat_shopping",

            // Health & Pharmacy
            "Неман" to "cat_health", "Neman" to "cat_health",
            "Аптека" to "cat_health", "Бимед" to "cat_health",
            "Бонецкий" to "cat_health",

            // Utilities & Mobile
            "О! Деньги" to "cat_housing", "MegaCom" to "cat_housing",
            "Beeline" to "cat_housing", "Северэлектро" to "cat_housing",
            "Тазалык" to "cat_housing", "Акнет" to "cat_housing"
        )

        // 4. Scan distinct text nodes for known vendors (never globally across fullCombined to prevent service catalog false positives)
        for (text in texts) {
            val lineLower = text.lowercase(Locale.ROOT).trim()
            if (lineLower.contains("сервис") || lineLower.contains("услуг") || lineLower.contains("каталог") || lineLower.contains("популярн")) {
                continue
            }
            for ((name, cat) in vendorDict) {
                val vendorLower = name.lowercase(Locale.ROOT)
                if (vendorLower == "такси" || vendorLower == "taxi") {
                    if (lineLower.contains("яндекс") || lineLower.contains("yandex") || lineLower.contains("поездка") || lineLower.contains("uber")) {
                        return Pair("Яндекс Go", "cat_transport")
                    }
                    continue
                }
                if (lineLower.contains(vendorLower)) {
                    return Pair(name, cat)
                }
            }
        }

        return Pair("Платеж MBank", "cat_other_expense")
    }

    private fun mapMerchantToCategory(nameLower: String): String {
        return when {
            nameLower.contains("глобус") || nameLower.contains("globus") ||
                    nameLower.contains("фрунзе") || nameLower.contains("frunze") ||
                    nameLower.contains("народный") || nameLower.contains("маркет") -> "cat_groceries"

            nameLower.contains("фаиза") || nameLower.contains("faiza") ||
                    nameLower.contains("нават") || nameLower.contains("бублик") ||
                    nameLower.contains("додо") || nameLower.contains("kfc") ||
                    nameLower.contains("кафе") || nameLower.contains("ресторан") ||
                    nameLower.contains("кофе") || nameLower.contains("куликов") -> "cat_restaurants"

            nameLower.contains("яндекс") || nameLower.contains("yandex") ||
                    nameLower.contains("такси") || nameLower.contains("газпром") ||
                    nameLower.contains("petroleum") || nameLower.contains("азс") ||
                    nameLower.contains("тулпар") -> "cat_transport"

            nameLower.contains("wildberries") || nameLower.contains("вайлдберриз") ||
                    nameLower.contains("ozon") || nameLower.contains("озон") ||
                    nameLower.contains("дордой") || nameLower.contains("цум") ||
                    nameLower.contains("mall") || nameLower.contains("zara") -> "cat_shopping"

            nameLower.contains("неман") || nameLower.contains("аптек") ||
                    nameLower.contains("фарм") || nameLower.contains("бонецк") ||
                    nameLower.contains("бимед") -> "cat_health"

            nameLower.contains("коммунал") || nameLower.contains("северэлектро") ||
                    nameLower.contains("тазалык") || nameLower.contains("акнет") ||
                    nameLower.contains("о!") || nameLower.contains("megacom") ||
                    nameLower.contains("beeline") -> "cat_housing"

            else -> "cat_other_expense"
        }
    }

    // =========================================================================
    // GENERAL HELPERS
    // =========================================================================

    private fun extractAmountFromTexts(texts: List<String>, fullCombined: String): Double? {
        val candidates = mutableListOf<Double>()

        // 0. Filter out promo / advertising nodes
        val cleanTexts = texts.filter { text ->
            val lower = text.lowercase(Locale.ROOT)
            !lower.contains("манипол") &&
            !lower.contains("приз") &&
            !lower.contains("акци") &&
            !lower.contains("эксклюзив") &&
            !lower.contains("рассрочк") &&
            !lower.contains("ставка") &&
            !lower.contains("депозит") &&
            !lower.contains("металл") &&
            !lower.contains("покупайте") &&
            !lower.contains("подробнее")
        }

        fun isBlacklistedAmount(amt: Double): Boolean {
            return amt == 2845.0 || amt == 6672.0 || amt == 9303.0 ||
                    amt == 480.0 || amt == 350000.0 || amt == 50000000.0
        }

        // 1. Check full screen combined text with unified BankPatternConfig.AMOUNT_REGEX
        val unifiedMatcher = BankPatternConfig.AMOUNT_REGEX.matcher(fullCombined)
        while (unifiedMatcher.find()) {
            val rawNum = unifiedMatcher.group(1)
                ?.replace(" ", "")
                ?.replace("\u00A0", "")
                ?.replace(",", ".") ?: ""
            val parsed = rawNum.toDoubleOrNull()
            if (parsed != null && parsed > 0.0 && parsed < 10_000_000.0) {
                if (!isBlacklistedAmount(parsed) && !BankPatternConfig.isLikelyPhoneNumberPrefix(parsed, fullCombined)) {
                    candidates.add(parsed)
                }
            }
        }

        // 2. Check each clean node independently
        for (text in cleanTexts) {
            val m = BankPatternConfig.AMOUNT_REGEX.matcher(text)
            while (m.find()) {
                val rawNumber = m.group(1)
                    ?.replace(" ", "")
                    ?.replace("\u00A0", "")
                    ?.replace(",", ".") ?: ""
                val parsedVal = rawNumber.toDoubleOrNull()
                if (parsedVal != null && parsedVal > 0.0 && parsedVal < 10_000_000.0) {
                    if (!isBlacklistedAmount(parsedVal) &&
                        !BankPatternConfig.isLikelyPhoneNumberPrefix(parsedVal, text) &&
                        !BankPatternConfig.isLikelyPhoneNumberPrefix(parsedVal, fullCombined)) {
                        candidates.add(parsedVal)
                    }
                }
            }
        }

        // 3. Proximity check across up to 3 neighboring nodes (for custom Compose/Flutter banking views)
        val currencyMarkers = listOf("сом", "kgs", "kzt", "rub", "usd", "eur", "c", "с", "⃀", "\u20C0")
        for (i in cleanTexts.indices) {
            val item = cleanTexts[i]
            val cleaned = item.replace(" ", "").replace("\u00A0", "").replace(",", ".")
            val num = cleaned.toDoubleOrNull()
            if (num != null && num > 0.0 && num < 10_000_000.0) {
                val isYear = num in 2020.0..2030.0
                if (isYear || isBlacklistedAmount(num)) continue
                if (BankPatternConfig.isLikelyPhoneNumberPrefix(num, fullCombined) ||
                    BankPatternConfig.isLikelyPhoneNumberPrefix(num, item)) {
                    continue
                }

                var hasNearbyCurrency = false
                for (offset in 1..3) {
                    if (i + offset < cleanTexts.size) {
                        val ahead = cleanTexts[i + offset].lowercase(Locale.ROOT)
                        if (currencyMarkers.any { ahead.contains(it) } || ahead == "c" || ahead == "с" || ahead.startsWith("c.") || ahead.startsWith("с.")) {
                            hasNearbyCurrency = true
                            break
                        }
                    }
                }

                var hasNearbyMarker = false
                for (offset in 1..3) {
                    if (i - offset >= 0) {
                        val behind = cleanTexts[i - offset].lowercase(Locale.ROOT)
                        if (behind.contains("сумма") || behind.contains("итог") || behind.contains("к оплате") ||
                            behind.contains("перевод") || behind.contains("списано") || behind.contains("оплачено") ||
                            behind.contains("отправлено") || behind.contains("переведено")
                        ) {
                            hasNearbyMarker = true
                            break
                        }
                    }
                }

                if (hasNearbyCurrency || (!isYear && hasNearbyMarker)) {
                    candidates.add(num)
                }
            }
        }

        if (candidates.isEmpty()) return null

        // Filter out nominal amounts like 0.0 or 1.0 (often commission/fee) if a main transfer amount exists
        val significant = candidates.filter { it > 1.0 }
        return if (significant.isNotEmpty()) {
            significant.maxOrNull()
        } else {
            candidates.firstOrNull()
        }
    }

    private fun extractBalanceAfter(fullCombined: String): Double? {
        val balancePattern = Pattern.compile(
            "(?:баланс|остаток|доступно)[:\\s]*(\\d{1,3}(?:[\\s\\u00A0]\\d{3})*(?:[.,]\\d{1,2})?)\\s*(?:сом|c|kgs)?",
            Pattern.CASE_INSENSITIVE
        )
        val balanceMatcher = balancePattern.matcher(fullCombined)
        if (balanceMatcher.find()) {
            val rawBal = balanceMatcher.group(1)
                ?.replace(" ", "")
                ?.replace("\u00A0", "")
                ?.replace(",", ".")
            return rawBal?.toDoubleOrNull()
        }
        return null
    }

    private fun extractTransferInputAmount(texts: List<String>, fullCombined: String): Double? {
        // 1. Look for number directly adjacent to "сумма" or "сумма перевода"
        for (i in texts.indices) {
            val text = texts[i].lowercase(Locale.ROOT).trim()
            if (text == "сумма" || text.startsWith("сумма:") || text == "сумма перевода" || text == "введите сумму") {
                // Check next 2 nodes or previous node
                for (offset in listOf(1, 2, -1)) {
                    val targetIdx = i + offset
                    if (targetIdx in texts.indices) {
                        val candidate = texts[targetIdx].trim()
                        val amt = parseStrictTransferAmount(candidate)
                        if (amt != null && amt > 0.0) {
                            return amt
                        }
                    }
                }
            }
        }

        // 2. Proximity to currency on the transfer screen (excluding the user's card balance)
        for (i in texts.indices) {
            val text = texts[i].trim()
            val lower = text.lowercase(Locale.ROOT)
            // Exclude balance node (often preceded by "доступно", "баланс", "карт-счет")
            val prev = if (i > 0) texts[i - 1].lowercase(Locale.ROOT) else ""
            if (prev.contains("баланс") || prev.contains("доступно") || prev.contains("остаток") || prev.contains("комиссия")) {
                continue
            }
            if (lower.contains("сом") || lower.endsWith(" с") || lower.endsWith(" c") || lower.contains("⃀") || lower.contains("\u20C0")) {
                val amt = parseStrictTransferAmount(text)
                if (amt != null && amt > 0.0) {
                    return amt
                }
            }
        }

        return null
    }

    private fun parseStrictTransferAmount(str: String): Double? {
        val trimmed = str.trim()
        val lower = trimmed.lowercase(Locale.ROOT)
        // Отсекаем рекламные карточки и акции
        if (lower.contains("манипол") || lower.contains("приз") || lower.contains("акци") ||
            lower.contains("эксклюзив") || lower.contains("рассрочк") || lower.contains("ставка") ||
            lower.contains("депозит") || lower.contains("металл") || lower.contains("покупайте") ||
            lower.contains("подробнее")) {
            return null
        }
        // Reject phone numbers, card numbers, years
        if (trimmed.length > 8 && (trimmed.startsWith("+996") || trimmed.startsWith("0") || trimmed.startsWith("996"))) return null
        if (trimmed.matches(Regex("""^\d{4}$"""))) return null // Reject pure 4-digit card ending
        val cleaned = trimmed.replace(" ", "")
            .replace("\u00A0", "")
            .replace("\u20C0", "")
            .replace("⃀", "")
            .replace("сом", "", ignoreCase = true)
            .replace("kgs", "", ignoreCase = true)
            .replace("с", "", ignoreCase = true)
            .replace("c", "", ignoreCase = true)
            .replace(",", ".")
            .trim()
        val m = Pattern.compile("""(\d+(?:\.\d{1,2})?)""").matcher(cleaned)
        if (m.find()) {
            val v = m.group(1)?.toDoubleOrNull()
            if (v != null && v > 0.0 && v < 10_000_000.0) {
                if (v in 2024.0..2030.0 && !str.contains("сом", ignoreCase = true) && !str.contains("⃀")) return null
                if (v == 2845.0 || v == 6672.0 || v == 9303.0 || v == 480.0 || v == 350000.0 || v == 50000000.0) return null
                return v
            }
        }
        return null
    }

    private fun extractCardBalanceFromTexts(texts: List<String>, fullCombined: String): Double? {
        fun normalizeSpaces(s: String): String {
            return s.replace(Regex("""[\u00A0\u202F\u2007\u2008\u2009\u200A\uFEFF]"""), " ").trim()
        }

        fun parseCardBalanceCandidate(str: String): Double? {
            val trimmed = normalizeSpaces(str)
            val lower = trimmed.lowercase(Locale.ROOT)

            // 1. Blacklist check: brand names, promos, expenses, metals, loans
            if (lower.contains("visa") || lower.contains("mastercard") ||
                lower.contains("элкарт") || lower.contains("elkart") ||
                lower.contains("манипол") || lower.contains("приз") ||
                lower.contains("акци") || lower.contains("рассрочк") ||
                lower.contains("ставка") || lower.contains("депозит") ||
                lower.contains("кредит") || lower.contains("металл") ||
                lower.contains("за ") || lower.contains("ноябр") ||
                lower.contains("декабр") || lower.contains("январ") ||
                lower.contains("расход") || lower.contains("трат") ||
                lower.contains("подробнее") || lower.contains("покупайте")
            ) {
                return null
            }

            // 2. Reject ANY card/account number:
            // e.g. "*2845", "*6672", "103***6672", "••9303", "••6672", "2845", "6672", "9303"
            if (trimmed.startsWith("*") || trimmed.startsWith("••") || trimmed.startsWith("..") ||
                trimmed.startsWith("**") || trimmed.contains("***") || trimmed.matches(Regex("""^\d{4}$"""))
            ) {
                return null
            }

            // 3. Monetary balance with decimal part (e.g. "5 190,66 C", "3 477,66 ⃀", "3 477,66", "1,20 C", "1,20", "5190.66")
            val pDec = Pattern.compile(
                """([0-9]{1,3}(?:[ ][0-9]{3})*|[0-9]+)(?:[,\.]([0-9]{1,2}))\s*(?:[⃀\u20C0CcСс]|сом|kgs)?""",
                Pattern.CASE_INSENSITIVE
            )
            val mDec = pDec.matcher(trimmed)
            if (mDec.find()) {
                val intPart = mDec.group(1)?.replace(" ", "") ?: ""
                val decPart = mDec.group(2) ?: "00"
                val v = "$intPart.$decPart".toDoubleOrNull()
                if (v != null && v >= 0.0 && v < 100_000_000.0) {
                    if (v == 2845.0 || v == 6672.0 || v == 9303.0 || v == 480.0 || v == 350000.0 || v == 50000000.0) {
                        return null
                    }
                    return v
                }
            }

            // 4. Whole monetary amount with mandatory currency symbol (e.g. "5 190 C", "3 477 ⃀", "12 500 сом")
            val pWhole = Pattern.compile(
                """([0-9]{1,3}(?:[ ][0-9]{3})*|[0-9]+)\s*(?:[⃀\u20C0CcСс]|сом|kgs)""",
                Pattern.CASE_INSENSITIVE
            )
            val mWhole = pWhole.matcher(trimmed)
            if (mWhole.find()) {
                val intPart = mWhole.group(1)?.replace(" ", "") ?: ""
                val v = intPart.toDoubleOrNull()
                if (v != null && v >= 0.0 && v < 100_000_000.0) {
                    if (v == 2845.0 || v == 6672.0 || v == 9303.0 || v == 480.0 || v == 350000.0 || v == 50000000.0) {
                        return null
                    }
                    return v
                }
            }

            return null
        }

        // =========================================================================
        // ПРИОРИТЕТ 1: MBank Карт-виджет: Основная карта (••9303 ⭐, ••6672)
        // В MBank основная карта всегда помечена звездой ⭐ и находится вверху списка!
        // =========================================================================
        val maskedCardPattern = Pattern.compile("""[•\*\.\u2022]{2,4}\s*(\d{4})""")
        val detectedCards = mutableListOf<Pair<String, Double>>()

        for (i in texts.indices) {
            val text = texts[i].trim()
            if (maskedCardPattern.matcher(text).find() || text.startsWith("••") || text.startsWith("..") || text.startsWith("**")) {
                for (offset in listOf(1, 2, -1, 3, 4, -2)) {
                    val targetIdx = i + offset
                    if (targetIdx in texts.indices) {
                        val candidateText = texts[targetIdx].trim()

                        // A. Одиночный узел
                        var amt = parseCardBalanceCandidate(candidateText)

                        // B. Объединение 2 соседних узлов (на случай если дробная часть/валюта в отдельном Text)
                        if (amt == null && targetIdx + 1 in texts.indices) {
                            val nextText = texts[targetIdx + 1].trim()
                            amt = parseCardBalanceCandidate("$candidateText $nextText")
                        }

                        // C. Объединение 3 соседних узлов ("5 190," + "66" + "C")
                        if (amt == null && targetIdx + 2 in texts.indices) {
                            val next1 = texts[targetIdx + 1].trim()
                            val next2 = texts[targetIdx + 2].trim()
                            amt = parseCardBalanceCandidate("$candidateText $next1 $next2")
                        }

                        if (amt != null && amt >= 0.0) {
                            detectedCards.add(Pair(text, amt))
                            break
                        }
                    }
                }
            }
        }

        // Если нашли карты: ищем в первую очередь основную карту (••9303 с золотой звездой),
        // либо берем баланс первой карты в списке (основной счет в MBank)
        if (detectedCards.isNotEmpty()) {
            val primaryCard = detectedCards.find { it.first.contains("9303") } ?: detectedCards.first()
            Log.i(TAG, "Authoritative primary card balance selected [${primaryCard.first}]: ${primaryCard.second}")
            return primaryCard.second
        }

        // =========================================================================
        // ПРИОРИТЕТ 2: Сканирование всех узлов с валютой ⃀ (\u20C0), сом или с
        // Отсекаем блоки трат ("За Ноябрь", "Маниполия", "Кэшбэк", "350 000 призов")
        // =========================================================================
        val currencyBalances = mutableListOf<Double>()
        for (i in texts.indices) {
            val text = texts[i].trim()
            val prev = if (i > 0) texts[i - 1].lowercase(Locale.ROOT) else ""
            if (prev.contains("за ") || prev.contains("ноябр") || prev.contains("декабр") || prev.contains("январ") ||
                prev.contains("расход") || prev.contains("трат") || prev.contains("манипол") || prev.contains("приз")) {
                continue
            }
            val amt = parseCardBalanceCandidate(text)
            if (amt != null && amt >= 0.0) {
                currencyBalances.add(amt)
            }
        }

        if (currencyBalances.isNotEmpty()) {
            // Если на экране несколько сумм, берем первую (основную карту)
            val selected = currencyBalances.first()
            Log.i(TAG, "Scraped card balance via currency token: $selected")
            return selected
        }

        // =========================================================================
<<<<<<< HEAD
        // ПРИОРИТЕТ 3: Соседние узлы со словами-якорями (карт-счет, доступно, эсеп, калдык)
        // =========================================================================
        val anchorWords = listOf("карт-счет", "карт счет", "доступно", "эсеп", "калдык", "мой банк", "дебетовая")
        for (i in texts.indices) {
            val lower = texts[i].lowercase(Locale.ROOT).trim()
            if (anchorWords.any { lower == it || lower.startsWith("$it:") || lower.contains(it) }) {
                for (offset in listOf(1, 2, 3, -1)) {
                    val targetIdx = i + offset
                    if (targetIdx in texts.indices) {
                        val candidateText = texts[targetIdx].trim()
                        val amt = parseCardBalanceCandidate(candidateText)
                        if (amt != null && amt >= 0.0) {
                            Log.i(TAG, "Scraped card balance via anchor [$lower]: $amt (from '$candidateText')")
=======
        // ПРИОРИТЕТ 3: Соседние узлы со словами-якорями (баланс, карт-счет, доступно, эсеп, калдык)
        // ВАЖНО: якоря баланса должны быть СТРОГИМИ, а не общими ("мой банк", "mbank" - это название шапки, а не баланс!)
        // =========================================================================
        val anchorWords = listOf(
            "баланс", "доступно", "остаток", "карт-счет", "карт счет",
            "эсеп", "калдык"
        )
        for (i in texts.indices) {
            val lower = texts[i].lowercase(Locale.ROOT).trim()
            if (anchorWords.any { lower == it || lower.startsWith(it + ":") || lower.startsWith(it + " ") }) {
                for (offset in 1..3) {
                    if (i + offset < texts.size) {
                        val candidateText = texts[i + offset].trim()
                        val candLower = candidateText.lowercase(Locale.ROOT)
                        // Игнорируем рекламу, промо-акции, лотереи (Маниполия, призы, кэшбэк, за месяц)
                        if (candLower.contains("за ") || candLower.contains("расход") ||
                            candLower.contains("приз") || candLower.contains("манипол") ||
                            candLower.contains("акци") || candLower.contains("бонус") ||
                            candLower.contains("эксклюзив")) {
                            continue
                        }
                        val amt = parseAmount(candidateText)
                        if (amt != null && amt > 10.0 && amt != 350000.0 && amt != 50000000.0) {
                            Log.i(TAG, "Scraped card balance via anchor [" + lower + "]: " + amt + " (from '" + candidateText + "')")
>>>>>>> 058a5cc7c8b2da8faa87ce75c83dd4b559c907a6
                            return amt
                        }
                    }
                }
            }
        }
<<<<<<< HEAD
=======
        // =========================================================================
        // ПРИОРИТЕТ 4: Сканирование всех узлов с валютой ⃀ (\u20C0), сом или с
        // Отсекаем блоки трат ("За Ноябрь", "Маниполия", "Кэшбэк")
        // =========================================================================
        for (i in texts.indices) {
            val text = texts[i].trim()
            // Check if text has currency symbol (⃀, \u20C0, сом, с, c)
            val hasCurrency = text.contains("\u20C0") || text.contains("⃀") || text.contains("сом", ignoreCase = true) || text.endsWith(" с", ignoreCase = true) || text.endsWith(" c", ignoreCase = true)
            if (hasCurrency) {
                // If previous node was a spending tracker ("За Ноябрь", "За месяц", "Расходы", "Маниполия"), skip it!
                val prev = if (i > 0) texts[i - 1].lowercase(Locale.ROOT) else ""
                if (prev.contains("за ") || prev.contains("ноябр") || prev.contains("декабр") || prev.contains("расход") || prev.contains("трат") || prev.contains("манипол")) {
                    continue
                }
                val amt = parseAmount(text)
                if (amt != null && amt > 10.0 && amt != 480.0 && amt != 350000.0 && amt != 50000000.0) {
                    Log.i(TAG, "Scraped card balance via currency token: $amt (from '$text')")
                    return amt
                }
            }
        }
>>>>>>> 058a5cc7c8b2da8faa87ce75c83dd4b559c907a6

        return null
    }

    private fun cleanUpOldSignatures(now: Long) {
        val iterator = recentSignatures.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (now - entry.value > DEDUPLICATION_WINDOW_MS) {
                iterator.remove()
            }
        }
    }

    private fun savePendingScreenTransaction(
        title: String,
        body: String,
        rawText: String,
        amount: Double,
        isIncome: Boolean,
        categoryId: String,
        balanceAfter: Double?
    ) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val existingJson = prefs.getString("flutter.$PREFS_KEY_PENDING_SCREEN_TXS", null)
                ?: prefs.getString(PREFS_KEY_PENDING_SCREEN_TXS, null)
                ?: "[]"

            val jsonArray = JSONArray(existingJson)

            // Deduplication: Don't add duplicate pending transaction with same amount within 5 minutes
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.optJSONObject(i)
                if (obj != null) {
                    val prevAmount = obj.optDouble("amount", 0.0)
                    val prevTime = obj.optLong("timestamp", 0)
                    if (Math.abs(prevAmount - amount) < 0.01 && Math.abs(System.currentTimeMillis() - prevTime) < 300_000L) {
                        return // Already recorded in pending within 5 minutes!
                    }
                }
            }

            val newObj = JSONObject().apply {
                put("title", title)
                put("body", body)
                put("rawText", rawText)
                put("amount", amount)
                put("isIncome", isIncome)
                put("categoryId", categoryId)
                put("source", "accessibility_screen")
                put("timestamp", System.currentTimeMillis())
                if (balanceAfter != null) {
                    put("balanceAfter", balanceAfter)
                }
            }
            jsonArray.put(newObj)

            while (jsonArray.length() > 30) {
                jsonArray.remove(0)
            }

            prefs.edit()
                .putString("flutter.$PREFS_KEY_PENDING_SCREEN_TXS", jsonArray.toString())
                .putString(PREFS_KEY_PENDING_SCREEN_TXS, jsonArray.toString())
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving pending screen transaction: ${e.message}", e)
        }
    }

    // =========================================================================
    // FEATURE 5: FLOATING CAPYBARA CHAT HEAD & QUICK ENTRY OVERLAY SHEET
    // =========================================================================

        private var bubbleStatusText: TextView? = null
    private var bubbleSubtitleText: TextView? = null
    private var bubbleContainer: FrameLayout? = null

    private fun updateBubbleStatus(status: String, subtitle: String? = null, isAlert: Boolean = false) {
        mainHandler.post {
            bubbleStatusText?.let { tv ->
                tv.text = status
                if (isAlert) {
                    tv.setTextColor(Color.parseColor("#FF453A")) // Red warning
                } else {
                    tv.setTextColor(Color.parseColor("#FF9F0A")) // Amber gold
                }
            }
            bubbleSubtitleText?.let { sub ->
                if (subtitle != null) {
                    sub.text = subtitle
                    sub.visibility = View.VISIBLE
                    if (isAlert) {
                        sub.setTextColor(Color.parseColor("#FF6961"))
                    } else {
                        sub.setTextColor(Color.parseColor("#8E8E93"))
                    }
                } else {
                    sub.text = "Следит"
                    sub.visibility = View.VISIBLE
                    sub.setTextColor(Color.parseColor("#8E8E93"))
                }
            }
            bubbleContainer?.let { container ->
                val bg = GradientDrawable().apply {
                    cornerRadius = dpToPx(24).toFloat()
                    setColor(Color.parseColor("#F51C1A17"))
                    val strokeColor = if (isAlert) Color.parseColor("#FF453A") else Color.parseColor("#FF9F0A")
                    setStroke(dpToPx(2.2f), strokeColor)
                }
                container.background = bg
            }
        }
    }

    private fun showFloatingBubble() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isEnabled = if (prefs.contains("flutter.arc_floating_capy_enabled")) {
            prefs.getBoolean("flutter.arc_floating_capy_enabled", false)
        } else if (prefs.contains("arc_floating_capy_enabled")) {
            prefs.getBoolean("arc_floating_capy_enabled", false)
        } else {
            false // Disabled by default per user request to keep banking UI clean
        }
        if (!isEnabled) {
            if (floatingBubbleView != null) {
                mainHandler.post { hideFloatingBubble() }
            }
            return
        }

        if (floatingBubbleView != null) return

        try {
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val bubbleWidth = dpToPx(74)
            val bubbleHeight = dpToPx(62)

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                bubbleWidth,
                bubbleHeight,
                layoutType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = resources.displayMetrics.widthPixels - bubbleWidth - dpToPx(14)
                y = dpToPx(220)
            }
            bubbleParams = params

            val bubble = FrameLayout(this).apply {
                val bg = GradientDrawable().apply {
                    cornerRadius = dpToPx(22).toFloat()
                    setColor(Color.parseColor("#F51C1A17")) // Obsidian Amber Glass
                    setStroke(dpToPx(2.2f), Color.parseColor("#FF9F0A")) // Capybara Amber Glow
                }
                background = bg
                elevation = dpToPx(14).toFloat()
                setPadding(dpToPx(4), dpToPx(4), dpToPx(4), dpToPx(4))
            }
            bubbleContainer = bubble

            val capyContent = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
            }

            val capyIcon = TextView(this).apply {
                text = "Капибара"
                setTextColor(Color.parseColor("#FF9F0A"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }
            val capyBadge = TextView(this).apply {
                text = "Следит"
                setTextColor(Color.parseColor("#8E8E93"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 8.5f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }
            bubbleStatusText = capyIcon
            bubbleSubtitleText = capyBadge

            capyContent.addView(capyIcon)
            capyContent.addView(capyBadge)

            bubble.addView(
                capyContent,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                ).apply {
                    gravity = Gravity.CENTER
                }
            )

            var initialX = 0
            var initialY = 0
            var initialTouchX = 0f
            var initialTouchY = 0f
            var isClick = true

            bubble.setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = bubbleParams?.x ?: 0
                        initialY = bubbleParams?.y ?: 0
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        isClick = true
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - initialTouchX).toInt()
                        val dy = (event.rawY - initialTouchY).toInt()
                        if (Math.abs(dx) > 12 || Math.abs(dy) > 12) {
                            isClick = false
                        }
                        bubbleParams?.x = initialX + dx
                        bubbleParams?.y = initialY + dy
                        try {
                            windowManager.updateViewLayout(bubble, bubbleParams)
                        } catch (_: Exception) {}
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (isClick) {
                            openQuickEntrySheet()
                        }
                        true
                    }
                    else -> false
                }
            }

            try {
                windowManager.addView(bubble, params)
                floatingBubbleView = bubble
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add bubble with layoutType $layoutType: ${e.message}")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        params.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                        windowManager.addView(bubble, params)
                        floatingBubbleView = bubble
                    } catch (e2: Exception) {
                        Log.e(TAG, "Fallback to TYPE_APPLICATION_OVERLAY also failed: ${e2.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error showing floating bubble: ${e.message}")
        }
    }

    private fun hideFloatingBubble() {
        floatingBubbleView?.let {
            try {
                val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                windowManager.removeView(it)
            } catch (_: Exception) {}
            floatingBubbleView = null
            bubbleContainer = null
            bubbleStatusText = null
            bubbleSubtitleText = null
        }
    }

    private fun openQuickEntrySheet() {
        if (quickEntrySheetView != null) return
        try {
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

            val rootLayout = FrameLayout(this).apply {
                setBackgroundColor(Color.parseColor("#80000000"))
                setOnClickListener {
                    dismissQuickEntrySheet()
                }
            }

            val sheet = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                val bg = GradientDrawable().apply {
                    setColor(Color.parseColor("#1C1C1E"))
                    cornerRadius = dpToPx(20).toFloat()
                    setStroke(dpToPx(1.5f), Color.parseColor("#00C7BE"))
                }
                background = bg
                setPadding(dpToPx(20), dpToPx(18), dpToPx(20), dpToPx(18))
                elevation = dpToPx(16).toFloat()
                isClickable = true
            }

            val sheetParams = FrameLayout.LayoutParams(
                dpToPx(320),
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
            }
            rootLayout.addView(sheet, sheetParams)

            // Header row
            val headerRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }
            val titleText = TextView(this).apply {
                text = "БЫСТРАЯ ЗАПИСЬ РАСХОДА"
                setTextColor(Color.parseColor("#00C7BE"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                typeface = Typeface.DEFAULT_BOLD
                letterSpacing = 0.05f
            }
            headerRow.addView(titleText, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f))

            val closeBtn = TextView(this).apply {
                text = "Закрыть"
                setTextColor(Color.parseColor("#8E8E93"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(4))
                setOnClickListener { dismissQuickEntrySheet() }
            }
            headerRow.addView(closeBtn)
            sheet.addView(headerRow)

            // Amount EditText
            val amountInput = EditText(this).apply {
                hint = "Сумма в сомах (например, 250)"
                setHintTextColor(Color.parseColor("#636366"))
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                typeface = Typeface.DEFAULT_BOLD
                inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL
                val inputBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#2C2C2E"))
                    cornerRadius = dpToPx(12).toFloat()
                    setStroke(dpToPx(1f), Color.parseColor("#3A3A3C"))
                }
                background = inputBg
                setPadding(dpToPx(14), dpToPx(12), dpToPx(14), dpToPx(12))
            }
            sheet.addView(amountInput, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(12)
                bottomMargin = dpToPx(10)
            })

            // Quick Amount Chips
            val chipsScroll = HorizontalScrollView(this).apply {
                isHorizontalScrollBarEnabled = false
            }
            val chipsRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
            }
            val quickAmounts = listOf(50, 100, 200, 500, 1000)
            for (amt in quickAmounts) {
                val chip = Button(this).apply {
                    text = "+$amt"
                    setTextColor(Color.parseColor("#00C7BE"))
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                    typeface = Typeface.DEFAULT_BOLD
                    val chipBg = GradientDrawable().apply {
                        setColor(Color.parseColor("#142426"))
                        cornerRadius = dpToPx(8).toFloat()
                        setStroke(dpToPx(1f), Color.parseColor("#00C7BE"))
                    }
                    background = chipBg
                    setOnClickListener {
                        val currentVal = amountInput.text.toString().toDoubleOrNull() ?: 0.0
                        amountInput.setText(String.format(Locale.US, "%.0f", currentVal + amt))
                        amountInput.setSelection(amountInput.text.length)
                    }
                }
                chipsRow.addView(chip, LinearLayout.LayoutParams(dpToPx(60), dpToPx(34)).apply {
                    marginEnd = dpToPx(6)
                })
            }
            chipsScroll.addView(chipsRow)
            sheet.addView(chipsScroll)

            // Category Chips Row
            var selectedCategory = "cat_restaurants"
            val catRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                weightSum = 4.0f
                setPadding(0, dpToPx(10), 0, dpToPx(14))
            }
            val categories = listOf(
                Pair("Кафе", "cat_restaurants"),
                Pair("Продукты", "cat_groceries"),
                Pair("Такси", "cat_transport"),
                Pair("Шоппинг", "cat_shopping")
            )
            val catButtons = mutableListOf<Button>()
            for ((catName, catId) in categories) {
                val catBtn = Button(this).apply {
                    text = catName
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
                    typeface = Typeface.DEFAULT_BOLD
                    val isSelected = catId == selectedCategory
                    setTextColor(if (isSelected) Color.WHITE else Color.parseColor("#8E8E93"))
                    val btnBg = GradientDrawable().apply {
                        setColor(if (isSelected) Color.parseColor("#00C7BE") else Color.parseColor("#2C2C2E"))
                        cornerRadius = dpToPx(8).toFloat()
                    }
                    background = btnBg
                    setOnClickListener {
                        selectedCategory = catId
                        for (b in catButtons) {
                            val active = (b.tag == selectedCategory)
                            b.setTextColor(if (active) Color.WHITE else Color.parseColor("#8E8E93"))
                            (b.background as? GradientDrawable)?.setColor(
                                if (active) Color.parseColor("#00C7BE") else Color.parseColor("#2C2C2E")
                            )
                        }
                    }
                    tag = catId
                }
                catButtons.add(catBtn)
                catRow.addView(catBtn, LinearLayout.LayoutParams(0, dpToPx(36), 1.0f).apply {
                    marginEnd = dpToPx(4)
                })
            }
            sheet.addView(catRow)

            // Save Button
            val saveBtn = Button(this).apply {
                text = "Сохранить расход"
                setTextColor(Color.parseColor("#161412"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
                typeface = Typeface.DEFAULT_BOLD
                val btnBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#00C7BE"))
                    cornerRadius = dpToPx(12).toFloat()
                }
                background = btnBg
                setOnClickListener {
                    val enteredAmount = amountInput.text.toString().toDoubleOrNull()
                    if (enteredAmount != null && enteredAmount > 0) {
                        val catLabel = when (selectedCategory) {
                            "cat_restaurants" -> "Кафе"
                            "cat_groceries" -> "Продукты"
                            "cat_transport" -> "Такси"
                            else -> "Шоппинг"
                        }
                        val title = "Расход: $catLabel"
                        val body = "−${enteredAmount.toInt()} сом • Записано через шторку"
                        savePendingScreenTransaction(
                            title = title,
                            body = body,
                            rawText = "$title $body",
                            amount = enteredAmount,
                            isIncome = false,
                            categoryId = selectedCategory,
                            balanceAfter = null
                        )
                        val broadcastIntent = Intent(ACTION_SCREEN_TX_CAPTURED).apply {
                            putExtra("title", title)
                            putExtra("body", body)
                            putExtra("rawText", "$title $body")
                            putExtra("amount", enteredAmount)
                            putExtra("isIncome", false)
                            putExtra("categoryId", selectedCategory)
                            putExtra("source", "accessibility_screen")
                            putExtra("timestamp", System.currentTimeMillis())
                            setPackage(packageName)
                        }
                        sendBroadcast(broadcastIntent)
                        Toast.makeText(applicationContext, "ARC Finance: расход сохранен!", Toast.LENGTH_SHORT).show()
                        dismissQuickEntrySheet()
                    } else {
                        Toast.makeText(applicationContext, "Введите корректную сумму", Toast.LENGTH_SHORT).show()
                    }
                }
            }
            sheet.addView(saveBtn, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dpToPx(44)))

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                layoutType,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            try {
                windowManager.addView(rootLayout, params)
                quickEntrySheetView = rootLayout
            } catch (e: Exception) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        params.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                        windowManager.addView(rootLayout, params)
                        quickEntrySheetView = rootLayout
                    } catch (e2: Exception) {
                        Log.e(TAG, "Fallback to TYPE_APPLICATION_OVERLAY failed for sheet: ${e2.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error opening quick entry sheet: ${e.message}")
        }
    }

    private fun dismissQuickEntrySheet() {
        quickEntrySheetView?.let {
            try {
                val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                windowManager.removeView(it)
            } catch (_: Exception) {}
            quickEntrySheetView = null
        }
    }

    // =========================================================================
    // FEATURE 6: HARDCORE SOCIAL MEDIA BLOCKER DICTATOR (OVERSPENDING ENFORCER)
    // =========================================================================

    private fun isBlockedSocialApp(pkg: String): Boolean {
        val lower = pkg.lowercase(Locale.ROOT)
        return lower.contains("instagram") ||
                lower.contains("musically") ||
                lower.contains("tiktok") ||
                lower.contains("trill") ||
                lower.contains("aweme") ||
                lower.contains("youtube") ||
                lower.contains("twitter") ||
                lower.contains("x.android") ||
                lower.contains("threads") ||
                lower.contains("facebook") ||
                lower.contains("snapchat") ||
                lower.contains("reddit") ||
                lower.contains("pinterest")
    }

    private fun isSocialBlockerActive(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isEnabled = if (prefs.contains("flutter.arc_social_blocker_enabled")) {
            prefs.getBoolean("flutter.arc_social_blocker_enabled", false)
        } else {
            prefs.getBoolean("arc_social_blocker_enabled", false)
        }
        if (!isEnabled) return false

        // Check if user snoozed the blocker
        val snoozeUntil = prefs.getLong("arc_social_blocker_snooze_until", 0L)
        if (System.currentTimeMillis() < snoozeUntil) {
            return false // Currently snoozed!
        }

        val mode = prefs.getString("flutter.arc_social_blocker_mode", null)
            ?: prefs.getString("arc_social_blocker_mode", "always") ?: "always"
        if (mode == "always") return true

        return if (prefs.contains("flutter.arc_social_blocker_active")) {
            prefs.getBoolean("flutter.arc_social_blocker_active", false)
        } else {
            prefs.getBoolean("arc_social_blocker_active", false)
        }
    }

    private fun getReadableSocialAppName(pkg: String): String {
        return when {
            pkg.contains("instagram") -> "Instagram"
            pkg.contains("tiktok") || pkg.contains("musically") || pkg.contains("trill") || pkg.contains("aweme") -> "TikTok"
            pkg.contains("youtube") -> "YouTube"
            pkg.contains("twitter") || pkg.contains("x.android") -> "X (Twitter)"
            pkg.contains("threads") -> "Threads"
            pkg.contains("facebook") -> "Facebook"
            pkg.contains("snapchat") -> "Snapchat"
            pkg.contains("reddit") -> "Reddit"
            else -> "Соцсеть"
        }
    }

    private fun handleSocialAppBlocked(pkg: String) {
        if (socialBlockerOverlayView != null) return // Already showing blocker overlay
        val now = System.currentTimeMillis()
        if (now - lastSocialBlockTimestamp < 1500) return
        lastSocialBlockTimestamp = now

        // Present the Capybara fullscreen blocker overlay window directly over the social media app
        mainHandler.post {
            showSocialBlockerOverlay(pkg)
        }
    }

    private fun showSocialBlockerOverlay(pkg: String) {
        if (socialBlockerOverlayView != null) return

        try {
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val dreamGoal = prefs.getString("flutter.arc_blocker_dream_goal", null)
                ?: prefs.getString("arc_blocker_dream_goal", null)
                ?: "Свою цель"
            val appName = getReadableSocialAppName(pkg)

            val rootLayout = FrameLayout(this).apply {
                setBackgroundColor(Color.parseColor("#B30A0A0C")) // Semi-transparent scrim
                setOnClickListener {
                    dismissSocialBlockerOverlay() // Clicking outside dismisses overlay without closing app
                }
            }

            val card = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                val bg = GradientDrawable().apply {
                    setColor(Color.parseColor("#151518"))
                    cornerRadius = dpToPx(24).toFloat()
                    setStroke(dpToPx(1.8f), Color.parseColor("#FF9F0A")) // Amber border
                }
                background = bg
                setPadding(dpToPx(22), dpToPx(22), dpToPx(22), dpToPx(22))
                elevation = dpToPx(24).toFloat()
                isClickable = true
            }

            val cardParams = FrameLayout.LayoutParams(
                dpToPx(330),
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
            }
            rootLayout.addView(card, cardParams)

            // 0. Capybara Avatar
            val avatarContainer = FrameLayout(this).apply {
                val aBg = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#26FF9F0A"))
                    setStroke(dpToPx(2f), Color.parseColor("#FF9F0A"))
                }
                background = aBg
                elevation = dpToPx(8).toFloat()
            }
            val capyIcon = TextView(this).apply {
                text = "ARC"
                setTextColor(Color.parseColor("#FF9F0A"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }
            avatarContainer.addView(capyIcon, FrameLayout.LayoutParams(
                dpToPx(56),
                dpToPx(56)
            ).apply {
                gravity = Gravity.CENTER
            })
            card.addView(avatarContainer, LinearLayout.LayoutParams(
                dpToPx(56),
                dpToPx(56)
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dpToPx(10)
            })

            // 1. Badge
            val badgeLayout = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                val badgeBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#26FF9F0A"))
                    cornerRadius = dpToPx(8).toFloat()
                    setStroke(dpToPx(1f), Color.parseColor("#FF9F0A"))
                }
                background = badgeBg
                setPadding(dpToPx(12), dpToPx(4), dpToPx(12), dpToPx(4))
            }
            val badgeText = TextView(this).apply {
                text = "КАПИБАРА • КОНТРОЛЬ ВРЕМЕНИ"
                setTextColor(Color.parseColor("#FF9F0A"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
                typeface = Typeface.DEFAULT_BOLD
                letterSpacing = 0.05f
            }
            badgeLayout.addView(badgeText)
            card.addView(badgeLayout, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dpToPx(10)
            })

            // 2. Title
            val titleText = TextView(this).apply {
                text = "Открыт $appName\nВремя для отдыха или цели?"
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }
            card.addView(titleText, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(10)
            })

            // 3. Body
            val bodyText = TextView(this).apply {
                text = "Капибара напоминает: время бесценно, а впереди цель «$dreamGoal». Выберите, продолжить просмотр или закрыть приложение."
                setTextColor(Color.parseColor("#D1D1D6"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
                gravity = Gravity.CENTER
                setLineSpacing(dpToPx(2).toFloat(), 1.15f)
            }
            card.addView(bodyText, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(14)
            })

            // 4. Primary Action: ПРОДОЛЖИТЬ ПРОСМОТР (15 МИН)
            val snoozeBtn = Button(this).apply {
                text = "ПРОДОЛЖИТЬ ПРОСМОТР (15 МИН)"
                setTextColor(Color.BLACK)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                typeface = Typeface.DEFAULT_BOLD
                val btnBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#30D158")) // Green
                    cornerRadius = dpToPx(12).toFloat()
                }
                background = btnBg
                setOnClickListener {
                    dismissSocialBlockerOverlay()
                    val snoozeMs = System.currentTimeMillis() + (15 * 60 * 1000L)
                    prefs.edit().putLong("arc_social_blocker_snooze_until", snoozeMs).apply()
                    try {
                        Toast.makeText(applicationContext, "Приятного просмотра! Пауза на 15 минут", Toast.LENGTH_SHORT).show()
                    } catch (_: Exception) {}
                }
            }
            card.addView(snoozeBtn, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(44)
            ).apply {
                bottomMargin = dpToPx(8)
            })

            // 5. Action: ОТКЛЮЧИТЬ БЛОКИРАТОР
            val disableBtn = Button(this).apply {
                text = "ОТКЛЮЧИТЬ БЛОКИРАТОР"
                setTextColor(Color.parseColor("#FF9F0A"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
                typeface = Typeface.DEFAULT_BOLD
                val dBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#242426"))
                    cornerRadius = dpToPx(10).toFloat()
                    setStroke(dpToPx(1f), Color.parseColor("#FF9F0A"))
                }
                background = dBg
                setOnClickListener {
                    dismissSocialBlockerOverlay()
                    prefs.edit()
                        .putBoolean("arc_social_blocker_enabled", false)
                        .putBoolean("flutter.arc_social_blocker_enabled", false)
                        .putBoolean("arc_social_blocker_active", false)
                        .putBoolean("flutter.arc_social_blocker_active", false)
                        .apply()
                    try {
                        Toast.makeText(applicationContext, "Блокиратор приложений отключен", Toast.LENGTH_SHORT).show()
                    } catch (_: Exception) {}
                }
            }
            card.addView(disableBtn, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(40)
            ).apply {
                bottomMargin = dpToPx(8)
            })

            // 6. Action: ЗАКРЫТЬ $appName
            val closeBtn = Button(this).apply {
                text = "ЗАКРЫТЬ $appName"
                setTextColor(Color.parseColor("#8E8E93"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                typeface = Typeface.DEFAULT_BOLD
                val cBg = GradientDrawable().apply {
                    setColor(Color.TRANSPARENT)
                }
                background = cBg
                setOnClickListener {
                    dismissSocialBlockerOverlay()
                    performGlobalAction(GLOBAL_ACTION_HOME)
                }
            }
            card.addView(closeBtn, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(36)
            ))

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                layoutType,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            try {
                windowManager.addView(rootLayout, params)
                socialBlockerOverlayView = rootLayout
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add social blocker with layoutType $layoutType: ${e.message}")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        params.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                        windowManager.addView(rootLayout, params)
                        socialBlockerOverlayView = rootLayout
                    } catch (e2: Exception) {
                        Log.e(TAG, "Fallback to TYPE_APPLICATION_OVERLAY also failed: ${e2.message}")
                    }
                }
            }

            // If overlay view could not be attached (strict OEM restriction on Vivo/Xiaomi),
            // show a polite Toast instead of abruptly kicking the user to home screen!
            if (socialBlockerOverlayView == null) {
                Log.w(TAG, "Overlay blocked by OS. Showing warning toast without closing app.")
                try {
                    Toast.makeText(applicationContext, "Капибара: открыт $appName. Помни о цели на $dreamGoal!", Toast.LENGTH_SHORT).show()
                } catch (_: Exception) {}
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error showing social blocker overlay: ${e.message}")
            try {
                Toast.makeText(applicationContext, "Капибара: не забывай о финансовых целях!", Toast.LENGTH_SHORT).show()
            } catch (_: Exception) {}
        }
    }

    private fun postSocialBlockerWarningNotification(appName: String, pullups: Int) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            val channelId = "arc_finance_blocker_channel"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "ARC Блокиратор соцсетей",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Предупреждения блокировки приложений"
                    enableVibration(true)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val arcIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("quick_action", "workout_penalty")
            }
            val pendingIntent = PendingIntent.getActivity(
                this,
                9941,
                arcIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(this, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("⚠️ $appName заблокирован Капибарой!")
                .setContentText("Строгий режим Winter Arc: сделайте $pullups подтягиваний в ARC Finance!")
                .setStyle(NotificationCompat.BigTextStyle().bigText("Строгий режим Winter Arc: доступ к $appName закрыт! Сделайте $pullups подтягиваний или 50 отжиманий для разблокировки."))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            notificationManager.notify(7771, builder.build())
        } catch (e: Exception) {
            Log.e(TAG, "Error posting social blocker notification: ${e.message}")
        }
    }

    private fun dismissSocialBlockerOverlay() {
        socialBlockerOverlayView?.let {
            try {
                val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                windowManager.removeView(it)
            } catch (_: Exception) {}
            socialBlockerOverlayView = null
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "MBankScreenAccessibilityService interrupted")
        dismissCapybaraOverlay()
        hideFloatingBubble()
        dismissQuickEntrySheet()
        dismissSocialBlockerOverlay()
    }

    override fun onDestroy() {
        Log.i(TAG, "MBankScreenAccessibilityService destroyed")
        pendingTransferConfirmRunnable?.let { mainHandler.removeCallbacks(it) }
        activePendingTransfer = null
        isServiceRunning = false
        instance = null
        dismissCapybaraOverlay()
        hideFloatingBubble()
        dismissQuickEntrySheet()
        dismissSocialBlockerOverlay()
        super.onDestroy()
    }
}
