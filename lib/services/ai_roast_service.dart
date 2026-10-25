import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../utils/formatters.dart';

class AIRoastResult {
  final String roastText;
  final String verdict; // 'ТАКСИ-ОЛИГАРХ', 'МАСТЕР ЛАГМАНОВ', 'ХОЛОДНЫЙ КРЕМЕНЬ', 'СЛИВ ДЕНЕГ'
  final Color verdictColor;
  final int toxicityScore; // 1 to 100
  final bool isFromApi;
  final DateTime date;

  const AIRoastResult({
    required this.roastText,
    required this.verdict,
    required this.verdictColor,
    required this.toxicityScore,
    required this.isFromApi,
    required this.date,
  });
}

class AIRoastService {
  static const String _prefApiKey = 'arc_ai_roast_api_key';
  static const String _prefProvider = 'arc_ai_roast_provider';

  static Future<String?> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefApiKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveApiKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefApiKey, key.trim());
    } catch (_) {}
  }

  static Future<String> getProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefProvider) ?? 'gemini';
    } catch (_) {
      return 'gemini';
    }
  }

  static Future<void> saveProvider(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefProvider, provider);
    } catch (_) {}
  }

  /// Generates weekly roast. Uses Gemini API if API key configured, otherwise
  /// falls back instantly to the local offline Bishkek Roast Engine.
  static Future<AIRoastResult> generateRoast({
    required List<Transaction> transactions,
    required double totalBalance,
    required int streak,
    String dreamGoal = 'MacBook Pro M3',
    double remainingGoal = 120000.0,
  }) async {
    final apiKey = await getApiKey();

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final apiResult = await _callGeminiApi(
          apiKey: apiKey,
          transactions: transactions,
          totalBalance: totalBalance,
          streak: streak,
          dreamGoal: dreamGoal,
          remainingGoal: remainingGoal,
        );
        if (apiResult != null) return apiResult;
      } catch (e) {
        debugPrint('[AIRoastService] Gemini API call failed: $e. Falling back to local engine.');
      }
    }

    return _generateLocalBishkekRoast(
      transactions: transactions,
      totalBalance: totalBalance,
      streak: streak,
      dreamGoal: dreamGoal,
      remainingGoal: remainingGoal,
    );
  }

  /// REST call to Gemini 1.5 Flash using standard dart:io HttpClient
  static Future<AIRoastResult?> _callGeminiApi({
    required String apiKey,
    required List<Transaction> transactions,
    required double totalBalance,
    required int streak,
    required String dreamGoal,
    required double remainingGoal,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);

    try {
      final now = DateTime.now();
      final recent = transactions
          .where((t) => t.date.isAfter(now.subtract(const Duration(days: 7))))
          .take(15)
          .map((t) => {
                'title': t.title,
                'amount': t.amount,
                'type': t.type.name,
                'category': t.categoryId,
                'date': t.date.toIso8601String(),
              })
          .toList();

      final prompt =
          'Ты — циничная, жесткая, саркастичная капибара-финансист из Бишкека в рамках Winter Arc. '
          'Прожарь пользователя максимально токсично за его недельные траты. Используй молодежный сленг, '
          'бишкекский колорит (маршрутки, лагманы, Фаиза, Дордой, Яндекс Такси). '
          'Цель пользователя: накопить на $dreamGoal (осталось ${remainingGoal.toInt()} сом). '
          'Текущий баланс: ${totalBalance.toInt()} сом. Стрик без спонтанных трат: $streak дней. '
          'Список трат за неделю: ${jsonEncode(recent)}. '
          'Формат ответа строго JSON:\n'
          '{"verdict": "КОРОТКИЙ ВЕРДИКТ В ВЕРХНЕМ РЕГИСТРЕ (до 20 символов)", '
          '"roast": "Текст прожарки на 3-5 предложений. Без эмодзи, только чистый сарказм.", '
          '"toxicity": число от 60 до 99}';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.85,
          'maxOutputTokens': 400,
        }
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody);
        final candidateText =
            json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

        if (candidateText != null) {
          // Extract JSON from markdown fences if any
          final cleaned = candidateText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final parsed = jsonDecode(cleaned);

          return AIRoastResult(
            roastText: parsed['roast'] as String? ?? 'Слишком много трат, капибара в шоке.',
            verdict: parsed['verdict'] as String? ?? 'СЛИВ ДЕНЕГ',
            verdictColor: const Color(0xFFFF453A),
            toxicityScore: (parsed['toxicity'] as num?)?.toInt() ?? 88,
            isFromApi: true,
            date: DateTime.now(),
          );
        }
      }
    } finally {
      client.close();
    }
    return null;
  }

  /// Authentic Bishkek Toxic Roast Generator (100% offline, zero network delay)
  static AIRoastResult _generateLocalBishkekRoast({
    required List<Transaction> transactions,
    required double totalBalance,
    required int streak,
    required String dreamGoal,
    required double remainingGoal,
  }) {
    final now = DateTime.now();
    final weekExpenses = transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.categoryId != 'cat_savings' &&
        t.date.isAfter(now.subtract(const Duration(days: 7))));

    final totalSpent = weekExpenses.fold(0.0, (s, t) => s + t.amount);

    // Analyze specific category spends
    final cafeSpent = weekExpenses
        .where((t) => t.categoryId == 'cat_restaurants')
        .fold(0.0, (s, t) => s + t.amount);
    final taxiSpent = weekExpenses
        .where((t) => t.categoryId == 'cat_transport')
        .fold(0.0, (s, t) => s + t.amount);
    final shoppingSpent = weekExpenses
        .where((t) => t.categoryId == 'cat_shopping')
        .fold(0.0, (s, t) => s + t.amount);

    if (totalSpent == 0) {
      return AIRoastResult(
        roastText:
            'Ты реально не потратил ни сома за всю неделю? Ты что, заперся в комнате и питаешься фотосинтезом? '
            'Либо в Бишкеке отключили электричество, либо ты забыл внести чек на 2000 сом. '
            'Но если это чистая правда — капибара снимает шляпу. Твой $dreamGoal стал на шаг ближе.',
        verdict: 'ХОЛОДНЫЙ КРЕМЕНЬ',
        verdictColor: const Color(0xFF30D158),
        toxicityScore: 25,
        isFromApi: false,
        date: DateTime.now(),
      );
    }

    if (taxiSpent > 800) {
      return AIRoastResult(
        roastText:
            'Слить ${CurrencyFormatter.format(taxiSpent)} на такси по Бишкеку за 7 дней — ты серьезно? '
            'Ты что, тайный инвестор Яндекс Go? В городе курсируют маршрутки и автобусы за 25 сом, '
            'а ты вызываешь Комфорт+, чтобы проехать три квартала от Советской до Чуя! '
            'С такими темпами твой $dreamGoal будет ждать тебя на складе до 2030 года.',
        verdict: 'ТАКСИ-ОЛИГАРХ',
        verdictColor: const Color(0xFFFF9F0A),
        toxicityScore: 92,
        isFromApi: false,
        date: DateTime.now(),
      );
    }

    if (cafeSpent > 1200) {
      return AIRoastResult(
        roastText:
            'Чек за кафе на ${CurrencyFormatter.format(cafeSpent)} сом? Капибара видит этот ночной лагман, '
            'пиццу и четыре чашки латте сквозь закрытый экран! Ты кормишь весь общепит Бишкека, '
            'пока твоя копилка на $dreamGoal сохнет от голода. С тебя 25 подтягиваний за каждую палочку шашлыка!',
        verdict: 'МАСТЕР ЛАГМАНОВ',
        verdictColor: const Color(0xFFFF453A),
        toxicityScore: 95,
        isFromApi: false,
        date: DateTime.now(),
      );
    }

    if (shoppingSpent > 1500) {
      return AIRoastResult(
        roastText:
            'Шоппинг на ${CurrencyFormatter.format(shoppingSpent)} сом? Зачем тебе ещё одна черная худи или чехол с маркетплейса? '
            'Ты открыл корзину на Wildberries и забыл, что у нас идет 90-дневный Winter Arc? '
            'Осталось собрать ${CurrencyFormatter.format(remainingGoal)} сом на $dreamGoal — опомнись и закрой маркетплейс!',
        verdict: 'ЖЕРТВА МАРКЕТПЛЕЙСОВ',
        verdictColor: const Color(0xFFFF375F),
        toxicityScore: 89,
        isFromApi: false,
        date: DateTime.now(),
      );
    }

    return AIRoastResult(
      roastText:
          'За эту неделю улетело ${CurrencyFormatter.format(totalSpent)} сом. Баланс тает быстрее, чем снег на Южной Магистрали. '
          'Капибара сидит в углу и считает дни до зарплаты. Если не включишь режим железной дисциплины прямо сегодня — '
          'стрик в $streak дней сгорит к чертям, а Mac останется картинкой на обоях.',
      verdict: 'РЕЖИМ ТРАНЖИРЫ',
      verdictColor: const Color(0xFFFF453A),
      toxicityScore: 84,
      isFromApi: false,
      date: DateTime.now(),
    );
  }
}
