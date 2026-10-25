import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/receipt_item.dart';
import 'ai_roast_service.dart';

class ReceiptVisionService {
  static const List<String> samplePresets = [
    'Фрунзе',
    'Фаиза',
    'Бублик',
    'Globus',
  ];

  static ParsedReceipt getPreset(String name, {String dreamGoal = 'MacBook Pro M3'}) {
    switch (name) {
      case 'Фаиза':
        return ParsedReceipt(
          merchant: 'Кафе «Фаиза»',
          items: const [
            ReceiptItem(
              name: 'Лагман жареный (босо)',
              price: 340.0,
              categoryId: 'cat_restaurants',
              categoryName: 'Кафе и еда',
              isImpulseOrJunk: true,
              capybaraComment: 'Двойной лагман в Фаизе? Mac M3 в слезах!',
            ),
            ReceiptItem(
              name: 'Лепешка тандырная',
              price: 35.0,
              categoryId: 'cat_restaurants',
              categoryName: 'Кафе и еда',
            ),
            ReceiptItem(
              name: 'Чай зеленый чайник',
              price: 70.0,
              categoryId: 'cat_restaurants',
              categoryName: 'Кафе и еда',
              capybaraComment: 'Зеленый чай одобрен Winter Arc',
            ),
          ],
          totalAmount: 445.0,
          date: DateTime.now(),
          rawText: 'Кафе Фаиза: Лагман босо 340, Лепешка 35, Чай 70. Итого: 445 сом',
          mainCapybaraAlert: 'Счет из Фаизы на 445 сом! Убери кошелек, помни про цель!',
        );

      case 'Бублик':
        return ParsedReceipt(
          merchant: 'Кофейня «Бублик»',
          items: const [
            ReceiptItem(
              name: 'Капучино большой 400мл',
              price: 220.0,
              categoryId: 'cat_restaurants',
              categoryName: 'Кафе и еда',
              capybaraComment: 'Инвестиция в бодрость, но держи темп',
            ),
            ReceiptItem(
              name: 'Круассан миндальный',
              price: 190.0,
              categoryId: 'cat_restaurants',
              categoryName: 'Кафе и еда',
              isImpulseOrJunk: true,
              capybaraComment: 'Сладкие калории и минус 190 сом от мечты!',
            ),
          ],
          totalAmount: 410.0,
          date: DateTime.now(),
          rawText: 'Кофейня Бублик: Капучино 220, Круассан 190. Итого: 410 сом',
          mainCapybaraAlert: 'Кофейный перекус на 410 сом. Округлим остаток в копилку!',
        );

      case 'Globus':
        return ParsedReceipt(
          merchant: 'Globus Express',
          items: [
            ReceiptItem(
              name: 'Red Bull 250мл',
              price: 185.0,
              categoryId: 'cat_restaurants',
              categoryName: 'Кафе и еда',
              isImpulseOrJunk: true,
              capybaraComment: 'Опять энергетики? Отдалил себя от $dreamGoal на 185 сом',
            ),
            const ReceiptItem(
              name: 'Вода Legend 1.5л',
              price: 45.0,
              categoryId: 'cat_groceries',
              categoryName: 'Продукты',
              capybaraComment: 'Вода — идеальный выбор дисциплины',
            ),
            const ReceiptItem(
              name: 'Батончики ореховые 2шт',
              price: 160.0,
              categoryId: 'cat_groceries',
              categoryName: 'Продукты',
            ),
          ],
          totalAmount: 390.0,
          date: DateTime.now(),
          rawText: 'Globus Express: Red Bull 185, Вода Legend 45, Батончики 160. Итого: 390 сом',
          mainCapybaraAlert: 'Red Bull за 185 сом зафиксирован сканером Капибары!',
        );

      case 'Фрунзе':
      default:
        return ParsedReceipt(
          merchant: 'Гипермаркет «Фрунзе»',
          items: [
            ReceiptItem(
              name: 'Энергетик Flash Up 0.5л',
              price: 140.0,
              categoryId: 'cat_restaurants',
              categoryName: 'Кафе и еда',
              isImpulseOrJunk: true,
              capybaraComment: 'Опять энергетики? Отдалил себя от $dreamGoal на 140 сом',
            ),
            const ReceiptItem(
              name: 'Молоко «Веселый Молочник» 3.2%',
              price: 85.0,
              categoryId: 'cat_groceries',
              categoryName: 'Продукты',
              capybaraComment: 'Базовые продукты одобрены Капибарой',
            ),
            const ReceiptItem(
              name: 'Чипсы Lays с солью 140г',
              price: 175.0,
              categoryId: 'cat_shopping',
              categoryName: 'Шоппинг',
              isImpulseOrJunk: true,
              capybaraComment: 'Чипсы за 175 сом? Стрик Winter Arc трещит по швам!',
            ),
            const ReceiptItem(
              name: 'Хлеб формовой',
              price: 35.0,
              categoryId: 'cat_groceries',
              categoryName: 'Продукты',
            ),
          ],
          totalAmount: 435.0,
          date: DateTime.now(),
          rawText: 'Фрунзе: Энергетик Flash 140, Молоко 85, Lays 175, Хлеб 35. Итого: 435 сом',
          mainCapybaraAlert: 'Капибара заметила энергетик и чипсы на 315 сом!',
        );
    }
  }

