import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_type.dart';
import '../services/mbank_parser_service.dart';
import '../services/widget_launch_service.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/glass_container.dart';

class MBankSyncScreen extends StatefulWidget {
  final FinanceController controller;

  const MBankSyncScreen({super.key, required this.controller});

  @override
  State<MBankSyncScreen> createState() => _MBankSyncScreenState();
}

class _MBankSyncScreenState extends State<MBankSyncScreen> with WidgetsBindingObserver {
  bool _isAccessibilityEnabled = false;
  bool _isListenerEnabled = false;
  bool _canDrawOverlays = false;
  List<Map<String, dynamic>> _pendingNotifications = [];

  final TextEditingController _testTextController = TextEditingController();
  ParsedMBankNotification? _parsedTestResult;

  final List<String> _sampleNotifications = [
    'Чек с экрана: Оплата Globus 1 250 сом успешно проведена. Доступно: 51 050 сом',
    'Квитанция: Оплата Фаиза 650 сом. Чек №4819. Баланс: 42 100 сом',
    'Оплата Фрунзе 1 420 сом проведена успешно. Остаток: 40 680 сом',
    'Списание 230 сом. Яндекс Такси. Баланс: 40 450 сом',
    'Чек: Оплата Wildberries 3 500 сом выполнено. Доступно: 36 950 сом',
    'Квитанция: Аптека Неман 850 сом. Оплата прошла. Баланс: 36 100 сом',
    'MBank: Зачисление зарплаты 45 000 сом. Баланс: 81 100 сом',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndPending();

    // Default test text
    _testTextController.text = _sampleNotifications[0];
    _updateParsedResult(_testTextController.text);

    _testTextController.addListener(() {
      _updateParsedResult(_testTextController.text);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _testTextController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndPending();
    }
  }

  Future<void> _checkPermissionAndPending() async {
    final accessibilityEnabled = await WidgetLaunchService.isAccessibilityServiceEnabled();
    final listenerEnabled = await WidgetLaunchService.isNotificationListenerEnabled();
    final canDrawOverlays = await WidgetLaunchService.canDrawOverlays();
    final rawPending = await WidgetLaunchService.getPendingBankNotifications();

    List<Map<String, dynamic>> pendingList = [];
    try {
      final decoded = jsonDecode(rawPending);
      if (decoded is List) {
        pendingList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isAccessibilityEnabled = accessibilityEnabled;
        _isListenerEnabled = listenerEnabled;
        _canDrawOverlays = canDrawOverlays;
        _pendingNotifications = pendingList;
      });
    }
  }

  void _updateParsedResult(String text) {
    final parsed = MBankParserService.parse(text);
    if (mounted) {
      setState(() {
        _parsedTestResult = parsed;
      });
    }
  }

  Future<void> _importPendingNotifications() async {
    if (_pendingNotifications.isEmpty) return;
    HapticFeedback.heavyImpact();

    int count = 0;
    for (final notif in _pendingNotifications) {
      final title = notif['title'] as String? ?? '';
      final body = notif['body'] as String? ?? '';
      final source = notif['source'] as String? ?? 'notification';
      final text = '$title $body'.trim();

      final parsed = MBankParserService.parse(text);
      if (parsed != null) {
        final origin = source == 'accessibility_screen' ? 'Экран MBank' : 'Push MBank';
        widget.controller.addMBankAutoTransaction(
          title: parsed.title,
          amount: parsed.amount,
          type: parsed.type,
          categoryId: parsed.categoryId,
          note: '$origin: $text',
          balanceAfter: parsed.balanceAfter,
        );
        count++;
      }
    }

    await WidgetLaunchService.clearPendingBankNotifications();
    await _checkPermissionAndPending();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.income, width: 1),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Успешно зачислено операций: $count',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _applyParsedToBalance() {
    if (_parsedTestResult == null) return;
    HapticFeedback.mediumImpact();

