import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/finance_controller.dart';
import '../state/notification_controller.dart';
import '../theme/app_colors.dart';

class CapybaraMemeBubble extends StatefulWidget {
  final FinanceController controller;
  final VoidCallback? onAction;

  const CapybaraMemeBubble({
    super.key,
    required this.controller,
    this.onAction,
  });

  @override
  State<CapybaraMemeBubble> createState() => _CapybaraMemeBubbleState();
}

class _CapybaraMemeBubbleState extends State<CapybaraMemeBubble>
    with SingleTickerProviderStateMixin {
  int _memeIndex = 0;
  late AnimationController _wiggleController;
  late Animation<double> _wiggleAnimation;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _wiggleAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  void _nextMeme() {
    HapticFeedback.lightImpact();
    _wiggleController.forward(from: 0).then((_) => _wiggleController.reverse());
    setState(() {
      _memeIndex++;
    });
  }

  void _openMemeOracleSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CapybaraMemeOracleSheet(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insight = NotificationController.getDynamicInsight(
      widget.controller,
      offset: _memeIndex,
    );
    final moodImage = widget.controller.capybaraMoodImagePath;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF201B15).withValues(alpha: 0.95),
            const Color(0xFF161310).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: AppColors.capybaraAmber.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.capybaraAmber.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _nextMeme,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Capybara Mascot Avatar with animated bounce/wiggle & amber ring
                GestureDetector(
                  onTap: _openMemeOracleSheet,
                  child: RotationTransition(
                    turns: _wiggleAnimation,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.capybaraAmber,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.capybaraAmber.withValues(alpha: 0.38),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          moodImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Speech Bubble Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Category Icon, Title, and Action Buttons
                      Row(
                        children: [
                          Icon(
                            insight.icon,
                            size: 13,
                            color: AppColors.capybaraAmber,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              insight.title.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppColors.capybaraAmber,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),

                          // "ЕЩЕ МЕМ" Shuffle Button
                          InkWell(
                            onTap: _nextMeme,
                            borderRadius: BorderRadius.circular(7),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.capybaraAmber.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: AppColors.capybaraAmber.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 11,
                                    color: AppColors.capybaraAmber,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'ЕЩЕ МЕМ',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.capybaraAmber,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // "ВСЕ" Oracle Sheet Button
                          InkWell(
                            onTap: _openMemeOracleSheet,
                            borderRadius: BorderRadius.circular(7),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Animated Meme Body Punchline
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          insight.body,
                          key: ValueKey('meme_$_memeIndex'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.94),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),

                      // Tag and Prompt Hint
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                insight.statusTag,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Тапни для следующего',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// Full-screen Bottom Sheet Oracle with all 30+ Bishkek & Financial Memes
class _CapybaraMemeOracleSheet extends StatefulWidget {
  final FinanceController controller;

  const _CapybaraMemeOracleSheet({required this.controller});

  @override
  State<_CapybaraMemeOracleSheet> createState() =>
      _CapybaraMemeOracleSheetState();
}

class _CapybaraMemeOracleSheetState extends State<_CapybaraMemeOracleSheet> {
  String _selectedFilter = 'Все';

  static const List<String> _filters = [
    'Все',
    'Бишкек',
    'Ночной жор',
    'Дордой',
    'Winter Arc',
    'Дзен',
  ];

  @override
  Widget build(BuildContext context) {
    // Generate pool of 35 items
    final List<CapybaraInsight> allMemes = [];
    for (int i = 0; i < 40; i++) {
      final item = NotificationController.getDynamicInsight(
        widget.controller,
        offset: i,
      );
      if (!allMemes.any((m) => m.title == item.title)) {
        allMemes.add(item);
      }
    }

    final filtered = allMemes.where((m) {
      if (_selectedFilter == 'Все') return true;
      if (_selectedFilter == 'Бишкек') {
        return m.title.contains('Бишкек') ||
            m.statusTag.contains('БИШКЕК') ||
            m.body.contains('Бишкек') ||
            m.body.contains('Ошском') ||
            m.body.contains('Глобус');
      }
      if (_selectedFilter == 'Ночной жор') {
        return m.title.contains('Ночн') ||
            m.statusTag.contains('ЖОР') ||
            m.body.contains('лагман') ||
            m.body.contains('самсы');
      }
      if (_selectedFilter == 'Дордой') {
        return m.title.contains('Дордой') ||
            m.statusTag.contains('ДОРДОЙ') ||
            m.body.contains('Дордой');
      }
      if (_selectedFilter == 'Winter Arc') {
        return m.title.contains('Winter') ||
            m.statusTag.contains('WINTER') ||
            m.body.contains('стрик') ||
            m.body.contains('самурай');
      }
      if (_selectedFilter == 'Дзен') {
        return m.mood == 'zen' ||
            m.statusTag.contains('ДЗЕН') ||
            m.body.contains('чай');
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF141210).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.capybaraAmber.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.capybaraAmber, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      widget.controller.capybaraMoodImagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Мемный Оракул Капибары',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Житейская финансовая мудрость Бишкека',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.capybaraAmber,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category filter pills
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: AppColors.capybaraAmber,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? const Color(0xFF161412) : Colors.white70,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.capybaraAmber
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedFilter = filter);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Memes List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final meme = filtered[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                meme.icon,
                                size: 14,
                                color: AppColors.capybaraAmber,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                meme.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.capybaraAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              meme.statusTag,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.capybaraAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meme.body,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
