import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/savings_goal.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/sound_player.dart';
import 'glass_container.dart';
import 'transaction_success_overlay.dart';

class SavingsGoalsCard extends StatelessWidget {
  final FinanceController controller;

  const SavingsGoalsCard({super.key, required this.controller});

  static int _memeCounter = 0;

  static final List<Map<String, String>> _insufficientMemes = [
    {
      'tag': 'ФИНАНСОВОЕ ПИКЕ',
      'meme': 'Брат, откуда бабки? На счету перекати-поле свистит и эхо гуляет!',
      'sub': 'Закинуть воздух в копилку пока не поддерживается Центральным Банком.',
    },
    {
      'tag': 'КАЗНА ПУСТА',
      'meme': 'Ормон, в казне пусто! Денег нет, но вы держитесь и хорошего настроения.',
      'sub': 'Министр финансов объявил технический дефолт этой попытки.',
    },
    {
      'tag': 'ДЕПРЕССИЯ БАНКОМАТА',
      'meme': 'Банкомат посмотрел на твой баланс, тихо всхлипнул и попросил не тревожить его раненую душу.',
      'sub': 'Счет пуст, как желудок голодного студента в 3 часа ночи перед сессией.',
    },
    {
      'tag': 'МАГИЯ ЗАПРЕЩЕНА',
      'meme': 'У тебя на счете нет столько сомов! Колдовать цифры вне Хогвартса строго наказуемо!',
      'sub': 'Придется сначала закинуть наличку или попросить перевод.',
    },
    {
      'tag': 'КРИК КАРТЫ',
      'meme': 'Твоя карта орет: «Пощади, хозяин, я и так на нулевой диете держусь!»',
      'sub': 'Сначала пополни счет, потом копи на мечту.',
    },
    {
      'tag': 'ФАТАЛЬНАЯ ОШИБКА 404',
      'meme': 'Ошибка 404: Деньги не найдены. Они ушли в закат и не обещали вернуться.',
      'sub': 'Попробуйте перезагрузить реальность или дождаться зарплаты.',
    },
  ];

  void _showInsufficientFundsMemeDialog(
    BuildContext context, {
    required String bankName,
    required double balance,
    required double amount,
  }) {
    HapticFeedback.heavyImpact();
    final meme = _insufficientMemes[(_memeCounter++) % _insufficientMemes.length];
    final shortfall = amount - balance;

    showDialog(
      context: context,
      builder: (dlgCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16161A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.expense.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.expense.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.expense.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.expense),
                    const SizedBox(width: 5),
                    Text(
                      meme['tag']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Meme Text
              Text(
                meme['meme']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meme['sub']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Balance breakdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Счет $bankName:',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        Text(
                          CurrencyFormatter.format(balance),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Хотите внести:',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        Text(
                          CurrencyFormatter.format(amount),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Не хватает:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.expense),
                        ),
                        Text(
                          CurrencyFormatter.format(shortfall),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Dismiss Button
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(dlgCtx).pop();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Понял, иду искать деньги',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDepositModal(BuildContext context, SavingsGoal goal) {
    final amountCtrl = TextEditingController(text: '1000');
    String selectedAccId = controller.accounts.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final account = controller.getAccountById(selectedAccId);
          final currentInputAmt = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0.0;
          final isShort = (account != null && currentInputAmt > account.balance);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.98),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Пополнить: ${goal.title}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Накоплено: ${CurrencyFormatter.format(goal.currentAmount)} из ${CurrencyFormatter.format(goal.targetAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Account Selector
                    const Text(
                      'Списать со счета',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.accounts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final acc = controller.accounts[idx];
                          final isSelected = acc.id == selectedAccId;
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => selectedAccId = acc.id);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    acc.type.icon,
                                    size: 14,
                                    color: isSelected ? Colors.black : acc.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    acc.bankName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.black : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    CurrencyFormatter.format(acc.balance),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                      color: isSelected ? Colors.black54 : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      borderRadius: BorderRadius.circular(14),
                      surfaceColor: Colors.white.withValues(alpha: 0.05),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const Text(
                            'сом',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.iosGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Account balance hint
                    if (account != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'На счете: ${CurrencyFormatter.format(account.balance)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isShort ? AppColors.expense : Colors.white.withValues(alpha: 0.5),
                              fontWeight: isShort ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (isShort)
                            Text(
                              'Не хватает: ${CurrencyFormatter.format(currentInputAmt - account.balance)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.expense,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 18),

                    // Confirm Button
                    GlassContainer(
                      height: 52,
                      borderRadius: BorderRadius.circular(16),
                      surfaceColor: isShort ? const Color(0xFF2C2C2E) : AppColors.iosBlue,
                      onTap: () {
                        final amt = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0.0;
                        if (amt <= 0) return;

                        if (account == null || account.balance < amt) {
                          _showInsufficientFundsMemeDialog(
                            ctx,
                            bankName: account?.bankName ?? 'Счет',
                            balance: account?.balance ?? 0.0,
                            amount: amt,
                          );
                          return;
                        }

                        final ok = controller.depositToGoal(
                          goalId: goal.id,
                          amount: amt,
                          fromAccountId: selectedAccId,
                        );

                        if (ok) {
                          SoundPlayer.playAtmSound();
                          Navigator.of(ctx).pop();
                          TransactionSuccessOverlay.show(
                            context,
                            title: 'В копилку: ${goal.title}',
                            amount: amt,
                            bankName: account.bankName,
                            isIncome: false,
                          );
                        }
                      },
                      child: Center(
                        child: Text(
                          isShort ? 'Недостаточно средств (Проверить)' : 'Пополнить цель',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isShort ? AppColors.expense : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddGoalModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Новая цель накопления',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    labelText: 'Название цели',
                    hintText: 'Например: Поездка на Иссык-Куль',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    labelText: 'Целевая сумма',
                    suffixText: 'сом',
                    hintText: '50 000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GlassContainer(
                  height: 52,
                  borderRadius: BorderRadius.circular(16),
                  surfaceColor: AppColors.iosBlue,
                  onTap: () {
                    final title = titleCtrl.text.trim();
                    final target = double.tryParse(targetCtrl.text.replaceAll(',', '.')) ?? 0.0;
                    if (title.isNotEmpty && target > 0) {
                      controller.addSavingsGoal(
                        title: title,
                        targetAmount: target,
                        icon: Icons.savings_rounded,
                        color: AppColors.iosPurple,
                      );
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Center(
                    child: Text(
                      'Создать цель',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = controller.savingsGoals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Цели и копилка',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: () => _showAddGoalModal(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Новая цель',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goals.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final goal = goals[index];
            final pct = (goal.progress * 100).toInt();

            return GlassContainer(
              padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
              borderRadius: BorderRadius.circular(18),
              surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: goal.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(goal.icon, size: 18, color: goal.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${CurrencyFormatter.format(goal.currentAmount)} из ${CurrencyFormatter.format(goal.targetAmount)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          onTap: () => _showDepositModal(context, goal),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '+ Пополнить',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$pct% накоплено',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: goal.color,
                        ),
                      ),
                      Text(
                        'Осталось: ${CurrencyFormatter.format(goal.targetAmount - goal.currentAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
