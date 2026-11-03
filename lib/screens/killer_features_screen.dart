import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_penalty.dart';
import '../services/geoshame_service.dart';
import '../services/widget_launch_service.dart';
import '../state/finance_controller.dart';
import '../state/notification_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/workout_penalty_modal.dart';
import 'ai_roast_screen.dart';
import 'receipt_scanner_screen.dart';

class KillerFeaturesScreen extends StatefulWidget {
  final FinanceController controller;
  final NotificationController? notificationController;

  const KillerFeaturesScreen({
    super.key,
    required this.controller,
    this.notificationController,
  });

  @override
  State<KillerFeaturesScreen> createState() => _KillerFeaturesScreenState();
}

class _KillerFeaturesScreenState extends State<KillerFeaturesScreen> {
  bool _canDrawOverlays = false;
  bool _floatingCapyEnabled = false;
  bool _socialBlockerEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkOverlayPermission();
  }

  Future<void> _checkOverlayPermission() async {
    final canDraw = await WidgetLaunchService.canDrawOverlays();
    final isA11y = await WidgetLaunchService.isAccessibilityServiceEnabled();
    final hasAccess = canDraw || isA11y;
    if (mounted) {
      setState(() {
        _canDrawOverlays = hasAccess;
        _floatingCapyEnabled = widget.controller.floatingCapyEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final dreamGoalTitle = controller.savingsGoals.isNotEmpty
        ? controller.savingsGoals.first.title
        : 'MacBook Pro M3';

    return GlassBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'КИЛЛЕР-ФИЧИ & WINTER ARC',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // Section 1: Convenient Features
          _buildSectionHeader('УДОБНО • НА КАЖДЫЙ ДЕНЬ'),
          const SizedBox(height: 10),

          // 1. Floating Capybara Chat Head
          _buildFeatureCard(
            title: 'Плавающая Капибара (Chat Head)',
            subtitle:
                'Появляется поверх MBank и Оптимы. Тапнул по капибаре — открывается мини-шторка ARC FINANCE для моментальной записи без переключения приложений.',
            badge: (_floatingCapyEnabled && _canDrawOverlays) ? 'АКТИВНА' : (_canDrawOverlays ? 'ОТКЛ' : 'ТРЕБУЕТ ДОСТУП'),
            badgeColor: (_floatingCapyEnabled && _canDrawOverlays) ? AppColors.capybaraAmber : const Color(0xFF8E8E93),
            trailingWidget: Switch.adaptive(
              value: _floatingCapyEnabled && _canDrawOverlays,
              activeTrackColor: AppColors.capybaraAmber,
              activeThumbColor: const Color(0xFF09090B),
              onChanged: (val) async {
                if (val && !_canDrawOverlays) {
                  await WidgetLaunchService.requestOverlayPermission();
                  _checkOverlayPermission();
                } else {
                  widget.controller.toggleFloatingCapy(val);
                  setState(() => _floatingCapyEnabled = val);
                }
              },
            ),
            customAction: !_canDrawOverlays
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await WidgetLaunchService.requestOverlayPermission();
                          _checkOverlayPermission();
                        },
                        icon: const Icon(Icons.layers_outlined, size: 16, color: AppColors.capybaraAmber),
                        label: const Text(
                          'Разрешить отображение поверх других окон',
                          style: TextStyle(fontSize: 12, color: AppColors.capybaraAmber, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.capybaraAmber.withValues(alpha: 0.45)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),

          // 1b. Capybara Pre-Transaction Filter
          _buildFeatureCard(
            title: 'Капибара-фильтр (До оплаты)',
            subtitle:
                'Перехватывает экран подтверждения перевода от 500 сом в MBank и маркетплейсах. Поверх экрана всплывает системное окно: «Точно переводим? А как же цель на $dreamGoalTitle?».',
            badge: (widget.controller.capybaraFilterEnabled && _canDrawOverlays) ? 'АКТИВЕН' : (_canDrawOverlays ? 'ОТКЛ' : 'ТРЕБУЕТ ДОСТУП'),
            badgeColor: (widget.controller.capybaraFilterEnabled && _canDrawOverlays) ? AppColors.capybaraAmber : const Color(0xFF8E8E93),
            trailingWidget: Switch.adaptive(
              value: widget.controller.capybaraFilterEnabled && _canDrawOverlays,
              activeTrackColor: AppColors.capybaraAmber,
              activeThumbColor: const Color(0xFF09090B),
              onChanged: (val) async {
                if (val && !_canDrawOverlays) {
                  await WidgetLaunchService.requestOverlayPermission();
                  _checkOverlayPermission();
                } else {
                  widget.controller.toggleCapybaraFilter(val);
                  setState(() {});
                }
              },
            ),
          ),
          const SizedBox(height: 14),

          // 2. Clipboard Parser
          _buildFeatureCard(
            title: 'Парсер буфера обмена',
            subtitle:
                'Моментально ловит скопированные суммы от друзей («Закинь 1200 сом за обед») и выдает быстрое Toast-действие.',
            badge: 'РАБОТАЕТ',
            badgeColor: AppColors.capybaraAmber,
            customAction: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'Закинь 1200 сом за обед в Фаизе'));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Скопировано в буфер! Сверни и открой приложение для проверки.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.content_paste_go_rounded, size: 16, color: AppColors.capybaraAmber),
                  label: const Text(
                    'Скопировать тест: «Закинь 1200 сом за обед»',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. AR Receipt Scanner
          _buildFeatureCard(
            title: 'AR-сканер чеков с Vision AI',
            subtitle:
                'Наведи камеру на чек из «Фрунзе» или кафе. Vision AI мгновенно распознает позиции, а AR-капибара выдаст поп-ап с реакцией («Опять энергетики? Отдалил себя от $dreamGoalTitle на 200 сом») и умным округлением.',
            badge: 'VISION AI',
            badgeColor: AppColors.capybaraAmber,
            customAction: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReceiptScannerScreen(controller: widget.controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.document_scanner_rounded, size: 16, color: Color(0xFF09090B)),
                  label: const Text(
                    'Запустить AR-сканер чеков',
                    style: TextStyle(fontSize: 12, color: Color(0xFF09090B), fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.capybaraAmber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Winter Arc & Savage Discipline
          _buildSectionHeader('МЕМНО И КРУТО • ДЛЯ WINTER ARC'),
          const SizedBox(height: 10),

          // Hardcore Social Blocker
          _buildFeatureCard(
            title: 'Блокиратор соцсетей (Hardcore Dictator)',
            subtitle:
                'Использует системные права AccessibilityService: при открытии Instagram, TikTok, YouTube показывает строгий полноэкранный экран Капибары-Диктатора поверх приложения. Никаких продлений на 15–20 минут! Доступ закрыт, пока не сделаешь 20 подтягиваний в ARC Finance или не закроешь соцсеть.',
            badge: _socialBlockerEnabled ? 'ЖЕСТКИЙ ДИКТАТОР' : 'ОТКЛ',
            badgeColor: _socialBlockerEnabled ? AppColors.capybaraAmber : const Color(0xFF8E8E93),
            trailingWidget: Switch.adaptive(
              value: _socialBlockerEnabled,
              activeTrackColor: AppColors.capybaraAmber,
              activeThumbColor: const Color(0xFF09090B),
              onChanged: (val) async {
                if (val) {
                  final isAccess =
                      await WidgetLaunchService.isAccessibilityServiceEnabled();
                  final canOverlay =
                      await WidgetLaunchService.canDrawOverlays();

                  if (!isAccess || !canOverlay) {
                    if (context.mounted) {
                      _showBlockerPermissionsDialog(
                        context,
                        needAccessibility: !isAccess,
                        needOverlay: !canOverlay,
                      );
                    }
                  }
                }

                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('arc_social_blocker_enabled', val);
                  await prefs.setBool('arc_social_blocker_active', val);
                  await prefs.setString('arc_social_blocker_mode', 'always');
                } catch (_) {}
                setState(() => _socialBlockerEnabled = val);
                await WidgetLaunchService.syncSocialBlockerConfig(
                  enabled: val,
                  isBlocked: val,
                  dreamGoal: dreamGoalTitle,
                  pullupsRequired: 20,
                );
              },
            ),
            customAction: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildAppBadge('Instagram', Icons.camera_alt_outlined),
                      _buildAppBadge('TikTok', Icons.play_arrow_rounded),
                      _buildAppBadge('YouTube', Icons.video_collection_outlined),
                      _buildAppBadge('X (Twitter)', Icons.alternate_email_rounded),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        WorkoutPenaltyModal.show(
                          context,
                          penalty: WorkoutPenalty(
                            id: 'social_block_${DateTime.now().millisecondsSinceEpoch}',
                            title: '20 подтягиваний',
                            reps: 20,
                            exercise: 'подтягиваний',
                            reason: 'ЛИМИТ ПРОБИТ: Доступ к соцсетям заблокирован диктатором Winter Arc!',
                            excessAmount: 350.0,
                            timestamp: DateTime.now(),
                          ),
                          controller: widget.controller,
                        );
                      },
                      icon: const Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.capybaraAmber),
                      label: const Text(
                        'Симуляция блокировки соцсетей (20 подтягиваний)',
                        style: TextStyle(fontSize: 11.5, color: AppColors.capybaraAmber, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.capybaraAmber.withValues(alpha: 0.45)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Geoshame (Bishkek Geofencing)
          _buildFeatureCard(
            title: 'Гео-шейминг (Bishkek Danger Zones)',
            subtitle:
                'Завис около Фаизы или в Дордой Плазе? Телефон жестко завибрирует и выдаст пуш: «Я всё вижу. Убери кошелек, мы копим на Mac M3!».',
            badge: GeoshameService.isEnabled ? 'РАДАР АКТИВЕН' : 'ОТКЛ',
            badgeColor: GeoshameService.isEnabled ? AppColors.capybaraAmber : const Color(0xFF8E8E93),
            trailingWidget: Switch.adaptive(
              value: GeoshameService.isEnabled,
              activeTrackColor: AppColors.capybaraAmber,
              activeThumbColor: const Color(0xFF09090B),
              onChanged: (val) {
                GeoshameService.setEnabled(val);
                setState(() {});
              },
            ),
            customAction: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final zone = GeoshameService.bishkekDangerZones.first;
                        GeoshameService.triggerShameAlert(
                          context,
                          zone,
                          notificationController: widget.notificationController,
                        );
                      },
                      icon: const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.capybaraAmber),
                      label: const Text(
                        'Тест: Фаиза',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final zone = GeoshameService.bishkekDangerZones[1];
                        GeoshameService.triggerShameAlert(
                          context,
                          zone,
                          notificationController: widget.notificationController,
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_outlined, size: 15, color: AppColors.capybaraAmber),
                      label: const Text(
                        'Тест: Дордой',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 5. Workout Penalty (Streetlifting)
          _buildFeatureCard(
            title: 'Спортивный штраф за срыв',
            subtitle:
                'Трата превышает лимит на «Развлечения»? Транзакция одобрится, но капибара назначит 25 подтягиваний на турнике или 50 отжиманий для спасения стрика.',
            badge: 'СТРИТЛИФТИНГ',
            badgeColor: AppColors.capybaraAmber,
            customAction: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    WorkoutPenaltyModal.show(
                      context,
                      penalty: WorkoutPenalty(
                        id: 'demo_penalty',
                        title: '25 подтягиваний',
                        reps: 25,
                        exercise: 'подтягиваний',
                        reason: 'Превышен лимит на «Развлечения» на 450 сом',
                        excessAmount: 450.0,
                        timestamp: DateTime.now(),
                      ),
                      controller: widget.controller,
                    );
                  },
                  icon: const Icon(Icons.fitness_center_rounded, size: 16, color: Color(0xFF09090B)),
                  label: const Text(
                    'Демонстрация штрафа (25 подтягиваний)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF09090B), fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.capybaraAmber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 6. AI Roast
          _buildFeatureCard(
            title: 'Нейро-прожарка (AI Roast)',
            subtitle:
                'Токсичный воскресный отчет. Отправляет твои чеки в Gemini или встроенный бишкекский сленг-движок и жестко разносит за такси, лагманы и шоппинг.',
            badge: 'ТОКСИК-МОД',
            badgeColor: AppColors.capybaraAmber,
            customAction: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AIRoastScreen(controller: widget.controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.capybaraAmber),
                  label: const Text(
                    'Открыть Нейро-прожарку (AI Roast)',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1B1F),
                    side: BorderSide(color: AppColors.capybaraAmber.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF8E8E93),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    Widget? trailingWidget,
    Widget? customAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailingWidget,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          ?customAction,
        ],
      ),
    );
  }

  Widget _buildAppBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.capybaraAmber.withValues(alpha: 0.85)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showBlockerPermissionsDialog(
    BuildContext context, {
    required bool needAccessibility,
    required bool needOverlay,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.capybaraAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.capybaraAmber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Разрешения для Блокатора',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Чтобы Капибара-Диктатор могла распознавать запуск Instagram / TikTok и показывать экран блокировки, включите системные разрешения:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (needAccessibility) ...[
              _buildPermissionStep(
                icon: Icons.accessibility_new_rounded,
                title: '1. Спец. возможности (Accessibility)',
                subtitle: 'Распознавание запуска соцсетей в фоне',
                btnText: 'Включить в настройках',
                onTap: () {
                  WidgetLaunchService.openAccessibilitySettings();
                },
              ),
              const SizedBox(height: 12),
            ],
            if (needOverlay) ...[
              _buildPermissionStep(
                icon: Icons.layers_rounded,
                title: '2. Поверх других приложений (Overlay)',
                subtitle: 'Отображение экрана блокировки Капибары',
                btnText: 'Разрешить поверх окон',
                onTap: () {
                  WidgetLaunchService.requestOverlayPermission();
                },
              ),
              const SizedBox(height: 14),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.capybaraAmber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Понятно, всё настроено',
                  style: TextStyle(
                    color: Color(0xFF09090B),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required String btnText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.capybaraAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppColors.capybaraAmber.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            child: Text(
              btnText,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.capybaraAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
