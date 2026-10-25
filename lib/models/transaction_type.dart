enum TransactionType {
  expense,
  income,
  transfer;

  String get label {
    switch (this) {
      case TransactionType.expense:
        return 'Расход';
      case TransactionType.income:
        return 'Доход';
      case TransactionType.transfer:
        return 'Перевод';
    }
  }
}