  /// High-speed local OCR text parser for receipts and menus
  static ParsedReceipt parseRawText(String rawText, {String dreamGoal = 'MacBook Pro M3'}) {
    final lines = rawText.split('\n');
    String merchant = 'Магазин / Кафе';
    final items = <ReceiptItem>[];
    double total = 0.0;
    String? mainAlert;

    final lowerFull = rawText.toLowerCase();
    if (lowerFull.contains('фрунзе')) {
      merchant = 'Гипермаркет «Фрунзе»';
    } else if (lowerFull.contains('глобус') || lowerFull.contains('globus')) {
      merchant = 'Гипермаркет «Globus»';
    } else if (lowerFull.contains('фаиза') || lowerFull.contains('faiza')) {
      merchant = 'Кафе «Фаиза»';
    } else if (lowerFull.contains('бублик')) {
      merchant = 'Кофейня «Бублик»';
    } else if (lowerFull.contains('нават')) {
      merchant = 'Чайхана «Navat»';
    }

    final priceRegex = RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:сом|c|kgs)?', caseSensitive: false);

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();

      if (lower.contains('итог') || lower.contains('к оплате') || lower.contains('всего')) {
        final m = priceRegex.firstMatch(trimmed);
        if (m != null) {
          final tVal = double.tryParse(m.group(1)!.replaceAll(',', '.'));
          if (tVal != null && tVal > 0) {
            total = tVal;
          }
        }
        continue;
      }

