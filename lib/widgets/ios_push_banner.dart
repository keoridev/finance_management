import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_notification.dart';

class IosPushBanner extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;

  const IosPushBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<IosPushBanner> createState() => _IosPushBannerState();
}

class _IosPushBannerState extends State<IosPushBanner> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Dismissible(
              key: ValueKey(notification.id),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: notification.color.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Identity & Time
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: notification.color.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Icon(
                              notification.icon,
                              size: 13,
                              color: notification.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ARC FINANCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'сейчас',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Notification Title
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Notification Body
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),

                    if (notification.actionLabel != null && notification.onAction != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              notification.onAction!();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: notification.color,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: notification.color.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                notification.actionLabel!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
