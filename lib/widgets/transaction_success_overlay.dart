import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_container.dart';

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
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Auto dismiss after 2.2 seconds
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
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

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
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
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: BorderRadius.circular(22),
            surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
            borderColor: Colors.white.withValues(alpha: 0.18),
            borderWidth: 0.8,
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            child: Row(
              children: [
                // Animated Success Check / Coin
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (widget.isIncome ? AppColors.income : AppColors.iosBlue)
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      widget.isIncome ? Icons.arrow_downward_rounded : Icons.check_rounded,
                      color: widget.isIncome ? AppColors.income : Colors.white,
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
                            ? 'Списано • ${widget.bankName}'
                            : (widget.isIncome ? 'Пополнение баланса' : 'Расход учтен'),
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
                    color: widget.isIncome ? AppColors.income : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
