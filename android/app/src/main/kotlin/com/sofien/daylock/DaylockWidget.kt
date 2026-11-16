package com.sofien.daylock

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneId

/** What the home screen widget shows. Pure, so it can be unit tested. */
data class WidgetRow(val index: Int, val name: String, val kept: Boolean, val excused: Boolean)

data class WidgetModel(
    val date: String,
    val rows: List<WidgetRow>,
    val kept: Int,
    val eligible: Int,
    val freedomTime: String?,
) {
    val progress get() = if (eligible == 0) 0f else kept.toFloat() / eligible
    val allKept get() = eligible > 0 && kept == eligible

    companion object {
        const val MAX_ROWS = 4

        /**
         * Today's plan from the mirrored snapshot. After midnight the saved
         * "tomorrow" becomes today; anything older shows nothing.
         */
        fun from(snapshot: ReminderSnapshot?, valid: Boolean, today: String): WidgetModel? {
            if (!valid || snapshot == null) return null
            val plan = snapshot.plan(today) ?: return null
            val rows = plan.tasks.mapIndexed { i, t ->
                WidgetRow(i, t.name, t.outcome == "completed", t.outcome == "excused")
            }
            val eligible = rows.count { !it.excused }
            val time = if (snapshot.freedomEnabled)
                String.format(java.util.Locale.ROOT, "%02d:%02d", snapshot.freedomHour, snapshot.freedomMinute) else null
            return WidgetModel(today, rows, rows.count { it.kept }, eligible, time)
        }

        /** Open rows first (in plan order), then kept ones, capped. */
        fun visible(rows: List<WidgetRow>): List<WidgetRow> =
            (rows.filter { !it.kept && !it.excused } + rows.filter { it.kept || it.excused }).take(MAX_ROWS)

        /** The tap payload Daylock reads, like a notification tap. */
        fun keepPayload(date: String, row: WidgetRow): String = JSONObject().put("screen", "today")
            .put("date", date).put("taskIndex", row.index).put("taskName", row.name).put("action", "keep").toString()
    }
}

class DaylockWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        NotificationRuntime.worker.execute { render(context.applicationContext, manager, ids) }
    }

    companion object {
        private val rowIds = listOf(
            Triple(R.id.widget_row_0, R.id.widget_mark_0, R.id.widget_name_0),
            Triple(R.id.widget_row_1, R.id.widget_mark_1, R.id.widget_name_1),
            Triple(R.id.widget_row_2, R.id.widget_mark_2, R.id.widget_name_2),
            Triple(R.id.widget_row_3, R.id.widget_mark_3, R.id.widget_name_3),
        )

        /** Redraws every Daylock widget. Call on the notification worker. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, DaylockWidget::class.java))
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        private fun open(context: Context, request: Int, payload: String?): PendingIntent =
            PendingIntent.getActivity(context, request, Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                if (payload != null) putExtra(NotificationRuntime.TAP, payload)
            }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val today = Instant.now().atZone(ZoneId.systemDefault()).toLocalDate().toString()
            val (snapshot, valid) = NotificationRuntime.mirror(context)
            val model = WidgetModel.from(snapshot, valid, today)
            val views = RemoteViews(context.packageName, R.layout.daylock_widget)
            views.setOnClickPendingIntent(R.id.widget_root, open(context, 7700, null))
            views.setImageViewBitmap(R.id.widget_sky, sky(context, model))
            if (model == null || model.rows.isEmpty()) {
                views.setTextViewText(R.id.widget_status, "")
                views.setTextViewText(R.id.widget_footer, context.getString(R.string.widget_empty))
                rowIds.forEach { views.setViewVisibility(it.first, View.GONE) }
            } else {
                views.setTextViewText(R.id.widget_status,
                    context.getString(R.string.widget_kept, model.kept, model.eligible))
                val shown = WidgetModel.visible(model.rows)
                rowIds.forEachIndexed { slot, (row, mark, name) ->
                    val item = shown.getOrNull(slot)
                    if (item == null) { views.setViewVisibility(row, View.GONE); return@forEachIndexed }
                    views.setViewVisibility(row, View.VISIBLE)
                    views.setTextViewText(name, item.name)
                    views.setTextViewText(mark, when { item.kept -> "✓"; item.excused -> "–"; else -> "○" })
                    views.setInt(name, "setPaintFlags", if (item.kept) android.graphics.Paint.STRIKE_THRU_TEXT_FLAG or
                        android.graphics.Paint.ANTI_ALIAS_FLAG else android.graphics.Paint.ANTI_ALIAS_FLAG)
                    views.setContentDescription(row, if (item.kept) context.getString(R.string.widget_kept_row, item.name)
                        else context.getString(R.string.widget_keep_row, item.name))
                    // Open rows keep the commitment in Daylock; kept ones just open it.
                    views.setOnClickPendingIntent(row, open(context, 7710 + slot,
                        if (item.kept || item.excused) null else WidgetModel.keepPayload(model.date, item)))
                }
                val more = model.rows.size - shown.size
                views.setTextViewText(R.id.widget_footer, when {
                    more > 0 -> context.getString(R.string.widget_more, more)
                    model.allKept -> context.getString(R.string.widget_all_kept)
                    model.freedomTime != null -> context.getString(R.string.widget_unlock, model.freedomTime)
                    else -> ""
                })
            }
            for (id in ids) manager.updateAppWidget(id, views)
        }

        /** The Daylock sky with today's sun, drawn to a bitmap. */
        private fun sky(context: Context, model: WidgetModel?): Bitmap {
            val density = context.resources.displayMetrics.density
            val width = (300 * density).toInt()
            val height = (84 * density).toInt()
            val dark = context.resources.configuration.uiMode and
                android.content.res.Configuration.UI_MODE_NIGHT_MASK == android.content.res.Configuration.UI_MODE_NIGHT_YES
            val accent = Color.parseColor(if (dark) "#C08BFF" else "#6A3FC0")
            val background = Color.parseColor(if (dark) "#1B1533" else "#FFFFFF")
            val view = DaylockSkyView(context, accent, background, dark, model?.progress ?: 0f, model?.allKept == true)
            view.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
                View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
            view.layout(0, 0, width, height)
            return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { view.draw(Canvas(it)) }
        }
    }
}
