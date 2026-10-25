import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recurring_payment.dart';
import '../models/transaction_type.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/glass_container.dart';

class RecurringPaymentsScreen extends StatelessWidget {
  final FinanceController controller;

  const RecurringPaymentsScreen({super.key, required this.controller});

  void _showAddRecurringDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    RecurringFrequency selectedFreq = RecurringFrequency.monthly;
    String selectedCatId = controller.categories
        .firstWhere((c) => c.type == TransactionType.expense)
        .id;
    String selectedAccId = controller.accounts.first.id;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1322).withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Новый регулярный платеж',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title input
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      labelText: 'Название подписки / платежа',
                      hintText: 'Например: Аренда, Netflix, Акнет, Фитнес',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Amount input
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}'))],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      labelText: 'Сумма (сом)',
                      suffixText: 'сом',
                      suffixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Frequency Selector
                  const Text('Периодичность', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: RecurringFrequency.values.map((f) {
                      final isSelected = f == selectedFreq;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(f.label),
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) => setState(() => selectedFreq = f),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Account Selector
                  const Text('Счет для списания', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.accounts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final acc = controller.accounts[index];
                        final isSelected = acc.id == selectedAccId;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(acc.name),
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => selectedAccId = acc.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Submit Button
                  GlassContainer(
                    height: 52,
                    borderRadius: BorderRadius.circular(16),
                    surfaceGradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF6366F1)],
                    ),
                    onTap: () {
                      final title = titleCtrl.text.trim();
                      final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0.0;
                      if (title.isNotEmpty && amount > 0) {
                        controller.addRecurringPayment(
                          title: title,
                          amount: amount,
                          frequency: selectedFreq,
                          categoryId: selectedCatId,
                          accountId: selectedAccId,
                          nextDueDate: selectedDate,
                        );
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: const Center(
                      child: Text(
                        'Сохранить подписку',
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
    final list = controller.recurringPayments;
    final totalMonthly = controller.totalMonthlyRecurring;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Повторные платежи и подписки',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Добавить платеж',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => _showAddRecurringDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Total Monthly Commitments Card
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(22),
            surfaceGradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withValues(alpha: 0.25),
                const Color(0xFF0F172A).withValues(alpha: 0.75),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.event_repeat_rounded,
                    color: Color(0xFFA5B4FC),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Обязательства в месяц',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(totalMonthly),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${list.where((r) => r.isActive).length} активных регулярных списаний',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ваши регулярные списания',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${list.length} всего',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (list.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(32),
              borderRadius: BorderRadius.circular(20),
              child: const Center(
                child: Text(
                  'Нет запланированных регулярных платежей',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = list[index];
                final category = controller.getCategoryById(item.categoryId);
                final account = controller.getAccountById(item.accountId);
                final daysText = AppDateFormatter.formatDaysRemaining(item.nextDueDate);

                return GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (category?.color ?? AppColors.primary).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              category?.icon ?? Icons.repeat,
                              color: category?.color ?? AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.frequency.label} • ${account?.name ?? 'Счет'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(item.amount),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.isDueSoon
                                      ? AppColors.warning.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  daysText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: item.isDueSoon ? AppColors.warning : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Actions Row: Quick Pay Now & Toggle Active
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: item.isActive,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (_) => controller.toggleRecurringPayment(item.id),
                                ),
                              ),
                              Text(
                                item.isActive ? 'Активен' : 'Приостановлен',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: item.isActive ? AppColors.textLight : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                                onPressed: () => controller.deleteRecurringPayment(item.id),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  controller.payRecurringNow(item.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Платеж "${item.title}" успешно оплачен!'),
                                      backgroundColor: AppColors.income,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 14),
                                label: const Text('Оплатить сейчас', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                            ],
                          ),
                        ],
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
