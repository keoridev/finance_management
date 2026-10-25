import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class AddBankAccountModal extends StatefulWidget {
  final FinanceController controller;

  const AddBankAccountModal({super.key, required this.controller});

  static Future<void> show(BuildContext context, FinanceController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddBankAccountModal(controller: controller),
    );
  }

  @override
  State<AddBankAccountModal> createState() => _AddBankAccountModalState();
}

class _AddBankAccountModalState extends State<AddBankAccountModal> {
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _lastDigitsController = TextEditingController();
  final _balanceController = TextEditingController();

  final AccountType _selectedType = AccountType.card;
  Color _selectedColor = AppColors.iosBlue;
  String? _selectedBankPreset = 'MBank';

  static const List<String> _bankPresets = [
    'MBank',
    'Оптима Банк',
    'Бакай Банк',
    'Demir Bank',
    'KICB',
    'РСК Банк',
    'Айыл Банк',
    'Finca Банк',
    'Наличные',
    'Свой банк',
  ];

  static const List<Color> _cardColors = [
    AppColors.iosBlue,
    AppColors.iosIndigo,
    AppColors.iosPurple,
    AppColors.iosGreen,
    AppColors.iosOrange,
    AppColors.iosRed,
    AppColors.iosTeal,
    Color(0xFF2C2C2E), // Apple Dark Titanium
  ];

  @override
  void initState() {
    super.initState();
    _bankNameController.text = 'MBank';
    _nameController.text = 'MBank Visa';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _lastDigitsController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _onPresetSelected(String preset) {
    setState(() {
      _selectedBankPreset = preset;
      if (preset == 'Свой банк') {
        _bankNameController.clear();
        _nameController.clear();
      } else {
        _bankNameController.text = preset;
        _nameController.text = '$preset Card';
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final bankName = _bankNameController.text.trim().isEmpty ? 'Банк' : _bankNameController.text.trim();
    final balance = double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0;
    final lastDigits = _lastDigitsController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название счета или карты')),
      );
      return;
    }

    widget.controller.addAccount(
      name: name,
      bankName: bankName,
      lastDigits: lastDigits.isNotEmpty ? lastDigits : null,
      initialBalance: balance,
      type: _selectedType,
      color: _selectedColor,
      currency: 'сом',
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Счет "$name" ($bankName) успешно добавлен!'),
        backgroundColor: _selectedColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),

            const Text(
              'Добавить банк / счет',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Bank Presets
            const Text(
              'Выберите банк или создайте свой',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bankPresets.map((preset) {
                final isSelected = preset == _selectedBankPreset;
                return InkWell(
                  onTap: () => _onPresetSelected(preset),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.iosBlue
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.iosBlue : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      preset,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Bank Name & Account Name Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bankNameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Банк',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lastDigitsController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Посл. 4 цифры',
                      hintText: '4820',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Account Name
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Название счета (для вас)',
                hintText: 'Например: Зарплатная MBank, Накопления',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Initial Balance
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}'))],
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Начальный баланс',
                suffixText: 'сом',
                suffixStyle: const TextStyle(color: AppColors.iosBlue, fontWeight: FontWeight.w700),
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Card Color
            const Text(
              'Цвет карты',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _cardColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = _cardColors[index];
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            // Save Button
            GlassContainer(
              height: 50,
              borderRadius: BorderRadius.circular(14),
              surfaceColor: AppColors.iosBlue,
              onTap: _save,
              child: const Center(
                child: Text(
                  'Добавить счет в сомах',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
