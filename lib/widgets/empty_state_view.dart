import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_container.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    this.icon = Icons.auto_awesome_rounded,
    this.title = 'Пока чисто, как в коде после рефакторинга',
    this.subtitle = 'Кошелек отдыхает, баланс под контролем',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glass circle with subtle glow and icon
            GlassContainer(
              padding: const EdgeInsets.all(22),
              borderRadius: BorderRadius.circular(32),
              surfaceColor: Colors.white.withValues(alpha: 0.05),
              borderColor: Colors.white.withValues(alpha: 0.12),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.45),
                height: 1.4,
              ),
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onAction!();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                      const SizedBox(width: 6),
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
