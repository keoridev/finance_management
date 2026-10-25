import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/glass_container.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  final FinanceController controller;

  const SplashScreen({super.key, required this.controller});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _counterAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;

  bool _isUnlocked = false;
  Timer? _autoNavTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.55),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 0.9, curve: Curves.easeIn),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _counterAnimation = Tween<double>(
      begin: 0.0,
      end: widget.controller.totalBalance,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.addListener(() {
      setState(() {});
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isUnlocked = true;
        });
        HapticFeedback.heavyImpact();

        // Auto transition into app after brief lock animation
        _autoNavTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) _navigateToMain();
        });
      }
    });

    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      _animController.forward();
    }
  }

  void _navigateToMain() {
    _autoNavTimer?.cancel();
    HapticFeedback.lightImpact();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
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
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAmount = _counterAnimation.value;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: Stack(
        children: [
          // Ambient Apple Dark Glass Aura
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.iosBlue.withValues(alpha: 0.18 * _glowAnimation.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.iosPurple.withValues(alpha: 0.12 * _glowAnimation.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 18,
            child: InkWell(
              onTap: _navigateToMain,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Пропустить',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),

          // Central Minimalist Vault Experience
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  // Animated ARC Logo (Slides in smoothly from below)
                  SlideTransition(
                    position: _logoSlideAnimation,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        color: const Color(0xFF141417),
                        border: Border.all(
                          color: _isUnlocked
                              ? AppColors.income.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.22),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.iosBlue.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                          if (_isUnlocked)
                            BoxShadow(
                              color: AppColors.income.withValues(alpha: 0.35),
                              blurRadius: 30,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/app_logo.jpg',
                              fit: BoxFit.cover,
                            ),
                            if (_isUnlocked)
                              Container(
                                color: AppColors.income.withValues(alpha: 0.12),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 36,
                                    color: AppColors.income,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Brand Title & Tagline (Slides up from below with fade)
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'KGS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'ARC FINANCE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isUnlocked
                                ? 'Доступ разрешен • Бишкек'
                                : 'Осознанные финансы и дисциплина',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Smooth Counting Total Balance
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    borderRadius: BorderRadius.circular(20),
                    surfaceColor: Colors.white.withValues(alpha: 0.05),
                    borderColor: Colors.white.withValues(alpha: 0.12),
                    child: Column(
                      children: [
                        Text(
                          'ТЕКУЩИЙ БАЛАНС',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(currentAmount),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Enter Button
                  InkWell(
                    onTap: _navigateToMain,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 16,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.black,
                          ),
                        ],
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
);
  }
}
