import 'package:flutter/material.dart';

enum NotificationType {
  hourlyExpense,
  winterArc,
  dreamSavings,
  capybaraZen,
  systemInfo,
  mbankAutoSync,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  IconData get icon {
    switch (type) {
      case NotificationType.hourlyExpense:
        return Icons.access_time_filled_rounded;
      case NotificationType.winterArc:
        return Icons.local_fire_department_rounded;
      case NotificationType.dreamSavings:
        return Icons.star_rounded;
      case NotificationType.capybaraZen:
        return Icons.spa_rounded;
      case NotificationType.systemInfo:
        return Icons.notifications_active_rounded;
      case NotificationType.mbankAutoSync:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.hourlyExpense:
        return const Color(0xFF0A84FF); // iOS Blue
      case NotificationType.winterArc:
        return const Color(0xFFFF9F0A); // iOS Orange
      case NotificationType.dreamSavings:
        return const Color(0xFF30D158); // iOS Green
      case NotificationType.capybaraZen:
        return const Color(0xFFE09F3E); // Capybara Warm Caramel Amber
      case NotificationType.systemInfo:
        return const Color(0xFFBF5AF2); // iOS Purple
      case NotificationType.mbankAutoSync:
        return const Color(0xFF30D158); // Green
    }
  }
}
