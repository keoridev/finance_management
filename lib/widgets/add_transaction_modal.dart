import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../models/transaction_type.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import 'add_bank_account_modal.dart';
import 'create_category_modal.dart';
import 'glass_container.dart';
import 'transaction_success_overlay.dart';

class AddTransactionModal extends StatefulWidget {
  final FinanceController controller;
  final TransactionType initialType;

  const AddTransactionModal({
    super.key,
    required this.controller,
    this.initialType = TransactionType.expense,
  });

  static Future<void> show(
    BuildContext context,
    FinanceController controller, {
    TransactionType defaultType = TransactionType.expense,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AddTransactionModal(controller: controller, initialType: defaultType),
    );
  }

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();
  bool _isAmountFocused = true;

  late TransactionType _selectedType;
  late String _selectedCategoryId;
  late String _selectedAccountId;
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    final firstAcc = widget.controller.accounts.firstOrNull;
    _selectedAccountId = firstAcc?.id ?? '';
    _updateDefaultCategory();

    _amountFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isAmountFocused = _amountFocusNode.hasFocus;
        });
      }
    });
  }

  void _updateDefaultCategory() {
    final categories = widget.controller.categories
        .where((c) => c.type == _selectedType)
        .toList();
    if (categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addQuickAmount(int value) {
    final current =
        double.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0.0;
    final updated = current + value;
    setState(() {
      _amountController.text = updated.toInt().toString();
    });
  }

  void _submit() {
    final rawText = _amountController.text
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    final amount = double.tryParse(rawText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, введите сумму'),
          backgroundColor: AppColors.iosRed,
        ),
      );
      return;
    }

    final category = widget.controller.getCategoryById(_selectedCategoryId);
    String title = _titleController.text.trim();
    if (title.isEmpty) {
      title =
          category?.name ??
          (_selectedType == TransactionType.expense ? 'Расход' : 'Доход');
    }

    widget.controller.addTransaction(
      title: title,
      amount: amount,
      date: _selectedDate,
      type: _selectedType,
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    Navigator.of(context).pop();

    final acc = widget.controller.getAccountById(_selectedAccountId);
    TransactionSuccessOverlay.show(
      context,
      title: title,
      amount: amount,
      bankName: acc?.bankName,
      isIncome: _selectedType == TransactionType.income,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.controller.categories
        .where((c) => c.type == _selectedType)
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header & Type Switcher + Top 'Готово' Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Новый платеж',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTypePill(
                            'Расход',
                            TransactionType.expense,
                            AppColors.iosRed,
                          ),
                          _buildTypePill(
                            'Доход',
                            TransactionType.income,
                            AppColors.iosGreen,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _submit();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedType == TransactionType.expense
                              ? AppColors.iosRed
                              : AppColors.iosGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Готово',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Shortcut Templates for fast auto-fill
            if (widget.controller.quickShortcuts.isNotEmpty &&
                _selectedType == TransactionType.expense) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Быстрые шаблоны:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '1 тап для автозаполнения',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.controller.quickShortcuts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final s = widget.controller.quickShortcuts[idx];
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _amountController.text = s.amount.toInt() == s.amount
                              ? s.amount.toInt().toString()
                              : s.amount.toString();
                          _titleController.text = s.title;
                          _selectedCategoryId = s.categoryId;
                          if (widget.controller.getAccountById(s.accountId) != null) {
                            _selectedAccountId = s.accountId;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: s.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: s.color.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s.icon, size: 14, color: s.color),
                            const SizedBox(width: 6),
                            Text(
                              '${s.title} • ${s.amount.toInt()} с.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Amount Input Card (MBank / Revolut Style with zero borders on TextField)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isAmountFocused
                      ? (_selectedType == TransactionType.expense
                            ? AppColors.iosRed.withValues(alpha: 0.5)
                            : AppColors.iosGreen.withValues(alpha: 0.5))
                      : Colors.white.withValues(alpha: 0.08),
                  width: _isAmountFocused ? 1.2 : 0.8,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _selectedType == TransactionType.expense ? '- ' : '+ ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: _selectedType == TransactionType.expense
                              ? AppColors.iosRed
                              : AppColors.iosGreen,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          autofocus: false,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+[\.,]?\d{0,2}'),
                            ),
                          ],
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.22),
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                            ),
                            suffixText: ' сом',
                            suffixStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_amountController.text.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _amountController.clear();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick Preset Amount Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [100, 500, 1000, 5000].map((val) {
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _addQuickAmount(val);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9F0A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFF9F0A).withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '+$val с.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF9F0A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title / Comment with concise placeholder
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                hintText: _selectedType == TransactionType.income
                    ? 'Комментарий (Зарплата, Перевод...)'
                    : 'Комментарий (Обед, Такси, Кофе...)',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Select Bank Account Header (Clean single plus)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedType == TransactionType.expense
                      ? 'Списать со счета:'
                      : 'Зачислить на счет:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await AddBankAccountModal.show(context, widget.controller);
                    setState(() {});
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Добавить банк',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Compact Single-Row Bank Chips (matching category chip aesthetics)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.controller.accounts.map((acc) {
                final isSelected = acc.id == _selectedAccountId;
                final accIcon = acc.type == AccountType.cash
                    ? Icons.payments_rounded
                    : Icons.credit_card_rounded;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedAccountId = acc.id);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? acc.color.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? acc.color
                            : Colors.white.withValues(alpha: 0.08),
                        width: isSelected ? 1.4 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          accIcon,
                          size: 14,
                          color: isSelected ? Colors.white : acc.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          acc.bankName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Select Category (Clean single plus)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Категория:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await CreateCategoryModal.show(context, widget.controller);
                    setState(() {});
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Создать категорию',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = cat.id == _selectedCategoryId;
                return InkWell(
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? cat.color
                            : Colors.white.withValues(alpha: 0.08),
                        width: isSelected ? 1.5 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 14,
                          color: isSelected ? Colors.white : cat.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Persistent Save Button (Always visible with clear tactile feedback)
            const SizedBox(height: 22),
            GlassContainer(
              height: 52,
              borderRadius: BorderRadius.circular(16),
              surfaceColor: _selectedType == TransactionType.expense
                  ? AppColors.iosRed
                  : AppColors.income,
              onTap: _submit,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedType == TransactionType.expense
                          ? Icons.remove_circle_outline_rounded
                          : Icons.add_circle_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedType == TransactionType.expense
                          ? 'Записать расход'
                          : 'Записать доход',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePill(String label, TransactionType type, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedType = type;
          _updateDefaultCategory();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
