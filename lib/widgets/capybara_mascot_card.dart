import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/finance_controller.dart';
import '../state/notification_controller.dart';
import '../theme/app_colors.dart';
import '../utils/capybara_sound.dart';
import 'glass_container.dart';

class CapybaraMascotCard extends StatefulWidget {
  final FinanceController controller;
  final NotificationController? notificationController;

  const CapybaraMascotCard({
    super.key,
    required this.controller,
    this.notificationController,
  });

  @override
  State<CapybaraMascotCard> createState() => _CapybaraMascotCardState();
}

class _CapybaraMascotCardState extends State<CapybaraMascotCard>
    with TickerProviderStateMixin {
  int _petCount = 0;
  int _adviceIndex = 0;
  bool _showMemeAdvice = false;
  bool _scheduledNotice = false;
  Timer? _noticeTimer;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 0.95), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  void _tapCapybara() {
    HapticFeedback.lightImpact();
    CapybaraSound.playWaterDrop();
    _bounceController.reset();
    _bounceController.forward();
    setState(() => _petCount++);
  }

  void _cycleAdvice() {
    HapticFeedback.lightImpact();
    CapybaraSound.playWaterDrop();
    setState(() {
      _showMemeAdvice = true;
      _adviceIndex++;
    });
  }

  void _onStepActionPressed() {
    HapticFeedback.heavyImpact();
    final step = widget.controller.completeNextDisciplineStep();

    if (step == 1) {
      CapybaraSound.playOrangePop();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF1E1A16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.capybaraAmber, width: 1),
          ),
          content: const Row(
            children: [
              Icon(Icons.looks_one_rounded, color: AppColors.capybaraAmber, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Шаг 1 из 2 выполнен! Сделай второй шаг, чтобы получить похвалу!',
                  style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (step >= 2) {
      CapybaraSound.playZenChime();
      _showDisciplinePraiseDialog();
    }
  }

  void _showDisciplinePraiseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(22),
          borderRadius: BorderRadius.circular(26),
          surfaceColor: const Color(0xFF1C1814).withValues(alpha: 0.96),
          borderColor: AppColors.capybaraAmber.withValues(alpha: 0.45),
          borderWidth: 1.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero artwork of happy capybara
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.capybaraAmber, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.capybaraAmber.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/capy_happy.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Похвала от Капибары!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.capybaraAmber,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: AppColors.income),
                    SizedBox(width: 5),
                    Text(
                      '2 из 2 шагов завершено',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.income),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '«Ты завершил оба шага дисциплины за сегодня! Баланс в сохранности, капибара полностью довольна и спокойна. Продолжай в том же духе!»',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(ctx).pop();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.capybaraAmber, AppColors.capybaraCopper],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Горжусь собой',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF161412),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerShadePush() async {
    HapticFeedback.heavyImpact();
    CapybaraSound.playOrangePop();

    await widget.notificationController?.requestSystemPermission();
    widget.notificationController?.scheduleBackgroundShadePush(
      5,
      'Капибара: ${widget.controller.capybaraMoodTitle}',
      widget.controller.capybaraMoodComment,
    );

    setState(() => _scheduledNotice = true);
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _scheduledNotice = false);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E1A16).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.capybaraAmber, width: 1),
          ),
          content: const Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: AppColors.capybaraAmber, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Сверните приложение — через 5 секунд пуш с состоянием прибудет в шторку!',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Color _getHealthColor(int health) {
    if (health >= 75) return AppColors.income;
    if (health >= 50) return AppColors.capybaraAmber;
    if (health >= 25) return Colors.orange;
    return AppColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    final health = widget.controller.capybaraHealth;
    final moodTitle = widget.controller.capybaraMoodTitle;
    final moodComment = widget.controller.capybaraMoodComment;
    final moodImagePath = widget.controller.capybaraMoodImagePath;
    final healthColor = _getHealthColor(health);
    final disciplineSteps = widget.controller.dailyDisciplineSteps;
    final isDisciplineDone = widget.controller.isDailyDisciplineComplete;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      surfaceColor: const Color(0xFF171411).withValues(alpha: 0.88),
      borderColor: AppColors.capybaraAmber.withValues(alpha: 0.32),
      borderWidth: 1.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Mascot Avatar, Title, Mood Badge & Pet Count
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with generated 3D artwork and bounce animation
              GestureDetector(
                onTap: _tapCapybara,
                child: ScaleTransition(
                  scale: _bounceAnimation,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: healthColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: healthColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        moodImagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Health Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            moodTitle,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: healthColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: healthColor.withValues(alpha: 0.4),
                              width: 0.7,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded, size: 10, color: healthColor),
                              const SizedBox(width: 3),
                              Text(
                                '$health%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: healthColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      health >= 50 ? 'Зависит от вложений и трат' : 'Внимание: высокий уровень трат',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Push test button
              InkWell(
                onTap: _triggerShadePush,
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.6,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                    color: AppColors.capybaraAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Health Bar (Animated)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Финансовое здоровье',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$health / 100',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: healthColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: health / 100.0,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Situational Commentary Bubble with Interactive Meme / Advice Switcher
          InkWell(
            onTap: _cycleAdvice,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.capybaraAmber.withValues(alpha: 0.22),
                  width: 0.9,
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
                            _showMemeAdvice ? Icons.auto_awesome_rounded : Icons.spa_rounded,
                            size: 12,
                            color: AppColors.capybaraAmber,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _showMemeAdvice ? 'МУДРОСТЬ КАПИБАРЫ' : 'ТЕКУЩИЙ НАСТРОЙ',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.capybaraAmber,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.capybaraAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 9, color: AppColors.capybaraAmber),
                            SizedBox(width: 3),
                            Text(
                              'ДРУГОЙ СОВЕТ',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: AppColors.capybaraAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _showMemeAdvice
                          ? NotificationController.getDynamicInsight(widget.controller, offset: _adviceIndex).body
                          : moodComment,
                      key: ValueKey('comment_${_showMemeAdvice}_$_adviceIndex'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2-Step Daily Discipline Action Tracker ("прям считает пока до конца не сделаю до есть два раза")
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.capybaraAmber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.capybaraAmber.withValues(alpha: 0.28),
                width: 0.9,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: AppColors.capybaraAmber,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Дисциплина дня',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDisciplineDone
                            ? AppColors.income.withValues(alpha: 0.2)
                            : AppColors.capybaraAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$disciplineSteps из 2 шагов',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDisciplineDone ? AppColors.income : AppColors.capybaraAmber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2 Segments Indicator
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: disciplineSteps >= 1
                              ? AppColors.capybaraAmber
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: disciplineSteps >= 2
                              ? AppColors.income
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Interactive Multi-Step Action Button
                if (!isDisciplineDone)
                  InkWell(
                    onTap: _onStepActionPressed,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.capybaraAmber, AppColors.capybaraCopper],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.capybaraAmber.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            disciplineSteps == 0 ? Icons.looks_one_rounded : Icons.looks_two_rounded,
                            size: 16,
                            color: const Color(0xFF161412),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              disciplineSteps == 0
                                  ? 'Шаг 1: Проверить расходы'
                                  : 'Шаг 2: Закрепить дисциплину',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF161412),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.income.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 15, color: AppColors.income),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Похвала получена! 2 из 2 выполнено!',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.income,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Notice banner if scheduled
          if (_scheduledNotice) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.capybaraAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 13, color: AppColors.capybaraAmber),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Пуш отправлен в шторку! Сверните окно для проверки.',
                      style: TextStyle(fontSize: 10.5, color: AppColors.capybaraAmber, fontWeight: FontWeight.w600),
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
}
