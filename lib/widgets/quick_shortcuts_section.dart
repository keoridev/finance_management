import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quick_payment_shortcut.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_container.dart';
import 'transaction_success_overlay.dart';

class QuickShortcutsSection extends StatelessWidget {
  final FinanceController controller;

  const QuickShortcutsSection({super.key, required this.controller});

  void _showConfigureModal(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfigureShortcutsModal(controller: controller),
    );
  }

  void _onShortcutTap(BuildContext context, QuickPaymentShortcut shortcut) {
    final account = controller.getAccountById(shortcut.accountId);
    controller.executeQuickShortcut(shortcut);
    TransactionSuccessOverlay.show(
      context,
      title: shortcut.title,
      amount: shortcut.amount,
      bankName: account?.bankName ?? 'Счет',
      isIncome: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = controller.quickShortcuts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Быстрые платежи в 1 тап',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showConfigureModal(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text(
                      'Настроить',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == list.length) {
                // Add Shortcut Button
                return InkWell(
                  onTap: () => _showConfigureModal(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Text(
                          'Добавить кнопку',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final item = list[index];
              return InkWell(
                onTap: () => _onShortcutTap(context, item),
                borderRadius: BorderRadius.circular(14),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: BorderRadius.circular(14),
                  surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.7),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.color, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        CurrencyFormatter.format(item.amount),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConfigureShortcutsModal extends StatefulWidget {
  final FinanceController controller;

  const _ConfigureShortcutsModal({required this.controller});

  @override
  State<_ConfigureShortcutsModal> createState() => _ConfigureShortcutsModalState();
}

class _ConfigureShortcutsModalState extends State<_ConfigureShortcutsModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late String _selectedCategoryId;
  late String _selectedAccountId;
  IconData _selectedIcon = Icons.directions_bus_rounded;
  Color _selectedColor = AppColors.iosBlue;

  static const List<IconData> _shortcutIcons = [
    Icons.directions_bus_rounded,
    Icons.airport_shuttle_rounded,
    Icons.local_taxi_rounded,
    Icons.local_gas_station_rounded,
    Icons.restaurant_rounded,
    Icons.coffee_rounded,
    Icons.shopping_basket_rounded,
    Icons.shopping_bag_rounded,
    Icons.medication_rounded,
    Icons.fitness_center_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.controller.categories.first.id;
    _selectedAccountId = widget.controller.accounts.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addShortcut() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите название и сумму платежа')),
      );
      return;
    }

    widget.controller.addQuickShortcut(
      title: title,
      amount: amount,
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    _titleController.clear();
    _amountController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = widget.controller.quickShortcuts;
    final accounts = widget.controller.accounts;
    final categories = widget.controller.categories;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: EdgeInsets.only(
        top: 12,
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Настройка быстрых кнопок',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Existing shortcuts list with delete
            if (shortcuts.isNotEmpty) ...[
              const Text(
                'Текущие кнопки (нажмите крестик для удаления):',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shortcuts.map((s) {
                  return Chip(
                    avatar: Icon(s.icon, size: 14, color: s.color),
                    label: Text('${s.title} (${CurrencyFormatter.format(s.amount)})'),
                    labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                    onDeleted: () {
                      widget.controller.deleteQuickShortcut(s.id);
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const Divider(color: Colors.white12, height: 28),
            ],

            const Text(
              'Создать новую быструю кнопку',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Название (напр. Транспорт)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}'))],
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Сумма',
                      suffixText: 'сом',
                      suffixStyle: const TextStyle(color: AppColors.iosBlue),
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Select Bank Account
            const Text('Счет списания', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  final isSelected = acc.id == _selectedAccountId;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(acc.name),
                    selectedColor: AppColors.iosBlue,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppColors.textLight,
                    ),
                    onSelected: (_) => setState(() => _selectedAccountId = acc.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Select Category
            const Text('Категория', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat.id == _selectedCategoryId;
                  return ChoiceChip(
                    selected: isSelected,
                    avatar: Icon(cat.icon, size: 12, color: isSelected ? Colors.white : cat.color),
                    label: Text(cat.name),
                    selectedColor: cat.color,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppColors.textLight,
                    ),
                    onSelected: (_) => setState(() {
                      _selectedCategoryId = cat.id;
                      _selectedColor = cat.color;
                      _selectedIcon = cat.icon;
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Icon Selector Row
            const Text('Иконка кнопки', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _shortcutIcons.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final icon = _shortcutIcons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: _selectedColor, width: 1.5) : null,
                      ),
                      child: Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textLight),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            GlassContainer(
              height: 48,
              borderRadius: BorderRadius.circular(14),
              surfaceColor: AppColors.iosBlue,
              onTap: _addShortcut,
              child: const Center(
                child: Text(
                  'Добавить быструю кнопку',
                  style: TextStyle(
                    fontSize: 14,
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
  }
}
