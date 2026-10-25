import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/recurring_payments_screen.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_container.dart';

class DashboardSubscriptionsCard extends StatelessWidget {
  final FinanceController controller;

  const DashboardSubscriptionsCard({
    super.key,
    required this.controller,
  });

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    final diff = due.difference(today).inDays;

    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Завтра';
    if (diff > 1 && diff <= 7) return 'Через $diff дн.';
    return AppDateFormatter.formatShortDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final recurring = controller.recurringPayments;
    final active = recurring.where((r) => r.isActive).toList();
    final monthlyTotal = controller.totalMonthlyRecurring;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(22),
      surfaceColor: const Color(0xFF161514).withValues(alpha: 0.88),
      borderColor: AppColors.capybaraAmber.withValues(alpha: 0.24),
      borderWidth: 1.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.capybaraAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.autorenew_rounded,
                      size: 16,
                      color: AppColors.capybaraAmber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Подписки и платежи',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => RecurringPaymentsScreen(controller: controller),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Все (${active.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.capybaraAmber,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.capybaraAmber,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total monthly summary pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'В месяц на подписки:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${CurrencyFormatter.format(monthlyTotal)}/мес',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subscriptions list
          if (active.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.subscriptions_outlined,
                    size: 28,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Нет активных регулярных платежей',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => RecurringPaymentsScreen(controller: controller),
                        ),
                      );
                    },
                    child: const Text(
                      '+ Добавить подписку',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.capybaraAmber,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...active.take(3).map((item) {
              final cat = controller.getCategoryById(item.categoryId);
              final catIcon = item.customIcon ?? cat?.icon ?? Icons.subscriptions_rounded;
              final catColor = cat?.color ?? AppColors.capybaraAmber;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Category / Sub icon
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(catIcon, size: 17, color: catColor),
                      ),
                      const SizedBox(width: 10),

                      // Title & Next date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.frequency.label} • ${_formatDueDate(item.nextDueDate)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Amount & 1-tap Pay Action
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(item.amount),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              controller.payRecurringNow(item.id);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: const Color(0xFF1E1A16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: AppColors.income, width: 1),
                                  ),
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Подписка «${item.title}» оплачена: ${CurrencyFormatter.format(item.amount)}',
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.income.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.income.withValues(alpha: 0.35),
                                  width: 0.6,
                                ),
                              ),
                              child: const Text(
                                'Оплатить',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.income,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
