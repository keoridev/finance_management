import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_penalty.dart';
import '../services/geoshame_service.dart';
import '../services/widget_launch_service.dart';
import '../state/finance_controller.dart';
import '../state/notification_controller.dart';
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
  bool _floatingCapyEnabled = true;
  bool _socialBlockerEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkOverlayPermission();
  }

  Future<void> _checkOverlayPermission() async {
    final canDraw = await WidgetLaunchService.canDrawOverlays();
    final prefs = await SharedPreferences.getInstance();
    final floatingEnabled = prefs.getBool('arc_floating_capy_enabled') ?? true;
    final socialEnabled = prefs.getBool('arc_social_blocker_enabled') ?? true;
    if (mounted) {
      setState(() {
        _canDrawOverlays = canDraw;
        _floatingCapyEnabled = floatingEnabled;
        _socialBlockerEnabled = socialEnabled;
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
            badge: _canDrawOverlays ? 'АКТИВНА' : 'ТРЕБУЕТ ДОСТУП',
            badgeColor: _canDrawOverlays ? const Color(0xFF30D158) : const Color(0xFFFF9F0A),
            trailingWidget: Switch.adaptive(
              value: _floatingCapyEnabled && _canDrawOverlays,
              activeTrackColor: const Color(0xFF00C7BE),
              activeThumbColor: Colors.white,
              onChanged: (val) async {
                if (val && !_canDrawOverlays) {
                  await WidgetLaunchService.requestOverlayPermission();
                  _checkOverlayPermission();
                } else {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('arc_floating_capy_enabled', val);
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
                        icon: const Icon(Icons.layers_outlined, size: 16, color: Color(0xFF00C7BE)),
                        label: const Text(
                          'Разрешить отображение поверх других окон',
                          style: TextStyle(fontSize: 12, color: Color(0xFF00C7BE), fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00C7BE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),

          // 2. Clipboard Parser
          _buildFeatureCard(
            title: 'Парсер буфера обмена',
            subtitle:
                'Моментально ловит скопированные суммы от друзей («Закинь 1200 сом за обед») и выдает быстрое Toast-действие.',
            badge: 'РАБОТАЕТ',
            badgeColor: const Color(0xFF30D158),
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
                  icon: const Icon(Icons.content_paste_go_rounded, size: 16, color: Colors.white70),
                  label: const Text(
                    'Скопировать тест: «Закинь 1200 сом за обед»',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Smart Round-Up
          _buildFeatureCard(
            title: 'Умное округление в копилку',
            subtitle:
                'Каждый расход (например, 340 сом за кофе) округляется до ${controller.smartRoundUpStep} сом. Разница (+60 сом) автоматически падает в копилку на $dreamGoalTitle.',
            badge: controller.smartRoundUpEnabled ? 'ВКЛЮЧЕНО' : 'ОТКЛ',
            badgeColor: controller.smartRoundUpEnabled ? const Color(0xFF30D158) : const Color(0xFF8E8E93),
            trailingWidget: Switch.adaptive(
              value: controller.smartRoundUpEnabled,
              activeTrackColor: const Color(0xFF00C7BE),
              activeThumbColor: Colors.white,
              onChanged: (val) {
                controller.toggleSmartRoundUp(val);
                setState(() {});
              },
            ),
            customAction: controller.smartRoundUpEnabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Text(
                          'Шаг округления: ',
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                        ),
                        ChoiceChip(
                          label: const Text('до 50 сом', style: TextStyle(fontSize: 11)),
                          selected: controller.smartRoundUpStep == 50,
                          selectedColor: const Color(0xFF00C7BE),
                          onSelected: (sel) {
                            if (sel) {
                              controller.setSmartRoundUpStep(50);
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('до 100 сом', style: TextStyle(fontSize: 11)),
                          selected: controller.smartRoundUpStep == 100,
                          selectedColor: const Color(0xFF00C7BE),
                          onSelected: (sel) {
                            if (sel) {
                              controller.setSmartRoundUpStep(100);
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),

          // 4. AR Receipt Scanner
          _buildFeatureCard(
            title: 'AR-сканер чеков с Vision AI',
            subtitle:
                'Наведи камеру на чек из «Фрунзе» или кафе. Vision AI мгновенно распознает позиции, а AR-капибара выдаст поп-ап с реакцией («Опять энергетики? Отдалил себя от $dreamGoalTitle на 200 сом») и умным округлением.',
            badge: 'VISION AI',
            badgeColor: const Color(0xFF00C7BE),
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
                  icon: const Icon(Icons.document_scanner_rounded, size: 16, color: Colors.black),
                  label: const Text(
                    'Запустить AR-сканер чеков',
                    style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7BE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
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
                'Раз уж у приложения есть системные права AccessibilityService, оно использует их как диктатор: при превышении дневного лимита трат моментально сворачивает Instagram, TikTok, YouTube и показывает системный экран: «Лимит пробит. Доступ закрыт, пока не сделаешь 20 подтягиваний».',
            badge: _socialBlockerEnabled ? 'ЖЕСТКИЙ ДИКТАТОР' : 'ОТКЛ',
            badgeColor: _socialBlockerEnabled ? const Color(0xFFFF453A) : const Color(0xFF8E8E93),
            trailingWidget: Switch.adaptive(
              value: _socialBlockerEnabled,
              activeTrackColor: const Color(0xFFFF453A),
              activeThumbColor: Colors.white,
              onChanged: (val) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('arc_social_blocker_enabled', val);
                setState(() => _socialBlockerEnabled = val);
                await WidgetLaunchService.syncSocialBlockerConfig(
                  enabled: val,
                  isBlocked: widget.controller.isSocialBlockerActive,
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
                      icon: const Icon(Icons.lock_clock_rounded, size: 16, color: Color(0xFFFF453A)),
                      label: const Text(
                        'Симуляция блокировки соцсетей (20 подтягиваний)',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFFFF453A), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF453A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            badgeColor: GeoshameService.isEnabled ? const Color(0xFFFF453A) : const Color(0xFF8E8E93),
            trailingWidget: Switch.adaptive(
              value: GeoshameService.isEnabled,
              activeTrackColor: const Color(0xFFFF453A),
              activeThumbColor: Colors.white,
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
                      icon: const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFFF453A)),
                      label: const Text(
                        'Тест: Фаиза',
                        style: TextStyle(fontSize: 11, color: Color(0xFFFF453A), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF453A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      icon: const Icon(Icons.shopping_cart_outlined, size: 15, color: Color(0xFFFF9F0A)),
                      label: const Text(
                        'Тест: Дордой',
                        style: TextStyle(fontSize: 11, color: Color(0xFFFF9F0A), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF9F0A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            badgeColor: const Color(0xFFFF9F0A),
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
                  icon: const Icon(Icons.fitness_center_rounded, size: 16, color: Colors.black),
                  label: const Text(
                    'Демонстрация штрафа (25 подтягиваний)',
                    style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9F0A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
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
            badgeColor: const Color(0xFFFF453A),
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
                  icon: const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.black),
                  label: const Text(
                    'Открыть Нейро-прожарку (AI Roast)',
                    style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF453A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
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
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
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
            style: const TextStyle(
              color: Color(0xFF8E8E93),
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
