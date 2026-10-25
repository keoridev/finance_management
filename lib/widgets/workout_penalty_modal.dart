import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_penalty.dart';
import '../state/finance_controller.dart';
import '../utils/formatters.dart';

class WorkoutPenaltyModal extends StatelessWidget {
  final WorkoutPenalty penalty;
  final FinanceController controller;

  const WorkoutPenaltyModal({
    super.key,
    required this.penalty,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required WorkoutPenalty penalty,
    required FinanceController controller,
  }) {
    HapticFeedback.heavyImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkoutPenaltyModal(
        penalty: penalty,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFFFF453A), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Glowing badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x26FF453A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF453A), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center_rounded, color: Color(0xFFFF453A), size: 16),
                SizedBox(width: 8),
                Text(
                  'WINTER ARC • ШТРАФ ЗА СРЫВ',
                  style: TextStyle(
                    color: Color(0xFFFF453A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Транзакция одобрена,\nно с тебя 25 подтягиваний!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            '${penalty.reason} (+${CurrencyFormatter.format(penalty.excessAmount)}). Стритлифтинг спасает стрик: выполни подход прямо сейчас!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Exercise requirement card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x1AFF9F0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF9F0A), width: 1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sports_gymnastics_rounded,
                      color: Color(0xFFFF9F0A),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${penalty.reps} ${penalty.exercise}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Или 50 глубоких отжиманий от пола',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x2630D158),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+1 ЩИТ',
                    style: TextStyle(
                      color: Color(0xFF30D158),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Complete Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                controller.completeWorkoutPenalty();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1C1C1E),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF30D158), width: 1.2),
                    ),
                    content: const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Color(0xFF30D158), size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Красавчик! Стрик спасен, начислен +1 Щит!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9F0A),
                foregroundColor: const Color(0xFF000000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Я сделал 25 подтягиваний! (Спасти стрик)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Dismiss Button
          TextButton(
            onPressed: () {
              controller.dismissWorkoutPenalty();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Сдаться и признать срыв',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
