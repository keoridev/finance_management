import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_roast_service.dart';
import '../state/finance_controller.dart';
import '../widgets/glass_container.dart';

class AIRoastScreen extends StatefulWidget {
  final FinanceController controller;

  const AIRoastScreen({super.key, required this.controller});

  @override
  State<AIRoastScreen> createState() => _AIRoastScreenState();
}

class _AIRoastScreenState extends State<AIRoastScreen> {
  AIRoastResult? _roast;
  bool _isLoading = false;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _showApiSettings = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _generateRoast();
  }

  Future<void> _loadApiKey() async {
    final key = await AIRoastService.getApiKey();
    if (key != null) {
      _apiKeyController.text = key;
    }
  }

  Future<void> _generateRoast() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final dreamGoal = widget.controller.savingsGoals.isNotEmpty
        ? widget.controller.savingsGoals.first.title
        : 'MacBook Pro M3';
    final remaining = widget.controller.savingsGoals.isNotEmpty
        ? (widget.controller.savingsGoals.first.targetAmount -
                widget.controller.savingsGoals.first.currentAmount)
            .clamp(0.0, 99999999.0)
        : 120000.0;

    final result = await AIRoastService.generateRoast(
      transactions: widget.controller.transactions,
      totalBalance: widget.controller.totalBalance,
      streak: widget.controller.noSpendStreak,
      dreamGoal: dreamGoal,
      remainingGoal: remaining,
    );

    if (mounted) {
      setState(() {
        _roast = result;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'НЕЙРО-ПРОЖАРКА (AI ROAST)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showApiSettings ? Icons.close_rounded : Icons.key_rounded,
              color: const Color(0xFFFF9F0A),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showApiSettings = !_showApiSettings;
              });
            },
            tooltip: 'Настройки API Ключа',
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Key Settings Drawer
            if (_showApiSettings) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF9F0A).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, color: Color(0xFFFF9F0A), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Ключ Gemini / Claude / Qwen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Вставьте API-ключ Gemini Flash. Без ключа прожарку моментально генерирует встроенный локальный движок Бишкека.',
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apiKeyController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'AIzaSy...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await AIRoastService.saveApiKey(_apiKeyController.text);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('API-ключ успешно сохранен!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            setState(() => _showApiSettings = false);
                            _generateRoast();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9F0A),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Сохранить ключ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Main Roast Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _roast != null
                      ? _roast!.verdictColor.withValues(alpha: 0.5)
                      : const Color(0xFFFF453A).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_roast?.verdictColor ?? const Color(0xFFFF453A)).withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: (_roast?.verdictColor ?? const Color(0xFFFF453A)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _roast?.verdictColor ?? const Color(0xFFFF453A),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFFF453A),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _roast?.verdict ?? 'ТОКСИЧНЫЙ ОТЧЕТ',
                              style: TextStyle(
                                color: _roast?.verdictColor ?? const Color(0xFFFF453A),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _roast != null
                            ? '${_roast!.isFromApi ? "Gemini AI" : "Bishkek Engine"} • ${_roast!.toxicityScore}%'
                            : '',
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_isLoading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Color(0xFFFF9F0A)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Капибара анализирует твои чеки и готовит ядовитый панчлайн...',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_roast != null) ...[
                    Text(
                      _roast!.roastText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Toxicity Meter Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Шкала токсичности',
                              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                            ),
                            Text(
                              '${_roast!.toxicityScore} / 100',
                              style: TextStyle(
                                color: _roast!.verdictColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _roast!.toxicityScore / 100.0,
                            minHeight: 6,
                            backgroundColor: const Color(0xFF2C2C2E),
                            valueColor: AlwaysStoppedAnimation(_roast!.verdictColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _roast != null
                          ? () {
                              Clipboard.setData(ClipboardData(text: _roast!.roastText));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Панчлайн скопирован в буфер!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Скопировать',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateRoast,
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.black),
                      label: const Text(
                        'Прожарить снова',
                        style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9F0A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
