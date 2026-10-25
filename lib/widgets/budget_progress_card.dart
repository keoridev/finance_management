import 'package:flutter/material.dart';
import '../models/category_budget.dart';
import '../models/transaction_category.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_container.dart';

class BudgetProgressCard extends StatelessWidget {
  final CategoryBudget budget;
  final TransactionCategory category;
  final double spent;

  const BudgetProgressCard({
    super.key,
    required this.budget,
    required this.category,
    required this.spent,
  });

  String _getHumorAlert(String categoryId) {
    if (categoryId == 'cat_restaurants') {
      return '«Ормон, хорош заказывать фастфуд, до зарплаты еще далеко!»';
    } else if (categoryId == 'cat_entertainment') {
      return '«Ормон, тусовки подождут — лимит уже трещит по швам!»';
    } else if (categoryId == 'cat_transport') {
      return '«Ормон, пересаживайся на велики или пешком, лимит на такси сгорел!»';
    } else if (categoryId == 'cat_shopping') {
      return '«Ормон, тормози с покупками, кошелек уже на пределе!»';
    } else {
      return '«Ормон, лимит превышен! Притормози с тратами до конца месяца!»';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = budget.monthlyLimit > 0 ? (spent / budget.monthlyLimit) : 0.0;
    final progress = ratio.clamp(0.0, 1.0);
    final isExceeded = spent > budget.monthlyLimit;
    final isWarning = !isExceeded && ratio >= 0.70;
    final remaining = budget.monthlyLimit - spent;

    final progressColor = isExceeded
        ? AppColors.expense
        : (isWarning ? AppColors.iosOrange : category.color);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
      borderColor: isExceeded
          ? AppColors.expense.withValues(alpha: 0.5)
          : (isWarning ? AppColors.iosOrange.withValues(alpha: 0.35) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, color: category.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(spent),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isExceeded ? AppColors.expense : Colors.white,
                    ),
                  ),
                  Text(
                    'из ${CurrencyFormatter.format(budget.monthlyLimit)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar with Apple Rounded Ends
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(ratio * 100).toInt()}% израсходовано',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isWarning ? FontWeight.w600 : FontWeight.w400,
                  color: isExceeded
                      ? AppColors.expense
                      : (isWarning ? AppColors.iosOrange : Colors.white.withValues(alpha: 0.45)),
                ),
              ),
              Text(
                isExceeded
                    ? 'Превышен на ${CurrencyFormatter.format(remaining.abs())}'
                    : 'Осталось ${CurrencyFormatter.format(remaining)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isExceeded
                      ? AppColors.expense
                      : (isWarning ? AppColors.iosOrange : AppColors.income),
                ),
              ),
            ],
          ),

          // Humorous Overrun Alert (if exceeded)
          if (isExceeded)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.expense,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getHumorAlert(category.id),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFB3B0),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isWarning)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.iosOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.iosOrange.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.iosOrange,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ормон, потрачено ${(ratio * 100).toInt()}% лимита! До зарплаты держи темп.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.iosOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
