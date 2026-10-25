import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'animated_currency_text.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double periodIncome;
  final double periodExpense;
  final String periodLabel;
  final String title;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.periodIncome,
    required this.periodExpense,
    required this.periodLabel,
    this.title = 'Общий баланс',
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(22),
      surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  periodLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total Balance with responsive scale & rapid count-up animation
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedCurrencyText(
              amount: totalBalance,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.0,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Subtle hairline divider
          Container(
            height: 0.8,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 14),

          // Income and Expense Statistics
          Row(
            children: [
              // Доходы
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.income,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Доходы',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: AnimatedCurrencyText(
                              amount: periodIncome,
                              showSign: true,
                              style: const TextStyle(
                                color: AppColors.income,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                width: 0.8,
                color: Colors.white.withValues(alpha: 0.08),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Расходы
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.textSecondary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Расходы',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: AnimatedCurrencyText(
                              amount: -periodExpense.abs(),
                              showSign: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
