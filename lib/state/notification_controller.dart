import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_notification.dart';
import '../models/transaction_type.dart';
import '../services/widget_launch_service.dart';
import '../utils/browser_notifications.dart';
import 'finance_controller.dart';

class CapybaraInsight {
  final String title;
  final String body;
  final String actionLabel;
  final String statusTag;
  final IconData icon;
  final String mood;

  const CapybaraInsight({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.statusTag,
    this.icon = Icons.spa_rounded,
    this.mood = 'zen',
  });
}

class NotificationController extends ChangeNotifier {
  bool _hourlyReminderEnabled = true;
  bool _winterArcReminderEnabled = true;
  bool _dreamSavingsReminderEnabled = true;
  bool _hasSystemPermission = false;

  AppNotification? _activeBannerNotification;
  Timer? _dismissTimer;
  Timer? _hourlyTimer;
  Timer? _initialEntranceTimer;
  final List<AppNotification> _history = [];
  static int _zenIndex = 0;

  NotificationController() {
    _hasSystemPermission = BrowserNotifications.hasPermission();
    _startSchedules();
  }

  // Getters
  bool get hourlyReminderEnabled => _hourlyReminderEnabled;
  bool get winterArcReminderEnabled => _winterArcReminderEnabled;
  bool get dreamSavingsReminderEnabled => _dreamSavingsReminderEnabled;
  bool get hasSystemPermission => _hasSystemPermission;
  AppNotification? get activeBannerNotification => _activeBannerNotification;
  List<AppNotification> get history => List.unmodifiable(_history);
  String get permissionStatus => BrowserNotifications.getPermissionStatus();

  void toggleHourlyReminder(bool value) {
    _hourlyReminderEnabled = value;
    _scheduleNativeAlarms();
    notifyListeners();
  }

  void toggleWinterArcReminder(bool value) {
    _winterArcReminderEnabled = value;
    _scheduleNativeAlarms();
    notifyListeners();
  }

  void toggleDreamSavingsReminder(bool value) {
    _dreamSavingsReminderEnabled = value;
    _scheduleNativeAlarms();
    notifyListeners();
  }

  Future<void> requestSystemPermission() async {
    final browserGranted = await BrowserNotifications.requestPermission();
    final androidGranted =
        await WidgetLaunchService.requestNotificationPermission();
    _hasSystemPermission = browserGranted || androidGranted;
    notifyListeners();
  }

  void _scheduleNativeAlarms() {
    if (_hourlyReminderEnabled) {
      WidgetLaunchService.scheduleNotification(
        id: 201,
        title: 'Ничего не забыли записать?',
        body:
            'Капибара напоминает: запишите чашку кофе, такси или покупки, пока сумма свежа в памяти!',
        delaySeconds: 3600,
      );
    } else {
      WidgetLaunchService.cancelScheduledNotification(201);
    }

    if (_winterArcReminderEnabled) {
      WidgetLaunchService.scheduleNotification(
        id: 202,
        title: 'Winter Arc: Дисциплина под угрозой!',
        body:
            'День подходит к концу. Зафиксируйте день без импульсивных трат и спасите стрик!',
        delaySeconds: 7200,
      );
    } else {
      WidgetLaunchService.cancelScheduledNotification(202);
    }
  }

  void _startSchedules() {
    _initialEntranceTimer?.cancel();
    _hourlyTimer?.cancel();

    // 1. Automatic Entrance Trigger: Capybara greets user with chill wisdom after 1.8s
    _initialEntranceTimer = Timer(const Duration(milliseconds: 1800), () {
      triggerCapybaraZenNotification();
    });

    // 2. Periodic background & session reminder every 25 minutes
    _hourlyTimer = Timer.periodic(const Duration(minutes: 25), (timer) {
      if (_hourlyReminderEnabled) {
        triggerCapybaraZenNotification();
      }
    });

    // 3. Register native OS alarms with AlarmManager so push appears even when app is closed
    _scheduleNativeAlarms();
  }

