import 'package:flutter/material.dart';
import 'glass_container.dart';

class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-2.0, -0.3),
              end: const Alignment(2.0, 0.3),
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.05),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Balance Card Skeleton
          GlassContainer(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 120, height: 14, borderRadius: BorderRadius.circular(6)),
                    SkeletonBox(width: 80, height: 22, borderRadius: BorderRadius.circular(12)),
                  ],
                ),
                const SizedBox(height: 14),
                SkeletonBox(width: 200, height: 36, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.circular(10)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 50, height: 10, borderRadius: BorderRadius.circular(4)),
                              const SizedBox(height: 6),
                              SkeletonBox(width: 75, height: 14, borderRadius: BorderRadius.circular(4)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.circular(10)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 50, height: 10, borderRadius: BorderRadius.circular(4)),
                              const SizedBox(height: 6),
                              SkeletonBox(width: 75, height: 14, borderRadius: BorderRadius.circular(4)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Accounts Row Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 100, height: 18, borderRadius: BorderRadius.circular(6)),
              SkeletonBox(width: 60, height: 14, borderRadius: BorderRadius.circular(4)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              children: List.generate(
                2,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index == 0 ? 12 : 0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.circular(10)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 80, height: 12, borderRadius: BorderRadius.circular(4)),
                              const SizedBox(height: 6),
                              SkeletonBox(width: 110, height: 16, borderRadius: BorderRadius.circular(4)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Transactions List Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 140, height: 18, borderRadius: BorderRadius.circular(6)),
              SkeletonBox(width: 80, height: 14, borderRadius: BorderRadius.circular(4)),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    SkeletonBox(width: 40, height: 40, borderRadius: BorderRadius.circular(12)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 130, height: 14, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 6),
                          SkeletonBox(width: 80, height: 11, borderRadius: BorderRadius.circular(4)),
                        ],
                      ),
                    ),
                    SkeletonBox(width: 70, height: 16, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
