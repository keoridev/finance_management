import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/widget_launch_service.dart';
import '../theme/app_colors.dart';
import 'transaction_success_overlay.dart';

class WidgetInstallationGuideModal extends StatefulWidget {
  const WidgetInstallationGuideModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WidgetInstallationGuideModal(),
    );
  }

  @override
  State<WidgetInstallationGuideModal> createState() => _WidgetInstallationGuideModalState();
}

class _WidgetInstallationGuideModalState extends State<WidgetInstallationGuideModal> {
  int _selectedPlatform = 0; // 0: iOS, 1: Android

  @override
  Widget build(BuildContext context) {
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

            // Header with App Logo
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/app_logo.jpg',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Установка ARC на экран смартфона',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'PWA • Виджет • Без рамок браузера',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.iosBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Platform Switcher (iPhone vs Android)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPlatform = 0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedPlatform == 0 ? const Color(0xFF2C2C2E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedPlatform == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apple,
                              size: 16,
                              color: _selectedPlatform == 0 ? Colors.white : Colors.white60,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'iPhone (iOS)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedPlatform == 0 ? FontWeight.w700 : FontWeight.w500,
                                    color: _selectedPlatform == 0 ? Colors.white : Colors.white60,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPlatform = 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedPlatform == 1 ? const Color(0xFF2C2C2E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedPlatform == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.android_rounded,
                              size: 16,
                              color: _selectedPlatform == 1 ? AppColors.income : Colors.white60,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Android',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedPlatform == 1 ? FontWeight.w700 : FontWeight.w500,
                                    color: _selectedPlatform == 1 ? Colors.white : Colors.white60,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedPlatform == 0) ...[
              // Steps for iPhone (iOS)
              _buildStepCard(
                stepNumber: '1',
                icon: Icons.public_rounded,
                title: 'Откройте в Safari',
                description: 'Зайдите на сайт приложения через браузер Safari на вашем iPhone.',
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                stepNumber: '2',
                icon: Icons.ios_share_rounded,
                title: 'Нажмите «Поделиться»',
                description: 'В нижней панели Safari коснитесь кнопки «Поделиться» (иконка квадрата со стрелкой вверх [↑]).',
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                stepNumber: '3',
                icon: Icons.add_box_rounded,
                title: 'Выберите «На экран "Домой"»',
                description: 'Прокрутите открывшийся список вниз и нажмите «На экран "Домой"» (Add to Home Screen).',
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                stepNumber: '4',
                icon: Icons.widgets_rounded,
                title: 'Виджеты на рабочий стол (iOS 18)',
                description: 'Иконка ARC появится на рабочем столе. Удерживайте палец на иконке, чтобы добавить виджет или разместить на экране блокировки.',
              ),
            ] else ...[
              // Quick 1-tap installation cards for Android
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F0A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFF9F0A)),
                        SizedBox(width: 6),
                        Text(
                          'Быстрая установка в 1 тап (Android 8.0+)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF9F0A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildPinActionButton(
                      title: 'Winter Arc (Квадраты стрика 2×2)',
                      type: 'winter',
                      icon: Icons.grid_view_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildPinActionButton(
                      title: 'Предсказания Капибары (Дзен 2×2)',
                      type: 'capy',
                      icon: Icons.auto_awesome_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildPinActionButton(
                      title: 'Финансы и быстрые действия (4×2)',
                      type: 'finance',
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildPinActionButton(
                      title: 'Мини-баланс и расход (2×2)',
                      type: 'mini',
                      icon: Icons.crop_square_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Steps for manual Android widget menu
              _buildStepCard(
                stepNumber: '1',
                icon: Icons.touch_app_rounded,
                title: 'Зажмите экран смартфона',
                description: 'На главном экране Android удерживайте палец на любом свободном месте 1 секунду.',
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                stepNumber: '2',
                icon: Icons.widgets_rounded,
                title: 'Выберите пункт «Виджеты»',
                description: 'В появившемся меню рабочего стола нажмите на кнопку «Виджеты» (Widgets).',
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                stepNumber: '3',
                icon: Icons.search_rounded,
                title: 'Найдите «ARC Finance»',
                description: 'В списке приложений найдите ARC Finance. Там доступны все 4 нативных виджета: Winter Arc, Капибара, Финансы и Мини-баланс.',
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                stepNumber: '4',
                icon: Icons.drag_indicator_rounded,
                title: 'Перетащите на рабочий стол',
                description: 'Зажмите выбранный виджет и перетащите его в любое удобное место вашего экрана.',
              ),
            ],
            const SizedBox(height: 24),

            // Close button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Понятно',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.iosBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.iosBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinActionButton({
    required String title,
    required String type,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () async {
        HapticFeedback.heavyImpact();
        final success = await WidgetLaunchService.requestPinWidget(type);
        if (!mounted) return;
        if (success) {
          TransactionSuccessOverlay.show(
            context,
            title: 'Виджет отправлен на рабочий стол',
            amount: 0,
            bankName: 'Подтвердите в системном окне Android',
            isIncome: true,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Используйте зажатие экрана на рабочем столе -> Виджеты -> ARC Finance'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFF9F0A)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.add_circle_outline_rounded,
              size: 16,
              color: Color(0xFFFF9F0A),
            ),
          ],
        ),
      ),
    );
  }
}
