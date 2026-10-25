import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'transaction_success_overlay.dart';
import 'winter_arc_detail_modal.dart';

class WinterArcStreakCard extends StatelessWidget {
  final FinanceController controller;

  const WinterArcStreakCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final streak = controller.noSpendStreak;
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final currentDayIdx = DateTime.now().weekday - 1; // 0..6

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(22),
      surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              WinterArcDetailModal.show(context, controller);
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.iosOrange.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            size: 20,
                            color: AppColors.iosOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Winter Arc: Дисциплина',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Протокол 90 дней • ${controller.winterArcRankTitle}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.iosOrange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.iosOrange.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 14, color: AppColors.iosOrange),
                      const SizedBox(width: 3),
                      Text(
                        '$streak дн.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iosOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Days of Week Tracker Row with adaptive scale and generous breathing room
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isPassed = i <= currentDayIdx;
                final isToday = i == currentDayIdx;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: i == 0 || i == 6 ? 0 : 4),
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday
                              ? AppColors.iosOrange
                              : (isPassed
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.03)),
                          border: Border.all(
                            color: isToday
                                ? AppColors.iosOrange
                                : Colors.white.withValues(alpha: 0.08),
                            width: isToday ? 1.5 : 0.8,
                          ),
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: AppColors.iosOrange.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isPassed
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  // Inactive days have lowered opacity (0.28) so active orange day pops with high contrast
                                  color: isToday ? Colors.black : Colors.white.withValues(alpha: 0.28),
                                )
                              : Text(
                                  '•',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        days[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 22),

          // Action row - spaced out with vertical air
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  streak == 0
                      ? 'Начните 90-дневный Winter Arc сегодня!'
                      : 'День $streak завершен без спонтанных покупок!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Кнопка Сброса (если нужно начать заново)
              if (streak > 0) ...[
                InkWell(
                  onTap: () => _showResetConfirmation(context, controller),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.expense.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restart_alt_rounded, size: 13, color: AppColors.expense),
                        SizedBox(width: 4),
                        Text(
                          'Сброс',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              InkWell(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  final wasChecked = controller.isWinterCheckedToday;
                  controller.checkInWinterDay();
                  TransactionSuccessOverlay.show(
                    context,
                    title: wasChecked
                        ? 'Сегодня уже зафиксировано'
                        : 'День зафиксирован: ${controller.noSpendStreak} дн.!',
                    amount: 0,
                    bankName: 'Winter Arc Дисциплина',
                    isIncome: true,
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'День',
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
          ),
        ],
      ),
    );
  }

  static void _showResetConfirmation(BuildContext context, FinanceController controller) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.of(ctx).pop(),
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
              final messenger = ScaffoldMessenger.maybeOf(context);
              controller.resetWinterStreak();
              Navigator.of(ctx).pop();
              messenger?.showSnackBar(
                const SnackBar(
                  content: Text('Серия Winter Arc сброшена на День 0. Начни с чистого листа!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Сбросить на 0'),
          ),
        ],
      ),
    );
  }
}
