import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'transaction_success_overlay.dart';

class WinterArcHabitGrid extends StatelessWidget {
  final FinanceController controller;

  const WinterArcHabitGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final streak = controller.noSpendStreak;
    final isChecked = controller.isWinterCheckedToday;
    final rank = controller.winterArcRankTitle;
    final daysTotal = 90;
    final progress = controller.winterArcProgress;
    final shields = controller.winterShields;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(24),
      surfaceColor: const Color(0xFF16181D).withValues(alpha: 0.92),
      borderColor: Colors.white.withValues(alpha: 0.12),
      borderWidth: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Badges (Clean, NO emojis)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EA043).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          size: 15,
                          color: Color(0xFF39D353),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Winter Arc: Дисциплина',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$rank • $streak из $daysTotal дней',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.60),
                    ),
                  ),
                ],
              ),
              // Shield protection badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      size: 12,
                      color: Color(0xFFFF9F0A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Щиты: $shields',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // GitHub-style Habit Contribution Grid (7 rows x 13 columns = 91 days)
          LayoutBuilder(
            builder: (context, constraints) {
              const columns = 13;
              const rows = 7;
              final spacing = 5.0;
              final availableWidth = constraints.maxWidth;
              final tileSize = ((availableWidth - (spacing * (columns - 1))) / columns)
                  .clamp(8.0, 22.0);

              return Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(columns, (colIdx) {
                      return Padding(
                        padding: EdgeInsets.only(right: colIdx < columns - 1 ? spacing : 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(rows, (rowIdx) {
                            final dayNumber = (colIdx * rows) + rowIdx + 1;
                            if (dayNumber > daysTotal) {
                              return SizedBox(width: tileSize, height: tileSize);
                            }

                            final isPassedAndDone = dayNumber <= streak;
                            final isTodayCell = dayNumber == (streak + (isChecked ? 0 : 1));

                            Color cellColor;
                            Border? border;

                            if (isPassedAndDone) {
                              // Vary green intensity slightly for natural GitHub heatmap look
                              final level = (dayNumber % 4);
                              if (level == 0) {
                                cellColor = const Color(0xFF39D353);
                              } else if (level == 1) {
                                cellColor = const Color(0xFF2EA043);
                              } else if (level == 2) {
                                cellColor = const Color(0xFF238636);
                              } else {
                                cellColor = const Color(0xFF0E4429);
                              }
                            } else if (isTodayCell && !isChecked) {
                              cellColor = const Color(0xFFFF9F0A).withValues(alpha: 0.25);
                              border = Border.all(
                                color: const Color(0xFFFF9F0A),
                                width: 1.2,
                              );
                            } else {
                              cellColor = const Color(0xFF161B22);
                              border = Border.all(
                                color: Colors.white.withValues(alpha: 0.04),
                                width: 0.6,
                              );
                            }

                            return Padding(
                              padding: EdgeInsets.only(bottom: rowIdx < rows - 1 ? spacing : 0),
                              child: Container(
                                width: tileSize,
                                height: tileSize,
                                decoration: BoxDecoration(
                                  color: cellColor,
                                  borderRadius: BorderRadius.circular(4.5),
                                  border: border,
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Прогресс: ${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Меньше',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 5),
                  _buildLegendDot(const Color(0xFF161B22)),
                  const SizedBox(width: 3),
                  _buildLegendDot(const Color(0xFF0E4429)),
                  const SizedBox(width: 3),
                  _buildLegendDot(const Color(0xFF26A641)),
                  const SizedBox(width: 3),
                  _buildLegendDot(const Color(0xFF39D353)),
                  const SizedBox(width: 5),
                  Text(
                    'Больше',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: Check-in & Reset
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.checkInWinterDay();
                    TransactionSuccessOverlay.show(
                      context,
                      title: isChecked
                          ? 'День уже отмечен в стрике'
                          : 'День зафиксирован!',
                      amount: 0,
                      bankName: 'Winter Arc Дисциплина',
                      isIncome: true,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? const Color(0xFF2EA043).withValues(alpha: 0.22)
                          : const Color(0xFFFF9F0A),
                      borderRadius: BorderRadius.circular(12),
                      border: isChecked
                          ? Border.all(
                              color: const Color(0xFF39D353).withValues(alpha: 0.4),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isChecked
                                ? Icons.check_circle_rounded
                                : Icons.calendar_today_rounded,
                            size: 15,
                            color: isChecked
                                ? const Color(0xFF39D353)
                                : const Color(0xFF161412),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isChecked
                                ? 'Сегодня зафиксировано'
                                : 'Зафиксировать сегодняшний день',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isChecked
                                  ? const Color(0xFF39D353)
                                  : const Color(0xFF161412),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _confirmReset(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.restart_alt_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Сбросить серию Winter Arc?',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Стрик будет сброшен до 0. Щиты останутся нетронутыми.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.resetWinterStreak();
            },
            child: const Text('Сбросить', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}
