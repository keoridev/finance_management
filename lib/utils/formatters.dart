import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const String defaultCurrency = 'сом';

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: defaultCurrency,
    decimalDigits: 0,
  );

  static final NumberFormat _decimalFormatter = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: defaultCurrency,
    decimalDigits: 2,
  );

  static String format(
    double amount, {
    bool showSign = false,
    bool withDecimals = false,
    String? currency,
  }) {
    final NumberFormat formatter;
    if (currency == null || currency == defaultCurrency) {
      formatter = withDecimals ? _decimalFormatter : _formatter;
    } else {
      formatter = withDecimals
          ? NumberFormat.currency(locale: 'ru_RU', symbol: currency, decimalDigits: 2)
          : NumberFormat.currency(locale: 'ru_RU', symbol: currency, decimalDigits: 0);
    }

    final formatted = formatter.format(amount.abs()).trim();

    if (showSign) {
      if (amount > 0) {
        return '+ $formatted';
      } else if (amount < 0) {
        return '- $formatted';
      }
    }
    return formatted;
  }

  /// Compact formatting (e.g., 14.5K сом)
  static String formatCompact(double amount, {String? currency}) {
    final symbol = currency ?? defaultCurrency;
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M $symbol';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K $symbol';
    }
    return format(amount, currency: symbol);
  }
}

class AppDateFormatter {
  AppDateFormatter._();

  static String formatShortDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'Сегодня';
    } else if (difference == 1) {
      return 'Вчера';
    } else if (difference == -1) {
      return 'Завтра';
    }

    return DateFormat('d MMMM', 'ru_RU').format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('d MMMM y', 'ru_RU').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('LLLL y', 'ru_RU').format(date);
  }

  static String formatDaysRemaining(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final days = target.difference(today).inDays;

    if (days < 0) {
      return 'Просрочено на ${days.abs()} дн.';
    } else if (days == 0) {
      return 'Сегодня';
    } else if (days == 1) {
      return 'Завтра';
    } else if (days <= 4) {
      return 'Через $days дня';
    } else {
      return 'Через $days дней';
    }
  }
}
