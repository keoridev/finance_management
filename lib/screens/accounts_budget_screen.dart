import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_type.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/add_bank_account_modal.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/create_category_modal.dart';
import '../widgets/glass_container.dart';

class AccountsBudgetScreen extends StatelessWidget {
  final FinanceController controller;

  const AccountsBudgetScreen({super.key, required this.controller});

  void _showSetBudgetDialog(BuildContext context) {
    String selectedCatId = controller.categories
        .firstWhere((c) => c.type == TransactionType.expense)
        .id;
    final limitCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            padding: EdgeInsets.only(
              top: 14,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Лимит бюджета (сом)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Категория расхода',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.categories
                        .where((c) => c.type == TransactionType.expense)
                        .map((c) {
                      final isSelected = c.id == selectedCatId;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(c.name),
                        avatar: Icon(c.icon, size: 14, color: isSelected ? Colors.white : c.color),
                        selectedColor: c.color,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textLight,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) => setState(() => selectedCatId = c.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      labelText: 'Месячный лимит',
                      suffixText: 'сом',
                      hintText: '30 000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  GlassContainer(
                    height: 52,
                    borderRadius: BorderRadius.circular(16),
                    surfaceColor: AppColors.iosBlue,
                    onTap: () {
                      final limit = double.tryParse(limitCtrl.text) ?? 0.0;
                      if (limit > 0) {
                        controller.updateBudget(selectedCatId, limit);
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: const Center(
                      child: Text(
                        'Сохранить лимит',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Счета и категории',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Раздел банков и счетов
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Банки и счета',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: () => AddBankAccountModal.show(context, controller),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Добавить банк',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.accounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final acc = controller.accounts[index];
              return GlassContainer(
                padding: const EdgeInsets.all(14),
                borderRadius: BorderRadius.circular(16),
                surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: acc.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: acc.color.withValues(alpha: 0.35)),
                      ),
                      child: Icon(acc.type.icon, size: 20, color: acc.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                acc.bankName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (acc.lastDigits != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '• ${acc.lastDigits}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            acc.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(acc.balance, currency: acc.currency),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 26),

          // Раздел управления категориями
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Категории',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: () => CreateCategoryModal.show(context, controller),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.iosGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iosGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 14, color: AppColors.iosGreen),
                      SizedBox(width: 4),
                      Text(
                        'Создать категорию',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iosGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GlassContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: BorderRadius.circular(18),
            surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.categories.map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon, size: 14, color: c.color),
                      const SizedBox(width: 6),
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 26),

          // Раздел бюджетов
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Лимиты бюджета',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: () => _showSetBudgetDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.tune, size: 14, color: AppColors.iosBlue),
                      SizedBox(width: 4),
                      Text(
                        'Настроить',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iosBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (controller.budgets.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: BorderRadius.circular(18),
              surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
              child: const Center(
                child: Text(
                  'Лимиты расходов еще не заданы',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.budgets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final budget = controller.budgets[index];
                final category = controller.getCategoryById(budget.categoryId);
                if (category == null) return const SizedBox.shrink();

                final spent = controller.getCategorySpending(
                  budget.categoryId,
                  period: PeriodFilter.thisMonth,
                );

                return BudgetProgressCard(
                  budget: budget,
                  category: category,
                  spent: spent,
                );
              },
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
