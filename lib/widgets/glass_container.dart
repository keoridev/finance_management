import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? surfaceColor;
  final Gradient? surfaceGradient;
  final Color? borderColor;
  final Gradient? borderGradient;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 20.0,
    this.surfaceColor,
    this.surfaceGradient,
    this.borderColor,
    this.borderGradient,
    this.borderWidth = 0.8,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(20);

    // True Apple frosted glass surface: neutral translucent dark slate
    final defaultSurfaceColor = const Color(0xFF1C1C1E).withValues(alpha: 0.60);

    // Subtle Apple specular hairline border
    final defaultBorderColor = Colors.white.withValues(alpha: 0.12);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceGradient == null ? (surfaceColor ?? defaultSurfaceColor) : null,
        gradient: surfaceGradient,
        borderRadius: effectiveRadius,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            foregroundPainter: _GlassBorderPainter(
              borderRadius: effectiveRadius,
              borderWidth: borderWidth,
              borderColor: borderColor ?? defaultBorderColor,
              borderGradient: borderGradient,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Gradient? borderGradient;

  _GlassBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.borderColor,
    this.borderGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth <= 0) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(borderWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (borderGradient != null) {
      paint.shader = borderGradient!.createShader(rect);
    } else {
      paint.color = borderColor;
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderGradient != borderGradient;
  }
}

/// Clean Apple OLED Background Scaffold (pure minimal black backdrop, no neon disco)
class GlassBackgroundScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;

  const GlassBackgroundScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
