import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_type.dart';
import '../state/finance_controller.dart';
import '../state/notification_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/add_bank_account_modal.dart';
import '../widgets/create_category_modal.dart';
import '../widgets/currency_rates_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/ios_home_widget_preview.dart';
import '../widgets/widget_installation_guide_modal.dart';
import 'mbank_sync_screen.dart';
import 'recurring_payments_screen.dart';
import 'splash_screen.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  final FinanceController controller;
  final NotificationController? notificationController;

  const SettingsScreen({
    super.key,
    required this.controller,
    this.notificationController,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBackgroundScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Настройки и Инструменты',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                // 1. Курс валют (НБКР) — СРАЗУ виден без списков и скрытий
                CurrencyRatesCard(controller: controller),
                const SizedBox(height: 20),

                // 2. Раздел: Виджеты на рабочий стол
                _buildSectionHeader('ВИДЖЕТЫ НА ЭКРАН СМАРТФОНА'),
                const SizedBox(height: 8),
                GlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.widgets_rounded,
                        iconColor: AppColors.capybaraAmber,
                        title: 'Виджеты на рабочий стол',
                        subtitle: 'Предпросмотр, кастомизация и быстрые действия',
                        onTap: () => _showWidgetsModal(context),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.phone_iphone_rounded,
                        iconColor: AppColors.iosBlue,
                        title: 'Инструкция по установке',
                        subtitle: 'Пошаговый гайд для iPhone (iOS 18) и Android',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          WidgetInstallationGuideModal.show(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Раздел: Финансы и счета
                _buildSectionHeader('ФИНАНСЫ И СЧЕТА'),
                const SizedBox(height: 8),
                GlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.account_balance_rounded,
                        iconColor: AppColors.income,
                        title: 'Банки и счета',
                        subtitle: '${controller.accounts.length} активных счетов • Балансы',
                        onTap: () => _showAccountsModal(context),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.category_rounded,
                        iconColor: const Color(0xFFBF5AF2),
                        title: 'Категории расходов и доходов',
                        subtitle: '${controller.categories.where((c) => c.type == TransactionType.expense).length} категорий расходов',
                        onTap: () => _showCategoriesModal(context),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.autorenew_rounded,
                        iconColor: AppColors.capybaraAmber,
                        title: 'Подписки и регулярные платежи',
                        subtitle: '${controller.recurringPayments.length} активных подписок',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => RecurringPaymentsScreen(controller: controller),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.sync_alt_rounded,
                        iconColor: const Color(0xFF00C7BE),
                        title: 'MBank Авто-Синхронизация',
                        subtitle: 'Авто-учет зарплаты и трат через push-уведомления',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => MBankSyncScreen(controller: controller),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 4. Раздел: Уведомления и интерфейс
                _buildSectionHeader('УВЕДОМЛЕНИЯ И ИНТЕРФЕЙС'),
                const SizedBox(height: 8),
                GlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFFF9F0A),
                        title: 'Умные Push-уведомления',
                        subtitle: 'Напоминания о тратах, чекины Winter Arc',
                        onTap: () => _showNotificationsModal(context),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.flash_on_rounded,
                        iconColor: AppColors.iosBlue,
                        title: 'Заставка (Splash Screen)',
                        subtitle: 'Минималистичный вход с тактильным откликом',
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SplashScreen(controller: controller),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 5. Раздел: Данные и система
                _buildSectionHeader('БАЗА ДАННЫХ И РЕЗЕРВНЫЕ КОПИИ'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF30D158).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF30D158).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFF30D158), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Локальная база SQLite (WAL) • ${controller.transactions.length} транзакций под защитой',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF30D158),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.cloud_download_rounded,
                        iconColor: const Color(0xFF30D158),
                        title: 'Создать резервную копию (JSON)',
                        subtitle: 'Экспорт всех данных, истории и счетов в буфер',
                        onTap: () => _showExportBackupModal(context),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.settings_backup_restore_rounded,
                        iconColor: const Color(0xFF0A84FF),
                        title: 'Восстановить из резервной копии',
                        subtitle: 'Импорт JSON-копии и мгновенное обновление базы',
                        onTap: () => _showImportBackupModal(context),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.delete_outline_rounded,
                        iconColor: const Color(0xFFFF453A),
                        title: 'Сбросить данные приложения',
                        subtitle: 'Очистить историю транзакций и вернуть исходное состояние',
                        onTap: () => _confirmResetData(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // ARC Brand Logo Footer
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/app_logo.jpg',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'ARC FINANCE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Версия 2.4.0 • Осознанные финансы и Winter Arc',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 0.6,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white30,
            ),
          ],
        ),
      ),
    );
  }

  // --- Modals for organized subpages ---

  void _showWidgetsModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141417),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.all(18),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Виджеты на рабочий стол',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              IosHomeWidgetPreview(controller: controller),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountsModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF141417),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: const EdgeInsets.all(18),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Банки и счета',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(ctx).pop();
                        AddBankAccountModal.show(context, controller);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.capybaraAmber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.capybaraAmber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded, size: 14, color: AppColors.capybaraAmber),
                            SizedBox(width: 4),
                            Text(
                              'Добавить счет',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.capybaraAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...controller.accounts.map((acc) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: acc.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(acc.type.icon, size: 20, color: acc.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                acc.bankName,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                acc.type.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(acc.balance),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoriesModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141417),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.all(18),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Категории трат',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(ctx).pop();
                      CreateCategoryModal.show(context, controller);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.capybaraAmber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.capybaraAmber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: AppColors.capybaraAmber),
                          SizedBox(width: 4),
                          Text(
                            'Создать',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.capybaraAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.categories
                    .where((c) => c.type == TransactionType.expense)
                    .map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 14, color: c.color),
                        const SizedBox(width: 7),
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsModal(BuildContext context) {
    HapticFeedback.lightImpact();
    final notifCtrl = notificationController;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141417),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Умные напоминания',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildNotificationToggle(
                icon: Icons.access_time_filled_rounded,
                iconColor: const Color(0xFF0A84FF),
                title: 'Ежечасное напоминание о тратах',
                subtitle: '«Ничего не забыли записать?» — каждый 1 час',
                value: notifCtrl?.hourlyReminderEnabled ?? true,
                onChanged: (val) {
                  notifCtrl?.toggleHourlyReminder(val);
                  setModalState(() {});
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.white12),
              ),
              _buildNotificationToggle(
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFFFF9F0A),
                title: 'Winter Arc: Дисциплина',
                subtitle: 'Вечерний чекин и защита серии от срыва',
                value: notifCtrl?.winterArcReminderEnabled ?? true,
                onChanged: (val) {
                  notifCtrl?.toggleWinterArcReminder(val);
                  setModalState(() {});
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.white12),
              ),
              _buildNotificationToggle(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFF30D158),
                title: 'Напоминание о мечте',
                subtitle: '«Пора отложить на мечту» — пополнение копилки',
                value: notifCtrl?.dreamSavingsReminderEnabled ?? true,
                onChanged: (val) {
                  notifCtrl?.toggleDreamSavingsReminder(val);
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await notifCtrl?.requestSystemPermission();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Системные уведомления проверены и включены!'),
                        backgroundColor: AppColors.income,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.capybaraAmber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Разрешить системные Push-уведомления',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF161412),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: (val) {
            HapticFeedback.selectionClick();
            onChanged?.call(val);
          },
          activeTrackColor: AppColors.income,
        ),
      ],
    );
  }

  void _confirmResetData(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF453A), width: 1),
        ),
        title: const Text(
          'Сбросить все данные?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          'Все добавленные транзакции, изменения балансов и история будут стёрты.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.resetAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Данные успешно сброшены к начальным значениям'),
                  backgroundColor: AppColors.income,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF453A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  void _showExportBackupModal(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final backupJson = await StorageService.exportBackup();
    await Clipboard.setData(ClipboardData(text: backupJson));

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161618),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30D158).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF30D158).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Резервная копия создана',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Скопирована в буфер обмена',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF30D158),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Полный снимок базы данных SQLite (счета, история, транзакции, стрик) скопирован в буфер обмена. Вы можете отправить его в Telegram «Избранное», сохранить в Заметки или файл.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatChip(Icons.account_balance_rounded, '${controller.accounts.length} счетов'),
                _buildStatChip(Icons.receipt_long_rounded, '${controller.transactions.length} операций'),
                _buildStatChip(Icons.ac_unit_rounded, '${controller.noSpendStreak} дн. Winter Arc'),
                _buildStatChip(Icons.storage_rounded, 'SQLite WAL v2'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: backupJson));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('JSON-копия снова скопирована в буфер обмена'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF30D158),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                    label: const Text('Скопировать', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.capybaraAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Готово', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImportBackupModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161618),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Восстановление базы',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null && data!.text!.isNotEmpty) {
                        textController.text = data.text!;
                      }
                    },
                    icon: const Icon(Icons.paste_rounded, size: 15, color: AppColors.iosBlue),
                    label: const Text(
                      'Вставить из буфера',
                      style: TextStyle(fontSize: 12.5, color: AppColors.iosBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Вставьте текст резервной копии JSON. Все текущие записи будут безопасно заменены данными из копии.',
                style: TextStyle(fontSize: 12.5, color: Colors.white60, height: 1.35),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                maxLines: 5,
                style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '{\n  "version": "2.4.0",\n  "transactions": [...]\n}',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                  filled: true,
                  fillColor: const Color(0xFF222226),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.iosBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final text = textController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Вставьте текст резервной копии в поле'),
                        backgroundColor: Color(0xFFFF453A),
                      ),
                    );
                    return;
                  }

                  HapticFeedback.heavyImpact();
                  final success = await StorageService.importBackup(text);
                  if (success) {
                    await controller.loadFromStorage();
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('База данных SQLite успешно восстановлена!'),
                          backgroundColor: Color(0xFF30D158),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ошибка: Неверный формат JSON копии'),
                          backgroundColor: Color(0xFFFF453A),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.income,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Восстановить данные',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF242428),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.capybaraAmber),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

