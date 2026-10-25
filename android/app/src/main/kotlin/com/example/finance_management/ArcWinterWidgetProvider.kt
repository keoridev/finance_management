package com.example.finance_management

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import java.util.Calendar

class ArcWinterWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val TAG = "ArcWinterWidget"
        const val ACTION_WINTER_CHECKIN = "com.example.finance_management.WINTER_CHECKIN"

        private val SQ_IDS_ROW1 = intArrayOf(
            R.id.sq_1, R.id.sq_2, R.id.sq_3, R.id.sq_4, R.id.sq_5, R.id.sq_6, R.id.sq_7
        )
        private val SQ_IDS_ROW2 = intArrayOf(
            R.id.sq_8, R.id.sq_9, R.id.sq_10, R.id.sq_11, R.id.sq_12, R.id.sq_13, R.id.sq_14
        )
        private val DAY_HDR_IDS = intArrayOf(
            R.id.day_hdr_1, R.id.day_hdr_2, R.id.day_hdr_3, R.id.day_hdr_4, R.id.day_hdr_5, R.id.day_hdr_6, R.id.day_hdr_7
        )

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.arc_winter_widget)

                var streak = 0
                var isChecked = false
                var balance = "0,00 сом"

                try {
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    streak = prefs.getInt("flutter.arc_widget_winter_streak", -1)
                        .takeIf { it >= 0 }
                        ?: prefs.getInt("arc_widget_winter_streak", 0)

                    isChecked = prefs.getBoolean("flutter.arc_widget_winter_checked", false)
                        || prefs.getBoolean("arc_widget_winter_checked", false)

                    val rawBalance = prefs.getString("flutter.arc_widget_balance_display", null)
                        ?: prefs.getString("arc_widget_balance_display", null)
                    if (!rawBalance.isNullOrEmpty()) {
                        balance = rawBalance
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading prefs: ${e.message}")
                }

                // 1. Balance & Footer streak
                views.setTextViewText(R.id.winter_widget_balance, balance)
                views.setTextViewText(R.id.winter_widget_streak_text, "$streak дн. без спонтанных трат")

                // 2. Check-in action button
                if (isChecked) {
                    views.setTextViewText(R.id.winter_widget_btn_checkin, "Отмечено")
                } else {
                    views.setTextViewText(R.id.winter_widget_btn_checkin, "Отметить")
                }

                // 3. Current day of week (Monday = 1 ... Sunday = 7)
                val cal = Calendar.getInstance()
                val dayOfWeekJava = cal.get(Calendar.DAY_OF_WEEK)
                val currentWeekday = if (dayOfWeekJava == Calendar.SUNDAY) 7 else dayOfWeekJava - 1

                // Highlight current day header (e.g. Чт in amber)
                for (i in 0 until 7) {
                    val hdrId = DAY_HDR_IDS[i]
                    if (i + 1 == currentWeekday) {
                        views.setTextColor(hdrId, Color.parseColor("#FF9F0A"))
                    } else {
                        views.setTextColor(hdrId, Color.parseColor("#8E8E93"))
                    }
                }

                // 4. Fill Row 1 (Current Week habit squares)
                for (i in 0 until 7) {
                    val dayNum = i + 1
                    val sqId = SQ_IDS_ROW1[i]
                    when {
                        dayNum < currentWeekday -> {
                            // Past days of this week
                            views.setInt(sqId, "setBackgroundResource", R.drawable.widget_square_done)
                            views.setTextViewText(sqId, "✓")
                            views.setTextColor(sqId, Color.WHITE)
                        }
                        dayNum == currentWeekday -> {
                            // Today
                            if (isChecked) {
                                views.setInt(sqId, "setBackgroundResource", R.drawable.widget_square_today_done)
                                views.setTextViewText(sqId, "✓")
                                views.setTextColor(sqId, Color.parseColor("#161412"))
                            } else {
                                views.setInt(sqId, "setBackgroundResource", R.drawable.widget_square_today_pending)
                                views.setTextViewText(sqId, "")
                                views.setTextColor(sqId, Color.WHITE)
                            }
                        }
                        else -> {
                            // Upcoming days of this week
                            views.setInt(sqId, "setBackgroundResource", R.drawable.widget_square_empty)
                            views.setTextViewText(sqId, "")
                        }
                    }
                }

                // 5. Fill Row 2 (Cycle or Previous Week completed squares)
                val row2CompletedCount = if (streak > 7) {
                    (streak - 7).coerceAtMost(7)
                } else {
                    (streak).coerceAtMost(currentWeekday)
                }

                for (i in 0 until 7) {
                    val sqId = SQ_IDS_ROW2[i]
                    if (i < row2CompletedCount) {
                        views.setInt(sqId, "setBackgroundResource", R.drawable.widget_square_done)
                        views.setTextViewText(sqId, "✓")
                        views.setTextColor(sqId, Color.WHITE)
                    } else {
                        views.setInt(sqId, "setBackgroundResource", R.drawable.widget_square_empty)
                        views.setTextViewText(sqId, "")
                    }
                }

                val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                // 6. Click on widget background -> opens app directly
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openAppPendingIntent = PendingIntent.getActivity(
                    context,
                    10,
                    openAppIntent,
                    pendingFlags
                )
                views.setOnClickPendingIntent(R.id.winter_widget_root, openAppPendingIntent)

                // 7. Click on "Отметить" button -> checks in today's winter streak
                val checkinIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_WINTER_CHECKIN
                    putExtra("quick_action", "winter_checkin")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val checkinPendingIntent = PendingIntent.getActivity(
                    context,
                    11,
                    checkinIntent,
                    pendingFlags
                )
                views.setOnClickPendingIntent(R.id.winter_widget_btn_checkin, checkinPendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to updateAppWidget $appWidgetId", t)
            }
        }
    }
}
