import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quick_payment_shortcut.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_container.dart';
import 'transaction_success_overlay.dart';

/// Senior-engineered 1-tap quick payment shortcut section.
/// Features:
/// - Native tactile spring feedback on press (Haptic + Scale micro-animations)
/// - Long-press quick management action sheet directly from dashboard
/// - Refined frosted glass pills with custom category accents
/// - Rich configuration modal with Kyrgyz everyday presets (Tulpar, Coffee, Bread, Taxi, Lunch)
/// - Live shortcut preview and real-time account balance indicators
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

  void _showShortcutContextMenu(
    BuildContext context,
    QuickPaymentShortcut shortcut,
  ) {
    HapticFeedback.heavyImpact();
    final account = controller.getAccountById(shortcut.accountId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Shortcut preview header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: shortcut.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: shortcut.color.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        shortcut.icon,
                        color: shortcut.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shortcut.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${CurrencyFormatter.format(shortcut.amount)} • ${account?.name ?? 'Счет'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action: Execute now
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: AppColors.income,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Списать в 1 тап сейчас',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Внести ${CurrencyFormatter.format(shortcut.amount)} в расходы',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _onShortcutTap(context, shortcut);
                  },
                ),

                const Divider(color: Colors.white10, height: 16),

                // Action: Delete shortcut
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.expense,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Удалить эту кнопку',
                    style: TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    controller.deleteQuickShortcut(shortcut.id);
                    Navigator.of(ctx).pop();
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Кнопка «${shortcut.title}» удалена'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.capybaraAmber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: AppColors.capybaraAmber,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Быстрые платежи в 1 тап',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => _showConfigureModal(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Настроить',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (list.isEmpty)
          _buildEmptyState(context)
        else
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == list.length) {
                  return _buildAddButton(context);
                }

                final item = list[index];
                return _ShortcutPillButton(
                  shortcut: item,
                  onTap: () => _onShortcutTap(context, item),
                  onLongPress: () => _showShortcutContextMenu(context, item),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return InkWell(
      onTap: () => _showConfigureModal(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.capybaraAmber.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.capybaraAmber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_task_rounded,
                color: AppColors.capybaraAmber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добавьте кнопки частых трат',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Тулпар (20 с), кофе (180 с) или такси в один клик',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.capybaraAmber,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return _InteractiveScaleButton(
      onTap: () => _showConfigureModal(context),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.capybaraAmber.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 14,
                color: AppColors.capybaraAmber,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Добавить',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spring-animated interactive shortcut pill with native haptics.
class _ShortcutPillButton extends StatelessWidget {
  final QuickPaymentShortcut shortcut;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ShortcutPillButton({
    required this.shortcut,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return _InteractiveScaleButton(
      onTap: onTap,
      onLongPress: onLongPress,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: BorderRadius.circular(15),
        surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.78),
        borderColor: shortcut.color.withValues(alpha: 0.22),
        borderWidth: 1.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: shortcut.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: shortcut.color.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Icon(shortcut.icon, color: shortcut.color, size: 14),
            ),
            const SizedBox(width: 8),

            // Title
            Text(
              shortcut.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 7),

            // Amount badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: shortcut.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                CurrencyFormatter.format(shortcut.amount),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: shortcut.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Micro-interactive spring scale container for native button feel
class _InteractiveScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _InteractiveScaleButton({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_InteractiveScaleButton> createState() =>
      _InteractiveScaleButtonState();
}

class _InteractiveScaleButtonState extends State<_InteractiveScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}


/// Rich Configuration & Preset Modal Sheet
class _ConfigureShortcutsModal extends StatefulWidget {
  final FinanceController controller;

  const _ConfigureShortcutsModal({required this.controller});

  @override
  State<_ConfigureShortcutsModal> createState() =>
      _ConfigureShortcutsModalState();
}

class _ConfigureShortcutsModalState extends State<_ConfigureShortcutsModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late String _selectedCategoryId;
  late String _selectedAccountId;
  IconData _selectedIcon = Icons.directions_bus_rounded;
  Color _selectedColor = AppColors.iosBlue;

  // Everyday presets tailored to Kyrgyzstan & urban life
  static const List<_ShortcutPreset> _presets = [
    _ShortcutPreset(
      title: 'Тулпар',
      amount: 20,
      icon: Icons.directions_bus_rounded,
      color: AppColors.iosBlue,
      categoryKeyword: 'Транспорт',
    ),
    _ShortcutPreset(
      title: 'Маршрутка',
      amount: 20,
      icon: Icons.airport_shuttle_rounded,
      color: AppColors.iosBlue,
      categoryKeyword: 'Транспорт',
    ),
    _ShortcutPreset(
      title: 'Кофе',
      amount: 180,
      icon: Icons.coffee_rounded,
      color: AppColors.capybaraGold,
      categoryKeyword: 'Рестораны',
    ),
    _ShortcutPreset(
      title: 'Лепешка',
      amount: 35,
      icon: Icons.bakery_dining_rounded,
      color: AppColors.iosGreen,
      categoryKeyword: 'Продукты',
    ),
    _ShortcutPreset(
      title: 'Яндекс Go',
      amount: 160,
      icon: Icons.local_taxi_rounded,
      color: AppColors.iosOrange,
      categoryKeyword: 'Транспорт',
    ),
    _ShortcutPreset(
      title: 'Бизнес-ланч',
      amount: 320,
      icon: Icons.restaurant_rounded,
      color: AppColors.iosOrange,
      categoryKeyword: 'Рестораны',
    ),
    _ShortcutPreset(
      title: 'Супермаркет',
      amount: 500,
      icon: Icons.shopping_basket_rounded,
      color: AppColors.iosGreen,
      categoryKeyword: 'Продукты',
    ),
    _ShortcutPreset(
      title: 'Аптека',
      amount: 250,
      icon: Icons.medication_rounded,
      color: AppColors.iosRed,
      categoryKeyword: 'Здоровье',
    ),
  ];

  static const List<IconData> _shortcutIcons = [
    Icons.directions_bus_rounded,
    Icons.airport_shuttle_rounded,
    Icons.local_taxi_rounded,
    Icons.local_gas_station_rounded,
    Icons.restaurant_rounded,
    Icons.coffee_rounded,
    Icons.bakery_dining_rounded,
    Icons.shopping_basket_rounded,
    Icons.shopping_bag_rounded,
    Icons.medication_rounded,
    Icons.fitness_center_rounded,
    Icons.local_car_wash_rounded,
    Icons.water_drop_rounded,
    Icons.phone_android_rounded,
  ];

  static const List<Color> _shortcutColors = [
    AppColors.iosBlue,
    AppColors.capybaraAmber,
    AppColors.iosGreen,
    AppColors.iosOrange,
    AppColors.iosPurple,
    AppColors.iosRed,
    AppColors.iosTeal,
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.controller.categories.isNotEmpty
        ? widget.controller.categories.first.id
        : 'cat_transport';
    _selectedAccountId = widget.controller.accounts.isNotEmpty
        ? widget.controller.accounts.first.id
        : 'acc_main';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyPreset(_ShortcutPreset preset) {
    HapticFeedback.selectionClick();
    _titleController.text = preset.title;
    _amountController.text = preset.amount.toStringAsFixed(0);
    _selectedIcon = preset.icon;
    _selectedColor = preset.color;

    // Try matching appropriate category by name
    final match = widget.controller.categories.firstWhere(
      (c) =>
          c.name.toLowerCase().contains(preset.categoryKeyword.toLowerCase()),
      orElse: () => widget.controller.categories.first,
    );
    _selectedCategoryId = match.id;
    setState(() {});
  }

  void _addShortcut() {
    final title = _titleController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    if (title.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите название быстрой кнопки')),
      );
      return;
    }

    if (amount <= 0) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите корректную сумму платежа')),
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

    HapticFeedback.mediumImpact();
    _titleController.clear();
    _amountController.clear();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Кнопка «$title» добавлена на главный экран'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = widget.controller.quickShortcuts;
    final accounts = widget.controller.accounts;
    final categories = widget.controller.categories;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Быстрые платежи в 1 тап',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Existing shortcuts list with quick deletion
            if (shortcuts.isNotEmpty) ...[
              const Text(
                'Активные кнопки (нажмите крестик для удаления):',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shortcuts.map((s) {
                  return Chip(
                    avatar: Icon(s.icon, size: 14, color: s.color),
                    label: Text(
                      '${s.title} (${CurrencyFormatter.format(s.amount)})',
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    deleteIcon: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onDeleted: () {
                      HapticFeedback.lightImpact();
                      widget.controller.deleteQuickShortcut(s.id);
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const Divider(color: Colors.white12, height: 26),
            ],

            // Everyday Kyrgyz Presets Row
            const Text(
              'Готовые шаблоны (1 клик для заполнения):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.capybaraAmber,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _presets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final p = _presets[idx];
                  return InkWell(
                    onTap: () => _applyPreset(p),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: p.color.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(p.icon, size: 13, color: p.color),
                          const SizedBox(width: 5),
                          Text(
                            '${p.title} • ${p.amount.toInt()}с',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Live Preview of Current Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Вид кнопки: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_selectedIcon, size: 14, color: _selectedColor),
                        const SizedBox(width: 6),
                        Text(
                          _titleController.text.trim().isEmpty
                              ? 'Название'
                              : _titleController.text.trim(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_amountController.text.isEmpty ? '0' : _amountController.text} сом',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _selectedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Title & Amount Input Fields
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _titleController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Название (напр. Маршрутка)',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+[\.,]?\d{0,2}'),
                      ),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Сумма',
                      suffixText: 'сом',
                      suffixStyle: const TextStyle(
                        color: AppColors.capybaraAmber,
                        fontWeight: FontWeight.w700,
                      ),
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Select Bank Account (with live balance preview)
            const Text(
              'Счет списания',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  final isSelected = acc.id == _selectedAccountId;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(
                      '${acc.name} • ${CurrencyFormatter.format(acc.balance)}',
                    ),
                    selectedColor: AppColors.iosBlue,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textLight,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedAccountId = acc.id);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Select Category
            const Text(
              'Категория расходов',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat.id == _selectedCategoryId;
                  return ChoiceChip(
                    selected: isSelected,
                    avatar: Icon(
                      cat.icon,
                      size: 13,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(cat.name),
                    selectedColor: cat.color,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textLight,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategoryId = cat.id;
                        _selectedColor = cat.color;
                        _selectedIcon = cat.icon;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Color Selector Row
            const Text(
              'Цвет кнопки',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: Row(
                children: _shortcutColors.map((c) {
                  final isSelected = c == _selectedColor;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedColor = c);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2.2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Icon Selector Row
            const Text(
              'Иконка кнопки',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _shortcutIcons.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final icon = _shortcutIcons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIcon = icon);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: _selectedColor, width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.textLight,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            // Submit Button
            _InteractiveScaleButton(
              onTap: _addShortcut,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.capybaraAmber, AppColors.capybaraGold],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.capybaraAmber.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Color(0xFF161412),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Создать быструю кнопку',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF161412),
                        ),
                      ),
                    ],
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

class _ShortcutPreset {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final String categoryKeyword;

  const _ShortcutPreset({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.categoryKeyword,
  });
}
