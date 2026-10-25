import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_type.dart';
import '../services/widget_launch_service.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'add_transaction_modal.dart';
import 'glass_container.dart';
import 'transaction_success_overlay.dart';
import 'widget_installation_guide_modal.dart';

enum WidgetDisplayMode { winterArc, quickActions, capybara, medium, small, lockScreen }

class IosHomeWidgetPreview extends StatefulWidget {
  final FinanceController controller;

  const IosHomeWidgetPreview({super.key, required this.controller});

  @override
  State<IosHomeWidgetPreview> createState() => _IosHomeWidgetPreviewState();
}

class _IosHomeWidgetPreviewState extends State<IosHomeWidgetPreview> {
  WidgetDisplayMode _mode = WidgetDisplayMode.winterArc;
  String? _selectedAccountId; // null means all accounts
  bool _showForecast = true;
  bool _showQuickActions = true;
  int _capyQuoteIndex = 0;

  static const List<Map<String, String>> _capyQuotes = [
    {
      'tag': 'ДЗЕН',
      'quote': '«Лучший способ сберечь 1000 сом — это просто не покупать то, без чего можно обойтись. Пей чай и чилль.»',
    },
    {
      'tag': 'СКИДКИ',
      'quote': '«Увидел скидку 70%? Капибара советует полежать 10 минут. Скидка 100% — это не покупать вовсе.»',
    },
    {
      'tag': 'БАЛАНС',
      'quote': '«Деньги имеют свойство испаряться, когда забываешь их учитывать. Заглядывай в ARC чаще, бро!»',
    },
    {
      'tag': 'СОВЕТ',
      'quote': '«Импульсивная покупка длится 5 секунд, а дефицит на карте — до конца месяца. Будь дзен.»',
    },
    {
      'tag': 'КОПИЛКА',
      'quote': '«Положи 100 сом в копилку мечты прямо сейчас. Капибара довольно жмурится с апельсином на голове.»',
    },
    {
      'tag': 'ЧИЛЛ',
      'quote': '«Богат не тот, у кого миллион спонтанных трат, а тот, кто спокойно чиллит без долгов и суеты.»',
    },
    {
      'tag': 'СТРИК',
      'quote': '«Твой стрик дисциплины крепнет. Самурай кошелька не суетится — самурай уверен в завтрашнем дне.»',
    },
    {
      'tag': 'ПОКОЙ',
      'quote': '«Капибара сидит в горячем источнике и напоминает: финансовая подушка греет лучше любого пледа.»',
    },
    {
      'tag': 'ДЗЕН',
      'quote': '«Не покупай статус — покупай свободу и спокойный сон. Капибара гарантирует гармонию.»',
    },
  ];

