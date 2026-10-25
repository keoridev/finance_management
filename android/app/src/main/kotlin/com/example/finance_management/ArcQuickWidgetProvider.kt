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

                // Read cached balance from SharedPreferences
                try {
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val rawBalance = prefs.getString("flutter.arc_widget_balance_display", null)
                        ?: prefs.getString("arc_widget_balance_display", null)
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

                // 3. Click on "Маршрутка" (25 сом)
                val marshrutkaIntent = Intent(context, MainActivity::class.java).apply {
                    putExtra("quick_action", "shortcut:marshrutka")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                views.setOnClickPendingIntent(
                    R.id.btn_quick_marshrutka,
                    PendingIntent.getActivity(context, 12, marshrutkaIntent, pendingFlags)
                )

                // 4. Click on "Кофе" (150 сом)
                val coffeeIntent = Intent(context, MainActivity::class.java).apply {
                    putExtra("quick_action", "shortcut:coffee")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                views.setOnClickPendingIntent(
                    R.id.btn_quick_coffee,
                    PendingIntent.getActivity(context, 13, coffeeIntent, pendingFlags)
                )

                // 5. Click on "Обед" (350 сом)
                val lunchIntent = Intent(context, MainActivity::class.java).apply {
                    putExtra("quick_action", "shortcut:lunch")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                views.setOnClickPendingIntent(
                    R.id.btn_quick_lunch,
                    PendingIntent.getActivity(context, 14, lunchIntent, pendingFlags)
                )

                // 6. Click on "Такси" (180 сом)
                val taxiIntent = Intent(context, MainActivity::class.java).apply {
                    putExtra("quick_action", "shortcut:taxi")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                views.setOnClickPendingIntent(
                    R.id.btn_quick_taxi,
                    PendingIntent.getActivity(context, 15, taxiIntent, pendingFlags)
                )

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to update Quick Widget $appWidgetId", t)
            }
        }
    }
}
