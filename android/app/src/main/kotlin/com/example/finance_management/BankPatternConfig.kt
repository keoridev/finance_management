package com.example.finance_management

import java.util.regex.Pattern

/**
 * Configurable rules, whitelists, markers, and patterns for Kyrgyz & CIS banking apps.
 * Designed according to technical specification section 3.
 */
object BankPatternConfig {

    // 15-minute sliding TTL window for deduplication
    const val DEFAULT_TTL_MS: Long = 15 * 60 * 1000L // 15 minutes

    // Whitelist of banking & mobile wallet packages
    val WHITELIST_PACKAGES = setOf(
        "com.maanavan.mb_kyrgyzstan", // Official MBank Google Play ID
        "kg.mbank.app",
        "com.cbk.mbank",
        "com.cbk.android",
        "kg.cbk.mbank",
        "kg.cbk.android",
        "com.mbank",
        "com.doscredo.simbank",
        "kg.optima.app",
        "kg.optima24.android",
        "kg.bakai.bank",
        "kg.bakai.retail",
        "kg.demirbank.retail",
        "kg.finca.online",
        "kg.rsk.bank",
        "kg.rsk.mobile",
        "kg.eldik.bank",
        "kg.kompanion.online",
        "kg.kicb.mobile",
        "kg.keremetbank.retail",
        "kg.halykbank.retail",
        "kg.dengi",
        "kg.nurtelecom.myo",
        "kg.megacom.megapay",
        "kg.beeline.balance",
        "com.google.android.apps.walletnfcrel",
        "com.google.android.apps.messaging",
        "com.samsung.android.messaging",
        "com.android.mms"
    )

    // Markers indicating successful transaction or receipt screen on UI
    val SUCCESS_SCREEN_MARKERS = listOf(
        "перевод выполнен",
        "перевод отправлен",
        "деньги отправлены",
        "переведено",
        "перевод успешен",
        "перевод совершен",
        "платеж выполнен",
        "платеж проведен",
        "платеж совершен",
        "оплата проведена",
        "оплата прошла",
        "операция выполнена",
        "транзакция завершена",
        "успешно",
        "исполнен",
        "принят в обработку",
        "в обработке",
        "чек",
        "квитанция",
        "детали перевода",
        "детали платежа",
        "детали операции",
        "поделиться чеком",
        "поделиться квитанцией",
        "сохранить чек",
        "готово",
        "отправлено"
    )

    // Buttons triggering transfer execution in banking apps
    val TRANSFER_ACTION_BUTTONS = listOf(
        "перевести",
        "оплатить",
        "подтвердить",
        "отправить",
        "продолжить"
    )

    // Screens indicating transfer failure or error
    val ERROR_SCREEN_MARKERS = listOf(
        "ошибка",
        "недостаточно средств",
        "отклонен",
        "отклонена",
        "сбой",
        "повторите попытку",
        "не удалось",
        "платеж отклонен",
        "перевод отклонен",
        "лимит исчерпан"
    )

    // Regex specified in Section 3.1 for amount parsing with thousand separators and decimals
    val AMOUNT_REGEX: Pattern = Pattern.compile(
        "(?i)(?:сумма|перевод|списано|итог|оплата|покупка)?[:\\s]*([0-9]{1,3}(?:[ \\xA0,][0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)\\s*(сом|kgs|руб|rub|\\$|usd|eur|тенге|kzt|с\\.|c\\.|[cс]\\b)?",
        Pattern.CASE_INSENSITIVE
    )

    // Push expense trigger markers (Section 3.2)
    val PUSH_EXPENSE_MARKERS = listOf(
        "списание",
        "списано",
        "перевод",
        "покупка",
        "оплата",
        "снятие",
        "зачислено",
        "пополнение",
        "перевели",
        "platezh",
        "spisano",
        "oplata",
        "pokupka",
        "perevod",
        "popolnenie",
        "paid",
        "spent",
        "purchase"
    )

    // Push stop-words for promotional or non-transaction alerts (Section 3.2)
    val PUSH_STOP_WORDS = listOf(
        "акция",
        "скидк",
        "реклам",
        "вход в аккаунт",
        "код подтверждения",
        "пароль",
        "условия изменены",
        "новые возможности",
        "оцените приложение",
        "доступно обновление",
        "welcome"
    )

