import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class ReceiptDetailModal extends StatelessWidget {
  final Transaction transaction;
  final TransactionCategory? category;
  final Account? account;

  const ReceiptDetailModal({
    super.key,
    required this.transaction,
    this.category,
    this.account,
  });

  static Future<void> show(
    BuildContext context, {
    required Transaction transaction,
    TransactionCategory? category,
    Account? account,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReceiptDetailModal(
        transaction: transaction,
        category: category,
        account: account,
      ),
    );
  }

  bool get _isIncome => transaction.type == TransactionType.income;
  bool get _isQr =>
      (transaction.note?.toLowerCase().contains('qr') == true) ||
      transaction.title.toLowerCase().contains('qr');

  String get _formattedReceiptId {
    final hex = transaction.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final short = hex.length >= 8 ? hex.substring(0, 8).toUpperCase() : '84729104';
    return '#MB-$short';
  }

  @override
  Widget build(BuildContext context) {
    final catColor = category?.color ?? AppColors.catOther;
    final catIcon = category?.icon ?? Icons.category_rounded;
    final amountSign = _isIncome ? '+' : '−';
    final amountColor = _isIncome ? AppColors.income : Colors.white;

    final dateFormatted =
        '${AppDateFormatter.formatFullDate(transaction.date)} в ${AppDateFormatter.formatTime(transaction.date)}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull handle bar
              Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),

              // The Ticket Card
              ClipPath(
                clipper: const _TicketClipper(notchRadius: 12, notchYRatio: 0.44),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Ticket Half (Header, Title, Amount)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                        child: Column(
                          children: [
                            // Badge & Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: _isQr
                                            ? const Color(0xFFFFD60A).withValues(alpha: 0.18)
                                            : const Color(0xFF00E5FF).withValues(alpha: 0.16),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isQr ? Icons.qr_code_scanner_rounded : Icons.receipt_long_rounded,
                                        size: 16,
                                        color: _isQr ? const Color(0xFFFFD60A) : const Color(0xFF00E5FF),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isQr ? 'ЧЕК QR-ОПЛАТЫ' : 'ЭЛЕКТРОННЫЙ ЧЕК',
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.income.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.income.withValues(alpha: 0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 12, color: AppColors.income),
                                      SizedBox(width: 4),
                                      Text(
                                        'Исполнен',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.income,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Merchant / Title
                            Text(
                              transaction.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$amountSign${CurrencyFormatter.format(transaction.amount, currency: '')}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: amountColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'сом',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.70),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Perforated Dashed Line
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: CustomPaint(
                          size: const Size(double.infinity, 1),
                          painter: _DashedLinePainter(),
                        ),
                      ),

                      // Bottom Ticket Half (Details Table & Barcode)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                        child: Column(
                          children: [
                            _buildReceiptRow('Дата и время', dateFormatted),
                            const SizedBox(height: 11),
                            _buildReceiptRow(
                              'Способ оплаты',
                              account?.bankName ?? 'MBank ••9303',
                              leadingIcon: Icons.account_balance_wallet_outlined,
                            ),
                            const SizedBox(height: 11),
                            _buildReceiptRow(
                              'Категория',
                              category?.name ?? 'Прочее',
                              badgeColor: catColor,
                              badgeIcon: catIcon,
                            ),
                            const SizedBox(height: 11),
                            _buildReceiptRow(
                              'Тип операции',
                              _isIncome
                                  ? 'Пополнение счета'
                                  : (_isQr ? 'Оплата по QR' : 'Списание / Платеж'),
                            ),
                            const SizedBox(height: 11),
                            _buildReceiptRow('Код операции', _formattedReceiptId),

                            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                              const SizedBox(height: 11),
                              _buildReceiptRow(
                                'Детали',
                                transaction.note!,
                                isFlexible: true,
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Stylized Barcode
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Column(
                                children: [
                                  CustomPaint(
                                    size: const Size(double.infinity, 38),
                                    painter: _BarcodePainter(),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'АВТОМАТИЧЕСКАЯ ФИНАНСОВАЯ КВИТАНЦИЯ • ARC FINANCE',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 0.8,
                                      color: Colors.white.withValues(alpha: 0.35),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Закрыть',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final shareSummary = '''
ЧЕК ОБ ОПЛАТЕ • ARC FINANCE
━━━━━━━━━━━━━━━━━━━━
Торговая точка: ${transaction.title}
Сумма: $amountSign${CurrencyFormatter.format(transaction.amount)}
Дата: $dateFormatted
Счет: ${account?.bankName ?? "MBank"}
Категория: ${category?.name ?? "Прочее"}
Номер чека: $_formattedReceiptId
Статус: Исполнен ✓
━━━━━━━━━━━━━━━━━━━━
''';
                        Clipboard.setData(ClipboardData(text: shareSummary));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.income, size: 18),
                                SizedBox(width: 8),
                                Text('Данные чека скопированы в буфер'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF2C2C2E),
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9F0A),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Поделиться чеком',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    Color? badgeColor,
    IconData? badgeIcon,
    IconData? leadingIcon,
    bool isFlexible = false,
  }) {
    return Row(
      crossAxisAlignment:
          isFlexible ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.45),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeColor != null && badgeIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(badgeIcon, size: 12, color: badgeColor),
                ),
                const SizedBox(width: 6),
              ],
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: Colors.white.withValues(alpha: 0.50)),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: isFlexible ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom clipper that punches two circular cutouts at the tear-off notch line
class _TicketClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchYRatio;

  const _TicketClipper({this.notchRadius = 12, this.notchYRatio = 0.44});

  @override
  Path getClip(Size size) {
    final path = Path();
    final notchY = size.height * notchYRatio;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    // Right edge down to notch
    path.lineTo(size.width, notchY - notchRadius);
    path.arcToPoint(
      Offset(size.width, notchY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height);

    // Bottom edge
    path.lineTo(0, size.height);

    // Left edge up to notch
    path.lineTo(0, notchY + notchRadius);
    path.arcToPoint(
      Offset(0, notchY - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Painter that draws a clean dashed line across the receipt ticket
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1.0;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter that renders an authentic-looking barcode stripe pattern
class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..strokeCap = StrokeCap.butt;

    final widths = [
      1.5, 3.0, 1.0, 2.0, 1.0, 4.0, 1.5, 1.0, 2.5, 3.0, 1.0, 2.0,
      1.5, 4.0, 1.0, 2.5, 1.0, 3.0, 1.5, 2.0, 1.0, 3.5, 1.0, 2.0,
      3.0, 1.5, 2.0, 1.0, 4.0, 1.0, 2.5, 1.5, 3.0, 1.0, 2.0, 1.5,
      2.0, 3.5, 1.0, 2.5, 1.0, 4.0, 1.5, 1.0, 3.0, 2.0, 1.0, 2.5
    ];

    double currentX = 12.0;
    final totalAvailable = size.width - 24.0;
    final scale = totalAvailable / 120.0;

    for (int i = 0; i < widths.length; i++) {
      final w = widths[i] * scale;
      if (i % 2 == 0) {
        paint.strokeWidth = w;
        canvas.drawLine(
          Offset(currentX, 2),
          Offset(currentX, size.height - 2),
          paint,
        );
      }
      currentX += w + (1.2 * scale);
      if (currentX >= size.width - 12) break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

