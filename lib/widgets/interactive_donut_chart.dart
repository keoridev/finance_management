import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_category.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class ChartSegment {
  final TransactionCategory category;
  final double amount;
  final double percentage;
  final Color color;

  const ChartSegment({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class InteractiveDonutChart extends StatefulWidget {
  final Map<TransactionCategory, double> breakdown;
  final double totalAmount;
  final ValueChanged<TransactionCategory?>? onCategorySelected;

  const InteractiveDonutChart({
    super.key,
    required this.breakdown,
    required this.totalAmount,
    this.onCategorySelected,
  });

  @override
  State<InteractiveDonutChart> createState() => _InteractiveDonutChartState();
}

class _InteractiveDonutChartState extends State<InteractiveDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant InteractiveDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount ||
        oldWidget.breakdown.length != widget.breakdown.length) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<ChartSegment> get _segments {
    final list = <ChartSegment>[];
    if (widget.totalAmount <= 0) return list;

    final sortedEntries = widget.breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final e in sortedEntries) {
      final pct = e.value / widget.totalAmount;
      list.add(ChartSegment(
        category: e.key,
        amount: e.value,
        percentage: pct,
        color: e.key.color,
      ));
    }
    return list;
  }

  void _handleTap(Offset localPosition, Size size) {
    if (_segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);

    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.70;

    // Check if clicked inside donut ring
    if (dist < innerRadius * 0.70 || dist > outerRadius * 1.15) {
      if (_selectedIndex != null) {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = null);
        widget.onCategorySelected?.call(null);
      }
      return;
    }

    double angle = atan2(dy, dx);
    angle = (angle + pi / 2);
    if (angle < 0) angle += 2 * pi;

    double cumulativeAngle = 0.0;
    for (int i = 0; i < _segments.length; i++) {
      final sweep = _segments[i].percentage * 2 * pi;
      if (angle >= cumulativeAngle && angle < cumulativeAngle + sweep) {
        HapticFeedback.selectionClick();
        setState(() {
          if (_selectedIndex == i) {
            _selectedIndex = null;
            widget.onCategorySelected?.call(null);
          } else {
            _selectedIndex = i;
            widget.onCategorySelected?.call(_segments[i].category);
          }
        });
        return;
      }
      cumulativeAngle += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = _segments;

    if (segments.isEmpty || widget.totalAmount <= 0) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Нет данных о расходах',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final selectedSegment =
        (_selectedIndex != null && _selectedIndex! < segments.length)
            ? segments[_selectedIndex!]
            : null;

    return Column(
      children: [
        // Slender Apple Donut Chart
        Center(
          child: SizedBox(
            width: 230,
            height: 230,
            child: GestureDetector(
              onTapUp: (details) {
                _handleTap(details.localPosition, const Size(230, 230));
              },
              child: AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(230, 230),
                        painter: _DonutChartPainter(
                          segments: segments,
                          selectedIndex: _selectedIndex,
                          animationProgress: _progressAnim.value,
                        ),
                      ),
                      // Center Label (Selected Category or Total)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: selectedSegment != null
                            ? _buildSelectedCenter(selectedSegment)
                            : _buildDefaultCenter(widget.totalAmount),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Category Legend Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: segments.map((seg) {
            final isSelected =
                _selectedIndex != null && segments[_selectedIndex!] == seg;
            final pct = (seg.percentage * 100).toStringAsFixed(0);

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  final idx = segments.indexOf(seg);
                  if (_selectedIndex == idx) {
                    _selectedIndex = null;
                    widget.onCategorySelected?.call(null);
                  } else {
                    _selectedIndex = idx;
                    widget.onCategorySelected?.call(seg.category);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? seg.color.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? seg.color
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.2 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: seg.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      seg.category.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: seg.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDefaultCenter(double total) {
    return Column(
      key: const ValueKey('default_center'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Всего за месяц',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(total),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCenter(ChartSegment segment) {
    final pct = (segment.percentage * 100).toStringAsFixed(1);
    return Column(
      key: ValueKey('selected_${segment.category.id}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: segment.color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(segment.category.icon, size: 14, color: segment.color),
        ),
        const SizedBox(height: 3),
        Text(
          segment.category.name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.format(segment.amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: segment.color,
          ),
        ),
        Text(
          '$pct% от всех трат',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final int? selectedIndex;
  final double animationProgress;

  _DonutChartPainter({
    required this.segments,
    required this.selectedIndex,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 12;
    const strokeWidth = 14.0; // Slender, airy Apple ring thickness
    final innerRadius = outerRadius - strokeWidth;

    // Background track ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, (outerRadius + innerRadius) / 2, bgPaint);

    double startAngle = -pi / 2;
    const gapAngle = 0.035;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sweepAngle = (seg.percentage * 2 * pi * animationProgress) - gapAngle;

      if (sweepAngle <= 0) continue;

      final isSelected = selectedIndex == i;
      final currentStrokeWidth = isSelected ? strokeWidth + 4 : strokeWidth;
      final currentRadius = (outerRadius + innerRadius) / 2;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        startAngle + (gapAngle / 2),
        sweepAngle,
        false,
        paint,
      );

      startAngle += seg.percentage * 2 * pi * animationProgress;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.segments != segments;
  }
}
