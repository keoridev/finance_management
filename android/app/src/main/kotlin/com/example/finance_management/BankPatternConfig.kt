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
        "кэшбэк",
        "реклам",
        "вход в аккаунт",
        "код подтверждения",
        "пароль",
        "условия изменены",
        "новые возможности",
        "оцените приложение",
        "доступно обновление",
        "безопасность",
        "welcome"
    )

    // Recipient extraction regex patterns
    val RECIPIENT_PATTERNS = listOf(
        Pattern.compile("получател[ьяе][:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("кому[:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("клиент[:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
        Pattern.compile("перевод клиенту[:\\s]+([\\p{L}\\s.]{3,40})", Pattern.CASE_INSENSITIVE),
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
        return PUSH_STOP_WORDS.any { lower.contains(it) }
    }
}
