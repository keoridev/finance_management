import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/finance_controller.dart';
import '../state/notification_controller.dart';
import '../theme/app_colors.dart';
import '../utils/capybara_sound.dart';
import '../utils/formatters.dart';
import '../widgets/glass_container.dart';
import '../widgets/ios_home_widget_preview.dart';
import '../widgets/savings_goals_card.dart';
import '../widgets/winter_arc_habit_grid.dart';
import 'ai_roast_screen.dart';
import 'killer_features_screen.dart';
import 'recurring_payments_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final FinanceController controller;
  final NotificationController? notificationController;

  const ProfileScreen({
    super.key,
    required this.controller,
    this.notificationController,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getHealthColor(int health) {
    if (health >= 75) return AppColors.income;
    if (health >= 50) return AppColors.capybaraAmber;
    if (health >= 25) return Colors.orange;
    return AppColors.expense;
  }

  void _depositQuickBoost() {
    HapticFeedback.heavyImpact();
    CapybaraSound.playZenChime();
    widget.controller.depositToDreamGoal(100.0);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E1A16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.income, width: 1),
        ),
        content: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: AppColors.income, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '100 сом отправлено в накопления! Здоровье Капибары укреплено!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final health = widget.controller.capybaraHealth;
    final healthColor = _getHealthColor(health);

    return GlassBackgroundScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Профиль',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 21,
              ),
              tooltip: 'Настройки',
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => SettingsScreen(
                      controller: widget.controller,
                      notificationController: widget.notificationController,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                // 1. Hero Capybara Avatar & Financial Health Card
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(26),
                  surfaceColor: const Color(0xFF181512).withValues(alpha: 0.88),
                  borderColor: AppColors.capybaraAmber.withValues(alpha: 0.35),
                  borderWidth: 1.3,
                  child: Column(
                    children: [
                      // Avatar with generated 3D artwork and warm glow
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: healthColor, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: healthColor.withValues(alpha: 0.45),
                                blurRadius: 22,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              widget.controller.capybaraMoodImagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mood Title & Health Badge
                      Text(
                        widget.controller.capybaraMoodTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: healthColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: healthColor.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 12,
                              color: healthColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'ЗДОРОВЬЕ $health%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: healthColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Health Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: health / 100.0,
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            healthColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Situational Financial Commentary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.capybaraAmber.withValues(
                              alpha: 0.2,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          widget.controller.capybaraMoodComment,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.38,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick Health Boost via Savings Button
                      InkWell(
                        onTap: _depositQuickBoost,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.capybaraAmber,
                                AppColors.capybaraCopper,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.capybaraAmber.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: Color(0xFF161412),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Пополнить копилку (+100 сом) и укрепить здоровье',
                                style: TextStyle(
                                  fontSize: 12,
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
                ),
                const SizedBox(height: 14),

                // 3. Winter Arc Discipline Streak Grid (GitHub Heatmap Squares)
                WinterArcHabitGrid(controller: widget.controller),
                const SizedBox(height: 16),

                // 3.5. Нативные виджеты на рабочий стол
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  surfaceColor: const Color(0xFF181512).withValues(alpha: 0.88),
                  borderColor: AppColors.capybaraAmber.withValues(alpha: 0.25),
                  borderWidth: 1.0,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showWidgetsModal(context);
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.capybaraAmber.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.widgets_rounded,
                          size: 20,
                          color: AppColors.capybaraAmber,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Нативные виджеты на рабочий стол',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Winter Arc (квадраты), Мудрость Капибары, баланс',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Подписки и регулярные платежи Card
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  surfaceColor: const Color(0xFF181512).withValues(alpha: 0.88),
                  borderColor: AppColors.capybaraAmber.withValues(alpha: 0.25),
                  borderWidth: 1.0,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => RecurringPaymentsScreen(
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.capybaraAmber.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.autorenew_rounded,
                          size: 20,
                          color: AppColors.capybaraAmber,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Подписки и регулярные платежи',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.controller.recurringPayments.length} активных • ${CurrencyFormatter.format(widget.controller.totalMonthlyRecurring)} / мес',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Киллер-фичи & Winter Arc Hub
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  surfaceColor: const Color(0xFF181512).withValues(alpha: 0.88),
                  borderColor: const Color(0xFF00C7BE).withValues(alpha: 0.35),
                  borderWidth: 1.2,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => KillerFeaturesScreen(
                          controller: widget.controller,
                          notificationController: widget.notificationController,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C7BE).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 20,
                          color: Color(0xFF00C7BE),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Киллер-фичи & Winter Arc',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF00C7BE),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Chat Head, буфер, округление, гео-шейминг, штраф',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Нейро-прожарка (AI Roast)
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  surfaceColor: const Color(0xFF181512).withValues(alpha: 0.88),
                  borderColor: const Color(0xFFFF453A).withValues(alpha: 0.35),
                  borderWidth: 1.2,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => AIRoastScreen(
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF453A).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          size: 20,
                          color: Color(0xFFFF453A),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Нейро-прожарка (AI Roast)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Токсичный воскресный отчет недели от Капибары',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Цели накоплений (Savings Goals)
                SavingsGoalsCard(controller: widget.controller),
                const SizedBox(height: 16),

                // 6. Total Capital & Financial Stats Card
                GlassContainer(
                  padding: const EdgeInsets.all(18),
                  borderRadius: BorderRadius.circular(22),
                  surfaceColor: const Color(0xFF161412).withValues(alpha: 0.85),
                  borderColor: AppColors.capybaraAmber.withValues(alpha: 0.25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Финансовое состояние',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            'Капитал',
                            CurrencyFormatter.format(
                              widget.controller.totalBalance,
                            ),
                          ),
                          _buildStatItem(
                            'Доходы',
                            CurrencyFormatter.format(
                              widget.controller.periodIncome,
                            ),
                            color: AppColors.income,
                          ),
                          _buildStatItem(
                            'Расходы',
                            CurrencyFormatter.format(
                              widget.controller.periodExpense,
                            ),
                            color: AppColors.expense,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    Color color = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

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
                      fontSize: 16.5,
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
              IosHomeWidgetPreview(controller: widget.controller),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