  Future<void> _requestPinCurrentWidget() async {
    HapticFeedback.heavyImpact();
    final String widgetType;
    final String widgetName;
    switch (_mode) {
      case WidgetDisplayMode.quickActions:
        widgetType = 'quick';
        widgetName = 'Быстрые платежи (1 тап)';
        break;
      case WidgetDisplayMode.winterArc:
        widgetType = 'winter';
        widgetName = 'Winter Arc (Сетка квадратов)';
        break;
      case WidgetDisplayMode.capybara:
        widgetType = 'capy';
        widgetName = 'Предсказания Капибары';
        break;
      case WidgetDisplayMode.small:
        widgetType = 'mini';
        widgetName = 'Мини-баланс (2×2)';
        break;
      case WidgetDisplayMode.medium:
      case WidgetDisplayMode.lockScreen:
        widgetType = 'finance';
        widgetName = 'Баланс и быстрые действия (4×2)';
        break;
    }

    final bool pinned = await WidgetLaunchService.requestPinWidget(widgetType);
    if (!mounted) return;

    if (pinned) {
      TransactionSuccessOverlay.show(
        context,
        title: widgetName,
        amount: 0,
        bankName: 'Подтвердите установку в окне Android',
        isIncome: true,
      );
    } else {
      // Launcher does not support pinWidget (or on iOS) -> show installation instructions modal
      WidgetInstallationGuideModal.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _selectedAccountId == null
        ? widget.controller.totalBalance
        : widget.controller.getAccountById(_selectedAccountId!)?.balance ?? 0.0;

    final accountName = _selectedAccountId == null
        ? 'ВСЕ СЧЕТА'
        : widget.controller
                  .getAccountById(_selectedAccountId!)
                  ?.bankName
                  .toUpperCase() ??
              'СЧЕТ';

    final shortcuts = widget.controller.quickShortcuts.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.widgets_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Нативные виджеты (Android & iOS)',
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                WidgetInstallationGuideModal.show(context);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.iosBlue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.iosBlue.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline_rounded, size: 13, color: AppColors.iosBlue),
                    SizedBox(width: 4),
                    Text(
                      'Инструкция',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSizeToggle(
                      label: 'Winter Arc',
                      selected: _mode == WidgetDisplayMode.winterArc,
                      onTap: () =>
                          setState(() => _mode = WidgetDisplayMode.winterArc),
                    ),
                    _buildSizeToggle(
                      label: 'Быстрые кнопки',
                      selected: _mode == WidgetDisplayMode.quickActions,
                      onTap: () =>
                          setState(() => _mode = WidgetDisplayMode.quickActions),
                    ),
                    _buildSizeToggle(
                      label: 'Капибара 2×2',
                      selected: _mode == WidgetDisplayMode.capybara,
                      onTap: () =>
                          setState(() => _mode = WidgetDisplayMode.capybara),
                    ),
                    _buildSizeToggle(
                      label: '4×2 Баланс',
                      selected: _mode == WidgetDisplayMode.medium,
                      onTap: () =>
                          setState(() => _mode = WidgetDisplayMode.medium),
                    ),
                    _buildSizeToggle(
                      label: '2×2 Мини',
                      selected: _mode == WidgetDisplayMode.small,
                      onTap: () =>
                          setState(() => _mode = WidgetDisplayMode.small),
                    ),
                    _buildSizeToggle(
                      label: 'Lock',
                      selected: _mode == WidgetDisplayMode.lockScreen,
                      onTap: () =>
                          setState(() => _mode = WidgetDisplayMode.lockScreen),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Apple & Android Widget Container with interactive preview
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: (_mode == WidgetDisplayMode.medium || _mode == WidgetDisplayMode.quickActions)
                  ? 360
                  : ((_mode == WidgetDisplayMode.winterArc || _mode == WidgetDisplayMode.capybara)
                      ? 290
                      : (_mode == WidgetDisplayMode.small ? 180 : 150)),
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: (_mode == WidgetDisplayMode.winterArc ||
                        _mode == WidgetDisplayMode.capybara ||
                        _mode == WidgetDisplayMode.quickActions)
                    ? const Color(0xFFFF9F0A).withValues(alpha: 0.40)
                    : Colors.white.withValues(alpha: 0.16),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _mode == WidgetDisplayMode.quickActions
                ? _buildQuickActionsWidget(balance, accountName)
                : (_mode == WidgetDisplayMode.winterArc
                    ? _buildWinterArcWidget(balance, accountName)
                    : (_mode == WidgetDisplayMode.capybara
                        ? _buildCapybaraWidget()
                        : (_mode == WidgetDisplayMode.medium
                            ? _buildMediumWidget(balance, accountName, shortcuts)
                            : (_mode == WidgetDisplayMode.small
                                ? _buildSmallWidget(balance, accountName)
                                : _buildLockScreenWidget(balance))))),
          ),
        ),

        const SizedBox(height: 12),

        // Prominent 1-tap Pin to Home Screen Button
        InkWell(
          onTap: _requestPinCurrentWidget,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9F0A), Color(0xFFFFB340)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9F0A).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.install_mobile_rounded,
                  size: 18,
                  color: Color(0xFF161412),
                ),
                const SizedBox(width: 8),
                Text(
                  _mode == WidgetDisplayMode.winterArc
                      ? 'Установить Winter Arc на рабочий стол'
                      : (_mode == WidgetDisplayMode.quickActions
                          ? 'Установить Быстрые кнопки на рабочий стол'
                          : (_mode == WidgetDisplayMode.capybara
                              ? 'Установить Предсказания Капибары'
                              : 'Установить Виджет Баланса на рабочий стол')),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF161412),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Widget Configurator Controls
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(18),
          surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Настройка виджета',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),

              // Account Selector for Widget
              const Text(
                'Отображаемый счет',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildAccountChip(
                      id: null,
                      title: 'Все банки (Общий)',
                      isSelected: _selectedAccountId == null,
                    ),
                    const SizedBox(width: 8),
                    ...widget.controller.accounts.map((acc) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildAccountChip(
                          id: acc.id,
                          title: acc.bankName,
                          isSelected: _selectedAccountId == acc.id,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Toggles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Показывать прогноз трат',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  Switch.adaptive(
                    value: _showForecast,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.iosGreen,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _showForecast = val);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Кнопки быстрых оплат (1 тап)',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  Switch.adaptive(
                    value: _showQuickActions,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.iosGreen,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _showQuickActions = val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Export / Add to Home button
              InkWell(
                onTap: () async {
                  HapticFeedback.heavyImpact();
                  await WidgetLaunchService.syncBalanceToWidget(
                    widget.controller.totalBalance,
                    streak: widget.controller.noSpendStreak,
                    isWinterChecked: widget.controller.isWinterCheckedToday,
                    accountName: widget.controller.activeAccountLabel,
                    todaySpent: widget.controller.todaySpentLabel,
                  );
                  final quote = _capyQuotes[_capyQuoteIndex % _capyQuotes.length];
                  await WidgetLaunchService.syncCapyPrediction(
                    title: 'ПРЕДСКАЗАНИЕ КАПИБАРЫ',
                    body: quote['quote'] ?? 'Будь спокоен и держи баланс.',
                    statusTag: quote['tag'] ?? 'ДЗЕН',
                  );
                  if (!context.mounted) return;
                  TransactionSuccessOverlay.show(
                    context,
                    title: 'Данные виджетов обновлены',
                    amount: 0,
                    bankName: 'Android Виджеты',
                    isIncome: true,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F0A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF161412),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Синхронизировать с виджетами',
                          style: TextStyle(
                            fontSize: 13,
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
      ],
    );
  }

  Widget _buildAccountChip({
    required String? id,
    required String title,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedAccountId = id);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF9F0A)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? const Color(0xFF161412) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF9F0A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected
                ? const Color(0xFF161412)
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildMediumWidget(
    double balance,
    String accountName,
    List shortcuts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Bar with clean KGS pill badge in line with typography
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'KGS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ФИНАНСЫ • $accountName',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.iosGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 6, color: AppColors.iosGreen),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.iosGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.format(balance),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                if (_showForecast) ...[
                  const SizedBox(height: 2),
                  Text(
                    'До конца месяца: ~${CurrencyFormatter.format(balance * 0.35)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        if (_showQuickActions) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (final s in shortcuts) ...[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      widget.controller.executeShortcut(s);
                      TransactionSuccessOverlay.show(
                        context,
                        title: s.title,
                        amount: s.amount,
                        bankName: 'Виджет iOS',
                        isIncome: false,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(s.icon, size: 16, color: s.color),
                          const SizedBox(height: 4),
                          Text(
                            '${s.amount.toInt()} с.',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: () =>
                    AddTransactionModal.show(context, widget.controller),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.iosBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCapybaraWidget() {
    final item = _capyQuotes[_capyQuoteIndex % _capyQuotes.length];
    final tag = item['tag'] ?? 'ДЗЕН';
    final quote = item['quote'] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header: Mascot sparkle + Tag pill
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 13,
              color: Color(0xFFFF9F0A),
            ),
            const SizedBox(width: 5),
            const Expanded(
              child: Text(
                'КАПИБАРА',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Color(0xFFFF9F0A),
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F0A).withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFFF9F0A).withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF9F0A),
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2. Quote Body
        Text(
          quote,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.35,
            letterSpacing: -0.2,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // 3. Footer: Author + Cycle button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '— Капибара',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _capyQuoteIndex = (_capyQuoteIndex + 1) % _capyQuotes.length;
                });
                final current = _capyQuotes[_capyQuoteIndex];
                WidgetLaunchService.syncCapyPrediction(
                  title: 'Капибара советует',
                  body: current['quote']!,
                  statusTag: current['tag'],
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F0A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 11,
                      color: Color(0xFF161412),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Новая мысль',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF161412),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWinterArcWidget(double balance, String accountName) {
    final streak = widget.controller.noSpendStreak;
    final isChecked = widget.controller.isWinterCheckedToday;
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Mon ... 7 = Sun
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header: WINTER ARC and Check-in action button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'WINTER ARC',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFFFF9F0A),
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.bolt_rounded,
                          size: 12,
                          color: Color(0xFFFF9F0A),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(balance),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            InkWell(
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.controller.checkInWinterDay();
                TransactionSuccessOverlay.show(
                  context,
                  title: isChecked ? 'День уже отмечен' : 'День зафиксирован!',
                  amount: 0,
                  bankName: 'Winter Arc Виджет',
                  isIncome: true,
                );
              },
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.income.withValues(alpha: 0.22)
                      : const Color(0xFFFF9F0A),
                  borderRadius: BorderRadius.circular(7),
                  border: isChecked
                      ? Border.all(
                          color: AppColors.income.withValues(alpha: 0.4),
                          width: 0.8,
                        )
                      : null,
                ),
                child: Text(
                  isChecked ? 'Отмечено' : 'Отметить',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isChecked ? AppColors.income : const Color(0xFF161412),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Weekdays Header Row: Пн Вт Ср Чт Пт Сб Вс
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final isToday = (i + 1) == currentWeekday;
            return Expanded(
              child: Center(
                child: Text(
                  weekdays[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: isToday
                        ? const Color(0xFFFF9F0A)
                        : Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),

        // 3. Row 1: Habit Squares (Mon .. Sun) with clean 4dp horizontal margins
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final dayNum = i + 1;
            final isPast = dayNum < currentWeekday;
            final isToday = dayNum == currentWeekday;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildHabitSquare(
                  isDone: isPast || (isToday && isChecked),
                  isToday: isToday,
                  isChecked: isChecked,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // 4. Row 2: Habit Squares (Cycle / Streak Days)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final row2Done = streak > 7
                ? (i < (streak - 7).clamp(0, 7))
                : (i < streak.clamp(0, currentWeekday));

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildHabitSquare(
                  isDone: row2Done,
                  isToday: false,
                  isChecked: false,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // 5. Footer: "X дн. без спонтанных трат"
        Text(
          '$streak дн. без спонтанных трат',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF9F0A),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitSquare({
    required bool isDone,
    required bool isToday,
    required bool isChecked,
  }) {
    Color bg;
    Border? border;
    Widget? child;

    if (isToday) {
      if (isChecked) {
        bg = const Color(0xFFFF9F0A);
        border = Border.all(color: const Color(0xFFFFB340), width: 0.8);
        child = const Center(
          child: Icon(Icons.check_rounded, size: 10, color: Color(0xFF161412)),
        );
      } else {
        bg = const Color(0xFFFF9F0A).withValues(alpha: 0.18);
        border = Border.all(color: const Color(0xFFFF9F0A), width: 1.2);
      }
    } else if (isDone) {
      bg = const Color(0xFF2EA043);
      border = Border.all(color: const Color(0xFF48C764), width: 0.8);
      child = const Center(
        child: Icon(Icons.check_rounded, size: 10, color: Colors.white),
      );
    } else {
      bg = const Color(0xFF191D24);
      border = Border.all(color: const Color(0xFF2C313A), width: 0.8);
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6.0),
          border: border,
          boxShadow: (isToday && isChecked)
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildQuickActionsWidget(double balance, String accountName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Bar with clean KGS pill badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    '1 ТАП',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFFFF9F0A),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'БЫСТРЫЕ ПЛАТЕЖИ • $accountName',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => AddTransactionModal.show(context, widget.controller),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 12, color: Color(0xFFFF9F0A)),
                    SizedBox(width: 2),
                    Text(
                      'Свой расход',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF9F0A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Text(
          CurrencyFormatter.format(balance),
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),

        // 4 Fast payment tiles
        Row(
          children: [
            _buildQuickTile(
              icon: Icons.directions_bus_rounded,
              iconColor: const Color(0xFF0A84FF),
              title: 'Маршрутка',
              amount: 25.0,
              onTap: () => _executeQuickPayment('Маршрутка', 25.0, 'cat_transport'),
            ),
            const SizedBox(width: 6),
            _buildQuickTile(
              icon: Icons.coffee_rounded,
              iconColor: const Color(0xFFFF9F0A),
              title: 'Кофе',
              amount: 150.0,
              onTap: () => _executeQuickPayment('Кофе', 150.0, 'cat_restaurants'),
            ),
            const SizedBox(width: 6),
            _buildQuickTile(
              icon: Icons.restaurant_rounded,
              iconColor: const Color(0xFFFF453A),
              title: 'Обед',
              amount: 350.0,
              onTap: () => _executeQuickPayment('Обед', 350.0, 'cat_restaurants'),
            ),
            const SizedBox(width: 6),
            _buildQuickTile(
              icon: Icons.local_taxi_rounded,
              iconColor: const Color(0xFFFFD60A),
              title: 'Такси',
              amount: 180.0,
              onTap: () => _executeQuickPayment('Такси', 180.0, 'cat_transport'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double amount,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.heavyImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                '${amount.toInt()} сом',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _executeQuickPayment(String title, double amount, String categoryId) {
    final targetAccount = widget.controller.accounts.isNotEmpty
        ? widget.controller.accounts.first.id
        : 'acc_mbank';
    widget.controller.addTransaction(
      title: title,
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.expense,
      categoryId: categoryId,
      accountId: targetAccount,
      note: 'Быстрый 1-тап с виджета',
    );
    TransactionSuccessOverlay.show(
      context,
      title: title,
      amount: amount,
      bankName: 'Виджет (1 тап)',
      isIncome: false,
    );
  }

  Widget _buildSmallWidget(double balance, String accountName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Row: Title + KGS badge cleanly balanced
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              accountName,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'KGS',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          CurrencyFormatter.format(balance),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        if (_showForecast) ...[
          const SizedBox(height: 4),
          Text(
            'До конца мес.\n~${CurrencyFormatter.format(balance * 0.35)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            if (widget.controller.quickShortcuts.isNotEmpty) {
              final s = widget.controller.quickShortcuts.first;
              widget.controller.executeShortcut(s);
              TransactionSuccessOverlay.show(
                context,
                title: s.title,
                amount: s.amount,
                bankName: 'Виджет iOS',
                isIncome: false,
              );
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_bus_rounded,
                  size: 14,
                  color: AppColors.iosOrange,
                ),
                SizedBox(width: 5),
                Text(
                  'Маршрутка 20 с.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockScreenWidget(double balance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'БАЛАНС',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
            Icon(Icons.lock_rounded, size: 11, color: Colors.white54),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.format(balance),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Лимит в норме',
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
