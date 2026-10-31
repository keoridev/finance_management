package com.example.finance_management

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.RemoteViews

class ArcQuickWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val TAG = "ArcQuickWidget"

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.arc_quick_widget)

                val prefs = try {
                    context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                } catch (e: Exception) {
                    Log.e(TAG, "Error opening prefs: ${e.message}")
                    null
                }

                // Read cached balance from SharedPreferences
                try {
                    val rawBalance = prefs?.getString("flutter.arc_widget_balance_display", null)
                        ?: prefs?.getString("arc_widget_balance_display", null)
                    views.setTextViewText(R.id.quick_widget_balance, if (!rawBalance.isNullOrEmpty()) rawBalance else "0,00 сом")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading prefs: ${e.message}")
                }

                val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                // 1. Click on widget background -> opens app
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                views.setOnClickPendingIntent(
                    R.id.quick_widget_root,
                    PendingIntent.getActivity(context, 10, openAppIntent, pendingFlags)
                )

                // 2. Click on "+ Свой расход"
                val customExpenseIntent = Intent(context, MainActivity::class.java).apply {
                    putExtra("quick_action", "add_expense")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                views.setOnClickPendingIntent(
                    R.id.btn_quick_custom,
                    PendingIntent.getActivity(context, 11, customExpenseIntent, pendingFlags)
                )

                // 3. Dynamic Quick Buttons (the ones user last entered)
                val buttonLayouts = arrayOf(
                    Triple(R.id.btn_quick_marshrutka, R.id.btn_quick_0_title, R.id.btn_quick_0_amount),
                    Triple(R.id.btn_quick_coffee, R.id.btn_quick_1_title, R.id.btn_quick_1_amount),
                    Triple(R.id.btn_quick_lunch, R.id.btn_quick_2_title, R.id.btn_quick_2_amount),
                    Triple(R.id.btn_quick_taxi, R.id.btn_quick_3_title, R.id.btn_quick_3_amount)
                )

                val defaultButtons = arrayOf(
                    Triple("МАРШРУТКА", 25.0, "cat_transport"),
                    Triple("КОФЕ", 150.0, "cat_restaurants"),
                    Triple("ОБЕД", 350.0, "cat_restaurants"),
                    Triple("ТАКСИ", 180.0, "cat_transport")
                )

                for (i in 0 until 4) {
                    val viewsTriple = buttonLayouts[i]
                    val defTriple = defaultButtons[i]

                    var title = prefs?.getString("flutter.arc_widget_btn_${i}_title", null)
                        ?: prefs?.getString("arc_widget_btn_${i}_title", null)
                    var amount = try {
                        val f = prefs?.getFloat("flutter.arc_widget_btn_${i}_amount", -1f) ?: -1f
                        if (f >= 0) f.toDouble() else {
                            val f2 = prefs?.getFloat("arc_widget_btn_${i}_amount", -1f) ?: -1f
                            if (f2 >= 0) f2.toDouble() else null
                        }
                    } catch (_: Exception) {
                        null
                    }
                    var categoryId = prefs?.getString("flutter.arc_widget_btn_${i}_cat", null)
                        ?: prefs?.getString("arc_widget_btn_${i}_cat", null)

                    if (title.isNullOrEmpty() || amount == null || amount <= 0) {
                        title = defTriple.first
                        amount = defTriple.second
                        categoryId = defTriple.third
                    }

                    val formattedAmount = if (amount % 1.0 == 0.0) {
                        "${amount.toInt()} сом"
                    } else {
                        String.format(java.util.Locale.US, "%.1f сом", amount)
                    }

                    views.setTextViewText(viewsTriple.second, title.uppercase())
                    views.setTextViewText(viewsTriple.third, formattedAmount)

                    val shortcutIntent = Intent(context, MainActivity::class.java).apply {
                        putExtra("quick_action", "shortcut_dynamic:$i:$title:$amount:$categoryId")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    views.setOnClickPendingIntent(
                        viewsTriple.first,
                        PendingIntent.getActivity(context, 100 + i, shortcutIntent, pendingFlags)
                    )
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to update Quick Widget $appWidgetId", t)
            }
        }
    }
}
