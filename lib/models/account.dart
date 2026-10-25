import 'package:flutter/material.dart';

enum AccountType {
  card,
  cash,
  savings,
  investment;

  String get label {
    switch (this) {
      case AccountType.card:
        return 'Банковская карта';
      case AccountType.cash:
        return 'Наличные';
      case AccountType.savings:
        return 'Накопительный счет';
      case AccountType.investment:
        return 'Инвестиции';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.card:
        return Icons.credit_card_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.savings:
        return Icons.savings_rounded;
      case AccountType.investment:
        return Icons.trending_up_rounded;
    }
  }
}

class Account {
  final String id;
  final String name;
  final String bankName;
  final String? lastDigits;
  double balance;
  final String currency;
  final AccountType type;
  final Color color;

  Account({
    required this.id,
    required this.name,
    this.bankName = 'Банк',
    this.lastDigits,
    required this.balance,
    this.currency = 'сом',
    required this.type,
    required this.color,
  });

  Account copyWith({
    String? id,
    String? name,
    String? bankName,
    String? lastDigits,
    double? balance,
    String? currency,
    AccountType? type,
    Color? color,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      lastDigits: lastDigits ?? this.lastDigits,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      color: color ?? this.color,
    );
  }
}