    widget.controller.addMBankAutoTransaction(
      title: _parsedTestResult!.title,
      amount: _parsedTestResult!.amount,
      type: _parsedTestResult!.type,
      categoryId: _parsedTestResult!.categoryId,
      note: 'Тестовый парсер: ${_parsedTestResult!.rawText}',
      balanceAfter: _parsedTestResult!.balanceAfter,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: _parsedTestResult!.type == TransactionType.income
                ? AppColors.income
                : AppColors.expense,
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Icon(
              _parsedTestResult!.type == TransactionType.income
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: _parsedTestResult!.type == TransactionType.income
                  ? AppColors.income
                  : AppColors.expense,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Зачислено: ${_parsedTestResult!.title} (${CurrencyFormatter.format(_parsedTestResult!.amount)})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Синхронизация MBank',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Проверить статус',
            onPressed: _checkPermissionAndPending,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Accessibility Service Screen Scanner (PRIMARY & MOST RELIABLE)
              _buildAccessibilityGatewayCard(),
              const SizedBox(height: 16),

              // 2. Pre-transaction Capybara-Filter (SYSTEM_ALERT_WINDOW)
              _buildCapybaraFilterCard(),
              const SizedBox(height: 16),

              // 3. Shadow Scraping of Total Balances
              _buildShadowScrapingCard(),
              const SizedBox(height: 16),

              // 4. Notification Listener Service (SECONDARY / FALLBACK FOR SLEEPING SCREEN)
              _buildNotificationListenerCard(),
              const SizedBox(height: 16),

              // 5. Battery Optimization & Auto-start Protection (OEM Guard)
              _buildBatteryOptimizationGuideCard(),
              const SizedBox(height: 16),

              // 3. Pending Queue Card
              if (_pendingNotifications.isNotEmpty) ...[
                _buildPendingQueueCard(),
                const SizedBox(height: 16),
              ],

              // 4. Test Sandbox / Simulator
              _buildSandboxSection(),
              const SizedBox(height: 20),

              // 5. Instructions and Privacy Notice
              _buildPrivacyNotice(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Primary Gateway: Accessibility Service (screen-level view node reader)
  Widget _buildAccessibilityGatewayCard() {
    final isEnabled = _isAccessibilityEnabled;
    const accentColor = Color(0xFF00C7BE); // Premium Cupertino Teal
    final statusColor = isEnabled ? AppColors.income : const Color(0xFFFF9F0A);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF142426).withValues(alpha: 0.95),
            const Color(0xFF121A1C).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: isEnabled
              ? AppColors.income.withValues(alpha: 0.45)
              : accentColor.withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  isEnabled ? Icons.document_scanner_rounded : Icons.visibility_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Шлюз чтения экрана',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Спец. возможности',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isEnabled ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEnabled ? 'Активен • Чтение чеков включено' : 'Не активен • Рекомендуется',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Detailed Explanation
          Text(
            isEnabled
                ? 'Служба активна! Каждый раз, когда в приложении MBank отображается квитанция или успешный перевод (Globus, кафе, переводы, зарплата), данные считываются прямо из интерфейса и мгновенно вносятся в баланс.'
                : 'Android (HyperOS, Vivo, Xiaomi, OneUI) часто «усыпляет» приложения и задерживает пуши. Служба специальных возможностей работает на системном уровне и считывает чек сразу в момент оплаты внутри MBank.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // 3 Feature Bullets
          _buildFeatureBullet(
            icon: Icons.flash_on_rounded,
            title: '100% надежность без зависимости от пуш-уведомлений',
            color: accentColor,
          ),
          const SizedBox(height: 6),
          _buildFeatureBullet(
            icon: Icons.battery_charging_full_rounded,
            title: 'Иммунитет к системной оптимизации батареи Android',
            color: accentColor,
          ),
          const SizedBox(height: 6),
          _buildFeatureBullet(
            icon: Icons.shield_rounded,
            title: '100% локально — данные остаются исключительно на устройстве',
            color: accentColor,
          ),
          const SizedBox(height: 16),

          // Enable Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.selectionClick();
                await WidgetLaunchService.openAccessibilitySettings();
              },
              icon: Icon(
                isEnabled ? Icons.tune_rounded : Icons.accessibility_new_rounded,
                size: 18,
                color: const Color(0xFF161412),
              ),
              label: Text(
                isEnabled
                    ? 'Открыть настройки Спец. возможностей Android'
                    : 'Включить шлюз экрана в Спец. возможностях',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF161412),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled ? AppColors.income : accentColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }

  /// Feature 1: Pre-transaction Capybara-Filter (SYSTEM_ALERT_WINDOW)
  Widget _buildCapybaraFilterCard() {
    final isOverlayGranted = _canDrawOverlays;
    const accentColor = Color(0xFFFF9F0A); // Apple Amber / Gold
    final statusColor = isOverlayGranted ? AppColors.income : accentColor;
    final dreamGoal = widget.controller.savingsGoals.isNotEmpty
        ? widget.controller.savingsGoals.first.title
        : 'MacBook Pro M3';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF261C14).withValues(alpha: 0.95),
            const Color(0xFF1A1412).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: isOverlayGranted
              ? AppColors.income.withValues(alpha: 0.45)
              : accentColor.withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Капибара-фильтр (До оплаты)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'WINTER ARC',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isOverlayGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isOverlayGranted
                                ? 'Окно активно • Импульсы блокируются'
                                : 'Требуется разрешение SYSTEM_ALERT_WINDOW',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Detailed Explanation
          Text(
            'Сервис перехватывает экран подтверждения ДО того, как деньги уйдут со счёта. Если вы совершаете перевод или оформляете заказ в MBank, Optima или Wildberries на сумму от 500 сом, поверх экрана всплывает системное окно: «Точно переводим? А как же цель на $dreamGoal?». Кнопка «Подумать ещё» нажимает кнопку Назад и отменяет платеж!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          _buildFeatureBullet(
            icon: Icons.back_hand_rounded,
            title: 'Предотвращение импульсивных трат прямо в интерфейсе банка',
            color: accentColor,
          ),
          const SizedBox(height: 6),
          _buildFeatureBullet(
            icon: Icons.layers_rounded,
            title: 'Системное окно поверх банков, Wildberries и Ozon',
            color: accentColor,
          ),
          const SizedBox(height: 6),
          _buildFeatureBullet(
            icon: Icons.flag_rounded,
            title: 'Прямая защита цели «$dreamGoal» и дисциплины Winter Arc',
            color: accentColor,
          ),
          const SizedBox(height: 16),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.selectionClick();
                await WidgetLaunchService.requestOverlayPermission();
              },
              icon: Icon(
                isOverlayGranted ? Icons.check_circle_rounded : Icons.open_in_new_rounded,
                size: 18,
                color: const Color(0xFF161412),
              ),
              label: Text(
                isOverlayGranted
                    ? 'Окно поверх других приложений разрешено'
                    : 'Разрешить показ поверх других приложений',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF161412),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOverlayGranted ? AppColors.income : accentColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Feature 2: Shadow Balance Scraping (Bank Home / Dashboard)
  Widget _buildShadowScrapingCard() {
    final isEnabled = _isAccessibilityEnabled;
    const accentColor = Color(0xFF00C7BE);
    final statusColor = isEnabled ? AppColors.income : const Color(0xFFFF9F0A);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF122224).withValues(alpha: 0.95),
            const Color(0xFF10191B).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: isEnabled
              ? AppColors.income.withValues(alpha: 0.45)
              : accentColor.withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.sync_alt_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Теневой скрапинг баланса',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'АВТОСВЕРКА',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isEnabled ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isEnabled
                                ? 'Считывание с экрана банка включено'
                                : 'Требуется включить шлюз экрана выше',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'Когда вы просто заходите на главную страницу MBank, Optima или Bakai Bank, сервис тихо считывает верхние остатки по картам и автоматически обновляет ваш капитал в ARC Finance. Больше никакой ручной сверки!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          _buildFeatureBullet(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Автоматическая сверка капитала при каждом открытии банка',
            color: accentColor,
          ),
          const SizedBox(height: 6),
          _buildFeatureBullet(
            icon: Icons.auto_awesome_rounded,
            title: 'Синхронизация баланса без единого ручного ввода',
            color: accentColor,
          ),
        ],
      ),
    );
  }

  /// Secondary Gateway: Notification Listener (Push Interceptor)
  Widget _buildNotificationListenerCard() {
    final isEnabled = _isListenerEnabled;
    final color = isEnabled ? AppColors.income : const Color(0xFFFF9F0A);

    return GlassContainer(
      borderRadius: BorderRadius.circular(22),
      surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.75),
      padding: const EdgeInsets.all(18),
      borderColor: color.withValues(alpha: 0.3),
      borderWidth: 1.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Резервный перехват Push-уведомлений',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnabled ? 'Фоновая служба активна' : 'Доступ к уведомлениям отключен',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Служит резервным каналом для входящих переводов, когда экран заблокирован.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                HapticFeedback.selectionClick();
                await WidgetLaunchService.openNotificationListenerSettings();
              },
              icon: Icon(
                isEnabled ? Icons.settings_rounded : Icons.lock_open_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                isEnabled ? 'Настройки доступа к уведомлениям' : 'Разрешить доступ к пушам',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Battery Optimization & Auto-start Protection Guide
  Widget _buildBatteryOptimizationGuideCard() {
    const accentColor = Color(0xFFFF9F0A);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF261C12).withValues(alpha: 0.9),
            const Color(0xFF1C1410).withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.battery_charging_full_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Защита от сброса (Vivo / Xiaomi)',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Предотвращение усыпления служб системой',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Прошивки OriginOS, HyperOS и OneUI могут отключать службы после перезагрузки телефона ради экономии батареи. Чтобы шлюз никогда не выключался, выдайте следующие разрешения:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureBullet(
            icon: Icons.lock_outline_rounded,
            title: '1. Повесьте «замок» на ARC Finance в меню недавних приложений',
            color: accentColor,
          ),
          const SizedBox(height: 6),
          _buildFeatureBullet(
            icon: Icons.play_arrow_rounded,
            title: '2. Включите «Автозапуск» (Auto-start) в свойствах приложения',
            color: accentColor,
          ),
          const SizedBox(height: 6),
          _buildFeatureBullet(
            icon: Icons.battery_alert_rounded,
            title: '3. Контроль активности батареи: «Нет ограничений» (No restrictions)',
            color: accentColor,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.selectionClick();
                await WidgetLaunchService.openBatterySettings();
              },
              icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF161412)),
              label: const Text(
                'Открыть настройки батареи и автозапуска',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF161412),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingQueueCard() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(22),
      surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.75),
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.iosBlue.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: AppColors.iosBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Найдено в очереди: ${_pendingNotifications.length} операций',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Эти операции поступили, пока приложение было закрыто. Вы можете зачислить их в один клик.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),

          // Items preview list
          ..._pendingNotifications.take(4).map((item) {
            final title = item['title'] as String? ?? '';
            final body = item['body'] as String? ?? '';
            final source = item['source'] as String? ?? 'notification';
            final isScreen = source == 'accessibility_screen';

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isScreen ? Icons.document_scanner_rounded : Icons.notifications_rounded,
                    size: 15,
                    color: isScreen ? const Color(0xFF00C7BE) : AppColors.iosBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$title: $body',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isScreen ? const Color(0xFF00C7BE) : AppColors.iosBlue)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isScreen ? 'ЭКРАН' : 'ПУШ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isScreen ? const Color(0xFF00C7BE) : AppColors.iosBlue,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _importPendingNotifications,
                  icon: const Icon(Icons.done_all_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Импортировать все',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.iosBlue,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  await WidgetLaunchService.clearPendingBankNotifications();
                  await _checkPermissionAndPending();
                },
                child: Text(
                  'Очистить',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSandboxSection() {
    final parsed = _parsedTestResult;

    return GlassContainer(
      borderRadius: BorderRadius.circular(22),
      surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.7),
      padding: const EdgeInsets.all(18),
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.capybaraAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science_rounded, color: AppColors.capybaraAmber, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Песочница: Проверка текста с экрана или SMS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Нажмите на готовый шаблон или вставьте текст квитанции:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),

          // Sample chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sampleNotifications.map((sample) {
                final isSelected = _testTextController.text == sample;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _testTextController.text = sample;
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.capybaraAmber.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.capybaraAmber.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        sample.length > 28 ? '${sample.substring(0, 28)}...' : sample,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.capybaraAmber : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Input field
          TextField(
            controller: _testTextController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Вставьте текст квитанции или уведомления...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.capybaraAmber),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Parsed output card
          if (parsed != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (parsed.type == TransactionType.income ? AppColors.income : AppColors.expense)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (parsed.type == TransactionType.income ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            parsed.type == TransactionType.income
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 16,
                            color: parsed.type == TransactionType.income
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            parsed.type == TransactionType.income ? 'ДОХОД' : 'РАСХОД',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: parsed.type == TransactionType.income
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                          ),
                          if (parsed.isSalary) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.capybaraAmber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ЗАРПЛАТА',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.capybaraAmber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${parsed.type == TransactionType.income ? '+' : '−'}${CurrencyFormatter.format(parsed.amount)}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: parsed.type == TransactionType.income
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Название: ${parsed.title}',
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  if (parsed.balanceAfter != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Баланс после операции: ${CurrencyFormatter.format(parsed.balanceAfter!)}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                  if (parsed.cardLastDigits != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Карта: *${parsed.cardLastDigits}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _applyParsedToBalance,
                      icon: const Icon(Icons.add_task_rounded, size: 16, color: Colors.black),
                      label: const Text(
                        'Зачислить в баланс прямо сейчас',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.capybaraAmber,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Сумма в сомах или KGS не обнаружена в тексте. Введите, например: "MBank: Оплата 1250 сом, Globus".',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(22),
      surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.5),
      padding: const EdgeInsets.all(16),
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.income, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Конфиденциальность и Безопасность',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Никаких паролей и логинов: приложение не имеет доступа к вашему аккаунту MBank.\n'
            '• 100% офлайн: чеки и уведомления считываются прямо в оперативной памяти телефона и никуда не передаются через интернет.\n'
            '• Строгий фильтр: анализируются только окна с подтверждением платежей и чеками в банковских приложениях.',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
