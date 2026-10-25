package com.example.finance_management

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.RemoteViews

class ArcMiniWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val TAG = "ArcMiniWidget"
        const val ACTION_QUICK_EXPENSE = "com.example.finance_management.QUICK_EXPENSE"

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.arc_mini_widget)

                // Read cached balance from Flutter SharedPreferences if available
                try {
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val rawBalance = prefs.getString("flutter.arc_widget_balance_display", null)
                        ?: prefs.getString("arc_widget_balance_display", null)
                    views.setTextViewText(R.id.widget_mini_balance, if (!rawBalance.isNullOrEmpty()) rawBalance else "0,00 сом")

                    val accountName = prefs.getString("flutter.arc_widget_account_name", null)
                        ?: prefs.getString("arc_widget_account_name", null)
                    views.setTextViewText(R.id.widget_mini_balance_label, if (!accountName.isNullOrEmpty()) "Баланс • $accountName" else "Баланс кошелька")

                    val todaySpent = prefs.getString("flutter.arc_widget_today_spent", null)
                        ?: prefs.getString("arc_widget_today_spent", null)
                    views.setTextViewText(R.id.widget_mini_subtitle, if (!todaySpent.isNullOrEmpty()) todaySpent else "Сегодня: без трат")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading prefs: ${e.message}")
                }

                val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                // 1. Click on widget root -> opens app
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openAppPendingIntent = PendingIntent.getActivity(
                    context,
                    30,
                    openAppIntent,
                    pendingFlags
                )
                views.setOnClickPendingIntent(R.id.widget_mini_root, openAppPendingIntent)

                // 2. Click on "− Расход" -> opens app directly into Add Expense sheet
                val expenseIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_QUICK_EXPENSE
                    putExtra("quick_action", "add_expense")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val expensePendingIntent = PendingIntent.getActivity(
                    context,
                    31,
                    expenseIntent,
                    pendingFlags
                )
                views.setOnClickPendingIntent(R.id.widget_mini_btn_expense, expensePendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to updateAppWidget $appWidgetId", t)
            }
        }
    }
}