    // Recipient extraction regex patterns
    val RECIPIENT_PATTERNS = listOf(
        Pattern.compile("получател[ьяе][:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("кому[:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("клиент[:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("перевод клиенту[:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("отправител[ьяе][:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("от кого[:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("фио[:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(?:на карту|карта)[:\\s]*([*0-9\\s]{4,19})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("(?:на номер|номер|тел)[:\\s]*(\\+?[0-9\\s-]{9,18})", Pattern.CASE_INSENSITIVE)
    )

    fun isWhitelistedPackage(pkg: String): Boolean {
        val lower = pkg.lowercase()
        return WHITELIST_PACKAGES.any { lower.contains(it) } ||
                lower.contains("maanavan") ||
                lower.contains("mb_kyrgyzstan") ||
                lower.contains("mbank") ||
                lower.contains("cbk") ||
                lower.contains("doscredo") ||
                lower.contains("simbank") ||
                lower.contains("optima") ||
                lower.contains("bakai") ||
                lower.contains("demir") ||
                lower.contains("finca") ||
                lower.contains("rsk") ||
                lower.contains("eldik") ||
                lower.contains("kompanion") ||
                lower.contains("kicb") ||
                lower.contains("keremet") ||
                lower.contains("megapay") ||
                lower.contains("balance") ||
                lower.contains("dengi") ||
                lower.contains("walletnfcrel")
    }

    fun isSuccessScreen(combinedText: String): Boolean {
        val lower = combinedText.lowercase()
        return SUCCESS_SCREEN_MARKERS.any { lower.contains(it) }
    }

    fun isErrorScreen(combinedText: String): Boolean {
        val lower = combinedText.lowercase()
        return ERROR_SCREEN_MARKERS.any { lower.contains(it) }
    }

    fun isStopWordPush(text: String): Boolean {
        val lower = text.lowercase()
        // If message clearly contains a transaction amount or action verb, do NOT drop it!
        val hasTransaction = lower.contains("оплат") ||
                lower.contains("списан") ||
                lower.contains("покупк") ||
                lower.contains("перевод") ||
                lower.contains("пополнен") ||
                lower.contains("зачислен") ||
                lower.contains("поступил") ||
                lower.contains("зарплат")
        if (hasTransaction) return false

        return PUSH_STOP_WORDS.any { lower.contains(it) }
    }

    /**
     * Accurately determines if a notification or screen represents INCOME (+).
     */
    fun isIncomeTransaction(text: String): Boolean {
        val lower = text.lowercase()

        // Explicit positive markers
        if (lower.contains("зарплат") ||
            lower.contains("з/п") ||
            lower.contains("salary") ||
            lower.contains("аванс") ||
            lower.contains("avans") ||
            lower.contains("пополнен") ||
            lower.contains("зачислен") ||
            lower.contains("начислен") ||
            lower.contains("вам перевели") ||
            lower.contains("вам перевел") ||
            lower.contains("перевели вам") ||
            lower.contains("перевод от") ||
            lower.contains("поступил") ||
            lower.contains("поступлен") ||
            lower.contains("поступили средства") ||
            lower.contains("входящий перевод") ||
            lower.contains("входящ") ||
            lower.contains("возврат") ||
            lower.contains("vozvrat") ||
            lower.contains("кэшбэк начислен") ||
            lower.contains("начислен кэшбэк") ||
            lower.contains("келип түштү") ||
            lower.contains("толукталды") ||
            lower.contains("которулган") ||
            lower.contains("popolnen") ||
            lower.contains("zachislen")
        ) {
            return true
        }

        // Check for explicit positive sign before currency or digits e.g. "+500 сом", "+ 1250 KGS"
        val plusMatcher = Pattern.compile("(?:^|[\\s:(])\\+\\s*[0-9]+(?:[.,][0-9]{1,2})?\\s*(?:сом|kgs|c|с|kzt|rub|usd)", Pattern.CASE_INSENSITIVE).matcher(text)
        if (plusMatcher.find()) {
            return true
        }

        return false
    }

    /**
     * Extracts the real transaction amount from banking push or text,
     * carefully skipping card numbers (*1234), shortcodes (1444), and balance numbers.
     */
    fun extractTransactionAmount(text: String): Pair<Double, String>? {
        if (text.isBlank()) return null

        // Priority 1: Amount directly preceded by an action verb (e.g. "Оплата: 450 сом", "Списание 350 KGS", "Зачислено 5000 сом")
        val actionPattern = Pattern.compile(
            "(?i)(?:оплата|покупка|списание|перевод|пополнение|зачисление|снятие|platezh|oplata|popolnen|spisanie|pokupka|төлөм|которулган|сумма|итог)[:\\s–—\\-]+([0-9]{1,3}(?:[ \\xA0][0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)\\s*(сом|kgs|руб|rub|\\$|usd|eur|тенге|kzt|с\\.|c\\.|[cс]\\b)?",
            Pattern.CASE_INSENSITIVE
        )
        val actionMatcher = actionPattern.matcher(text)
        if (actionMatcher.find()) {
            val rawNum = actionMatcher.group(1)?.replace(" ", "")?.replace("\u00A0", "")?.replace(",", ".")
            val amt = rawNum?.toDoubleOrNull()
            if (amt != null && amt > 0.0 && amt < 50_000_000.0) {
                val rawCurr = actionMatcher.group(2) ?: "KGS"
                return Pair(amt, normalizeCurrency(rawCurr))
            }
        }

        // Priority 2: Amount with explicit sign (e.g. "+ 1 250.00 KGS", "−350 сом", "-500 c")
        val signedPattern = Pattern.compile(
            "(?:[+\\-–—])\\s*([0-9]{1,3}(?:[ \\xA0][0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)\\s*(сом|kgs|руб|rub|\\$|usd|eur|тенге|kzt|с\\.|c\\.|[cс]\\b)",
            Pattern.CASE_INSENSITIVE
        )
        val signedMatcher = signedPattern.matcher(text)
        if (signedMatcher.find()) {
            val rawNum = signedMatcher.group(1)?.replace(" ", "")?.replace("\u00A0", "")?.replace(",", ".")
            val amt = rawNum?.toDoubleOrNull()
            if (amt != null && amt > 0.0 && amt < 50_000_000.0) {
                val rawCurr = signedMatcher.group(2) ?: "KGS"
                return Pair(amt, normalizeCurrency(rawCurr))
            }
        }

        // Priority 3: Amount with MANDATORY currency indicator (e.g. "450 сом", "1 200 KGS"),
        // excluding card numbers (*1234) and balance amounts ("доступно 5000", "баланс 5000")
        val currencyPattern = Pattern.compile(
            "\\b([0-9]{1,3}(?:[ \\xA0][0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)\\s*(сом|kgs|руб|rub|\\$|usd|eur|тенге|kzt|с\\.|c\\.|[cс]\\b)",
            Pattern.CASE_INSENSITIVE
        )
        val curMatcher = currencyPattern.matcher(text)
        while (curMatcher.find()) {
            val startIdx = curMatcher.start()
            val prefix = if (startIdx > 20) text.substring(startIdx - 20, startIdx).lowercase() else text.substring(0, startIdx).lowercase()

            // Skip balance amounts
            if (prefix.contains("баланс") || prefix.contains("доступно") || prefix.contains("остаток") || prefix.contains("калдык")) {
                continue
            }

            val rawNum = curMatcher.group(1)?.replace(" ", "")?.replace("\u00A0", "")?.replace(",", ".")
            val amt = rawNum?.toDoubleOrNull() ?: continue
            val rawCurr = curMatcher.group(2) ?: "KGS"
            if (amt > 0.0 && amt < 50_000_000.0) {
                return Pair(amt, normalizeCurrency(rawCurr))
            }
        }

        return null
    }

    fun normalizeCurrency(raw: String): String {
        val u = raw.uppercase()
        return when {
            u.contains("СОМ") || u.contains("KGS") || u.contains("SOM") ||
                    u == "C" || u == "С" || u.startsWith("C.") || u.startsWith("С.") -> "KGS"
            u.contains("РУБ") || u.contains("RUB") -> "RUB"
            u.contains("USD") || u.contains("$") -> "USD"
            u.contains("EUR") -> "EUR"
            u.contains("KZT") || u.contains("ТЕНГЕ") -> "KZT"
            else -> "KGS"
        }
    }
}
