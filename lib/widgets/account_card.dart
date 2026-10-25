import 'package:flutter/material.dart';
import '../models/account.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'animated_currency_text.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final bool isSelected;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      width: 170,
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      surfaceColor: isSelected
          ? const Color(0xFF2C2C2E).withValues(alpha: 0.9)
          : const Color(0xFF1C1C1E).withValues(alpha: 0.6),
      borderColor: isSelected ? AppColors.iosBlue : Colors.white.withValues(alpha: 0.12),
      borderWidth: isSelected ? 1.5 : 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: account.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        account.type.icon,
                        size: 15,
                        color: account.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        account.bankName,
                        style: const TextStyle(
                          fontSize: 12,
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
              if (account.lastDigits != null) ...[
                const SizedBox(width: 6),
                Text(
                  '• ${account.lastDigits}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedCurrencyText(
                  amount: account.balance,
                  currency: account.currency,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
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
