import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/receipt_item.dart';
import '../models/transaction_type.dart';
import '../services/ai_roast_service.dart';
import '../services/receipt_vision_service.dart';
import '../state/finance_controller.dart';
import '../utils/formatters.dart';

class ReceiptScannerScreen extends StatefulWidget {
  final FinanceController controller;

  const ReceiptScannerScreen({super.key, required this.controller});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnim;

  String _selectedPreset = 'Фрунзе';
  ParsedReceipt? _currentReceipt;
  bool _isProcessing = false;
  bool _hasApiKey = false;
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _laserAnim = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );

    _checkApiKey();
    _loadPreset(_selectedPreset);
  }

  Future<void> _checkApiKey() async {
    final key = await AIRoastService.getApiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = key != null && key.isNotEmpty;
      });
    }
  }

  Future<void> _showApiKeyDialog() async {
    final currentKey = await AIRoastService.getApiKey() ?? '';
    final textController = TextEditingController(text: currentKey);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF00C7BE), width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: Color(0xFF00C7BE), size: 22),
              SizedBox(width: 10),
              Text(
                'Google Vision / Gemini API',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Введите ваш API-ключ Gemini (Google AI Studio) или Google Cloud Vision для мгновенного парсинга чеков и меню прямо с камеры.',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (currentKey.isNotEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await AIRoastService.saveApiKey('');
                  if (mounted) {
                    setState(() => _hasApiKey = false);
                  }
                },
                child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C7BE),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final key = textController.text.trim();
                Navigator.of(ctx).pop();
                await AIRoastService.saveApiKey(key);
                if (mounted) {
                  setState(() => _hasApiKey = key.isNotEmpty);
                }
              },
              child: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _loadPreset(String name) {
    final dreamGoal = widget.controller.savingsGoals.isNotEmpty
        ? widget.controller.savingsGoals.first.title
        : 'MacBook Pro M3';
    setState(() {
      _selectedPreset = name;
      _capturedImage = null;
      _currentReceipt = ReceiptVisionService.getPreset(name, dreamGoal: dreamGoal);
    });
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo == null) return;

      setState(() {
        _isProcessing = true;
        _capturedImage = File(photo.path);
      });
      HapticFeedback.mediumImpact();

      final dreamGoal = widget.controller.savingsGoals.isNotEmpty
          ? widget.controller.savingsGoals.first.title
          : 'MacBook Pro M3';

      // Unified Vision: Gemini Flash 1.5/2.0 and Google Cloud Vision OCR
      final visionResult = await ReceiptVisionService.analyzeReceiptImage(
        _capturedImage!,
        dreamGoal: dreamGoal,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentReceipt = visionResult ??
              ReceiptVisionService.getPreset('Фрунзе', dreamGoal: dreamGoal);
        });

        if (visionResult != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1C1C1E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF30D158), width: 1.2),
              ),
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Чек успешно распознан через Google Vision AI!',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _saveReceiptToARC() {
    if (_currentReceipt == null) return;

    HapticFeedback.heavyImpact();
    final targetAccount = widget.controller.accounts.isNotEmpty
        ? widget.controller.accounts.first.id
        : 'acc_mbank';

    // Group or save primary transaction
    final primaryItem = _currentReceipt!.items.firstWhere(
      (i) => i.isImpulseOrJunk,
      orElse: () => _currentReceipt!.items.first,
    );

    widget.controller.addTransaction(
      title: '${_currentReceipt!.merchant}: ${primaryItem.name}',
      amount: _currentReceipt!.totalAmount,
      date: DateTime.now(),
      type: TransactionType.expense,
      categoryId: primaryItem.categoryId,
      accountId: targetAccount,
      note: 'AR Vision чек: ${_currentReceipt!.items.map((i) => "${i.name} (${i.price.toInt()} с)").join(", ")}',
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF00C7BE), width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(Icons.document_scanner_rounded, color: Color(0xFF00C7BE), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Чек ${_currentReceipt!.merchant} на ${CurrencyFormatter.format(_currentReceipt!.totalAmount)} сохранен!',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _currentReceipt;
    final total = receipt?.totalAmount ?? 0.0;
    final step = widget.controller.smartRoundUpStep;
    final remainder = (step - (total.toInt() % step)) % step;

    final impulseItem = receipt?.items.firstWhere(
      (i) => i.isImpulseOrJunk,
      orElse: () => receipt.items.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: Stack(
        children: [
          // 1. Camera Viewfinder Simulated / Image Background
          Positioned.fill(
            child: _capturedImage != null
                ? Image.file(_capturedImage!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.2),
                        radius: 1.2,
                        colors: [
                          Color(0xFF182026),
                          Color(0xFF0C1014),
                          Color(0xFF06080A),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 72,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'НАВЕДИТЕ КАМЕРУ НА ЧЕК ИЛИ МЕНЮ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.28),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Futuristic AR Holographic Overlay & Grid
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Top HUD Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        InkWell(
                          onTap: _showApiKeyDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _hasApiKey ? const Color(0x3330D158) : const Color(0x33FF9F0A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _hasApiKey ? const Color(0xFF30D158) : const Color(0xFFFF9F0A),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _hasApiKey ? Icons.check_circle_rounded : Icons.vpn_key_rounded,
                                  color: _hasApiKey ? const Color(0xFF30D158) : const Color(0xFFFF9F0A),
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _hasApiKey ? 'VISION AI OK' : 'ВВЕСТИ API КЛЮЧ',
                                  style: TextStyle(
                                    color: _hasApiKey ? const Color(0xFF30D158) : const Color(0xFFFF9F0A),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 19),
                                tooltip: 'Снять фото',
                                onPressed: () => _capturePhoto(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 19),
                                tooltip: 'Из галереи',
                                onPressed: () => _capturePhoto(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Preset Chips Selector (for instant realistic testing)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: ReceiptVisionService.samplePresets.map((preset) {
                        final isSelected = _selectedPreset == preset && _capturedImage == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(preset),
                            selected: isSelected,
                            selectedColor: const Color(0xFF00C7BE),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                            onSelected: (_) => _loadPreset(preset),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Spacer(),

                  // 3. Viewfinder Focus Box & Animated Cyber Laser
                  Container(
                    width: 290,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x6600C7BE), width: 1.5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      children: [
                        // Corner brackets
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF00C7BE), width: 3), left: BorderSide(color: Color(0xFF00C7BE), width: 3)))),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF00C7BE), width: 3), right: BorderSide(color: Color(0xFF00C7BE), width: 3)))),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF00C7BE), width: 3), left: BorderSide(color: Color(0xFF00C7BE), width: 3)))),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(width: 16, height: 16, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF00C7BE), width: 3), right: BorderSide(color: Color(0xFF00C7BE), width: 3)))),
                        ),

                        // Moving Laser Line
                        AnimatedBuilder(
                          animation: _laserAnim,
                          builder: (context, _) {
                            return Positioned(
                              top: 200 * _laserAnim.value,
                              left: 12,
                              right: 12,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C7BE),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00C7BE).withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Center reticle
                        const Center(
                          child: Icon(Icons.filter_center_focus_rounded, color: Colors.white24, size: 36),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. FLOATING AR CAPYBARA ALERT POP-UP (OVER CAMERA)
                  if (impulseItem != null && impulseItem.capybaraComment != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xE61C1414),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF453A), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF453A).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Color(0x33FF453A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Color(0xFFFF453A), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AR-ПОП-АП ОТ КАПИБАРЫ',
                                  style: TextStyle(
                                    color: Color(0xFFFF453A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '«${impulseItem.capybaraComment!}»',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // 5. Bottom Parsed Receipt Sheet
                  Container(
                    margin: const EdgeInsets.all(14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xF21C1C1E),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Merchant & Items count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              receipt?.merchant ?? 'Чек',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${receipt?.items.length ?? 0} позиций',
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Items preview chips
                        if (receipt != null && receipt.items.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: receipt.items.take(4).map((item) {
                              final isJunk = item.isImpulseOrJunk;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isJunk ? const Color(0x26FF453A) : const Color(0xFF2C2C2E),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isJunk ? const Color(0xFFFF453A) : Colors.white10,
                                  ),
                                ),
                                child: Text(
                                  '${item.name} • ${item.price.toInt()} с',
                                  style: TextStyle(
                                    color: isJunk ? const Color(0xFFFF453A) : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: isJunk ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Total & Round-up Preview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ИТОГО ПО ЧЕКУ',
                                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(total),
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            if (remainder > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0x2600C7BE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF00C7BE)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'В КОПИЛКУ (MAC M3)',
                                      style: TextStyle(color: Color(0xFF00C7BE), fontSize: 9.5, fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      '+$remainder сом',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Save Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _saveReceiptToARC,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C7BE),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              remainder > 0
                                  ? 'Записать чек (+$remainder с в копилку)'
                                  : 'Записать расход в ARC',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
