import 'package:flutter/services.dart';

class ParsedClipboardExpense {
  final double amount;
  final String title;
  final String categoryId;
  final String categoryName;
  final String rawText;

  const ParsedClipboardExpense({
    required this.amount,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.rawText,
  });
}

class ClipboardParserService {
  static String? _lastCheckedText;

  static final RegExp _amountRegex = RegExp(
    r'(?:[+\-–—]\s*)?(\d{1,3}(?:[\s\u00A0]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)\s*(?:сом|KGS|kgs|c\.|C\.|som|SOM|[cс]\b)',
    caseSensitive: false,
  );

  /// Analyzes clipboard text. If it resembles a payment or transfer request from a friend or bill,
  /// returns a structured expense object.
  static Future<ParsedClipboardExpense?> checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty || text == _lastCheckedText) {
        return null;
      }

      // Ignore text if it's too long (not a short payment request message)
      if (text.length > 250) {
        return null;
      }

      // Ignore if text is purely our own app text
      if (text.contains('ARC Finance') || text.contains('Баланс:')) {
        return null;
      }

      final parsed = parseText(text);
      if (parsed != null) {
        _lastCheckedText = text;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  static ParsedClipboardExpense? parseText(String text) {
    final lower = text.toLowerCase();

    // Check if message resembles a transfer / expense request or bill
    final isExpenseContext = lower.contains('закинь') ||
        lower.contains('скинь') ||
        lower.contains('переведи') ||
        lower.contains('отправь') ||
        lower.contains('оплати') ||
        lower.contains('с тебя') ||
        lower.contains('за обед') ||
        lower.contains('за такси') ||
        lower.contains('за кофе') ||
        lower.contains('за еду') ||
        lower.contains('долг') ||
        lower.contains('сом') ||
        lower.contains('kgs') ||
        lower.contains('с.');

    if (!isExpenseContext) return null;

    final match = _amountRegex.firstMatch(text);
    if (match == null) return null;

    final rawAmount = match.group(1);
    if (rawAmount == null) return null;

    final cleaned = rawAmount
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '')
        .replaceAll(',', '.');
    final amount = double.tryParse(cleaned);
    if (amount == null || amount <= 0 || amount > 1000000) return null;

    String categoryId = 'cat_other_expense';
    String categoryName = 'Другие расходы';
    String title = 'Расход из буфера';

    if (lower.contains('обед') ||
        lower.contains('ужин') ||
        lower.contains('кафе') ||
        lower.contains('еда') ||
        lower.contains('шаурма') ||
        lower.contains('кофе') ||
        lower.contains('додо') ||
        lower.contains('фаиза') ||
        lower.contains('ланч')) {
      categoryId = 'cat_restaurants';
      categoryName = 'Кафе и еда';
      title = 'Обед / Кафе';
    } else if (lower.contains('такси') ||
        lower.contains('бензин') ||
        lower.contains('дорога') ||
        lower.contains('проезд') ||
        lower.contains('яндекс')) {
      categoryId = 'cat_transport';
      categoryName = 'Транспорт';
      title = 'Такси / Поездка';
    } else if (lower.contains('глобус') ||
        lower.contains('фрунзе') ||
        lower.contains('продукты') ||
        lower.contains('магазин') ||
        lower.contains('маркет') ||
        lower.contains('народный')) {
      categoryId = 'cat_groceries';
      categoryName = 'Продукты';
      title = 'Продукты';
    } else if (lower.contains('вайлдберриз') ||
        lower.contains('wildberries') ||
        lower.contains('ozon') ||
        lower.contains('озон') ||
        lower.contains('покупка')) {
      categoryId = 'cat_shopping';
      categoryName = 'Шоппинг';
      title = 'Покупки';
    }

    return ParsedClipboardExpense(
      amount: amount,
      title: title,
      categoryId: categoryId,
      categoryName: categoryName,
      rawText: text,
    );
  }
}
