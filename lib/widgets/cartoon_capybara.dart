import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Highly stylized, cute cartoon Capybara mascot with customizable
/// expressions, idle breathing, eye-blinking, and hand tapping.
class CartoonCapybara extends StatelessWidget {
  final double size;
  final double breath; // -1.0 to 1.0
  final double blink; // 0.0 (open) to 1.0 (closed)
  final double armTap; // 0.0 to 1.0 (tapping coin or calculator)
  final bool showMandarin;
  final bool showSpectacles;
  final bool isHappy;

  const CartoonCapybara({
    super.key,
    this.size = 130,
    this.breath = 0.0,
    this.blink = 0.0,
    this.armTap = 0.0,
    this.showMandarin = true,
    this.showSpectacles = false,
    this.isHappy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CartoonCapybaraPainter(
          breath: breath,
          blink: blink,
          armTap: armTap,
          showMandarin: showMandarin,
          showSpectacles: showSpectacles,
          isHappy: isHappy,
        ),
      ),
    );
  }
}

class _CartoonCapybaraPainter extends CustomPainter {
  final double breath;
  final double blink;
  final double armTap;
  final bool showMandarin;
  final bool showSpectacles;
  final bool isHappy;

  _CartoonCapybaraPainter({
    required this.breath,
    required this.blink,
    required this.armTap,
    required this.showMandarin,
    required this.showSpectacles,
    required this.isHappy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cX = w / 2;
    final cY = h / 2 + breath * 3.0;

    // Palette
    const furDark = Color(0xFF9E6534);
    const furMain = Color(0xFFBA8048);
    const furLight = Color(0xFFD49C65);
    const muzzleColor = Color(0xFFE5BE8C);
    const darkDetails = Color(0xFF2C1E18);
    const blushColor = Color(0xFFFF8B70);
    const orangeColor = Color(0xFFFF9500);
    const leafColor = Color(0xFF34C759);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // 0. Drop shadow under capybara
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cX, h - 8),
        width: w * 0.72,
        height: 14,
      ),
      shadowPaint,
    );

    // 1. Back Ears
    final leftEarCenter = Offset(cX - w * 0.28, cY - h * 0.26);
    final rightEarCenter = Offset(cX + w * 0.28, cY - h * 0.26);

    _drawEar(canvas, leftEarCenter, w * 0.11, furDark, furMain);
    _drawEar(canvas, rightEarCenter, w * 0.11, furDark, furMain);

    // 2. Main Body / Head (Chubby, round, cute silhouette)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cX, cY - h * 0.02),
        width: w * 0.76,
        height: h * 0.68,
      ),
      Radius.circular(w * 0.32),
    );

    final headGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [furLight, furMain, furDark],
    );

    final headPaint = Paint()
      ..shader = headGradient.createShader(headRect.outerRect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(headRect, headPaint);

    // 3. Cute chubby cheeks & Muzzle
    final muzzleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cX, cY + h * 0.12),
        width: w * 0.58,
        height: h * 0.36,
      ),
      Radius.circular(w * 0.22),
    );

    final muzzlePaint = Paint()
      ..color = muzzleColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(muzzleRect, muzzlePaint);

    // Rosy Blush on cheeks
    final blushPaint = Paint()
      ..color = blushColor.withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cX - w * 0.25, cY + h * 0.08),
        width: w * 0.14,
        height: h * 0.07,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cX + w * 0.25, cY + h * 0.08),
        width: w * 0.14,
        height: h * 0.07,
      ),
      blushPaint,
    );

    // 4. Cute Snout & Nose
    final noseCenter = Offset(cX, cY + h * 0.06);
    final noseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: noseCenter,
        width: w * 0.20,
        height: h * 0.11,
      ),
      Radius.circular(w * 0.07),
    );
    final nosePaint = Paint()
      ..color = darkDetails
      ..style = PaintingStyle.fill;
    canvas.drawRRect(noseRect, nosePaint);

    // Little nostrils
    final nostrilPaint = Paint()
      ..color = const Color(0xFF140D0A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cX - w * 0.05, cY + h * 0.07), w * 0.016, nostrilPaint);
    canvas.drawCircle(Offset(cX + w * 0.05, cY + h * 0.07), w * 0.016, nostrilPaint);

    // Cute mouth line
    final mouthPaint = Paint()
      ..color = darkDetails
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    mouthPath.moveTo(cX, cY + h * 0.115);
    mouthPath.lineTo(cX, cY + h * 0.16);

    // Gentle 3-smile curve
    mouthPath.moveTo(cX - w * 0.09, cY + h * 0.18);
    mouthPath.quadraticBezierTo(
      cX - w * 0.045,
      cY + h * 0.22,
      cX,
      cY + h * 0.17,
    );
    mouthPath.quadraticBezierTo(
      cX + w * 0.045,
      cY + h * 0.22,
      cX + w * 0.09,
      cY + h * 0.18,
    );
    canvas.drawPath(mouthPath, mouthPaint);

    // 5. Big expressive Cartoon Eyes
    _drawEye(
      canvas: canvas,
      center: Offset(cX - w * 0.20, cY - h * 0.05),
      size: w * 0.09,
      blink: blink,
      isHappy: isHappy,
      darkColor: darkDetails,
    );

    _drawEye(
      canvas: canvas,
      center: Offset(cX + w * 0.20, cY - h * 0.05),
      size: w * 0.09,
      blink: blink,
      isHappy: isHappy,
      darkColor: darkDetails,
    );

    // 6. Optional: Golden thinking spectacles
    if (showSpectacles) {
      final specPaint = Paint()
        ..color = AppColors.capybaraAmber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;

      // Left lens
      canvas.drawCircle(
        Offset(cX - w * 0.20, cY - h * 0.05),
        w * 0.11,
        specPaint,
      );
      // Right lens
      canvas.drawCircle(
        Offset(cX + w * 0.20, cY - h * 0.05),
        w * 0.11,
        specPaint,
      );
      // Bridge
      canvas.drawLine(
        Offset(cX - w * 0.09, cY - h * 0.05),
        Offset(cX + w * 0.09, cY - h * 0.05),
        specPaint,
      );
    }

    // 7. Signature Japanese Mandarin (Yuzu) on top of head
    if (showMandarin) {
      final orangeCenter = Offset(cX, cY - h * 0.38);
      final orangeRadius = w * 0.11;

      // Drop shadow on head
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cX, cY - h * 0.33),
          width: orangeRadius * 1.8,
          height: orangeRadius * 0.5,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.25),
      );

      // Orange body
      final orangePaint = Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFB84D), orangeColor, Color(0xFFD66900)],
        ).createShader(Rect.fromCircle(center: orangeCenter, radius: orangeRadius));

      canvas.drawCircle(orangeCenter, orangeRadius, orangePaint);

      // Cute green leaf
      final leafPath = Path();
      leafPath.moveTo(orangeCenter.dx, orangeCenter.dy - orangeRadius * 0.8);
      leafPath.quadraticBezierTo(
        orangeCenter.dx + orangeRadius * 0.9,
        orangeCenter.dy - orangeRadius * 1.6,
        orangeCenter.dx + orangeRadius * 0.4,
        orangeCenter.dy - orangeRadius * 0.4,
      );
      leafPath.close();

      canvas.drawPath(
        leafPath,
        Paint()
          ..color = leafColor
          ..style = PaintingStyle.fill,
      );

      // Stem
      canvas.drawCircle(
        Offset(orangeCenter.dx, orangeCenter.dy - orangeRadius * 0.9),
        2.5,
        Paint()..color = const Color(0xFF5D4037),
      );
    }

    // 8. Cute little paws at the bottom
    final leftPawCenter = Offset(cX - w * 0.18, cY + h * 0.32);
    final tapOffset = math.sin(armTap * math.pi) * 6.0;
    final rightPawCenter = Offset(cX + w * 0.18, cY + h * 0.32 - tapOffset);

    _drawPaw(canvas, leftPawCenter, w * 0.08, muzzleColor, darkDetails);
    _drawPaw(canvas, rightPawCenter, w * 0.08, muzzleColor, darkDetails);
  }

  void _drawEar(Canvas canvas, Offset center, double radius, Color outerColor, Color innerColor) {
    canvas.drawCircle(center, radius, Paint()..color = outerColor);
    canvas.drawCircle(
      center + const Offset(0, 1),
      radius * 0.65,
      Paint()..color = innerColor,
    );
  }

  void _drawEye({
    required Canvas canvas,
    required Offset center,
    required double size,
    required double blink,
    required bool isHappy,
    required Color darkColor,
  }) {
    if (blink > 0.6) {
      // Blinking closed eye: cute little arc
      final blinkPaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;

      final p = Path();
      p.moveTo(center.dx - size * 0.8, center.dy);
      p.quadraticBezierTo(center.dx, center.dy + size * 0.7, center.dx + size * 0.8, center.dy);
      canvas.drawPath(p, blinkPaint);
      return;
    }

    if (isHappy) {
      // Happy squinting eyes: ^-^
      final happyPaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;

      final p = Path();
      p.moveTo(center.dx - size * 0.8, center.dy + size * 0.2);
      p.quadraticBezierTo(center.dx, center.dy - size * 0.7, center.dx + size * 0.8, center.dy + size * 0.2);
      canvas.drawPath(p, happyPaint);
      return;
    }

    // Normal cartoon open eye with sparkling white highlights
    final eyePaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 1.1, height: size * 1.3),
      eyePaint,
    );

    // Big glossy highlight
    canvas.drawCircle(
      Offset(center.dx - size * 0.25, center.dy - size * 0.30),
      size * 0.35,
      Paint()..color = Colors.white,
    );

    // Small secondary specular highlight
    canvas.drawCircle(
      Offset(center.dx + size * 0.25, center.dy + size * 0.25),
      size * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  void _drawPaw(Canvas canvas, Offset center, double radius, Color pawColor, Color nailColor) {
    canvas.drawCircle(center, radius, Paint()..color = pawColor);

    // Little cute toe/nail accents
    final nailPaint = Paint()
      ..color = nailColor
      ..style = PaintingStyle.fill;

    for (int i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(center.dx + i * (radius * 0.5), center.dy - radius * 0.35),
        2.2,
        nailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CartoonCapybaraPainter oldDelegate) {
    return oldDelegate.breath != breath ||
        oldDelegate.blink != blink ||
        oldDelegate.armTap != armTap ||
        oldDelegate.showMandarin != showMandarin ||
        oldDelegate.showSpectacles != showSpectacles ||
        oldDelegate.isHappy != isHappy;
  }
}

