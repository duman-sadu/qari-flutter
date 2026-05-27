package com.example.qari_flutter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class QariWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(context: Context, manager: AppWidgetManager, id: Int) {
            val p = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val surahKz = p.getString("widget_surah", "") ?: ""
            val surahRu = p.getString("widget_surah_ru", "") ?: ""
            val arabic  = p.getString("widget_ayah_arabic", "") ?: ""
            val verse   = p.getInt("widget_verse", 0)
            val total   = p.getInt("widget_total_verses", 0)
            val days    = p.getInt("widget_goal_days", -1)
            val gType   = p.getString("widget_goal_type", "") ?: ""
            val isRu    = p.getBoolean("widget_is_ru", false)

            val views = RemoteViews(context.packageName, R.layout.qari_widget)

            // ── Surah + ayah ───────────────────────────────────────────────
            if (surahKz.isEmpty()) {
                views.setTextViewText(R.id.widget_surah_name, "")
                views.setTextViewText(
                    R.id.widget_ayah_arabic,
                    "بِسْمِ اللّهِ الرَّحْمٰنِ الرَّحِيْمِ",
                )
                val hint = if (isRu) "Откройте Qari" else "Qari ашыңыз"
                views.setTextViewText(R.id.widget_verse_info, hint)
            } else {
                val surahName = if (isRu && surahRu.isNotEmpty()) surahRu else surahKz
                views.setTextViewText(R.id.widget_surah_name, surahName)
                val ayahText = arabic.ifEmpty { "بِسْمِ اللّهِ الرَّحْمٰنِ الرَّحِيْمِ" }
                views.setTextViewText(R.id.widget_ayah_arabic, ayahText)
                val verseText = if (verse > 0 && total > 0) "Аят $verse / $total" else ""
                views.setTextViewText(R.id.widget_verse_info, verseText)
            }

            // ── Goal — always shown independently ──────────────────────────
            val goalText = if (days > 0) {
                val label = when {
                    gType == "learn" && isRu -> "Заучивание"
                    gType == "learn"         -> "Жаттау"
                    isRu                     -> "Чтение"
                    else                     -> "Оқу"
                }
                "🎯 $label: $days күн"
            } else ""
            views.setTextViewText(R.id.widget_goal, goalText)

            // ── Tap opens app ──────────────────────────────────────────────
            val intent = Intent(context, MainActivity::class.java)
            val pi = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)
            manager.updateAppWidget(id, views)
        }
    }
}
