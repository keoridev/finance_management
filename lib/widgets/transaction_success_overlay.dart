import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class TransactionSuccessOverlay {
  TransactionSuccessOverlay._();

  static void show(
    BuildContext context, {
    required String title,
    required double amount,
    String? bankName,
    bool isIncome = false,
  }) {
    HapticFeedback.mediumImpact();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _CelebrationBanner(
        title: title,
        amount: amount,
        bankName: bankName,
        isIncome: isIncome,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _CelebrationBanner extends StatefulWidget {
  final String title;
  final double amount;
  final String? bankName;
  final bool isIncome;
  final VoidCallback onDismiss;

  const _CelebrationBanner({
    required this.title,
    required this.amount,
    this.bankName,
    required this.isIncome,
    required this.onDismiss,
  });

  @override
  State<_CelebrationBanner> createState() => _CelebrationBannerState();
}

class _CelebrationBannerState extends State<_CelebrationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _slideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Auto dismiss after 2.0 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final accentColor =
        widget.isIncome ? AppColors.income : AppColors.capybaraAmber;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xF524272D),
                    Color(0xFA14161A),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animated Success Check / Coin
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        widget.isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.check_rounded,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.bankName != null
                              ? (widget.isIncome
                                  ? 'Пополнение • ${widget.bankName}'
                                  : 'Списано • ${widget.bankName}')
                              : (widget.isIncome
                                  ? 'Пополнение баланса'
                                  : 'Быстрый расход учтен'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Text(
                    CurrencyFormatter.format(widget.amount, showSign: true),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
