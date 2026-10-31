import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Intelligent Merchant & Category Memory Engine.
/// Remembers how the user categorizes every merchant/clinic/shop,
/// and automatically learns new merchants so future payments are accurately classified.
class MerchantMemoryService {
  static const String _prefKey = 'arc_learned_merchant_categories';

  // In-memory cache for fast synchronous lookup during MBankParserService parsing
  static final Map<String, String> _memoryCache = {};
  static bool _isLoadedFromPrefs = false;

  // Pre-seeded comprehensive Kyrgyz/Bishkek knowledge base
  static final Map<String, String> _defaultRules = {
    // Medical laboratories, clinics & health (analyses, tests, hospitals)
    'бонецк': 'cat_health',
    'бонецкого': 'cat_health',
    'аквалаб': 'cat_health',
    'aquilab': 'cat_health',
    'инвитро': 'cat_health',
    'invitro': 'cat_health',
    'евролаб': 'cat_health',
    'eurolab': 'cat_health',
    'гаммалаб': 'cat_health',
    'анализ': 'cat_health',
    'анализы': 'cat_health',
    'лаборатор': 'cat_health',
    'юрфа': 'cat_health',
    'бимед': 'cat_health',
    'неомед': 'cat_health',
    'неман': 'cat_health',
    'neman': 'cat_health',
    'фарм': 'cat_health',
    'аптек': 'cat_health',
    'клиник': 'cat_health',
    'госпитал': 'cat_health',
    'медцентр': 'cat_health',
    'стоматолог': 'cat_health',
    'дентал': 'cat_health',
    'dental': 'cat_health',
    'лекарь': 'cat_health',
    'диагност': 'cat_health',
    'узи': 'cat_health',
    'мрт': 'cat_health',
    'рентген': 'cat_health',
    'medcheck': 'cat_health',

    // Restaurants & Food
    'фаиза': 'cat_restaurants',
    'faiza': 'cat_restaurants',
    'нават': 'cat_restaurants',
    'navat': 'cat_restaurants',
    'бублик': 'cat_restaurants',
    'bublik': 'cat_restaurants',
    'куликов': 'cat_restaurants',
    'kulikov': 'cat_restaurants',
    'додо': 'cat_restaurants',
    'dodo': 'cat_restaurants',
    'kfc': 'cat_restaurants',
    'бургер': 'cat_restaurants',
    'burger': 'cat_restaurants',
    'чайхана': 'cat_restaurants',
    'столовая': 'cat_restaurants',
    'кофе': 'cat_restaurants',
    'coffee': 'cat_restaurants',

    // Groceries
    'глобус': 'cat_groceries',
    'globus': 'cat_groceries',
    'фрунзе': 'cat_groceries',
    'frunze': 'cat_groceries',
    'народный': 'cat_groceries',
    'narodnyi': 'cat_groceries',
    'азия': 'cat_groceries',
    'достор': 'cat_groceries',
    'корзинка': 'cat_groceries',

    // Transport
    'яндекс': 'cat_transport',
    'yandex': 'cat_transport',
    'такси': 'cat_transport',
    'тулпар': 'cat_transport',
    'газпром': 'cat_transport',
    'бишкекпетролеум': 'cat_transport',
    'red petroleum': 'cat_transport',

    // Shopping
    'wildberries': 'cat_shopping',
    'вайлдберриз': 'cat_shopping',
    'wb': 'cat_shopping',
    'ozon': 'cat_shopping',
    'озон': 'cat_shopping',
    'дордой': 'cat_shopping',
    'цум': 'cat_shopping',
    'asia mall': 'cat_shopping',
  };

  static void _ensureDefaults() {
    for (final entry in _defaultRules.entries) {
      if (!_memoryCache.containsKey(entry.key)) {
        _memoryCache[entry.key] = entry.value;
      }
    }
  }

  /// Initialize and load saved learned rules from SharedPreferences
  static Future<void> init() async {
    _ensureDefaults();
    if (_isLoadedFromPrefs) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = jsonDecode(savedJson);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is String && value is String) {
              _memoryCache[key.toLowerCase().trim()] = value;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[MerchantMemoryService] Error loading rules: $e');
    }
    _isLoadedFromPrefs = true;
  }

  /// Synchronous category lookup using cached learned memory
  static String? getCategoryForTextSync(String text) {
    _ensureDefaults();

    final lower = text.toLowerCase();
    // 1. Longest match first to avoid subword collisions
    final sortedKeys = _memoryCache.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (lower.contains(key)) {
        return _memoryCache[key];
      }
    }
    return null;
  }

  /// Automatically learns a new merchant when the user enters or recategorizes a transaction
  static Future<void> learnMerchant(String titleOrMerchant, String categoryId) async {
    _ensureDefaults();
    final clean = _normalizeMerchantKeyword(titleOrMerchant);
    if (clean.length < 3) return;

    _memoryCache[clean] = categoryId;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_memoryCache));
      debugPrint('[MerchantMemoryService] Learned: "$clean" -> "$categoryId"');
    } catch (e) {
      debugPrint('[MerchantMemoryService] Error saving learned rule: $e');
    }
  }

  /// Extracts the essential root word / merchant identifier
  static String _normalizeMerchantKeyword(String raw) {
    String clean = raw.toLowerCase().trim();
    // Strip common filler prefixes
    clean = clean.replaceAll(RegExp(r'^(?:оплата\s+|чек\s+|платеж\s+|покупка\s+|в\s+|кафе\s+|магазин\s+|аптека\s+)'), '');
    clean = clean.replaceAll(RegExp(r'[^\w\s\u0400-\u04FF]'), ' ').trim();

    // If multi-word, take the primary descriptive word
    final tokens = clean.split(RegExp(r'\s+')).where((t) {
      return t.length >= 3 &&
          t != 'сом' &&
          t != 'kgs' &&
          t != 'mbank' &&
          t != 'банк' &&
          t != 'счет' &&
          t != 'карта' &&
          t != 'осоо' &&
          t != 'зао' &&
          t != 'оплата' &&
          t != 'платеж';
    }).toList();

    if (tokens.isNotEmpty) {
      return tokens.first;
    }
    return clean;
  }

  /// Returns all active learned rules
  static Map<String, String> getAllRules() {
    _ensureDefaults();
    return Map.unmodifiable(_memoryCache);
  }
}
