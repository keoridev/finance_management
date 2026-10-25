import 'package:flutter/material.dart';

class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final IconData icon;
  final Color color;
  final DateTime targetDate;

  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.icon,
    required this.color,
    required this.targetDate,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentAmount >= targetAmount;

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    IconData? icon,
    Color? color,
    DateTime? targetDate,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      targetDate: targetDate ?? this.targetDate,
    );
  }
}
