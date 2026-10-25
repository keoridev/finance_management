class CurrencyRate {
  final String code;
  final String name;
  final String flagEmoji; // Used as currency symbol ($ € ₽ ₸ ¥) without emojis
  final double officialRate; // Курс НБКР (в сомах)
  final double buyRate; // Покупка в банках Бишкека
  final double sellRate; // Продажа в банках Бишкека
  final double change24h; // Изменение в %

  const CurrencyRate({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.officialRate,
    required this.buyRate,
    required this.sellRate,
    required this.change24h,
  });

  bool get isUp => change24h >= 0;

  static List<CurrencyRate> get defaultRates => const [
        CurrencyRate(
          code: 'USD',
          name: 'Доллар США',
          flagEmoji: '\$',
          officialRate: 87.45,
          buyRate: 87.20,
          sellRate: 87.75,
          change24h: 0.12,
        ),
        CurrencyRate(
          code: 'EUR',
          name: 'Евро',
          flagEmoji: '€',
          officialRate: 94.80,
          buyRate: 94.30,
          sellRate: 95.20,
          change24h: -0.24,
        ),
        CurrencyRate(
          code: 'RUB',
          name: 'Российский рубль',
          flagEmoji: '₽',
          officialRate: 0.952,
          buyRate: 0.940,
          sellRate: 0.965,
          change24h: 0.35,
        ),
        CurrencyRate(
          code: 'KZT',
          name: 'Казахский тенге',
          flagEmoji: '₸',
          officialRate: 0.181,
          buyRate: 0.176,
          sellRate: 0.186,
          change24h: -0.05,
        ),
        CurrencyRate(
          code: 'CNY',
          name: 'Китайский юань',
          flagEmoji: '¥',
          officialRate: 12.15,
          buyRate: 11.95,
          sellRate: 12.35,
          change24h: 0.18,
        ),
      ];
}
