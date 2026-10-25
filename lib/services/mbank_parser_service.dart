import '../models/transaction_type.dart';

class ParsedMBankNotification {
  final double amount;
  final TransactionType type;
  final String title;
  final String categoryId;
  final double? balanceAfter;
  final String? cardLastDigits;
  final String rawText;
  final DateTime timestamp;
  final bool isSalary;

  const ParsedMBankNotification({
    required this.amount,
    required this.type,
    required this.title,
    required this.categoryId,
    this.balanceAfter,
    this.cardLastDigits,
    required this.rawText,
    required this.timestamp,
    this.isSalary = false,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'type': type.index,
    'title': title,
    'categoryId': categoryId,
    'balanceAfter': balanceAfter,
    'cardLastDigits': cardLastDigits,
    'rawText': rawText,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isSalary': isSalary,
  };

  factory ParsedMBankNotification.fromJson(Map<String, dynamic> json) {
    return ParsedMBankNotification(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values[(json['type'] as int? ?? 0).clamp(0, TransactionType.values.length - 1)],
      title: json['title'] as String? ?? 'MBank',
      categoryId: json['categoryId'] as String? ?? 'cat_other',
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      cardLastDigits: json['cardLastDigits'] as String?,
      rawText: json['rawText'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      isSalary: json['isSalary'] as bool? ?? false,
    );
  }
}

class MBankParserService {
  // Common Kyrgyz Som indicators (including c, сом, KGS, SOM)
  static final RegExp _amountRegex = RegExp(
    r'(?:[+\-–—]\s*)?(\d{1,3}(?:[\s\u00A0]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)\s*(?:сом|KGS|kgs|c\.|C\.|som|SOM|[cс]\b)',
    caseSensitive: false,
  );

  static final RegExp _balanceRegex = RegExp(
    r'(?:доступно|баланс|остаток|dostupno|balans|ostatok)[:\s]*(\d{1,3}(?:[\s\u00A0]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)\s*(?:сом|KGS|kgs|c\.|C\.|som|SOM|[cс]\b)?',
    caseSensitive: false,
  );

  static final RegExp _cardDigitsRegex = RegExp(r'\*(\d{4})');

  /// Parse any incoming text from MBank Push Notification, SMS, or Clipboard
  static ParsedMBankNotification? parse(String text) {
    if (text.trim().isEmpty) return null;

    final lower = text.toLowerCase();

    // 1. Determine Income vs Expense
    bool isIncome = false;
    bool isSalary = false;

    if (lower.contains('зарплат') ||
        lower.contains('з/п') ||
        lower.contains('salary') ||
        lower.contains('avans') ||
        lower.contains('аванс')) {
      isIncome = true;
      isSalary = true;
    } else if (lower.contains('пополнен') ||
        lower.contains('зачислен') ||
        lower.contains('перевод от') ||
        lower.contains('поступил') ||
        lower.contains('начислен') ||
        lower.contains('popolnen') ||
        lower.contains('zachislen') ||
        lower.contains('perevod ot') ||
        lower.contains('postupil') ||
        lower.contains('vozvrat') ||
        lower.contains('возврат') ||
        text.contains('+')) {
      isIncome = true;
    } else if (lower.contains('списан') ||
        lower.contains('оплат') ||
        lower.contains('покупк') ||
        lower.contains('перевод клиент') ||
        lower.contains('перевод на карту') ||
        lower.contains('сняти') ||
        lower.contains('комисси') ||
        lower.contains('spisanie') ||
        lower.contains('oplata') ||
        lower.contains('pokupka') ||
        text.contains('-')) {
      isIncome = false;
    } else {
      // Default guess based on sign or keywords
      if (text.contains('+')) {
        isIncome = true;
      }
    }

    // 2. Extract Amount
    final amountMatch = _amountRegex.firstMatch(text);
    if (amountMatch == null) return null;

    final rawAmountStr = amountMatch.group(1);
    if (rawAmountStr == null) return null;

    final cleanedAmount = rawAmountStr
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '')
        .replaceAll(',', '.');
    final amount = double.tryParse(cleanedAmount);
    if (amount == null || amount <= 0) return null;

    // 3. Extract Balance After Transaction (if present)
    double? balanceAfter;
    final balanceMatch = _balanceRegex.firstMatch(text);
    if (balanceMatch != null) {
      final rawBalStr = balanceMatch.group(1);
      if (rawBalStr != null) {
        final cleanedBal = rawBalStr
            .replaceAll(' ', '')
            .replaceAll('\u00A0', '')
            .replaceAll(',', '.');
        balanceAfter = double.tryParse(cleanedBal);
      }
    }

    // 4. Extract Card digits
    String? cardDigits;
    final cardMatch = _cardDigitsRegex.firstMatch(text);
    if (cardMatch != null) {
      cardDigits = cardMatch.group(1);
    }

    // 5. Categorize and generate title
    String categoryId = isIncome ? 'cat_other' : 'cat_other';
    String title = isIncome ? 'Пополнение MBank' : 'Расход MBank';

    if (isSalary) {
      categoryId = 'cat_salary';
      title = 'Зарплата MBank';
    } else if (isIncome) {
      if (lower.contains('перевод')) {
        categoryId = 'cat_transfers';
        // Try to extract sender name e.g. "Перевод от Азамат Б."
        final senderMatch = RegExp(r'перевод от\s+([A-Za-zА-Яа-яЁё\s.]+)', caseSensitive: false).firstMatch(text);
        if (senderMatch != null) {
          final name = senderMatch.group(1)?.split(RegExp(r'[,.\d]')).first.trim();
          title = name != null && name.isNotEmpty ? 'Перевод: $name' : 'Входящий перевод';
        } else {
          title = 'Входящий перевод';
        }
      } else {
        categoryId = 'cat_salary';
        title = 'Пополнение счета';
      }
    } else {
      // Extract merchant name from push text (e.g., "Оплата 125 с. Баланс 469 с. Кафе Фаиза" or "Оплата в Sierra Coffee")
      final extractedMerchant = _extractMerchantName(text, rawAmountStr, balanceMatch?.group(1));

      // Expense categorization with extensive Bishkek/Kyrgyzstan merchant dictionary
      if (lower.contains('фаиза') ||
          lower.contains('faiza') ||
          lower.contains('нават') ||
          lower.contains('navat') ||
          lower.contains('бублик') ||
          lower.contains('bublik') ||
          lower.contains('куликов') ||
          lower.contains('kulikov') ||
          lower.contains('додо') ||
          lower.contains('dodo') ||
          lower.contains('kfc') ||
          lower.contains('бургер') ||
          lower.contains('burger') ||
          lower.contains('кофе') ||
          lower.contains('coffee') ||
          lower.contains('чайхана') ||
          lower.contains('столовая') ||
          lower.contains('кафе') ||
          lower.contains('пицца') ||
          lower.contains('pizza') ||
          lower.contains('суши') ||
          lower.contains('sushi') ||
          lower.contains('ресторан')) {
        categoryId = 'cat_restaurants';
        title = extractedMerchant ??
            (lower.contains('фаиза') ? 'Кафе Фаиза' : (lower.contains('нават') ? 'Чайхана Нават' : 'Кафе и еда'));
      } else if (lower.contains('глобус') ||
          lower.contains('globus') ||
          lower.contains('фрунзе') ||
          lower.contains('frunze') ||
          lower.contains('народный') ||
          lower.contains('narodnyi') ||
          lower.contains('азия') ||
          lower.contains('достор') ||
          lower.contains('корзинка') ||
          lower.contains('маркет') ||
          lower.contains('магазин') ||
          lower.contains('продукты') ||
          lower.contains('базар') ||
          lower.contains('market') ||
          lower.contains('supermarket')) {
        categoryId = 'cat_groceries';
        title = extractedMerchant ??
            (lower.contains('глобус') ? 'Гипермаркет Globus' : (lower.contains('фрунзе') ? 'Гипермаркет Фрунзе' : 'Продукты'));
      } else if (lower.contains('яндекс') ||
          lower.contains('yandex') ||
          lower.contains('такси') ||
          lower.contains('taxi') ||
          lower.contains('маршрутка') ||
          lower.contains('тулпар') ||
          lower.contains('tulpar') ||
          lower.contains('газпром') ||
          lower.contains('gazprom') ||
          lower.contains('бишкекпетролеум') ||
          lower.contains('red petroleum') ||
          lower.contains('азс') ||
          lower.contains('бензин')) {
        categoryId = 'cat_transport';
        title = extractedMerchant ??
            (lower.contains('яндекс') ? 'Яндекс Go' : (lower.contains('такси') ? 'Такси' : 'Транспорт и АЗС'));
      } else if (lower.contains('wildberries') ||
          lower.contains('вайлдберриз') ||
          lower.contains('wb') ||
          lower.contains('ozon') ||
          lower.contains('озон') ||
          lower.contains('дордой') ||
          lower.contains('цум') ||
          lower.contains('asia mall') ||
          lower.contains('zara') ||
          lower.contains('бутик') ||
          lower.contains('aliexpress')) {
        categoryId = 'cat_shopping';
        title = extractedMerchant ??
            (lower.contains('wildberries') || lower.contains('вайлдберриз')
                ? 'Wildberries'
                : (lower.contains('ozon') || lower.contains('озон') ? 'Ozon' : 'Покупки и одежда'));
      } else if (lower.contains('неман') ||
          lower.contains('neman') ||
          lower.contains('аптек') ||
          lower.contains('фарм') ||
          lower.contains('бимед') ||
          lower.contains('бонецк') ||
          lower.contains('клиника') ||
          lower.contains('лекарь')) {
        categoryId = 'cat_health';
        title = extractedMerchant ??
            (lower.contains('неман') ? 'Аптека Неман' : 'Аптека и здоровье');
      } else if (lower.contains('коммунал') ||
          lower.contains('северэлектро') ||
          lower.contains('тазалык') ||
          lower.contains('бишкектеплосеть') ||
          lower.contains('акнет') ||
          lower.contains('aknet') ||
          lower.contains('мегаком') ||
          lower.contains('megacom') ||
          lower.contains('о!') ||
          lower.contains('o!') ||
          lower.contains('beeline') ||
          lower.contains('билайн')) {
        categoryId = 'cat_housing';
        title = extractedMerchant ?? 'Жилье и связь';
      } else if (lower.contains('синематика') ||
          lower.contains('cinematica') ||
          lower.contains('broadway') ||
          lower.contains('кино') ||
          lower.contains('steam') ||
          lower.contains('playstation') ||
          lower.contains('netflix') ||
          lower.contains('spotify')) {
        categoryId = 'cat_entertainment';
        title = extractedMerchant ?? 'Развлечения и отдых';
      } else if (lower.contains('перевод')) {
        categoryId = 'cat_other_expense';
        title = extractedMerchant ?? 'Исходящий перевод';
      } else if (extractedMerchant != null) {
        title = extractedMerchant;
      }
    }

    // Preserve direct merchant or recipient name from screen capture if available
    final prefixMatch = RegExp(r'^(?:Оплата|Зачисление|Платеж|Перевод):\s*([^:–—\n]+)', caseSensitive: false).firstMatch(text);
    if (prefixMatch != null) {
      final cleanExtracted = prefixMatch.group(1)?.trim();
      if (cleanExtracted != null && cleanExtracted.isNotEmpty && cleanExtracted.toLowerCase() != 'mbank') {
        title = cleanExtracted;
      }
    }

    return ParsedMBankNotification(
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      title: title,
      categoryId: categoryId,
      balanceAfter: balanceAfter,
      cardLastDigits: cardDigits,
      rawText: text,
      timestamp: DateTime.now(),
      isSalary: isSalary,
    );
  }

  static String? _extractMerchantName(String text, String rawAmountStr, String? rawBalStr) {
    // 1. Direct preposition patterns: "в [Store]", "at [Store]", "v [Store]"
    final atMatch = RegExp(
      r"""(?:в|at|v|u)\s+([A-Za-zА-Яа-яЁё0-9\s"'\-#]{3,35}?)(?:[.,;\n]|баланс|dostupno|остаток|$)""",
      caseSensitive: false,
    ).firstMatch(text);
    if (atMatch != null) {
      final cand = atMatch.group(1)?.trim();
      if (_isValidMerchant(cand)) return _cleanMerchant(cand!);
    }

    // 2. Prefix / Colon patterns: "Оплата: [Store]", "Чек: [Store]", "Точка: [Store]"
    final prefixMatch = RegExp(
      r'^(?:Оплата|Зачисление|Платеж|Перевод|Покупка|Чек|Точка|Терминал|Место|Квитанция):\s*([^:–—\n]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (prefixMatch != null) {
      final cand = prefixMatch.group(1)?.trim();
      if (_isValidMerchant(cand)) return _cleanMerchant(cand!);
    }

    // 3. Sentence segmentation: e.g. "Оплата 125 с. Баланс 469 с. Кафе Фаиза"
    final segments = text.split(RegExp(r'[.,;\n]+'));
    for (final seg in segments) {
      final clean = seg.trim();
      if (clean.length < 3 || clean.length > 40) continue;
      if (clean.contains(rawAmountStr)) continue;
      if (rawBalStr != null && clean.contains(rawBalStr)) continue;

      final lower = clean.toLowerCase();
      if (lower.startsWith('баланс') ||
          lower.startsWith('доступно') ||
          lower.startsWith('остаток') ||
          lower.startsWith('карта') ||
          lower.startsWith('karta') ||
          lower.startsWith('чек №') ||
          lower.startsWith('оплата прошла') ||
          lower.startsWith('успешно') ||
          lower == 'mbank' ||
          lower == 'optima24' ||
          lower == 'google pay' ||
          lower == 'google wallet') {
        continue;
      }

      if (RegExp(r'[A-Za-zА-Яа-яЁё]{3,}').hasMatch(clean)) {
        final stripped = clean
            .replaceFirst(RegExp(r'^(?:оплата покупки|оплата|покупка|списание|platezh|oplata|pokupka)\s+', caseSensitive: false), '')
            .trim();
        if (_isValidMerchant(stripped)) {
          return _cleanMerchant(stripped);
        }
      }
    }

    return null;
  }

  static bool _isValidMerchant(String? candidate) {
    if (candidate == null) return false;
    final c = candidate.trim().toLowerCase();
    if (c.length < 3) return false;
    if (c == 'mbank' || c == 'cbk' || c == 'банк' || c == 'карта' || c == 'google pay' || c == 'google wallet') {
      return false;
    }
    return true;
  }

  static String _cleanMerchant(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'^[^\wА-Яа-яЁё]+|[^\wА-Яа-яЁё]+$'), '').trim();
    cleaned = cleaned.replaceFirst(RegExp(r'\s*\*\d{4}$'), '').trim();
    return cleaned;
  }
}