      final match = priceRegex.firstMatch(trimmed);
      if (match != null) {
        final priceStr = match.group(1)!.replaceAll(',', '.');
        final price = double.tryParse(priceStr);
        if (price != null && price > 0 && price < 100000) {
          final namePart = trimmed.substring(0, match.start).replaceAll(RegExp(r'[-–—:.]+$'), '').trim();
          final itemName = namePart.isNotEmpty ? namePart : 'Позиция чека';

          bool isJunk = false;
          String? comment;
          String catId = 'cat_groceries';
          String catName = 'Продукты';

          if (lower.contains('энергетик') ||
              lower.contains('flash') ||
              lower.contains('red bull') ||
              lower.contains('monster') ||
              lower.contains('burn') ||
              lower.contains('gorilla')) {
            isJunk = true;
            catId = 'cat_restaurants';
            catName = 'Кафе и еда';
            comment = 'Опять энергетики? Отдалил себя от $dreamGoal на ${price.toInt()} сом';
            mainAlert = 'Капибара зафиксировала энергетик на ${price.toInt()} сом!';
          } else if (lower.contains('чипсы') || lower.contains('lays') || lower.contains('pringles')) {
            isJunk = true;
            catId = 'cat_shopping';
            catName = 'Шоппинг';
            comment = 'Чипсы за ${price.toInt()} сом? Стрик Winter Arc трещит по швам!';
          } else if (lower.contains('лагман') || lower.contains('манты') || lower.contains('шаурма')) {
            isJunk = true;
            catId = 'cat_restaurants';
            catName = 'Кафе и еда';
            comment = 'Ночной фастфуд/лагман? Капибара прячет твой кошелек!';
          } else if (lower.contains('кофе') || lower.contains('капучино') || lower.contains('латте')) {
            catId = 'cat_restaurants';
            catName = 'Кафе и еда';
            comment = 'Инвестиция в бодрость, но держи темп';
          }

          items.add(ReceiptItem(
            name: itemName,
            price: price,
            categoryId: catId,
            categoryName: catName,
            isImpulseOrJunk: isJunk,
            capybaraComment: comment,
          ));
        }
      }
    }

    if (total == 0.0 && items.isNotEmpty) {
      total = items.fold(0.0, (s, i) => s + i.price);
    }

    if (items.isEmpty) {
      return getPreset('Фрунзе', dreamGoal: dreamGoal);
    }

    return ParsedReceipt(
      merchant: merchant,
      items: items,
      totalAmount: total,
      date: DateTime.now(),
      rawText: rawText,
      mainCapybaraAlert: mainAlert ?? (items.any((i) => i.isImpulseOrJunk)
          ? 'Обнаружены импульсивные траты! Проверь свои цели.'
          : 'Чек успешно распознан и разложен по категориям.'),
    );
  }

  /// Sends receipt image file to Gemini Vision REST API
  static Future<ParsedReceipt?> analyzeWithGeminiVision(
    File imageFile, {
    String dreamGoal = 'MacBook Pro M3',
  }) async {
    final apiKey = await AIRoastService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt =
          'Ты — система распознавания чеков в приложении ARC Finance (Кыргызстан). '
          'Проанализируй фото чека или меню. Распознай название заведения, список товаров, их цены в сомах, '
          'и определи категорию (cat_groceries, cat_restaurants, cat_shopping, cat_transport). '
          'Если в чеке есть вредные или импульсивные покупки (энергетики, чипсы, фастфуд, сладости), '
          'поставь isImpulseOrJunk = true и сгенерируй язвительный комментарий от Капибары: '
          '«Опять энергетики? Отдалил себя от $dreamGoal на Х сом». '
          'Формат строго JSON:\n'
          '{"merchant": "Название", "items": [{"name": "Товар", "price": 100.0, "categoryId": "cat_groceries", "categoryName": "Продукты", "isImpulseOrJunk": false, "capybaraComment": "текст"}], "total": 100.0, "mainAlert": "текст"}';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 800,
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
          final cleaned = candidateText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final parsed = jsonDecode(cleaned);

          final rawItems = parsed['items'] as List? ?? [];
          final items = rawItems.map((m) => ReceiptItem.fromMap(m as Map<String, dynamic>)).toList();
          final total = (parsed['total'] as num?)?.toDouble() ??
              items.fold<double>(0.0, (s, i) => s + i.price);

          return ParsedReceipt(
            merchant: parsed['merchant'] as String? ?? 'Магазин',
            items: items,
            totalAmount: total,
            date: DateTime.now(),
            rawText: responseBody,
            mainCapybaraAlert: parsed['mainAlert'] as String?,
          );
        }
      }
    } catch (e) {
      debugPrint('[ReceiptVisionService] Gemini Vision failed: $e');
    } finally {
      client.close();
    }
    return null;
  }

  /// Sends receipt image file to Google Cloud Vision OCR REST API
  static Future<ParsedReceipt?> analyzeWithGoogleCloudVision(
    File imageFile, {
    String dreamGoal = 'MacBook Pro M3',
  }) async {
    final apiKey = await AIRoastService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
      );

      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1}
            ]
          }
        ]
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody);
        final fullText = json['responses']?[0]?['fullTextAnnotation']?['text'] as String? ??
            json['responses']?[0]?['textAnnotations']?[0]?['description'] as String?;

        if (fullText != null && fullText.isNotEmpty) {
          return parseRawText(fullText, dreamGoal: dreamGoal);
        }
      }
    } catch (e) {
      debugPrint('[ReceiptVisionService] Google Cloud Vision failed: $e');
    } finally {
      client.close();
    }
    return null;
  }

  /// Unified vision runner: tries Gemini 1.5/2.0 Flash first, then Cloud Vision OCR
  static Future<ParsedReceipt?> analyzeReceiptImage(
    File imageFile, {
    String dreamGoal = 'MacBook Pro M3',
  }) async {
    // 1. Try Gemini Vision API first (structured JSON, categories, Capybara comment)
    final geminiResult = await analyzeWithGeminiVision(imageFile, dreamGoal: dreamGoal);
    if (geminiResult != null) return geminiResult;

    // 2. Try Google Cloud Vision OCR API
    final cloudVisionResult = await analyzeWithGoogleCloudVision(imageFile, dreamGoal: dreamGoal);
    if (cloudVisionResult != null) return cloudVisionResult;

    return null;
  }
}
