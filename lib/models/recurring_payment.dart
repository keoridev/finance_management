import 'package:flutter/material.dart';

enum RecurringFrequency {
  daily('Ежедневно'),
  weekly('Еженедельно'),
  monthly('Ежемесячно'),
  yearly('Ежегодно');

  final String label;
  const RecurringFrequency(this.label);

  DateTime computeNextDate(DateTime fromDate) {
    switch (this) {
      case RecurringFrequency.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return fromDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
      case RecurringFrequency.yearly:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
    }
  }
}

class RecurringPayment {
  final String id;
  final String title;
  final double amount;
  final RecurringFrequency frequency;
  final String categoryId;
  final String accountId;
  DateTime nextDueDate;
  bool isActive;
  final String? note;
  final IconData? customIcon;

  RecurringPayment({
    required this.id,
    required this.title,
    required this.amount,
    required this.frequency,
    required this.categoryId,
    required this.accountId,
    required this.nextDueDate,
    this.isActive = true,
    this.note,
    this.customIcon,
  });

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return target.difference(today).inDays;
  }

  bool get isDueSoon => daysUntilDue <= 3 && daysUntilDue >= 0;
  bool get isOverdue => daysUntilDue < 0;

  RecurringPayment copyWith({
    String? id,
    String? title,
    double? amount,
    RecurringFrequency? frequency,
    String? categoryId,
    String? accountId,
    DateTime? nextDueDate,
    bool? isActive,
    String? note,
    IconData? customIcon,
  }) {
    return RecurringPayment(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
      customIcon: customIcon ?? this.customIcon,
    );
  }
}
