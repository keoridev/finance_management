import 'package:flutter/material.dart';
import '../models/transaction_type.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class CreateCategoryModal extends StatefulWidget {
  final FinanceController controller;

  const CreateCategoryModal({super.key, required this.controller});

  static Future<void> show(BuildContext context, FinanceController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateCategoryModal(controller: controller),
    );
  }

  @override
  State<CreateCategoryModal> createState() => _CreateCategoryModalState();
}

class _CreateCategoryModalState extends State<CreateCategoryModal> {
  final _nameController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  IconData _selectedIcon = Icons.category_rounded;
  Color _selectedColor = AppColors.iosBlue;

  static const List<IconData> _availableIcons = [
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.restaurant_rounded,
    Icons.coffee_rounded,
    Icons.local_gas_station_rounded,
    Icons.directions_car_rounded,
    Icons.directions_bus_rounded,
    Icons.flight_rounded,
    Icons.home_rounded,
    Icons.apartment_rounded,
    Icons.electrical_services_rounded,
    Icons.medical_services_rounded,
    Icons.fitness_center_rounded,
    Icons.sports_esports_rounded,
    Icons.movie_rounded,
    Icons.music_note_rounded,
    Icons.menu_book_rounded,
    Icons.school_rounded,
    Icons.devices_rounded,
    Icons.phone_iphone_rounded,
    Icons.card_giftcard_rounded,
    Icons.pets_rounded,
    Icons.child_care_rounded,
    Icons.spa_rounded,
    Icons.work_rounded,
    Icons.payments_rounded,
    Icons.attach_money_rounded,
    Icons.trending_up_rounded,
  ];

  static const List<Color> _availableColors = [
    AppColors.iosBlue,
    AppColors.iosGreen,
    AppColors.iosIndigo,
    AppColors.iosPurple,
    AppColors.iosOrange,
    AppColors.iosRed,
    AppColors.iosTeal,
    AppColors.iosYellow,
    Color(0xFFFF375F), // Pink
    AppColors.iosGray,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название категории')),
      );
      return;
    }

    widget.controller.addCategory(
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
      type: _selectedType,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Категория "$name" успешно создана!'),
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
            // iOS drag pill
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

            // Header & Type Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Новая категория',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildTypePill('Расход', TransactionType.expense),
                      _buildTypePill('Доход', TransactionType.income),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview Badge & Name Input
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _selectedColor.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Icon(_selectedIcon, color: _selectedColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Название категории',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Color Selector
            const Text(
              'Цвет категории',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = _availableColors[index];
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Icon Selector Grid
            const Text(
              'Иконка категории',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = _availableIcons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: _selectedColor, width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : AppColors.textLight,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            GlassContainer(
              height: 50,
              borderRadius: BorderRadius.circular(14),
              surfaceColor: AppColors.iosBlue,
              onTap: _save,
              child: const Center(
                child: Text(
                  'Создать категорию',
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

  Widget _buildTypePill(String label, TransactionType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.iosBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