  void showNotification(AppNotification notification) {
    _dismissTimer?.cancel();
    _activeBannerNotification = notification;
    _history.insert(0, notification);
    if (_history.length > 50) _history.removeLast();

    // Trigger platform haptic
    HapticFeedback.mediumImpact();

    // Trigger native Android system tray notification
    WidgetLaunchService.showNativeNotification(
      notification.title,
      notification.body,
    );

    // Trigger native browser notification (Service Worker directly to Android/Desktop shade)
    BrowserNotifications.showNotification(
      notification.title,
      body: notification.body,
      icon: 'icons/Icon-192.png',
    );

    notifyListeners();

    // Auto dismiss in-app banner after 7 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 7000), () {
      dismissActiveNotification();
    });
  }

  VoidCallback? onOpenAddModal;
  VoidCallback? onWinterCheckIn;
  VoidCallback? onDepositDream;

  void dismissActiveNotification() {
    _dismissTimer?.cancel();
    _activeBannerNotification = null;
    notifyListeners();
  }

  /// Evaluates real financial data from [FinanceController] and returns a dynamic,
  /// chill, philosophical Capybara insight tailored to the user's actual numbers.
  static CapybaraInsight getDynamicInsight(
    FinanceController? controller, {
    int offset = 0,
  }) {
    final List<CapybaraInsight> pool = [];
    final now = DateTime.now();

    if (controller != null) {
      final balance = controller.totalBalance;
      final income = controller.periodIncome;
      final expense = controller.periodExpense;
      final streak = controller.noSpendStreak;
      final isWinterChecked = controller.isWinterCheckedToday;

      // 1. Night Shopping / Late Hour Awareness (22:00 - 06:00)
      if (now.hour >= 22 || now.hour < 6) {
        pool.add(
          const CapybaraInsight(
            title: 'Ночной дозор Капибары',
            body:
                'На часах глухая ночь, а маркетплейсы не спят. Капибара сидит в тёплом источнике и заклинает: положи телефон экраном вниз — утренний ты скажет спасибо!',
            actionLabel: 'Спать на чиле',
            statusTag: 'НОЧНОЙ ДОЗОР • СПИ СПОКОЙНО',
            mood: 'night',
          ),
        );
      }

      // 2. Today's Multiple Spending Detection
      final todayExpenses = controller.transactions.where((t) {
        return t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day;
      }).toList();

      if (todayExpenses.length >= 3) {
        final todaySpent = todayExpenses.fold(0.0, (s, t) => s + t.amount);
        pool.add(
          CapybaraInsight(
            title: 'Капибара считает чеки',
            body:
                'Сегодня уже ${todayExpenses.length} трат на сумму ${todaySpent.toInt()} сом. Капибара вежливо интересуется: пульс кошелька в норме? Сделай паузу и завари чай.',
            actionLabel: '+ Записать',
            statusTag: 'СЕГОДНЯ ${todayExpenses.length} ТРАТ • ПРИТОРМОЗИ',
            mood: 'alert',
          ),
        );
      }

      // 3. Zero or Very Low Balance condition
      if (balance <= 0) {
        pool.add(
          const CapybaraInsight(
            title: 'Капибара в медитации',
            body:
                'На счетах 0 сом. Капибара спокойна, как гладь Иссык-Куля... Но на обед сегодня разве что свежий горный воздух. Закинь сотку, верни баланс в чакру.',
            actionLabel: '+ Записать',
            statusTag: 'БАЛАНС 0 СОМ • ДУША БОГАТА',
            mood: 'zen',
          ),
        );
      } else if (balance < 1000) {
        pool.add(
          CapybaraInsight(
            title: 'Капибара экономит энергию',
            body:
                'На счету ${balance.toInt()} сом. Капибара переходит в режим энергосбережения и советует отложить маркетплейсы до зарплаты.',
            actionLabel: '+ Записать',
            statusTag: 'БАЛАНС ${balance.toInt()} СОМ • РЕЖИМ ЭКОНОМИИ',
            mood: 'alert',
          ),
        );
      } else if (balance >= 50000) {
        pool.add(
          CapybaraInsight(
            title: 'Капибара надевает тёмные очки',
            body:
                'Баланс солидный: ${balance.toInt()} сом! Капибара вальяжно попивает коктейль на пляже. Главное — сохранять холодный рассудок.',
            actionLabel: 'В копилку',
            statusTag: 'БАЛАНС ${balance.toInt()} СОМ • БОСС',
            mood: 'boss',
          ),
        );
      }

      // 4. Winter Arc Discipline streak check
      if (!isWinterChecked) {
        pool.add(
          CapybaraInsight(
            title: 'Капибара бережёт стрик',
            body:
                'День ещё не зафиксирован! Твой стрик дисциплины ($streak дн.) ждёт отметки. Один тап — и чилл продолжится со спокойной душой.',
            actionLabel: 'Спасти стрик',
            statusTag: 'СТРИК $streak ДН. • ПОРА ОТМЕТИТЬ',
            mood: 'alert',
          ),
        );
      } else {
        pool.add(
          CapybaraInsight(
            title: 'Капибара гордится тобой',
            body:
                'Сегодняшний день зафиксирован! Стрик: $streak дн. (${controller.winterArcRankTitle}). Никаких импульсивных трат. Ты истинный самурай на расслабоне.',
            actionLabel: 'В копилку',
            statusTag: 'СТРИК $streak ДН. • ПОЛНЫЙ ДЗЕН',
            mood: 'celebration',
          ),
        );
      }

      // 5. Category budget limits check
      for (final b in controller.budgets) {
        final spent = controller.getCategorySpending(b.categoryId);
        if (b.monthlyLimit > 0 && spent > b.monthlyLimit) {
          final cat = controller.getCategoryById(b.categoryId);
          final catName = cat?.name ?? 'Категория';
          final over = (spent - b.monthlyLimit).toInt();
          pool.add(
            CapybaraInsight(
              title: 'Капибара щурится на чеки',
              body:
                  'По категории «$catName» лимит превышен на $over сом (${spent.toInt()} из ${b.monthlyLimit.toInt()}). Капибара не осуждает, но советует отложить карту.',
              actionLabel: '+ Записать',
              statusTag: 'ЛИМИТ ПРЕВЫШЕН • $catName',
              mood: 'alert',
            ),
          );
          break;
        }
      }

      // 6. Period Deficit (expenses > income)
      if (expense > income && expense > 0) {
        final diff = (expense - income).toInt();
        pool.add(
          CapybaraInsight(
            title: 'Капибара советует притормозить',
            body:
                'Расходы за период (${expense.toInt()} сом) обогнали доходы (${income.toInt()} сом) на $diff сом. Капибара сидит в горячем источнике и советует не суетиться.',
            actionLabel: '+ Записать',
            statusTag: 'РАСХОДЫ > ДОХОДОВ НА $diff СОМ',
            mood: 'alert',
          ),
        );
      }

      // 7. Period Surplus (income > expense)
      if (income > expense && income > 0) {
        final diff = (income - expense).toInt();
        pool.add(
          CapybaraInsight(
            title: 'Капибара одобряет профицит',
            body:
                'Твой чистый плюс: +$diff сом за период! Капибара довольно жмурится с апельсином на голове. Отложи часть на мечту!',
            actionLabel: 'В копилку',
            statusTag: 'ПРОФИЦИТ +$diff СОМ',
            mood: 'celebration',
          ),
        );
      }

      // 8. Recurring Subscriptions
      if (controller.recurringPayments.any((r) => r.isActive)) {
        final monthlyRec = controller.totalMonthlyRecurring.toInt();
        pool.add(
          CapybaraInsight(
            title: 'Шёпот подписок',
            body:
                'Регулярные платежи забирают около $monthlyRec сом/мес. Капибара медитирует и спрашивает: всеми ли сервисами ты пользуешься прямо сейчас?',
            actionLabel: '+ Записать',
            statusTag: 'ПОДПИСКИ: $monthlyRec С/МЕС',
            mood: 'zen',
          ),
        );
      }

      // 9. Savings Goals Progress
      if (controller.savingsGoals.isNotEmpty) {
        final goal = controller.savingsGoals.first;
        final pct = (goal.progress * 100).toInt();
        if (pct >= 80) {
          pool.add(
            CapybaraInsight(
              title: 'Финишная прямая',
              body:
                  'В копилке «${goal.title}» уже $pct%! Осталось всего ${(goal.targetAmount - goal.currentAmount).toInt()} сом. Капибара уже выбирает праздничный десерт!',
              actionLabel: 'В копилку',
              statusTag: 'МЕЧТА ПОЧТИ В КАРМАНЕ $pct%',
              mood: 'celebration',
            ),
          );
        } else {
          pool.add(
            CapybaraInsight(
              title: 'Капибара плывёт к мечте',
              body:
                  'Копилка «${goal.title}»: собрано ${goal.currentAmount.toInt()} из ${goal.targetAmount.toInt()} сом ($pct%). Капибара медленно, но верно плывёт к цели. Подкинь 100 сом для кармы!',
              actionLabel: 'В копилку',
              statusTag: 'КОПИЛКА $pct% • НА ЧИЛЕ',
              mood: 'zen',
            ),
          );
        }
      }
    }

    // Extensive Bishkek Humor & Philosophical Zen Memes pool (strictly zero emojis)
    pool.addAll(const [
      CapybaraInsight(
        title: 'Экспедиция на Дордой',
        body:
            'Поехал на Дордой только за теплыми носками. Вернулся без денег, но с двумя спортивками, ковром и кумысом. Капибара глубоко вздыхает и ставит чайник.',
        actionLabel: '+ Записать',
        statusTag: 'БИШКЕК • ДОРДОЙСКИЙ СИНДРОМ',
        icon: Icons.shopping_bag_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Экономия по-бишкекски',
        body:
            'Пройти две остановки пешком, чтобы сберечь 25 сом на маршрутке, а потом психануть и вызвать такси комфорт за 260 сом. Финансовый гений 80 уровня.',
        actionLabel: '+ Записать',
        statusTag: 'БИШКЕК • 25 СОМ ИЛИ ТАКСИ',
        icon: Icons.directions_bus_rounded,
        mood: 'alert',
      ),
      CapybaraInsight(
        title: 'Ночной босо-лагман',
        body:
            'На часах 23:45. Разум шепчет: «Ты копишь на мечту». Желудок кричит: «Горячий лагман сам себя не съест!». Капибара прячет телефон под подушку.',
        actionLabel: 'Спать на чиле',
        statusTag: 'НОЧНОЙ ЖОР • ЛАГМАН ЖДЕТ',
        icon: Icons.restaurant_rounded,
        mood: 'night',
      ),
      CapybaraInsight(
        title: 'Эволюция зарплаты',
        body:
            'День получки: «Официант, всем чай с чабрецом и лепешки за мой счет!». За 3 дня до зарплаты: «Если разделить одну пачку гречки на 6 равных кучек...».',
        actionLabel: '+ Записать',
        statusTag: 'РЕАЛЬНОСТЬ • ДЕНЬ ЗАРПЛАТЫ',
        icon: Icons.account_balance_wallet_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Торги на Ошском',
        body:
            'Торговаться на Ошском базаре за 20 сом скидки на курагу с невозмутимым лицом управляющего фондом на Уолл-стрит. Капибара одобряет настойчивость.',
        actionLabel: '+ Записать',
        statusTag: 'БАЗАР • УОЛЛ-СТРИТ',
        icon: Icons.storefront_rounded,
        mood: 'boss',
      ),
      CapybaraInsight(
        title: 'Доставка в непогоду',
        body:
            'Доставка 190 сом, надбавка за снег 95 сом, сбор за упаковку 30 сом. Итого две самсы обошлись как обед в ресторане. Зато капибара в тепле.',
        actionLabel: '+ Записать',
        statusTag: 'ДОСТАВКА • СУХИЕ НОГИ',
        icon: Icons.delivery_dining_rounded,
        mood: 'alert',
      ),
      CapybaraInsight(
        title: 'Кофейная арифметика',
        body:
            'Капучино на овсяном молоке за 240 сом выпит за 4 минуты. Сидишь и считаешь в уме, сколько килограммов плова можно было сварить на эти деньги.',
        actionLabel: '+ Записать',
        statusTag: 'КОФЕ • КАПУЧИНО ТАЕТ',
        icon: Icons.coffee_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Уведомление от MBank',
        body:
            'Пришло уведомление о поступлении перевода. Две секунды эйфории... и сразу три списания за интернет, рассрочку и свет. Деньги просто зашли поздороваться.',
        actionLabel: '+ Записать',
        statusTag: 'MBANK • СЕКУНДА СЧАСТЬЯ',
        icon: Icons.notifications_active_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Корзина на маркетплейсе',
        body:
            'В корзине 14 жизненно необходимых вещей: автоматическая чесалка для кота, подсветка для унитаза и мини-фонтан. Капибара на грани обморока.',
        actionLabel: 'Спасти стрик',
        statusTag: 'МАРКЕТПЛЕЙС • ДЕРЖИСЬ',
        icon: Icons.shopping_cart_rounded,
        mood: 'alert',
      ),
      CapybaraInsight(
        title: 'Копилка на Иссык-Куль',
        body:
            'Если отказаться от кофе до июля — как раз хватит на четыре дня в Бостери, катамаран и три горячих чебурека на пляже. План утвержден Капибарой.',
        actionLabel: 'В копилку',
        statusTag: 'ИССЫК-КУЛЬ • ЛЕТНИЙ ПЛАН',
        icon: Icons.beach_access_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Магия безналичных',
        body:
            'Когда прикладываешь карту или платишь по QR — кажется, что деньги виртуальные. Пока не зайдешь в ARC и не посмотришь в глаза мудрой Капибаре.',
        actionLabel: '+ Записать',
        statusTag: 'БЕЗНАЛ • ЦИФРОВОЙ САМУРАЙ',
        icon: Icons.credit_card_rounded,
        mood: 'alert',
      ),
      CapybaraInsight(
        title: 'Шаг к бишкекской трешке',
        body:
            'Закинул 150 сом в копилку мечты. До покупки квартиры в центре Бишкека осталось всего 39 990 таких пополнений. Главное — регулярность и позитив!',
        actionLabel: 'В копилку',
        statusTag: 'МЕЧТА • ВЕЛИКИЙ СТАРТ',
        icon: Icons.home_rounded,
        mood: 'boss',
      ),
      CapybaraInsight(
        title: 'Ловушка скидки 70%',
        body:
            'Скидка 70% на вещь, о существовании которой ты не подозревал пять минут назад. Помни: скидка 100% — это закрыть вкладку и спокойно попить воды.',
        actionLabel: 'Спасти стрик',
        statusTag: 'ШОПИНГ • СКИДКА 100%',
        icon: Icons.local_offer_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Поход за солью в Глобус',
        body:
            'Зашел в гипермаркет только за солью и хлебом. На кассе чек на 3800 сом, а в тележке соус манго-чили и силиконовые формочки. Чистая магия!',
        actionLabel: '+ Записать',
        statusTag: 'ГИПЕРМАРКЕТ • ВНЕЗАПНО',
        icon: Icons.shopping_basket_rounded,
        mood: 'alert',
      ),
      CapybaraInsight(
        title: 'Долг вернулся из прошлого',
        body:
            'Знакомый вернул 500 сом, взятые прошлым летом. Ощущение, будто нашел клад древних кочевников. Мозг уже строит планы, как спустить их за 10 минут.',
        actionLabel: 'В копилку',
        statusTag: 'НЕОЖИДАННОСТЬ • БОНУС',
        icon: Icons.savings_rounded,
        mood: 'celebration',
      ),
      CapybaraInsight(
        title: 'Кэшбек инвестора',
        body:
            'Начислили 18 сом кэшбека. Почувствовал себя Уорреном Баффетом на максималках. Капибара уважительно кивает с кружкой горячего горного чая.',
        actionLabel: 'В копилку',
        statusTag: 'ИНВЕСТОР • КЭШБЕК 18 СОМ',
        icon: Icons.trending_up_rounded,
        mood: 'boss',
      ),
      CapybaraInsight(
        title: 'Шопинг-терапия',
        body:
            'Устал и решил порадовать себя спонтанной покупкой. Увидел баланс после чека — расстроился еще больше. Теперь нужно купить что-то еще, чтобы успокоиться.',
        actionLabel: '+ Записать',
        statusTag: 'ТЕРАПИЯ • ЗАМКНУТЫЙ КРУГ',
        icon: Icons.psychology_rounded,
        mood: 'alert',
      ),
      CapybaraInsight(
        title: 'Термос самурая',
        body:
            'Настоящий воин Winter Arc гордо идет мимо модной кофейни с домашним чаем в термосе. Сэкономлено 200 сом, самооценка выросла до снежных вершин.',
        actionLabel: 'Спасти стрик',
        statusTag: 'WINTER ARC • ТЕРМОС В РУКЕ',
        icon: Icons.shield_rounded,
        mood: 'celebration',
      ),
      CapybaraInsight(
        title: 'Подушка безопасности',
        body:
            'Моя финансовая подушка безопасности пока похожа на тонкий блинчик. Но Капибара верит: шаг за шагом мы превратим ее в царский ортопедический матрас!',
        actionLabel: 'В копилку',
        statusTag: 'ПОДУШКА • БЛИНЧИК',
        icon: Icons.bed_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Планы на выходные',
        body:
            'План: провести скромные выходные дома за книгой и сохранить бюджет. Реальность: «Бро, поехали на шашлыки в горы!» — и минус 2500 сом из кошелька.',
        actionLabel: '+ Записать',
        statusTag: 'ВЫХОДНЫЕ • ШАШЛЫКИ В ГОРАХ',
        icon: Icons.landscape_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Рассрочка без переплат',
        body:
            'Смартфон в рассрочку на 24 месяца: ноль переплат банку, сто процентов гарантии, что следующие два года ты будешь дышать воздухом вместо обеда.',
        actionLabel: '+ Записать',
        statusTag: 'РАССРОЧКА • ФИЛОСОФИЯ',
        icon: Icons.phone_android_rounded,
        mood: 'alert',
      ),
      CapybaraInsight(
        title: 'Дзен горячих источников',
        body:
            'Капибара сидит в горячих источниках Иссык-Аты. Деньги — это просто инструмент, а внутренний покой бесценен. Зафиксируй день и отдыхай.',
        actionLabel: 'Спасти стрик',
        statusTag: 'ИССЫК-АТА • ПОЛНЫЙ ДЗЕН',
        icon: Icons.hot_tub_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Волк с проспекта Чуй',
        body:
            'Купил актив на 400 сом. Обновляю приложение каждые сорок секунд с видом финансового магната. Доход: плюс 80 тыйынов. Жизнь удалась.',
        actionLabel: 'В копилку',
        statusTag: 'БИШКЕК • ВОЛК С ЧУЯ',
        icon: Icons.auto_graph_rounded,
        mood: 'boss',
      ),
      CapybaraInsight(
        title: 'Урок финансового дзена',
        body:
            'Капибара знает: лучший способ сохранить 1000 сом — это просто не покупать то, без чего можно обойтись. Пей чай и наслаждайся моментом.',
        actionLabel: '+ Записать',
        statusTag: 'РЕЖИМ ДЗЕН • НА РАССЛАБОНЕ',
        icon: Icons.spa_rounded,
        mood: 'zen',
      ),
      CapybaraInsight(
        title: 'Мудрость банкомата',
        body:
            'Банкомат передавал привет! Сказал, что уважает твой покой и просил заходить только за снятием кэша на приятные радости жизни.',
        actionLabel: 'В копилку',
        statusTag: 'ПОЛНЫЙ ЧИЛЛ • БАНКОМАТ',
        icon: Icons.atm_rounded,
        mood: 'boss',
      ),
    ]);

    final safeIndex = (offset.abs()) % pool.length;
    return pool[safeIndex];
  }

  /// Dynamic Capybara Zen Notification ("стиль поведение на чиле на расслабоне, понимает что происходит с бюджетом")
  void triggerCapybaraZenNotification({
    FinanceController? financeController,
    VoidCallback? onOpenAddModal,
    VoidCallback? onWinterCheckIn,
    VoidCallback? onDepositDream,
  }) {
    final insight = getDynamicInsight(financeController, offset: _zenIndex++);
    final actionLabel = insight.actionLabel;

    VoidCallback actionCallback;
    if (actionLabel == '+ Записать') {
      actionCallback = () {
        dismissActiveNotification();
        final action = onOpenAddModal ?? this.onOpenAddModal;
        action?.call();
      };
    } else if (actionLabel.contains('стрик') ||
        actionLabel.contains('Отметить')) {
      actionCallback = () {
        dismissActiveNotification();
        final action = onWinterCheckIn ?? this.onWinterCheckIn;
        action?.call();
      };
    } else {
      actionCallback = () {
        dismissActiveNotification();
        final action = onDepositDream ?? this.onDepositDream;
        action?.call();
      };
    }

    showNotification(
      AppNotification(
        id: 'capy_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.capybaraZen,
        title: insight.title,
        body: insight.body,
        actionLabel: actionLabel,
        onAction: actionCallback,
      ),
    );
  }

  /// Backward-compatibility alias for previous calls
  void triggerDuolingoMemeNotification({
    FinanceController? financeController,
    VoidCallback? onOpenAddModal,
    VoidCallback? onWinterCheckIn,
    VoidCallback? onDepositDream,
  }) {
    triggerCapybaraZenNotification(
      financeController: financeController,
      onOpenAddModal: onOpenAddModal,
      onWinterCheckIn: onWinterCheckIn,
      onDepositDream: onDepositDream,
    );
  }

  /// Schedules push directly into the OS / Android notification shade
  /// so it appears when user is in another app (Telegram, Browser, etc.) or when app is closed
  void scheduleBackgroundShadePush(
    int seconds,
    String title,
    String body, {
    int id = 101,
  }) {
    BrowserNotifications.scheduleBackgroundPush(seconds, title, body: body);
    WidgetLaunchService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      delaySeconds: seconds,
    );
  }

  /// 1. Hourly Expense Reminder ("каждый 1 час пусть напоминает ничего не забыли написать что потрачено")
  void triggerHourlyExpenseReminder({VoidCallback? onOpenAddModal}) {
    showNotification(
      AppNotification(
        id: 'hourly_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.hourlyExpense,
        title: 'Ничего не забыли записать?',
        body:
            'Чашка кофе, обед, такси или покупки — запишите расход в 1 тап, пока сумма свежа в памяти.',
        actionLabel: '+ Записать',
        onAction: () {
          dismissActiveNotification();
          final action = onOpenAddModal ?? this.onOpenAddModal;
          action?.call();
        },
      ),
    );
  }

  /// 2. Winter Arc Check-in Reminder ("если забываю там отметить день на winter будет уведомление")
  void triggerWinterArcReminder({VoidCallback? onCheckIn}) {
    showNotification(
      AppNotification(
        id: 'winter_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.winterArc,
        title: 'Winter Arc: Дисциплина под угрозой!',
        body:
            'Вы еще не зафиксировали сегодняшний день. Отметьте день без лишних спонтанных покупок, чтобы спасти серию.',
        actionLabel: 'Зафиксировать',
        onAction: () {
          dismissActiveNotification();
          final action = onCheckIn ?? onWinterCheckIn;
          action?.call();
        },
      ),
    );
  }

  /// 3. Dream Savings Reminder ("пусть напоминает думаю пора заложить деньги на мечту")
  void triggerDreamSavingsReminder({VoidCallback? onDeposit}) {
    showNotification(
      AppNotification(
        id: 'dream_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.dreamSavings,
        title: 'Пора отложить на мечту!',
        body:
            'Даже 100 или 200 сом сегодня приближают вашу цель. Отложите в копилку прямо сейчас.',
        actionLabel: 'Отложить',
        onAction: () {
          dismissActiveNotification();
          final action = onDeposit ?? onDepositDream;
          action?.call();
        },
      ),
    );
  }

  @override
  void dispose() {
    _initialEntranceTimer?.cancel();
    _dismissTimer?.cancel();
    _hourlyTimer?.cancel();
    super.dispose();
  }
}
