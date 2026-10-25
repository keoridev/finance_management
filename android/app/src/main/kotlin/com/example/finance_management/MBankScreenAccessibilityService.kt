package com.example.finance_management

import android.accessibilityservice.AccessibilityService
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

        // Shadow balance cache: bankName -> lastBalance
        private val lastScrapedBalances = mutableMapOf<String, Double>()
        private val lastScrapedTimestamps = mutableMapOf<String, Long>()
        private const val BALANCE_SCRAPE_INTERVAL_MS = 180_000L // 3 minutes throttle

        @Volatile
        var isServiceRunning = false
    }

    private var lastProcessTimestamp = 0L
    private val mainHandler = Handler(Looper.getMainLooper())
    private var activeOverlayView: View? = null
    private var floatingBubbleView: View? = null
    private var bubbleParams: WindowManager.LayoutParams? = null
    private var quickEntrySheetView: View? = null
    private var socialBlockerOverlayView: View? = null
    private var lastSocialBlockTimestamp = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
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
            }

            // Target bank apps or marketplaces
            if (!isTargetApp(packageNameStr)) {
                mainHandler.post { hideFloatingBubble() }
                return
            }

            // Show floating Capybara Chat Head when in a banking app
            if (isTargetBankingApp(packageNameStr)) {
                mainHandler.post { showFloatingBubble() }
            } else {
                mainHandler.post { hideFloatingBubble() }
            }

            // Rate-limit processing to avoid excessive CPU usage during UI transitions
            val now = System.currentTimeMillis()
            if (now - lastProcessTimestamp < 250) {
                return
            }
            lastProcessTimestamp = now

            // Extract visible text hierarchy
            val rootNode = rootInActiveWindow ?: event.source ?: return
            val texts = mutableListOf<String>()
            extractVisibleTexts(rootNode, texts, 0, 160)

            if (texts.isEmpty()) return

            val fullCombined = texts.joinToString(" ").lowercase(Locale.ROOT)

            // Check 1: Post-transaction receipt screen
            val isReceipt = isReceiptScreenText(fullCombined)
            if (isReceipt) {
                analyzeReceiptScreen(texts, packageNameStr, fullCombined)
                return
            }

            // Check 2: Pre-transaction confirmation (Capybara-Filter)
            val isPreConfirmation = isPreTransactionScreen(fullCombined)
            if (isPreConfirmation) {
                analyzePreTransactionCheckout(texts, packageNameStr, fullCombined)
                return
            }

            // Check 3: Shadow Balance Scraping (Bank Home / Dashboard)
            if (isTargetBankingApp(packageNameStr) && isDashboardScreen(fullCombined)) {
                analyzeDashboardBalances(texts, packageNameStr, fullCombined)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in onAccessibilityEvent: ${e.message}", e)
        }
    }

    private fun isTargetApp(pkg: String): Boolean {
        return isTargetBankingApp(pkg) || isTargetMarketplaceApp(pkg)
    }

    private fun isTargetBankingApp(pkg: String): Boolean {
        return pkg.contains("mbank") ||
                pkg.contains("cbk") ||
                pkg.contains("optima") ||
                pkg.contains("demir") ||
                pkg.contains("bakai") ||
                pkg.contains("finca") ||
                pkg.contains("keremet") ||
                pkg.contains("companion") ||
                pkg.contains("faktura") ||
                pkg.contains("o.dengi") ||
                pkg.contains("megapay") ||
                pkg.contains("balance.kg")
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
        if (node == null || result.size >= maxNodes || depth > 15) return

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
                try {
                    child.recycle()
                } catch (_: Exception) {}
            }
        }
    }

    // =========================================================================
    // FEATURE 1: POST-TRANSACTION RECEIPT CAPTURE + SMART AUTOCATEGORIZATION
    // =========================================================================

    private fun isReceiptScreenText(fullCombined: String): Boolean {
        return fullCombined.contains("успешно") ||
                fullCombined.contains("перевод выполнен") ||
                fullCombined.contains("платеж выполнен") ||
                fullCombined.contains("платеж проведен") ||
                fullCombined.contains("оплата проведена") ||
                fullCombined.contains("оплата прошла") ||
                fullCombined.contains("чек") ||
                fullCombined.contains("квитанция") ||
                fullCombined.contains("детали платежа") ||
                fullCombined.contains("детали операции") ||
                fullCombined.contains("детали перевода") ||
                fullCombined.contains("зачислено") ||
                fullCombined.contains("списано")
    }

    private fun analyzeReceiptScreen(texts: List<String>, pkg: String, fullCombined: String) {
        val amount = extractAmountFromTexts(texts, fullCombined) ?: return
        val isIncome = fullCombined.contains("зачислен") ||
                fullCombined.contains("пополнен") ||
                fullCombined.contains("вам перевели") ||
                fullCombined.contains("зарплат")

        val merchantInfo = extractMerchantAndCategory(texts, fullCombined, isIncome)
        val title = merchantInfo.first
        val categoryId = merchantInfo.second

        // Remaining balance if visible
        val balanceAfter = extractBalanceAfter(fullCombined)

        // Deduplication
        val cleanAmount = String.format(Locale.US, "%.2f", amount)
        val signature = "${cleanAmount}_${title}_${if (isIncome) "in" else "out"}"
        val currentTime = System.currentTimeMillis()

        cleanUpOldSignatures(currentTime)
        val lastSeen = recentSignatures[signature]
        if (lastSeen != null && (currentTime - lastSeen) < DEDUPLICATION_WINDOW_MS) {
            return
        }
        recentSignatures[signature] = currentTime

        Log.i(TAG, "Receipt captured! Amount: $amount, Title: $title, Category: $categoryId")

        val notificationTitle = if (isIncome) "Зачисление: $title" else "Оплата: $title"
        val notificationBody = "${if (isIncome) "+" else "−"}$cleanAmount сом • Зафиксировано с экрана"
        val rawText = "$notificationTitle: $notificationBody"

        savePendingScreenTransaction(
            title = notificationTitle,
            body = notificationBody,
            rawText = rawText,
            amount = amount,
            isIncome = isIncome,
            categoryId = categoryId,
            balanceAfter = balanceAfter
        )

        val broadcastIntent = Intent(ACTION_SCREEN_TX_CAPTURED).apply {
            putExtra("title", notificationTitle)
            putExtra("body", notificationBody)
            putExtra("rawText", rawText)
            putExtra("amount", amount)
            putExtra("isIncome", isIncome)
            putExtra("categoryId", categoryId)
            putExtra("source", "accessibility_screen")
            putExtra("timestamp", currentTime)
            setPackage(packageName)
        }
        sendBroadcast(broadcastIntent)

        mainHandler.post {
            try {
                Toast.makeText(
                    applicationContext,
                    "ARC Finance: чек на $cleanAmount сом зафиксирован ($title)",
                    Toast.LENGTH_SHORT
                ).show()
            } catch (_: Exception) {}
        }
    }

    // =========================================================================
    // FEATURE 2: PRE-TRANSACTION "CAPYBARA-FILTER" OVERLAY
    // =========================================================================

    private fun isPreTransactionScreen(fullCombined: String): Boolean {
        // Exclude receipt keywords
        if (fullCombined.contains("успешно") ||
            fullCombined.contains("чек") ||
            fullCombined.contains("квитанция") ||
            fullCombined.contains("детали платежа") ||
            fullCombined.contains("выполнено")
        ) {
            return false
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
        val amount = extractAmountFromTexts(texts, fullCombined) ?: return
        if (amount <= 0.0) return

        // Read user config from SharedPreferences
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isFilterEnabled = prefs.getBoolean("flutter.arc_capybara_filter_enabled", true)
        if (!isFilterEnabled) return

        val threshold = prefs.getFloat("flutter.arc_capybara_filter_threshold", 500.0f).toDouble()
        if (amount < threshold) return

        val now = System.currentTimeMillis()
        if (now - lastPreTxAlertTime < 25_000L && Math.abs(amount - lastPreTxAlertAmount) < 1.0) {
            return // Don't spam alert for same checkout within 25 seconds
        }
        lastPreTxAlertTime = now
        lastPreTxAlertAmount = amount

        val dreamGoal = prefs.getString("flutter.arc_active_dream_goal", "MacBook Pro M3") ?: "MacBook Pro M3"
        val remainingGoal = prefs.getFloat("flutter.arc_active_dream_remaining", 120_000.0f).toDouble()

        Log.i(TAG, "Triggering Capybara Pre-Transaction Filter for amount: $amount SOM")

        mainHandler.post {
            showCapybaraOverlay(amount, dreamGoal, remainingGoal)
        }
    }

    private fun showCapybaraOverlay(amount: Double, dreamGoal: String, remainingGoal: Double) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            // Overlay permission not granted; display instant Toast reminder
            Toast.makeText(
                applicationContext,
                "Капибара: Точно переводим ${amount.toInt()} сом? А как же цель на «$dreamGoal»?",
                Toast.LENGTH_LONG
            ).show()
            return
        }

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
                    setStroke(dpToPx(1.5f), Color.parseColor("#00C7BE")) // Cupertino Teal accent border
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

            // 1. Tag Banner
            val tagText = TextView(this).apply {
                text = "WINTER ARC • КАПИБАРА-ФИЛЬТР"
                setTextColor(Color.parseColor("#FF9F0A")) // Amber
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
                typeface = Typeface.DEFAULT_BOLD
                letterSpacing = 0.08f
            }
            cardContainer.addView(tagText)

            // 2. Heading
            val titleText = TextView(this).apply {
                text = "Точно переводим?"
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 19f)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, dpToPx(4), 0, 0)
            }
            cardContainer.addView(titleText)

            // 3. Amount
            val amountText = TextView(this).apply {
                text = "Сумма: ${amount.toInt()} сом"
                setTextColor(Color.parseColor("#00C7BE"))
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
                    dismissCapybaraOverlay()
                }
            }
            val btnProceedParams = LinearLayout.LayoutParams(0, dpToPx(44), 1.0f)
            btnRow.addView(btnProceed, btnProceedParams)

            cardContainer.addView(btnRow)

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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

            windowManager.addView(rootLayout, params)
            activeOverlayView = rootLayout
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

    private fun isDashboardScreen(fullCombined: String): Boolean {
        return (fullCombined.contains("карты") ||
                fullCombined.contains("мои карты") ||
                fullCombined.contains("счета") ||
                fullCombined.contains("депозиты") ||
                fullCombined.contains("главная") ||
                fullCombined.contains("мой банк") ||
                fullCombined.contains("доступно") ||
                fullCombined.contains("баланс")) &&
                !fullCombined.contains("подтвердите") &&
                !fullCombined.contains("квитанция")
    }

    private fun analyzeDashboardBalances(texts: List<String>, pkg: String, fullCombined: String) {
        val bankName = getBankDisplayName(pkg)
        val balance = extractCardBalanceFromTexts(texts, fullCombined) ?: return
        if (balance <= 0.0) return

        val now = System.currentTimeMillis()
        val lastSeenBalance = lastScrapedBalances[bankName]
        val lastSeenTime = lastScrapedTimestamps[bankName] ?: 0L

        // If balance unchanged and scraped recently within 3 min, skip
        if (lastSeenBalance != null && Math.abs(lastSeenBalance - balance) < 0.1 && (now - lastSeenTime) < BALANCE_SCRAPE_INTERVAL_MS) {
            return
        }

        lastScrapedBalances[bankName] = balance
        lastScrapedTimestamps[bankName] = now

        Log.i(TAG, "Shadow balance scraped! Bank: $bankName, Balance: $balance SOM")

        // Save to SharedPreferences
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

        mainHandler.post {
            try {
                Toast.makeText(
                    applicationContext,
                    "ARC Finance: баланс $bankName (${balance.toInt()} сом) синхронизирован",
                    Toast.LENGTH_SHORT
                ).show()
            } catch (_: Exception) {}
        }
    }

    private fun getBankDisplayName(pkg: String): String {
        return when {
            pkg.contains("mbank") || pkg.contains("cbk") -> "MBank"
            pkg.contains("optima") -> "Optima"
            pkg.contains("demir") -> "Demir Bank"
            pkg.contains("bakai") -> "Bakai Bank"
            pkg.contains("finca") -> "Finca Bank"
            pkg.contains("o.dengi") -> "O! Деньги"
            pkg.contains("megapay") -> "MegaPay"
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

        // 1. Check for explicit neighbor nodes: "Получатель", "Кому", "Магазин"
        for (i in texts.indices) {
            val lower = texts[i].lowercase(Locale.ROOT)
            if (lower == "получатель" || lower == "кому" || lower == "магазин" || lower == "торговая точка" || lower == "назначение") {
                if (i + 1 < texts.size && texts[i + 1].length > 1) {
                    val rawName = texts[i + 1]
                    val cat = mapMerchantToCategory(rawName.lowercase(Locale.ROOT))
                    return Pair(rawName, cat)
                }
            }
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

        for ((name, cat) in vendorDict) {
            if (fullCombined.contains(name.lowercase(Locale.ROOT))) {
                return Pair(name, cat)
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
        val amountPattern = Pattern.compile(
            "([+−\\-]?)\\s*(\\d{1,3}(?:[\\s\\u00A0]\\d{3})*(?:[.,]\\d{1,2})?)\\s*(сом|c|с|kgs|KGS)\\b",
            Pattern.CASE_INSENSITIVE
        )

        for (text in texts) {
            val matcher = amountPattern.matcher(text)
            if (matcher.find()) {
                val rawNumber = matcher.group(2)
                    ?.replace(" ", "")
                    ?.replace("\u00A0", "")
                    ?.replace(",", ".") ?: ""
                val parsedVal = rawNumber.toDoubleOrNull()
                if (parsedVal != null && parsedVal > 0) {
                    return parsedVal
                }
            }
        }

        // Check adjacent nodes
        for (i in texts.indices) {
            val item = texts[i]
            val cleaned = item.replace(" ", "").replace("\u00A0", "").replace(",", ".")
            val num = cleaned.toDoubleOrNull()
            if (num != null && num > 0 && num < 10_000_000) {
                val nextItem = if (i + 1 < texts.size) texts[i + 1].lowercase(Locale.ROOT) else ""
                val prevItem = if (i - 1 >= 0) texts[i - 1].lowercase(Locale.ROOT) else ""
                if (nextItem.contains("сом") || nextItem.contains("c") || nextItem.contains("kgs") ||
                    prevItem.contains("сумма") || prevItem.contains("итог") || prevItem.contains("к оплате")
                ) {
                    return num
                }
            }
        }

        return null
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

    private fun extractCardBalanceFromTexts(texts: List<String>, fullCombined: String): Double? {
        val lowerFull = fullCombined.lowercase(Locale.ROOT)
        // Must contain an anchor word indicating a balance or account
        val hasBalanceKeyword = lowerFull.contains("баланс") ||
                lowerFull.contains("доступно") ||
                lowerFull.contains("остаток") ||
                lowerFull.contains("на карте") ||
                lowerFull.contains("на счету") ||
                lowerFull.contains("мои карты") ||
                lowerFull.contains("моя карта")

        if (!hasBalanceKeyword) return null

        val anchorPattern = Pattern.compile(
            "(?:баланс|остаток|доступно|на карте|на счету|средств)[:\\s]*([+−\\-]?\\s*\\d{1,3}(?:[\\s\\u00A0]\\d{3})*(?:[.,]\\d{1,2})?)\\s*(?:сом|c|с|kgs|KGS)?",
            Pattern.CASE_INSENSITIVE
        )

        // 1. Check direct matches in individual node texts
        for (text in texts) {
            val matcher = anchorPattern.matcher(text)
            if (matcher.find()) {
                val numStr = matcher.group(1)
                    ?.replace(" ", "")
                    ?.replace("\u00A0", "")
                    ?.replace(",", ".") ?: ""
                val value = numStr.toDoubleOrNull()
                if (value != null && value > 0 && value < 100_000_000) {
                    return value
                }
            }
        }

        // 2. Check adjacent node sequence: node[i] has anchor, node[i+1] has amount
        for (i in texts.indices) {
            val lower = texts[i].lowercase(Locale.ROOT).trim()
            if (lower == "баланс" || lower == "доступно" || lower == "остаток" ||
                lower.startsWith("баланс:") || lower.startsWith("доступно:")
            ) {
                if (i + 1 < texts.size) {
                    val amountPattern = Pattern.compile("(\\d{1,3}(?:[\\s\\u00A0]\\d{3})*(?:[.,]\\d{1,2})?)")
                    val m = amountPattern.matcher(texts[i + 1])
                    if (m.find()) {
                        val numStr = m.group(1)?.replace(" ", "")?.replace("\u00A0", "")?.replace(",", ".") ?: ""
                        val value = numStr.toDoubleOrNull()
                        if (value != null && value > 0 && value < 100_000_000) {
                            return value
                        }
                    }
                }
            }
        }

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

    private fun showFloatingBubble() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            return
        }
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("flutter.arc_floating_capy_enabled", true)
        if (!isEnabled) return

        if (floatingBubbleView != null) return

        try {
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val bubbleSize = dpToPx(52)

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                bubbleSize,
                bubbleSize,
                layoutType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = resources.displayMetrics.widthPixels - bubbleSize - dpToPx(14)
                y = dpToPx(240)
            }
            bubbleParams = params

            val bubble = FrameLayout(this).apply {
                val bg = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#E61C1C1E")) // Apple Dark Glass
                    setStroke(dpToPx(2f), Color.parseColor("#00C7BE")) // Cupertino Teal Stroke
                }
                background = bg
                elevation = dpToPx(12).toFloat()
            }

            val capyText = TextView(this).apply {
                text = "ARC"
                setTextColor(Color.parseColor("#00C7BE"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }
            bubble.addView(
                capyText,
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

            windowManager.addView(bubble, params)
            floatingBubbleView = bubble
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

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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

            windowManager.addView(rootLayout, params)
            quickEntrySheetView = rootLayout
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
        return pkg.contains("instagram") ||
                pkg.contains("musically") ||
                pkg.contains("tiktok") ||
                pkg.contains("youtube") ||
                pkg.contains("twitter") ||
                pkg.contains("x.android")
    }

    private fun isSocialBlockerActive(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("flutter.arc_social_blocker_enabled", true)
        if (!isEnabled) return false
        return prefs.getBoolean("flutter.arc_social_blocker_active", false)
    }

    private fun getReadableSocialAppName(pkg: String): String {
        return when {
            pkg.contains("instagram") -> "Instagram"
            pkg.contains("tiktok") || pkg.contains("musically") -> "TikTok"
            pkg.contains("youtube") -> "YouTube"
            pkg.contains("twitter") || pkg.contains("x.android") -> "X (Twitter)"
            else -> "Соцсеть"
        }
    }

    private fun handleSocialAppBlocked(pkg: String) {
        val now = System.currentTimeMillis()
        if (now - lastSocialBlockTimestamp < 2500) return
        lastSocialBlockTimestamp = now

        // 1. Kick user immediately to home screen to stop social media usage
        performGlobalAction(GLOBAL_ACTION_HOME)

        // 2. Show Dictator warning overlay
        mainHandler.post {
            showSocialBlockerOverlay(pkg)
        }
    }

    private fun showSocialBlockerOverlay(pkg: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            return
        }
        if (socialBlockerOverlayView != null) return

        try {
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val dreamGoal = prefs.getString("flutter.arc_blocker_dream_goal", null)
                ?: prefs.getString("arc_blocker_dream_goal", null)
                ?: "MacBook Pro M3"
            val pullups = prefs.getInt("flutter.arc_blocker_pullups_required", 20)
            val appName = getReadableSocialAppName(pkg)

            val rootLayout = FrameLayout(this).apply {
                setBackgroundColor(Color.parseColor("#E6000000"))
                setOnClickListener {
                    dismissSocialBlockerOverlay()
                }
            }

            val card = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                val bg = GradientDrawable().apply {
                    setColor(Color.parseColor("#141416"))
                    cornerRadius = dpToPx(24).toFloat()
                    setStroke(dpToPx(2f), Color.parseColor("#FF453A"))
                }
                background = bg
                setPadding(dpToPx(22), dpToPx(24), dpToPx(22), dpToPx(22))
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

            // 1. Dictator Badge
            val badgeLayout = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                val badgeBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#26FF453A"))
                    cornerRadius = dpToPx(8).toFloat()
                    setStroke(dpToPx(1f), Color.parseColor("#FF453A"))
                }
                background = badgeBg
                setPadding(dpToPx(10), dpToPx(4), dpToPx(10), dpToPx(4))
            }
            val badgeText = TextView(this).apply {
                text = "WINTER ARC DICTATOR • ДОСТУП ЗАКРЫТ"
                setTextColor(Color.parseColor("#FF453A"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
                typeface = Typeface.DEFAULT_BOLD
            }
            badgeLayout.addView(badgeText)
            card.addView(badgeLayout, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dpToPx(14)
            })

            // 2. Title
            val titleText = TextView(this).apply {
                text = "ЛИМИТ ПРОБИТ!\n$appName ЗАБЛОКИРОВАН"
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }
            card.addView(titleText, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = dpToPx(10)
            })

            // 3. Toxic Body Message
            val bodyText = TextView(this).apply {
                text = "Лимит трат на сегодня исчерпан! Никаких рилсов, шортсов и тиктоков. Доступ заблокирован, пока не сделаешь $pullups подтягиваний (или 50 отжиманий)."
                setTextColor(Color.parseColor("#C7C7CC"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                gravity = Gravity.CENTER
                setLineSpacing(0f, 1.25f)
            }
            card.addView(bodyText, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = dpToPx(14)
            })

            // 4. Goal Motivation Box
            val goalBox = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                val gbg = GradientDrawable().apply {
                    setColor(Color.parseColor("#1C1C1E"))
                    cornerRadius = dpToPx(12).toFloat()
                    setStroke(dpToPx(1f), Color.parseColor("#2C2C2E"))
                }
                background = gbg
                setPadding(dpToPx(12), dpToPx(10), dpToPx(12), dpToPx(10))
            }
            val goalText = TextView(this).apply {
                text = "Цель накоплений: $dreamGoal\nТелефон заставляет тебя держать дисциплину!"
                setTextColor(Color.parseColor("#FF9F0A"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
                gravity = Gravity.CENTER
            }
            goalBox.addView(goalText)
            card.addView(goalBox, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = dpToPx(20)
            })

            // 5. Workout Unlock Button
            val unlockBtn = Button(this).apply {
                text = "ПОДТВЕРДИТЬ $pullups ПОДТЯГИВАНИЙ В ARC"
                setTextColor(Color.BLACK)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
                typeface = Typeface.DEFAULT_BOLD
                val btnBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#FF453A"))
                    cornerRadius = dpToPx(12).toFloat()
                }
                background = btnBg
                setOnClickListener {
                    dismissSocialBlockerOverlay()
                    try {
                        val arcIntent = Intent(this@MBankScreenAccessibilityService, MainActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            putExtra("quick_action", "workout_penalty")
                        }
                        startActivity(arcIntent)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error launching ARC Finance: ${e.message}")
                    }
                }
            }
            card.addView(unlockBtn, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dpToPx(46)).apply {
                bottomMargin = dpToPx(10)
            })

            // 6. Dismiss Button
            val closeBtn = Button(this).apply {
                text = "Убрать телефон (Держать дисциплину)"
                setTextColor(Color.parseColor("#8E8E93"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
                val cBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#1C1C1E"))
                    cornerRadius = dpToPx(10).toFloat()
                }
                background = cBg
                setOnClickListener {
                    dismissSocialBlockerOverlay()
                }
            }
            card.addView(closeBtn, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dpToPx(38)))

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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

            windowManager.addView(rootLayout, params)
            socialBlockerOverlayView = rootLayout
        } catch (e: Exception) {
            Log.e(TAG, "Error showing social blocker overlay: ${e.message}")
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
        isServiceRunning = false
        dismissCapybaraOverlay()
        hideFloatingBubble()
        dismissQuickEntrySheet()
        dismissSocialBlockerOverlay()
        super.onDestroy()
    }
}
