import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import '../models/quick_payment_shortcut.dart';
import '../models/transaction_type.dart';
import '../models/workout_penalty.dart';
import '../services/clipboard_parser_service.dart';
import '../services/geoshame_service.dart';
import '../services/mbank_parser_service.dart';
import '../services/widget_launch_service.dart';
import '../state/finance_controller.dart';
import '../state/notification_controller.dart';
import '../utils/formatters.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/glass_container.dart';
import '../widgets/ios_push_banner.dart';
import '../widgets/workout_penalty_modal.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'transactions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final FinanceController controller;

  const MainNavigationScreen({super.key, required this.controller});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final NotificationController _notificationController;
  Timer? _clipboardTimer;
  Timer? _permissionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex);
    _notificationController = NotificationController();
    _notificationController.onOpenAddModal = () {
      if (mounted) {
        AddTransactionModal.show(context, widget.controller);
      }
    };
    _notificationController.onWinterCheckIn = () {
      widget.controller.checkInWinterDay();
    };
    _notificationController.onDepositDream = () {
      widget.controller.depositToDreamGoal(100);
    };

    // Initialize Home Screen Widget handler for Android launcher and MBank push receiver
    WidgetLaunchService.initialize(
      onAddTransaction: (type) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              AddTransactionModal.show(context, widget.controller, defaultType: type);
            }
          });
        }
      },
      onWinterCheckinAction: () {
        widget.controller.checkInWinterDay();
      },
      onDepositDreamAction: () {
        widget.controller.depositToDreamGoal(100);
      },
      onWorkoutPenaltyAction: () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final penalty = widget.controller.activeWorkoutPenalty ??
                  WorkoutPenalty(
                    id: 'dictator_wp',
                    title: '20 подтягиваний',
                    reps: 20,
                    exercise: 'подтягиваний',
                    reason: 'Блокиратор соцсетей: перерасход дневного лимита',
                    excessAmount: 0.0,
                    timestamp: DateTime.now(),
                  );
              WorkoutPenaltyModal.show(
                context,
                penalty: penalty,
                controller: widget.controller,
              );
            }
          });
        }
      },
      onBankNotificationAction: (notification) {
        if (mounted) {
          _handleIncomingBankNotification(notification);
        }
      },
      onBankBalanceScrapedAction: (balanceData) {
        if (mounted) {
          _handleIncomingScrapedBalance(balanceData);
        }
      },
      onQuickShortcutAction: (shortcutKey) {
        if (mounted) {
          _handleQuickShortcutExecution(shortcutKey);
        }
      },
    );

    if (widget.controller.isStorageLoaded) {
      WidgetLaunchService.syncBalanceToWidget(
        widget.controller.totalBalance,
        streak: widget.controller.noSpendStreak,
        isWinterChecked: widget.controller.isWinterCheckedToday,
        accountName: widget.controller.activeAccountLabel,
        todaySpent: widget.controller.todaySpentLabel,
        quickButtons: widget.controller.quickButtonsForWidget,
      );
    }

    widget.controller.addListener(_onControllerChanged);
    GeoshameService.init();

    // Process any background MBank notifications, scraped balances, and clipboard expenses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndImportPendingBankNotifications();
      _checkAndImportPendingScrapedBalances();
      _clipboardTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) _checkClipboardForExpense();
      });
      _permissionTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) _checkNotificationListenerOnStartup();
      });
    });
  }

  Future<void> _checkNotificationListenerOnStartup() async {
    if (!mounted) return;

    try {
      final isGranted = await WidgetLaunchService.isNotificationListenerEnabled();
      if (!isGranted && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final lastPrompt = prefs.getInt('arc_listener_last_prompt_ms') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        // Prompt at most once every 24 hours until enabled
        if (now - lastPrompt > 24 * 60 * 60 * 1000 && mounted) {
          await prefs.setInt('arc_listener_last_prompt_ms', now);
          if (mounted) {
            _showNotificationListenerBottomSheet();
          }
        }
      }
    } catch (e) {
      debugPrint('[MainNavigationScreen] Notification listener startup check non-fatal error: $e');
    }
  }

  void _showNotificationListenerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF141417),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                size: 30,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Авто-учет MBank и NFC',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Чтобы ARC Finance автоматически записывал ваши платежи и баланс при оплате картой, через MBank или Google Pay, включите «Доступ к уведомлениям».',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF00E5FF)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'В открывшихся настройках найдите ARC FINANCE и активируйте тумблер',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Позже',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await WidgetLaunchService.openNotificationListenerSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Включить доступ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    _permissionTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    // Check if a Streetlifting Workout Penalty was triggered
    final penalty = widget.controller.activeWorkoutPenalty;
    if (penalty != null && !penalty.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.controller.activeWorkoutPenalty != null) {
          WorkoutPenaltyModal.show(
            context,
            penalty: penalty,
            controller: widget.controller,
          );
        }
      });
    }
  }

  Future<void> _checkClipboardForExpense() async {
    final parsed = await ClipboardParserService.checkClipboard();
    if (parsed == null || !mounted) return;

    _notificationController.showNotification(
      AppNotification(
        id: 'clip_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.hourlyExpense,
        title: 'Добавить ${CurrencyFormatter.format(parsed.amount)} в ${parsed.categoryName}?',
        body: '«${parsed.rawText}»',
        actionLabel: 'Добавить',
        onAction: () {
          _notificationController.dismissActiveNotification();
          final targetAccount = widget.controller.accounts.isNotEmpty
              ? widget.controller.accounts.first.id
              : 'acc_mbank';
          widget.controller.addTransaction(
            title: parsed.title,
            amount: parsed.amount,
            date: DateTime.now(),
            type: TransactionType.expense,
            categoryId: parsed.categoryId,
            accountId: targetAccount,
            note: 'Из буфера: ${parsed.rawText}',
          );
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndImportPendingBankNotifications();
      _checkAndImportPendingScrapedBalances();
      _checkClipboardForExpense();
    }
  }

  void _handleIncomingBankNotification(Map<String, dynamic> raw) {
    final title = raw['title'] as String? ?? '';
    final body = raw['body'] as String? ?? '';
    final fullText = '$title $body'.trim();

    // Ignore self-notifications from our own app
    if (fullText.contains('Баланс автоматически обновлен') ||
        fullText.contains('Записан быстрый расход') ||
        fullText.contains('Синхронизация MBank')) {
      return;
    }

    final parsed = MBankParserService.parse(fullText);
    if (parsed == null) return;

    // Pure balance notification from bank: update account balance safely, NO expense created!
    if (parsed.isBalanceOnly) {
      if (parsed.balanceAfter != null && parsed.balanceAfter! > 0) {
        widget.controller.updateScrapedBankBalance('MBank', parsed.balanceAfter!);
        _notificationController.showNotification(
          AppNotification(
            id: 'mbank_bal_${DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.mbankAutoSync,
            title: 'Баланс MBank: ${CurrencyFormatter.format(parsed.balanceAfter!)}',
            body: 'Баланс счета актуализирован из уведомления',
            actionLabel: 'Смотреть',
            onAction: () {
              _notificationController.dismissActiveNotification();
              _switchTab(0);
            },
          ),
        );
      }
      return;
    }

    final source = raw['source'] as String? ?? 'notification';
    final isScreen = source == 'accessibility_screen';

    widget.controller.addMBankAutoTransaction(
      title: parsed.title,
      amount: parsed.amount,
      type: parsed.type,
      categoryId: parsed.categoryId,
      note: isScreen ? 'Чек с экрана MBank: $fullText' : 'MBank: $fullText',
      balanceAfter: parsed.balanceAfter,
    );

    final sign = parsed.type == TransactionType.income ? '+' : '−';
    final amountText = '$sign${CurrencyFormatter.format(parsed.amount)}';

    _notificationController.showNotification(
      AppNotification(
        id: 'mbank_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.mbankAutoSync,
        title: isScreen
            ? 'Чек MBank: ${parsed.title}'
            : (parsed.isSalary ? 'Зарплата зачислена!' : 'MBank: ${parsed.title}'),
        body: '$amountText • Баланс автоматически обновлен',
        actionLabel: 'Смотреть',
        onAction: () {
          _notificationController.dismissActiveNotification();
          _switchTab(1);
        },
      ),
    );
  }

  void _handleQuickShortcutExecution(String shortcutKey) {
    String title = 'Платеж';
    double amount = 0.0;
    String categoryId = 'cat_restaurants';

    if (shortcutKey.startsWith('debt_reminder:')) {
      final parts = shortcutKey.split(':');
      final parsedAmount = parts.length > 1 ? (double.tryParse(parts[1]) ?? 200.0) : 200.0;
      final parsedPhrase = parts.length > 2 ? parts[2] : 'скинь 200 сом';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AddTransactionModal.show(
            context,
            widget.controller,
            defaultType: TransactionType.income,
            initialAmount: parsedAmount,
            initialTitle: 'Возврат долга / перевод',
            initialNote: 'Из переписки: «$parsedPhrase»',
          );
        }
      });
      return;
    }

    if (shortcutKey.startsWith('shortcut_dynamic:')) {
      final parts = shortcutKey.split(':');
      if (parts.length >= 5) {
        final idx = int.tryParse(parts[1]);
        final parsedTitle = parts[2];
        final parsedAmount = double.tryParse(parts[3]) ?? 0.0;
        final parsedCat = parts[4];

        if (idx != null &&
            idx >= 0 &&
            idx < widget.controller.quickButtonsForWidget.length) {
          final btn = widget.controller.quickButtonsForWidget[idx];
          title = btn.title;
          amount = btn.amount;
          categoryId = btn.categoryId;
        } else if (parsedTitle.isNotEmpty && parsedAmount > 0) {
          title = parsedTitle;
          amount = parsedAmount;
          categoryId = parsedCat.isNotEmpty ? parsedCat : 'cat_restaurants';
        }
      }
    } else {
      switch (shortcutKey) {
        case 'marshrutka':
          title = 'Маршрутка';
          amount = 25.0;
          categoryId = 'cat_transport';
          break;
        case 'coffee':
          title = 'Кофе';
          amount = 150.0;
          categoryId = 'cat_restaurants';
          break;
        case 'lunch':
          title = 'Обед';
          amount = 350.0;
          categoryId = 'cat_restaurants';
          break;
        case 'taxi':
          title = 'Такси';
          amount = 180.0;
          categoryId = 'cat_transport';
          break;
        default:
          final match = widget.controller.quickShortcuts.firstWhere(
            (s) => s.id == shortcutKey || s.title.toLowerCase().contains(shortcutKey),
            orElse: () => widget.controller.quickShortcuts.isNotEmpty
                ? widget.controller.quickShortcuts.first
                : QuickPaymentShortcut(
                    id: 'q_default',
                    title: 'Быстрый расход',
                    amount: 50.0,
                    categoryId: 'cat_restaurants',
                    accountId: 'acc_mbank',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFF9F0A),
                  ),
          );
          title = match.title;
          amount = match.amount;
          categoryId = match.categoryId;
          break;
      }
    }

    if (amount <= 0) return;

    HapticFeedback.heavyImpact();
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
      note: 'Быстрый 1-тап с виджета рабочего стола',
    );

    _notificationController.showNotification(
      AppNotification(
        id: 'quick_widget_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.hourlyExpense,
        title: 'Записан быстрый платеж',
        body: '$title: −${CurrencyFormatter.format(amount)} • Баланс списан',
        actionLabel: 'К операциям',
        onAction: () {
          _notificationController.dismissActiveNotification();
          _switchTab(1);
        },
      ),
    );
  }

  Future<void> _checkAndImportPendingBankNotifications() async {
    final rawPending = await WidgetLaunchService.getPendingBankNotifications();
    await WidgetLaunchService.clearPendingBankNotifications();
    if (rawPending.isEmpty || rawPending == '[]') return;

    try {
      final decoded = jsonDecode(rawPending);
      if (decoded is List && decoded.isNotEmpty) {
        int importedCount = 0;
        final Set<String> batchSeenSignatures = {};
        for (final item in decoded) {
          if (item is Map) {
            final title = item['title'] as String? ?? '';
            final body = item['body'] as String? ?? '';
            final fullText = '$title $body'.trim();

            if (fullText.contains('Баланс автоматически обновлен') ||
                fullText.contains('Записан быстрый расход') ||
                fullText.contains('Синхронизация MBank')) {
              continue;
            }

            final source = item['source'] as String? ?? 'notification';
            final isScreen = source == 'accessibility_screen';

            final parsed = MBankParserService.parse(fullText);
            if (parsed != null) {
              if (parsed.isBalanceOnly) {
                if (parsed.balanceAfter != null && parsed.balanceAfter! > 0) {
                  widget.controller.updateScrapedBankBalance('MBank', parsed.balanceAfter!);
                }
                continue;
              }

              // Deduplicate within the same pending batch (e.g. screen receipt + push notification for same purchase)
              final batchSig = '${parsed.amount.toStringAsFixed(2)}_${parsed.type.name}';
              if (batchSeenSignatures.contains(batchSig)) {
                if (parsed.balanceAfter != null && parsed.balanceAfter! > 0) {
                  widget.controller.updateScrapedBankBalance('MBank', parsed.balanceAfter!);
                }
                continue;
              }
              batchSeenSignatures.add(batchSig);

              widget.controller.addMBankAutoTransaction(
                title: parsed.title,
                amount: parsed.amount,
                type: parsed.type,
                categoryId: parsed.categoryId,
                note: isScreen ? 'Чек с экрана MBank: $fullText' : 'MBank: $fullText',
                balanceAfter: parsed.balanceAfter,
              );
              importedCount++;
            }
          }
        }

        if (importedCount > 0 && mounted) {
          _notificationController.showNotification(
            AppNotification(
              id: 'mbank_pending_${DateTime.now().millisecondsSinceEpoch}',
              type: NotificationType.mbankAutoSync,
              title: 'Синхронизация MBank',
              body: 'Автоматически импортировано операций: $importedCount',
              actionLabel: 'К операциям',
              onAction: () {
                _notificationController.dismissActiveNotification();
                _switchTab(1);
              },
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _handleIncomingScrapedBalance(Map<String, dynamic> data) {
    final bank = data['bank'] as String? ?? 'MBank';
    final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
    if (balance <= 0) return;

    final updated = widget.controller.updateScrapedBankBalance(bank, balance);
    if (updated && mounted) {
      _notificationController.showNotification(
        AppNotification(
          id: 'scraped_bal_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.mbankAutoSync,
          title: 'Теневой скрапинг: $bank',
          body: '${CurrencyFormatter.format(balance)} • Синхронизировано с экрана банка',
          actionLabel: 'Баланс',
          onAction: () {
            _notificationController.dismissActiveNotification();
            _switchTab(0);
          },
        ),
      );
    }
  }

  Future<void> _checkAndImportPendingScrapedBalances() async {
    final rawJson = await WidgetLaunchService.getPendingScrapedBalances();
    if (rawJson.isEmpty || rawJson == '{}') return;

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        await WidgetLaunchService.clearPendingScrapedBalances();
        _handleIncomingScrapedBalance(decoded);
      }
    } catch (_) {}
  }

  List<Widget> _buildScreens() {
    return [
      DashboardScreen(
        controller: widget.controller,
        onSeeAllTransactions: () => _switchTab(1),
        notificationController: _notificationController,
      ),
      TransactionsScreen(controller: widget.controller),
      AnalyticsScreen(controller: widget.controller),
      ProfileScreen(
        controller: widget.controller,
        notificationController: _notificationController,
      ),
    ];
  }

  void _switchTab(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      final previous = _currentIndex;
      setState(() {
        _currentIndex = index;
      });
      if (_pageController.hasClients) {
        if ((index - previous).abs() > 1) {
          _pageController.jumpToPage(index);
        } else {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, _notificationController]),
      builder: (context, _) {
        return GlassBackgroundScaffold(
          child: Stack(
            children: [
              // Screen contents centered with responsive max width for Web & Desktop (Smooth PageView)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: _buildScreens(),
                  ),
                ),
              ),

              // Interactive iOS Dynamic Push Banner (Positioned top, animated)
              if (_notificationController.activeBannerNotification != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: IosPushBanner(
                        notification: _notificationController.activeBannerNotification!,
                        onDismiss: () => _notificationController.dismissActiveNotification(),
                      ),
                    ),
                  ),
                ),

              // Floating Action Button (+) for instant Quick Add (warm Capybara Amber)
              Positioned(
                right: 20,
                bottom: 94,
                child: FloatingActionButton(
                  heroTag: 'main_fab_add',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    AddTransactionModal.show(context, widget.controller);
                  },
                  backgroundColor: const Color(0xFFFF9F0A),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: const Color(0xFFFF9F0A).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF161412),
                    size: 28,
                  ),
                ),
              ),

              // Floating Matte Frosted Glass Dock (4 Dedicated Tabs: Обзор, Операции, Аналитика, Профиль)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassContainer(
                        height: 62,
                        borderRadius: BorderRadius.circular(22),
                        blur: 20,
                        surfaceColor: const Color(0xFF141416).withValues(alpha: 0.94),
                        borderColor: const Color(0xFFFF9F0A).withValues(alpha: 0.20),
                        borderWidth: 0.8,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavItem(
                              index: 0,
                              icon: Icons.grid_view_rounded,
                              label: 'Обзор',
                            ),
                            _buildNavItem(
                              index: 1,
                              icon: Icons.receipt_long_rounded,
                              label: 'Операции',
                            ),
                            _buildNavItem(
                              index: 2,
                              icon: Icons.pie_chart_rounded,
                              label: 'Аналитика',
                            ),
                            _buildNavItem(
                              index: 3,
                              icon: Icons.person_rounded,
                              label: 'Профиль',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _switchTab(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: isSelected ? const Color(0xFFFF9F0A) : Colors.white.withValues(alpha: 0.38),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                    color: isSelected ? const Color(0xFFFF9F0A) : Colors.white.withValues(alpha: 0.38),
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
