import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_category.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/glass_container.dart';
import '../widgets/interactive_donut_chart.dart';
import '../widgets/empty_state_view.dart';

class AnalyticsScreen extends StatefulWidget {
  final FinanceController controller;

  const AnalyticsScreen({super.key, required this.controller});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  TransactionCategory? _highlightedCategory;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final breakdown = controller.getCategoryExpensesBreakdown();
    final sortedBreakdown = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      

    final totalExpense = controller.periodExpense;
    final totalIncome = controller.periodIncome;
    final netSavings = controller.periodCashFlow;
    final savingsRate = totalIncome > 0
        ? ((netSavings / totalIncome) * 100).clamp(-100.0, 100.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Аналитика расходов',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Period Filter Glass Chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: PeriodFilter.values.map((period) {
                final isSelected = controller.selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.setPeriod(period);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.1),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        period.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.black
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Cash Flow Glass Card
          GlassContainer(
            padding: const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Денежный поток за период (сом)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Поступления', style: TextStyle(color: AppColors.textLight)),
                    Text(
                      CurrencyFormatter.format(totalIncome, showSign: true),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.income),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Траты', style: TextStyle(color: AppColors.textLight)),
                    Text(
                      '- ${CurrencyFormatter.format(totalExpense)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.expense),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Чистый остаток (дельта)',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    Text(
                      CurrencyFormatter.format(netSavings, showSign: true),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: netSavings >= 0 ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
                if (totalIncome > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Уровень сбережений: ${savingsRate.toStringAsFixed(1)}% от дохода',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Interactive Circular / Donut Chart Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Круговая диаграмма расходов',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Всего: ${CurrencyFormatter.format(totalExpense)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Glass Container with Interactive Donut Chart
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            borderRadius: BorderRadius.circular(24),
            child: InteractiveDonutChart(
              breakdown: breakdown,
              totalAmount: totalExpense,
              onCategorySelected: (cat) {
                setState(() => _highlightedCategory = cat);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Category Breakdown List
          const Text(
            'Детализация по категориям',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          if (sortedBreakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: EmptyStateView(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Пока чисто, как в коде после рефакторинга',
                subtitle: 'Нет расходов за выбранный период. Бюджет в полной безопасности!',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedBreakdown.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = sortedBreakdown[index];
                final TransactionCategory cat = entry.key;
                final double amount = entry.value;
                final double percent = totalExpense > 0 ? (amount / totalExpense) : 0.0;
                final int percentInt = (percent * 100).round();
                final isHighlighted = _highlightedCategory?.id == cat.id;

                return GlassContainer(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(16),
                  borderColor: isHighlighted ? cat.color : null,
                  borderWidth: isHighlighted ? 1.5 : 1.0,
                  surfaceGradient: isHighlighted
                      ? LinearGradient(
                          colors: [
                            cat.color.withValues(alpha: 0.25),
                            const Color(0xFF0F172A).withValues(alpha: 0.8),
                          ],
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _highlightedCategory = isHighlighted ? null : cat;
                    });
                  },
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(amount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($percentInt%)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
