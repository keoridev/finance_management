class ReceiptItem {
  final String name;
  final double price;
  final String categoryId;
  final String categoryName;
  final bool isImpulseOrJunk;
  final String? capybaraComment;

  const ReceiptItem({
    required this.name,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    this.isImpulseOrJunk = false,
    this.capybaraComment,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isImpulseOrJunk': isImpulseOrJunk,
      'capybaraComment': capybaraComment,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      name: map['name'] as String? ?? 'Товар',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] as String? ?? 'cat_groceries',
      categoryName: map['categoryName'] as String? ?? 'Продукты',
      isImpulseOrJunk: map['isImpulseOrJunk'] as bool? ?? false,
      capybaraComment: map['capybaraComment'] as String?,
    );
  }
}

class ParsedReceipt {
  final String merchant;
  final List<ReceiptItem> items;
  final double totalAmount;
  final DateTime date;
  final String rawText;
  final String? mainCapybaraAlert;

  const ParsedReceipt({
    required this.merchant,
    required this.items,
    required this.totalAmount,
    required this.date,
    required this.rawText,
    this.mainCapybaraAlert,
  });
}
