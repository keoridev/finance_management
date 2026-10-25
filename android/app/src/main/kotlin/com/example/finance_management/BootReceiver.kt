package com.example.finance_management

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED || intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)

            // 1. ArcFinanceWidgetProvider
            val classicComponent = ComponentName(context, ArcFinanceWidgetProvider::class.java)
            for (appWidgetId in appWidgetManager.getAppWidgetIds(classicComponent)) {
                ArcFinanceWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
            }

            // 2. ArcWinterWidgetProvider
            val winterComponent = ComponentName(context, ArcWinterWidgetProvider::class.java)
            for (appWidgetId in appWidgetManager.getAppWidgetIds(winterComponent)) {
                ArcWinterWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
            }

            // 3. ArcCapyWidgetProvider
            val capyComponent = ComponentName(context, ArcCapyWidgetProvider::class.java)
            for (appWidgetId in appWidgetManager.getAppWidgetIds(capyComponent)) {
                ArcCapyWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
            }

            // 4. ArcMiniWidgetProvider
            val miniComponent = ComponentName(context, ArcMiniWidgetProvider::class.java)
            for (appWidgetId in appWidgetManager.getAppWidgetIds(miniComponent)) {
                ArcMiniWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}
