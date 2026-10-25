import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'transaction_type.dart';

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  static const List<TransactionCategory> defaultCategories = [
    // Расходы
    TransactionCategory(
      id: 'cat_groceries',
      name: 'Продукты',
      icon: Icons.shopping_basket_outlined,
      color: AppColors.catGroceries,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'cat_transport',
      name: 'Транспорт',
      icon: Icons.directions_subway_outlined,
      color: AppColors.catTransport,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'cat_housing',
      name: 'Жилье и ЖКХ',
      icon: Icons.home_work_outlined,
      color: AppColors.catHousing,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'cat_restaurants',
      name: 'Кафе и еда',
      icon: Icons.restaurant_outlined,
      color: AppColors.catRestaurants,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'cat_health',
      name: 'Здоровье и аптеки',
      icon: Icons.local_hospital_outlined,
      color: AppColors.catHealth,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'cat_shopping',
      name: 'Покупки и одежда',
      icon: Icons.shopping_bag_outlined,
      color: AppColors.catShopping,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'cat_entertainment',
      name: 'Развлечения и отдых',
      icon: Icons.movie_outlined,
      color: AppColors.catEntertainment,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'cat_other_expense',
      name: 'Другие расходы',
      icon: Icons.category_outlined,
      color: AppColors.catOther,
      type: TransactionType.expense,
    ),

    // Доходы
    TransactionCategory(
      id: 'cat_salary',
      name: 'Заработная плата',
      icon: Icons.payments_outlined,
      color: AppColors.income,
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'cat_freelance',
      name: 'Подработка / Фриланс',
      icon: Icons.laptop_chromebook_outlined,
      color: AppColors.catTransport,
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'cat_investment_income',
      name: 'Дивиденды и %',
      icon: Icons.trending_up_outlined,
      color: AppColors.catHousing,
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'cat_other_income',
      name: 'Прочий доход',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.catOther,
      type: TransactionType.income,
    ),
  ];
}
