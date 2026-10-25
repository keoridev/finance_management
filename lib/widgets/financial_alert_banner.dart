import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_type.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import 'add_transaction_modal.dart';
import 'glass_container.dart';

class FinancialAlertBanner extends StatefulWidget {
  final FinanceController controller;

  const FinancialAlertBanner({super.key, required this.controller});

  @override
  State<FinancialAlertBanner> createState() => _FinancialAlertBannerState();
}

class _FinancialAlertBannerState extends State<FinancialAlertBanner> {
  bool _dismissedForSession = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (!widget.controller.isCapybaraAlertState || _dismissedForSession) {
          return const SizedBox.shrink();
        }

        final isBankrupt = widget.controller.capybaraMood == CapybaraMoodState.bankruptSad;
        final accentColor = isBankrupt ? AppColors.expense : AppColors.capybaraAmber;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: BorderRadius.circular(20),
            surfaceColor: const Color(0xFF1C1510).withValues(alpha: 0.94),
            borderColor: accentColor.withValues(alpha: 0.45),
            borderWidth: 1.2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      widget.controller.capybaraMoodImagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Alert details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 15, color: accentColor),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.controller.capybaraMoodTitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _dismissedForSession = true);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.controller.capybaraMoodComment,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick fix action
            InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                AddTransactionModal.show(
                  context,
                  widget.controller,
                  defaultType: TransactionType.income,
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Пополнить баланс',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  }
}
