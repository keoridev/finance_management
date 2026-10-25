import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_type.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'add_transaction_modal.dart';
import 'glass_container.dart';

class InteractiveHomeWidget extends StatefulWidget {
  final FinanceController controller;

  const InteractiveHomeWidget({super.key, required this.controller});

  @override
  State<InteractiveHomeWidget> createState() => _InteractiveHomeWidgetState();
}

class _InteractiveHomeWidgetState extends State<InteractiveHomeWidget> {
  bool _hideBalance = false;

  void _depositQuickToDream() {
    HapticFeedback.mediumImpact();
    widget.controller.depositToDreamGoal(100.0);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E1A16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.capybaraAmber, width: 1),
        ),
        content: const Row(
          children: [
            Icon(Icons.star_rounded, color: AppColors.capybaraAmber, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '100 сом переведено в копилку мечты!',
                style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.controller.activeBalance;
    final accountName = widget.controller.activeAccountLabel;
    final income = widget.controller.periodIncome;
    final expense = widget.controller.periodExpense;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      surfaceColor: const Color(0xFF181512).withValues(alpha: 0.88),
      borderColor: AppColors.capybaraAmber.withValues(alpha: 0.32),
      borderWidth: 1.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Widget Label, Active Bank & Privacy Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.capybaraAmber,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.capybaraAmber,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ИНТЕРАКТИВНЫЙ ВИДЖЕТ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.capybaraAmber,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      accountName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _hideBalance = !_hideBalance);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        _hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 16,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Balance Display
          Text(
            _hideBalance ? '••••••' : CurrencyFormatter.format(balance),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Cashflow subtitle
          Row(
            children: [
              Icon(
                income >= expense ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: income >= expense ? AppColors.income : AppColors.expense,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  income >= expense
                      ? '+${CurrencyFormatter.format(income - expense)} профицит за период'
                      : '-${CurrencyFormatter.format(expense - income)} дефицит за период',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: income >= expense ? AppColors.income : AppColors.expense,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Usable Action Buttons Directly in Widget
          Row(
            children: [
              // 1. Add Expense
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    AddTransactionModal.show(context, widget.controller, defaultType: TransactionType.expense);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.capybaraAmber, AppColors.capybaraCopper],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.capybaraAmber.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF161412)),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Расход',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF161412),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Deposit 100 to dream goal in 1 tap
              Expanded(
                child: InkWell(
                  onTap: _depositQuickToDream,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.capybaraAmber.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: AppColors.capybaraAmber),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '+100 в цель',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Add Income
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    AddTransactionModal.show(context, widget.controller, defaultType: TransactionType.income);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.income),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Доход',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
