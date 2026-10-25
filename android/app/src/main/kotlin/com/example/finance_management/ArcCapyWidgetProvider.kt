package com.example.finance_management

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.RemoteViews

class ArcCapyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_CYCLE_PREDICTION) {
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val currentIndex = prefs.getInt("capy_widget_quote_index", 0)
                prefs.edit().putInt("capy_widget_quote_index", currentIndex + 1).apply()

                val appWidgetManager = AppWidgetManager.getInstance(context)
                val component = ComponentName(context, ArcCapyWidgetProvider::class.java)
                val ids = appWidgetManager.getAppWidgetIds(component)
                for (id in ids) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            } catch (t: Throwable) {
                Log.e(TAG, "Error in onReceive", t)
            }
        }
    }

    companion object {
        private const val TAG = "ArcCapyWidget"
        const val ACTION_CYCLE_PREDICTION = "com.example.finance_management.CYCLE_CAPY_PREDICTION"

        val PREDICTIONS = arrayOf(
            Pair("УРОК ДЗЕНА", "«Лучший способ сберечь 1000 сом — это просто не покупать то, без чего можно обойтись. Пей чай и отдыхай.»"),
            Pair("О СКИДКАХ", "«Увидел скидку 70%? Капибара советует полежать 10 минут. Скидка 100% — это не покупать вовсе.»"),
            Pair("БАЛАНС", "«Деньги имеют свойство испаряться, когда забываешь их учитывать. Заглядывай в ARC чаще, бро!»"),
            Pair("СОВЕТ ДНЯ", "«Импульсивная покупка длится 5 секунд, а дефицит на карте — до конца месяца. Будь дзен.»"),
            Pair("КОПИЛКА", "«Положи 100 сом в копилку мечты прямо сейчас. Капибара довольно жмурится с апельсином на голове.»"),
            Pair("ЧИЛЛ", "«Богат не тот, у кого миллион спонтанных трат, а тот, кто спокойно чиллит без долгов и суеты.»"),
            Pair("ДИСЦИПЛИНА", "«Твой стрик дисциплины крепнет. Самурай кошелька не суетится — самурай уверен в завтрашнем дне.»"),
            Pair("ГОСТЕПРИИМСТВО", "«Банкомат передавал привет! Сказал, что уважает твой покой и ждет только за снятием кэша на радости.»"),
            Pair("МУДРОСТЬ ВОДЫ", "«Капибара сидит в горячем источнике и напоминает: финансовая подушка греет лучше любого пледа.»"),
            Pair("ФИНАНСОВЫЙ МИР", "«Не покупай статус — покупай свободу и спокойный сон. Капибара гарантирует гармонию.»")
        )

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.arc_capy_widget)

                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val quoteIndex = prefs.getInt("capy_widget_quote_index", 0)
                val safeIndex = Math.abs(quoteIndex) % PREDICTIONS.size

                val customBody = prefs.getString("flutter.arc_widget_capy_body", null)
                    ?: prefs.getString("arc_widget_capy_body", null)
                val customTag = prefs.getString("flutter.arc_widget_capy_tag", null)
                    ?: prefs.getString("arc_widget_capy_tag", null)

                val tag: String
                val quote: String

                if (quoteIndex == 0 && !customBody.isNullOrEmpty()) {
                    tag = customTag ?: "ДЗЕН"
                    quote = "«$customBody»"
                } else {
                    val pair = PREDICTIONS[safeIndex]
                    tag = pair.first
                    quote = pair.second
                }

                views.setTextViewText(R.id.capy_widget_tag, tag)
                views.setTextViewText(R.id.capy_widget_quote, quote)

                val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                // 1. Click on widget body -> opens app
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openAppPendingIntent = PendingIntent.getActivity(
                    context,
                    20,
                    openAppIntent,
                    pendingFlags
                )
                views.setOnClickPendingIntent(R.id.capy_widget_root, openAppPendingIntent)

                // 2. Click on "Новая мысль" -> cycles prediction directly on home screen
                val cycleIntent = Intent(context, ArcCapyWidgetProvider::class.java).apply {
                    action = ACTION_CYCLE_PREDICTION
                }
                val cyclePendingIntent = PendingIntent.getBroadcast(
                    context,
                    21,
                    cycleIntent,
                    pendingFlags
                )
                views.setOnClickPendingIntent(R.id.capy_widget_btn_refresh, cyclePendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to updateAppWidget $appWidgetId", t)
            }
        }
    }
}
