import 'package:flutter/material.dart';
import '../models/currency_rate.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_container.dart';

class CurrencyRatesCard extends StatelessWidget {
  final FinanceController controller;

  const CurrencyRatesCard({super.key, required this.controller});

  void _showConverterModal(BuildContext context, CurrencyRate initialRate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyConverterSheet(
        controller: controller,
        initialRate: initialRate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rates = controller.currencyRates;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'KGS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Курсы валют (НБКР)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showConverterModal(context, rates.first),
                child: const Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.iosBlue),
                    SizedBox(width: 4),
                    Text(
                      'Конвертер',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iosBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable currency rates chips
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final rate = rates[index];
                return InkWell(
                  onTap: () => _showConverterModal(context, rate),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(rate.flagEmoji, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                rate.code,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${rate.isUp ? '+' : ''}${rate.change24h}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: rate.isUp ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${rate.officialRate.toStringAsFixed(2)} с.',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _CurrencyConverterSheet extends StatefulWidget {
  final FinanceController controller;
  final CurrencyRate initialRate;

  const _CurrencyConverterSheet({
    required this.controller,
    required this.initialRate,
  });

  @override
  State<_CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<_CurrencyConverterSheet> {
  late CurrencyRate _selectedRate;
  final _amountController = TextEditingController(text: '100');
  bool _toKgs = true;

  @override
  void initState() {
    super.initState();
    _selectedRate = widget.initialRate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _result {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (_toKgs) {
      return amount * _selectedRate.officialRate;
    } else {
      return _selectedRate.officialRate > 0 ? amount / _selectedRate.officialRate : 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rates = widget.controller.currencyRates;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Конвертер в сомы',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final r = rates[index];
                final isSelected = r.code == _selectedRate.code;
                return InkWell(
                  onTap: () => setState(() => _selectedRate = r),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.iosBlue : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(r.flagEmoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          r.code,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          GlassContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: BorderRadius.circular(14),
            surfaceColor: Colors.white.withValues(alpha: 0.04),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
                Text(
                  _toKgs ? _selectedRate.code : 'сом',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iosBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Center(
            child: IconButton(
              onPressed: () => setState(() => _toKgs = !_toKgs),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_vert_rounded, color: AppColors.iosBlue, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 6),

          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(14),
            surfaceColor: Colors.white.withValues(alpha: 0.06),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _toKgs ? 'В сомах:' : 'В ${_selectedRate.code}:',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _toKgs
                          ? CurrencyFormatter.format(_result, currency: 'сом', withDecimals: true)
                          : '${_result.toStringAsFixed(2)} ${_selectedRate.code}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  '1 ${_selectedRate.code} = ${_selectedRate.officialRate.toStringAsFixed(2)} сом',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
