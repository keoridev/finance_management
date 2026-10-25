class CategoryBudget {
  final String categoryId;
  final double monthlyLimit;

  const CategoryBudget({
    required this.categoryId,
    required this.monthlyLimit,
  });

  CategoryBudget copyWith({
    String? categoryId,
    double? monthlyLimit,
  }) {
    return CategoryBudget(
      categoryId: categoryId ?? this.categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }
}
