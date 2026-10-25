import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/widget_launch_service.dart';
import 'state/finance_controller.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = FinanceController();
  await controller.loadFromStorage();

  try {
    await WidgetLaunchService.syncBalanceToWidget(
      controller.totalBalance,
      streak: controller.noSpendStreak,
      isWinterChecked: controller.isWinterCheckedToday,
      accountName: controller.activeAccountLabel,
      todaySpent: controller.todaySpentLabel,
    );
    await WidgetLaunchService.syncCapyPrediction(
      title: 'ПРЕДСКАЗАНИЕ КАПИБАРЫ',
      body:
          'Лучший способ сберечь 1000 сом — это просто не покупать то, без чего можно обойтись. Пей чай и отдыхай.',
      statusTag: 'ДЗЕН',
    );
  } catch (_) {}

  runApp(FinanceApp(controller: controller));
}

class FinanceApp extends StatefulWidget {
  final FinanceController? controller;
  const FinanceApp({super.key, this.controller});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  late final FinanceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? FinanceController();
    if (widget.controller == null) {
      _controller.loadFromStorage();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Финансы KG - Кыргызский менеджер',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkGlassTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('ky', 'KG'),
        Locale('en', 'US'),
      ],
      home: SplashScreen(controller: _controller),
    );
  }
}
