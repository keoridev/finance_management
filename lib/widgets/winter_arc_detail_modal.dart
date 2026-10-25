import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'transaction_success_overlay.dart';

class WinterArcDetailModal extends StatelessWidget {
  final FinanceController controller;

  const WinterArcDetailModal({super.key, required this.controller});

  static Future<void> show(BuildContext context, FinanceController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => WinterArcDetailModal(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = controller.noSpendStreak;
    final progress = controller.winterArcProgress;
    final isChecked = controller.isWinterCheckedToday;
    final rank = controller.winterArcRankTitle;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 18),

            // Header with Fire Badge
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.iosOrange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.iosOrange.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.iosOrange,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Winter Arc: Протокол 90 дней',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Ранг: $rank',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.iosOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 90-Day Progress Bar & Streak Stat Card
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(20),
              surfaceColor: Colors.white.withValues(alpha: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Серия дней',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$streak / ${controller.winterArcTargetDays} дн.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        widthFactor: progress,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.iosOrange, Color(0xFFFF453A)],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.iosOrange.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Milestones
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('7 дн: Искра', style: TextStyle(fontSize: 10, color: Colors.white54)),
                      Text('21 дн: Фокус', style: TextStyle(fontSize: 10, color: Colors.white54)),
                      Text('90 дн: Мастер', style: TextStyle(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rules Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Правила зимнего протокола:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRuleRow(Icons.block_rounded, 'Ноль спонтанных покупок и эмоциональных трат'),
                  _buildRuleRow(Icons.shield_rounded, '1 щит заморозки серии при форс-мажоре (${controller.winterShields} доступно)'),
                  _buildRuleRow(Icons.savings_rounded, 'Все сохраненные сомы направляются на мечту'),
                  _buildRuleRow(Icons.alarm_on_rounded, 'Обязательный вечерний чекин до 23:59'),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Check-in Action Button
            InkWell(
              onTap: () {
                HapticFeedback.heavyImpact();
                controller.checkInWinterDay();
                Navigator.of(context).pop();
                TransactionSuccessOverlay.show(
                  context,
                  title: 'День $streak зафиксирован!',
                  amount: 0,
                  bankName: 'Winter Arc Дисциплина',
                  isIncome: true,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: isChecked
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.iosOrange, Color(0xFFFF5E3A)],
                        ),
                  color: isChecked ? Colors.white.withValues(alpha: 0.12) : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isChecked
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.iosOrange.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isChecked ? Icons.check_circle_rounded : Icons.check_rounded,
                      color: isChecked ? AppColors.income : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isChecked
                          ? 'Сегодня уже зафиксировано'
                          : 'Зафиксировать день без спонтанных трат',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isChecked ? Colors.white70 : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.restart_alt_rounded, color: AppColors.expense, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Сбросить Winter Arc?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'Если произошел срыв или непредвиденная эмоциональная трата — начни заново с Дня 0. Честность с собой — основа настоящей дисциплины.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: Text(
                            'Отмена',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.expense,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            controller.resetWinterStreak();
                            Navigator.of(dialogCtx).pop(); // Close dialog
                            Navigator.of(context).pop(); // Close detail bottom sheet
                          },
                          child: const Text('Сбросить на 0'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(
                  Icons.restart_alt_rounded,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                label: Text(
                  'Сбросить стрик на День 0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.iosOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
