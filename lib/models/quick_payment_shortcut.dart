import 'package:flutter/material.dart';

class QuickPaymentShortcut {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final String accountId;
  final IconData icon;
  final Color color;

  const QuickPaymentShortcut({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.icon,
    required this.color,
  });

  QuickPaymentShortcut copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    String? accountId,
    IconData? icon,
    Color? color,
  }) {
    return QuickPaymentShortcut(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
