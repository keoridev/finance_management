import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  final FinanceController controller;

  const SplashScreen({super.key, required this.controller});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bootController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _ringsExpansion;
  late Animation<double> _ringsOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _balanceCounter;
  late Animation<double> _cardSlide;
  late Animation<double> _buttonScale;

  bool _isUnlocked = false;
  Timer? _autoNavTimer;

  @override
  void initState() {
    super.initState();

    // 1. Boot sequence controller (runs once on launch)
    _bootController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 2. Ambient continuous breathing / shimmer controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // Staggered intro animations
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _bootController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bootController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _ringsExpansion = Tween<double>(begin: 0.2, end: 1.4).animate(
      CurvedAnimation(
        parent: _bootController,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _ringsOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(
        parent: _bootController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _bootController,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bootController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeIn),
      ),
    );

    _balanceCounter = Tween<double>(
      begin: 0.0,
      end: widget.controller.totalBalance,
    ).animate(
      CurvedAnimation(
        parent: _bootController,
        curve: const Interval(0.45, 0.95, curve: Curves.easeOutExpo),
      ),
    );

    _cardSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bootController,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _buttonScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _bootController,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _bootController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isUnlocked = true;
        });
        HapticFeedback.lightImpact();

        // Auto transition into app smoothly
        _autoNavTimer = Timer(const Duration(milliseconds: 1100), () {
          if (mounted) _navigateToMain();
        });
      }
    });

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _bootController.forward();
    }
  }

  void _navigateToMain() {
    _autoNavTimer?.cancel();
    HapticFeedback.mediumImpact();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              MainNavigationScreen(controller: widget.controller),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _autoNavTimer?.cancel();
    _bootController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: AnimatedBuilder(
        animation: Listenable.merge([_bootController, _pulseController]),
        builder: (context, child) {
          final pulse = _pulseController.value;
          final currentAmount = _balanceCounter.value;

          return Stack(
            children: [
              // 1. Futuristic Ambient Neon Glow Orbs
              Positioned(
                top: -140,
                left: -100,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E5FF).withValues(alpha: 0.16 + 0.08 * pulse),
                        const Color(0xFF0077FE).withValues(alpha: 0.08 + 0.04 * pulse),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                right: -80,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7928CA).withValues(alpha: 0.14 + 0.06 * pulse),
                        const Color(0xFFFF0080).withValues(alpha: 0.05 + 0.03 * pulse),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Cyber Subtle Grid Lines Pattern Overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _CyberGridPainter(
                    opacity: 0.03 + 0.02 * pulse,
                  ),
                ),
              ),

              // 3. Top Status Header & Skip Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 14,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // System online pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isUnlocked ? const Color(0xFF00FF88) : const Color(0xFF00E5FF),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isUnlocked ? const Color(0xFF00FF88) : const Color(0xFF00E5FF))
                                      .withValues(alpha: 0.6 + 0.4 * pulse),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _isUnlocked ? 'VAULT DECRYPTED' : 'ARC ENGINE v2.4',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Skip button
                    InkWell(
                      onTap: _navigateToMain,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Пропустить',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.white60),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Center Content: Holographic Vault Visual
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // Sonar Biometric Ripple Rings + Central Emblem
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing Sonar Rings
                                if (_ringsOpacity.value > 0.01) ...[
                                  Transform.scale(
                                    scale: 0.7 + _ringsExpansion.value * 0.5,
                                    child: Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF00E5FF).withValues(
                                            alpha: _ringsOpacity.value * 0.45,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.5 + _ringsExpansion.value * 0.35,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF7928CA).withValues(
                                            alpha: _ringsOpacity.value * 0.35,
                                          ),
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // Ambient breathing glow halo behind logo
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isUnlocked
                                                ? const Color(0xFF00FF88)
                                                : const Color(0xFF00B4D8))
                                            .withValues(alpha: 0.35 + 0.15 * pulse),
                                        blurRadius: 36,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),

                                // Central Glassmorphic Squircle Logo with Holographic Sheen
                                FadeTransition(
                                  opacity: _logoOpacity,
                                  child: Transform.scale(
                                    scale: _logoScale.value,
                                    child: Container(
                                      width: 104,
                                      height: 104,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1E2029),
                                            Color(0xFF0E1015),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: _isUnlocked
                                              ? const Color(0xFF00FF88).withValues(alpha: 0.8)
                                              : Colors.white.withValues(alpha: 0.25),
                                          width: 1.6,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(26),
                                        child: Stack(
                                          children: [
                                            // Real App Logo
                                            Image.asset(
                                              'assets/images/app_logo.jpg',
                                              width: 104,
                                              height: 104,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.account_balance_wallet_rounded,
                                                    size: 48,
                                                    color: Color(0xFF00E5FF),
                                                  ),
                                                );
                                              },
                                            ),

                                            // Animated Holographic Glint Beam passing across
                                            Positioned.fill(
                                              child: Transform.rotate(
                                                angle: math.pi / 4,
                                                child: Transform.translate(
                                                  offset: Offset((pulse * 240) - 120, 0),
                                                  child: Container(
                                                    width: 25,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.white.withValues(alpha: 0.0),
                                                          Colors.white.withValues(alpha: 0.35),
                                                          Colors.white.withValues(alpha: 0.0),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Unlock checkmark indicator
                                            if (_isUnlocked)
                                              Container(
                                                color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.lock_open_rounded,
                                                    color: Color(0xFF00FF88),
                                                    size: 32,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Brand Title & Animated Typographic Hierarchy
                          SlideTransition(
                            position: _textSlide,
                            child: FadeTransition(
                              opacity: _textOpacity,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'KGS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      const Text(
                                        'ARC FINANCE',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 3.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isUnlocked
                                        ? 'Доступ подтвержден • Бишкек'
                                        : 'Осознанные финансы и дисциплина',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.3,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 26),

                          // Futuristic Balance Telemetry Card
                          Transform.scale(
                            scale: 0.9 + 0.1 * _cardSlide.value,
                            child: Opacity(
                              opacity: _cardSlide.value.clamp(0.0, 1.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: Colors.white.withValues(alpha: 0.04),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.security_rounded,
                                          size: 13,
                                          color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ОБЩИЙ АКТИВНЫЙ БАЛАНС',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.4,
                                            color: Colors.white.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      CurrencyFormatter.format(currentAmount),
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'MBANK • О!ДЕНЬГИ • НАЛИЧНЫЕ',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        color: Colors.white.withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // High-Tech Cyber Glowing Action Button
                          Transform.scale(
                            scale: _buttonScale.value,
                            child: Opacity(
                              opacity: _buttonScale.value.clamp(0.0, 1.0),
                              child: InkWell(
                                onTap: _navigateToMain,
                                borderRadius: BorderRadius.circular(20),
                                splashColor: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFE0E5EC),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.3 + 0.15 * pulse),
                                        blurRadius: 22,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Открыть кошелек',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter to draw subtle holographic tech grid lines
class _CyberGridPainter extends CustomPainter {
  final double opacity;

  _CyberGridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 0.5;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_CyberGridPainter oldDelegate) => oldDelegate.opacity != opacity;
}
