import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/widget_launch_service.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/cartoon_capybara.dart';
import 'main_navigation_screen.dart';

/// Bombastic Cartoon Capybara Money-Counting Splash Screen
/// Completely silent (no sound), 60 FPS fluid vector & particle animation:
/// 1. Cute illustrated cartoon Capybara mascot with ambient breathing, blinking, and paw tapping.
/// 2. Kinetic flying golden coins and stylized som banknotes with 3D rotation and sparkles.
/// 3. Whimsical floating thought bubble with dynamic financial calculations.
/// 4. Rapid micro-haptic odometer counting smoothly to user's real balance.
/// 5. Fast-track skip on tap or Home Screen widget launch.
class SplashScreen extends StatefulWidget {
  final FinanceController controller;

  const SplashScreen({super.key, required this.controller});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _breathingController;
  late final AnimationController _particleController;
  late final AnimationController _billFlipController;

  late final Animation<double> _countAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  Timer? _navigationTimer;
  bool _hasNavigated = false;

  late final double _targetAmount;
  String _currentThought = 'Считаем сомы в кошельке... 💭';
  String _currentStatus = 'Капибара анализирует бюджет...';
  bool _isHappy = false;

  @override
  void initState() {
    super.initState();
    _configureSystemUi();

    final userBalance = widget.controller.totalBalance;
    _targetAmount = userBalance > 100 ? userBalance : 74850.0;

    // 1. Main timeline controller (2200ms)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 2. Continuous breathing / idle motion (1400ms)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // 3. Floating coins & sparkle rotation (1800ms)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 4. Banknote flipping loop (380ms)
    _billFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
      ),
    );

    _countAnimation = Tween<double>(begin: 0.0, end: _targetAmount).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.12, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Dynamic thoughts and expressions as money is counted
    _mainController.addListener(() {
      final progress = _mainController.value;
      if (progress < 0.35) {
        if (_currentThought != 'Считаем сомы в кошельке... 💭') {
          setState(() {
            _currentThought = 'Считаем сомы в кошельке... 💭';
            _currentStatus = 'Купюра к купюре, всё под контролем...';
            _isHappy = false;
          });
        }
      } else if (progress < 0.75) {
        if (_currentThought != '🧮 ∑ Заначка + MBank + Оптима 📈') {
          setState(() {
            _currentThought = '🧮 ∑ Заначка + MBank + Оптима 📈';
            _currentStatus = 'Капибара проверяет инвестиции...';
            _isHappy = false;
          });
          HapticFeedback.selectionClick();
        }
      } else {
        if (_currentThought != '✨ Баланс сошёлся до тыйына! 🎯') {
          setState(() {
            _currentThought = '✨ Баланс сошёлся до тыйына! 🎯';
            _currentStatus = 'Баланс идеален. Деньги любят тишину.';
            _isHappy = true;
          });
        }
      }
    });

    _mainController.forward();

    // Fast-track: if user tapped a native Home Screen widget button, skip splash delay
    WidgetLaunchService.hasPendingWidgetAction().then((hasAction) {
      if (hasAction && mounted) {
        _navigateToMain();
      }
    });

    // Auto-advance after counting finishes
    _navigationTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) _navigateToMain();
    });
  }

  void _configureSystemUi() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  void _navigateToMain() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _navigationTimer?.cancel();

    HapticFeedback.mediumImpact();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigationScreen(controller: widget.controller),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _mainController.dispose();
    _breathingController.dispose();
    _particleController.dispose();
    _billFlipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToMain,
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Ambient Warm Golden Radial Glow
              Positioned.fill(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _breathingController,
                    builder: (context, child) {
                      final breath = _breathingController.value;
                      return Container(
                        width: 320 + breath * 30,
                        height: 320 + breath * 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.capybaraAmber.withValues(alpha: 0.16),
                              AppColors.capybaraAmber.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. Animated Floating Golden Coins & Particle Sparkles
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _SplashParticlesPainter(
                        progress: _particleController.value,
                        accentColor: AppColors.capybaraAmber,
                      ),
                    );
                  },
                ),
              ),

              // 3. Main Centerpiece (Thought Bubble, Cartoon Capybara, Banknotes, Counter)
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _mainController,
                    _breathingController,
                    _billFlipController,
                  ]),
                  builder: (context, child) {
                    final breath = math.sin(_breathingController.value * math.pi) * 4.0;
                    final flipVal = _billFlipController.value;
                    final blinkPhase = _breathingController.value;
                    final isBlinking = blinkPhase > 0.88 && blinkPhase < 0.95;

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // A. Dynamic Thought Bubble
                            Transform.translate(
                              offset: Offset(0, -breath * 0.4),
                              child: _buildThoughtBubble(),
                            ),
                            const SizedBox(height: 14),

                            // B. Cute Illustrated Cartoon Capybara Mascot
                            Transform.translate(
                              offset: Offset(0, breath),
                              child: CartoonCapybara(
                                size: 136,
                                breath: math.sin(_breathingController.value * math.pi),
                                blink: isBlinking ? 1.0 : 0.0,
                                armTap: flipVal,
                                showMandarin: true,
                                showSpectacles: false,
                                isHappy: _isHappy,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // C. Flying Banknotes & Cash Stack
                            _buildBanknotesStack(flipVal),
                            const SizedBox(height: 18),

                            // D. Large Digital Som Counter
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  CurrencyFormatter.format(_countAnimation.value),
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // E. Status Subtitle
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.capybaraAmber.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.capybaraAmber.withValues(alpha: 0.22),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _currentStatus,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.capybaraAmber.withValues(alpha: 0.95),
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 4. Subtle skip hint at bottom
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: (_fadeAnimation.value * 0.55).clamp(0.0, 1.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.capybaraAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Нажмите в любом месте, чтобы пропустить',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThoughtBubble() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Trailing thought bubble dot 1
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(bottom: 2, right: 4),
          decoration: BoxDecoration(
            color: AppColors.capybaraAmber.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
        // Trailing thought bubble dot 2
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(bottom: 6, right: 6),
          decoration: BoxDecoration(
            color: AppColors.capybaraAmber.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
        ),
        // Thought bubble pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.capybaraAmber.withValues(alpha: 0.40),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.capybaraAmber.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Text(
            _currentThought,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanknotesStack(double flipVal) {
    // Dynamic banknote drop and tilt height
    final dropY = (math.sin(flipVal * math.pi) * 6.0);

    return SizedBox(
      width: 148,
      height: 66,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottom banknote (rotated -6 degrees)
          Transform.rotate(
            angle: -0.10,
            child: _buildSingleBanknote(opacity: 0.45, label: '200 сом'),
          ),

          // Middle banknote (rotated +5 degrees)
          Transform.rotate(
            angle: 0.08,
            child: _buildSingleBanknote(opacity: 0.75, label: '500 сом'),
          ),

          // Top active banknote counting & bouncing
          Transform.translate(
            offset: Offset(0, -dropY),
            child: Transform.rotate(
              angle: 0.01,
              child: _buildSingleBanknote(
                opacity: 1.0,
                label: '1 000 сом',
                isTop: true,
              ),
            ),
          ),

          // Golden Coin next to stack
          Positioned(
            right: 0,
            top: 2,
            child: Transform.translate(
              offset: Offset(0, dropY * 0.7),
              child: _buildGoldenCoin(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBanknote({
    required double opacity,
    required String label,
    bool isTop = false,
  }) {
    return Container(
      width: 114,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF16231A).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTop
              ? AppColors.capybaraAmber.withValues(alpha: 0.8)
              : const Color(0xFF30D158).withValues(alpha: 0.3 * opacity),
          width: isTop ? 1.2 : 0.8,
        ),
        boxShadow: isTop
            ? [
                BoxShadow(
                  color: AppColors.capybaraAmber.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Holographic security line
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(
              color: isTop
                  ? AppColors.capybaraAmber.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.15 * opacity),
            ),
          ),
          Center(
            child: Text(
              label,
              style: TextStyle(
                color: isTop ? AppColors.capybaraAmber : Colors.white.withValues(alpha: 0.8 * opacity),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenCoin() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [
            Color(0xFFFFEE99),
            AppColors.capybaraAmber,
            Color(0xFFC48200),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.capybaraAmber.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'c',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4A3000),
          ),
        ),
      ),
    );
  }
}

/// Particle system rendering floating golden coins, som currency symbols, and sparkles
class _SplashParticlesPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _SplashParticlesPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cX = w / 2;
    final cY = h / 2 - 20;

    // 8 Orbiting/floating particles around center
    final particles = [
      _ParticleDef(angle: 0.2, distance: 130, size: 7, speed: 1.0, isSparkle: true),
      _ParticleDef(angle: 1.0, distance: 150, size: 10, speed: 0.8, isSparkle: false, text: 'c'),
      _ParticleDef(angle: 2.1, distance: 120, size: 6, speed: 1.2, isSparkle: true),
      _ParticleDef(angle: 2.9, distance: 140, size: 12, speed: 0.9, isSparkle: false, text: '∑'),
      _ParticleDef(angle: 3.8, distance: 160, size: 8, speed: 1.1, isSparkle: true),
      _ParticleDef(angle: 4.6, distance: 135, size: 11, speed: 0.85, isSparkle: false, text: '%'),
      _ParticleDef(angle: 5.4, distance: 145, size: 7, speed: 1.05, isSparkle: true),
      _ParticleDef(angle: 6.0, distance: 155, size: 10, speed: 0.95, isSparkle: false, text: '📈'),
    ];

    for (final p in particles) {
      final currentAngle = p.angle + progress * 2 * math.pi * 0.15 * p.speed;
      final floatY = math.sin(progress * 2 * math.pi * p.speed) * 8;
      final px = cX + math.cos(currentAngle) * p.distance;
      final py = cY + math.sin(currentAngle) * (p.distance * 0.7) + floatY;

      if (p.isSparkle) {
        // Draw 4-point golden star sparkle
        _drawSparkle(canvas, Offset(px, py), p.size, accentColor.withValues(alpha: 0.65));
      } else {
        // Draw floating mini golden bubble with symbol
        final bgPaint = Paint()
          ..color = const Color(0xFF1E1C18).withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), p.size * 1.1, bgPaint);

        final borderPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(px, py), p.size * 1.1, borderPaint);

        final textSpan = TextSpan(
          text: p.text,
          style: TextStyle(
            color: accentColor,
            fontSize: p.size * 1.1,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SplashParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ParticleDef {
  final double angle;
  final double distance;
  final double size;
  final double speed;
  final bool isSparkle;
  final String text;

  const _ParticleDef({
    required this.angle,
    required this.distance,
    required this.size,
    required this.speed,
    required this.isSparkle,
    this.text = '',
  });
}
