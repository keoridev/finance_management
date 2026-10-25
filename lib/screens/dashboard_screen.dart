import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/finance_controller.dart';
import '../state/notification_controller.dart';
import '../theme/app_colors.dart';
import '../models/transaction_type.dart';
import '../widgets/account_card.dart';
import '../widgets/add_bank_account_modal.dart';
import '../widgets/balance_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/glass_skeleton.dart';
import '../widgets/transaction_success_overlay.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/capybara_meme_bubble.dart';
import '../widgets/quick_shortcuts_section.dart';
import 'killer_features_screen.dart';
import 'mbank_sync_screen.dart';
import 'receipt_scanner_screen.dart';
import 'recurring_payments_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  final FinanceController controller;
  final VoidCallback onSeeAllTransactions;
  final NotificationController? notificationController;

  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onSeeAllTransactions,
    this.notificationController,
  });

  String _getMonthName(int month) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = '${_getMonthName(now.month)} ${now.year}';
    final recentTransactions = controller.transactions.take(5).toList();

    if (controller.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Загрузка...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const DashboardSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.iosBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/app_logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Финансы',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          // Subscriptions icon button - dedicated page for recurring payments
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            tooltip: 'Подписки и регулярные платежи',
            icon: const Icon(
              Icons.autorenew_rounded,
              color: AppColors.capybaraAmber,
              size: 21,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) =>
                      RecurringPaymentsScreen(controller: controller),
                ),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            tooltip: 'AR-сканер чеков (Vision AI)',
            icon: const Icon(
              Icons.document_scanner_rounded,
              color: Color(0xFF00C7BE),
              size: 21,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => ReceiptScannerScreen(controller: controller),
                ),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            tooltip: 'Киллер-фичи & Winter Arc',
            icon: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF00C7BE),
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => KillerFeaturesScreen(
                    controller: controller,
                    notificationController: notificationController,
                  ),
                ),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            tooltip: 'Настройки и виджеты',
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 21),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => SettingsScreen(
                    controller: controller,
                    notificationController: notificationController,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1C1C1E),
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await controller.simulateLoading();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. Главный верхний блок: Общий баланс
            BalanceCard(
              title: controller.activeAccountLabel,
              totalBalance: controller.activeBalance,
              periodIncome: controller.periodIncome,
              periodExpense: controller.periodExpense,
              periodLabel: controller.selectedAccountId != null
                  ? '${controller.activeAccountLabel} • ${controller.selectedPeriod.label}'
                  : controller.selectedPeriod.label,
            ),
            const SizedBox(height: 14),

            // 2. Интерактивная мысль и мем Капибары
            CapybaraMemeBubble(controller: controller),
            const SizedBox(height: 18),

            // 3. Быстрые платежи в 1 тап (Маршрутка, Кофе, Обед...)
            QuickShortcutsSection(controller: controller),
            const SizedBox(height: 18),

            // 4. Счета и Банки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Мои банки и счета',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => MBankSyncScreen(controller: controller),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C7BE).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00C7BE).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync_rounded,
                              size: 13,
                              color: Color(0xFF00C7BE),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'MBank Авто',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00C7BE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AddBankAccountModal.show(context, controller);
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
                            'Добавить',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.accounts.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == controller.accounts.length) {
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AddBankAccountModal.show(context, controller);
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_card_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Свой банк',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final account = controller.accounts[index];
                  final isSelected = controller.selectedAccountId == account.id;
                  return AccountCard(
                    account: account,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (isSelected) {
                        controller.setSelectedAccount(null);
                      } else {
                        controller.setSelectedAccount(account.id);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 5. Последние операции
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Последние операции',
                    style: TextStyle(
                      fontSize: 16,
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
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSeeAllTransactions();
                  },
                  child: Text(
                    'Все операции',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EmptyStateView(
                  icon: Icons.receipt_long_rounded,
                  title: 'Пока нет операций',
                  subtitle:
                      'Нажмите кнопку «+» внизу, чтобы добавить первую транзакцию',
                ),
              )
            else
              ...recentTransactions.map((tx) {
                final category = controller.getCategoryById(tx.categoryId);
                final account = controller.getAccountById(tx.accountId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionTile(
                    transaction: tx,
                    category: category,
                    account: account,
                    onDelete: () => controller.deleteTransaction(tx.id),
                    onDuplicate: () {
                      controller.duplicateTransaction(tx);
                      TransactionSuccessOverlay.show(
                        context,
                        title: 'Операция повторена',
                        amount: tx.amount,
                        bankName: account?.bankName ?? '',
                        isIncome: tx.type == TransactionType.income,
                      );
                    },
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
