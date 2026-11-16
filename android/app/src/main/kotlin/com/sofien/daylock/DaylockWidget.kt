package com.sofien.daylock

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.Locale
import kotlin.math.min

/** What the home screen widget shows. Pure, so it can be unit tested. */
data class WidgetRow(val index: Int, val name: String, val kept: Boolean, val excused: Boolean,
    val area: String? = null, val areaColour: Int? = null)

data class WidgetModel(
    val date: String,
    val rows: List<WidgetRow>,
    val kept: Int,
    val eligible: Int,
    val freedomTime: String?,
    /** Freedom is earned: all kept, tomorrow committed, Freedom Time reached. */
    val earned: Boolean = false,
) {
    val progress get() = if (eligible == 0) 0f else kept.toFloat() / eligible
    val allKept get() = eligible > 0 && kept == eligible
    val remaining get() = eligible - kept

    companion object {
        const val MAX_ROWS = 4

        /**
         * Today's plan from the mirrored snapshot. After midnight the saved
         * "tomorrow" becomes today; anything older shows nothing.
         */
        fun from(snapshot: ReminderSnapshot?, valid: Boolean, today: String, minuteOfDay: Int = 0): WidgetModel? {
            if (!valid || snapshot == null) return null
            val plan = snapshot.plan(today) ?: return null
            val rows = plan.tasks.mapIndexed { i, t ->
                WidgetRow(i, t.name, t.outcome == "completed", t.outcome == "excused", t.areaName, t.areaColour)
            }
            val eligible = rows.count { !it.excused }
            val kept = rows.count { it.kept }
            val time = if (snapshot.freedomEnabled)
                String.format(Locale.ROOT, "%02d:%02d", snapshot.freedomHour, snapshot.freedomMinute) else null
            // Tomorrow is only known as committed while the snapshot's today is today.
            val tomorrowCommitted = plan === snapshot.today && snapshot.tomorrow.committed
            val earned = snapshot.freedomEnabled && eligible > 0 && kept == eligible && tomorrowCommitted &&
                minuteOfDay >= snapshot.freedomHour * 60 + snapshot.freedomMinute
            return WidgetModel(today, rows, kept, eligible, time, earned)
        }

        /** Open rows first (in plan order), then kept ones, capped. */
        fun visible(rows: List<WidgetRow>, max: Int = MAX_ROWS): List<WidgetRow> =
            (rows.filter { !it.kept && !it.excused } + rows.filter { it.kept || it.excused }).take(max)

        /** The tap payload Daylock reads, like a notification tap. */
        fun keepPayload(date: String, row: WidgetRow): String = JSONObject().put("screen", "today")
            .put("date", date).put("taskIndex", row.index).put("taskName", row.name).put("action", "keep").toString()
    }
}

/** Colours from the app's chosen theme (colour and light/dark), with defaults. */
data class WidgetPalette(val dark: Boolean, val background: Int, val foreground: Int, val muted: Int,
    val accent: Int, val onAccent: Int) {
    val gold get() = Color.parseColor(if (dark) "#FFC27A" else "#E38A2B")
    /** Text drawn over the sky. */
    val onSky get() = if (dark) Color.parseColor("#F7F3FF") else foreground
    val onSkyMuted get() = if (dark) Color.parseColor("#DCD3F2") else foreground

    companion object {
        fun of(appearance: JSONObject?, systemDark: Boolean): WidgetPalette {
            val dark = when (appearance?.optString("mode", "system")) {
                "light" -> false
                "dark" -> true
                else -> systemDark
            }
            val colors = appearance?.optJSONObject(if (dark) "dark" else "light")
            fun color(key: String, fallback: String) =
                colors?.optLong(key)?.takeIf { it != 0L }?.toInt() ?: Color.parseColor(fallback)
            return WidgetPalette(dark,
                color("background", if (dark) "#120E26" else "#F8F4FD"),
                color("foreground", if (dark) "#F5F1FF" else "#1B1330"),
                color("muted", if (dark) "#C4BBE0" else "#5E5478"),
                color("accent", if (dark) "#C08BFF" else "#6A3FC0"),
                color("onAccent", if (dark) "#1D1036" else "#FFFFFF"))
        }
    }
}

class DaylockWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val app = context.applicationContext
        NotificationRuntime.worker.execute { ids.forEach { render(app, manager, it) } }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        val app = context.applicationContext
        NotificationRuntime.worker.execute { render(app, manager, id) }
    }

    private enum class Size { SMALL, MEDIUM, LARGE }

    companion object {
        private val rowIds = listOf(
            intArrayOf(R.id.widget_row_0, R.id.widget_mark_0, R.id.widget_name_0, R.id.widget_area_0),
            intArrayOf(R.id.widget_row_1, R.id.widget_mark_1, R.id.widget_name_1, R.id.widget_area_1),
            intArrayOf(R.id.widget_row_2, R.id.widget_mark_2, R.id.widget_name_2, R.id.widget_area_2),
            intArrayOf(R.id.widget_row_3, R.id.widget_mark_3, R.id.widget_name_3, R.id.widget_area_3),
        )

        /** Redraws every Daylock widget. Call on the notification worker. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, DaylockWidget::class.java)).forEach { render(context, manager, it) }
        }

        private fun open(context: Context, request: Int, payload: String?): PendingIntent =
            PendingIntent.getActivity(context, request, Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                if (payload != null) putExtra(NotificationRuntime.TAP, payload)
            }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        private fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val options = manager.getAppWidgetOptions(id)
            val portrait = context.resources.configuration.orientation != Configuration.ORIENTATION_LANDSCAPE
            val widthDp = options.getInt(if (portrait) AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 300)
            val heightDp = options.getInt(if (portrait) AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 260)
            val zone = ZoneId.systemDefault()
            val now = Instant.now().atZone(zone)
            val today = now.toLocalDate()
            val (snapshot, valid) = NotificationRuntime.mirror(context)
            val model = WidgetModel.from(snapshot, valid, today.toString(), now.hour * 60 + now.minute)
            val systemDark = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
            val palette = WidgetPalette.of(runCatching { DetectionStore(context).lockAppearance() }.getOrNull(), systemDark)
            manager.updateAppWidget(id, build(context, widthDp, heightDp, model, palette, today))
        }

        /** The widget's views for a size, plan and theme (also used by the debug preview). */
        fun build(context: Context, widthDp: Int, heightDp: Int, model: WidgetModel?, palette: WidgetPalette,
                  today: LocalDate): RemoteViews {
            val size = when {
                widthDp < 200 -> Size.SMALL
                heightDp < 220 -> Size.MEDIUM
                else -> Size.LARGE
            }
            val empty = model == null || model.rows.isEmpty()
            val layout = when (size) {
                Size.SMALL -> R.layout.daylock_widget_small
                Size.MEDIUM -> R.layout.daylock_widget_medium
                Size.LARGE -> R.layout.daylock_widget
            }
            val views = RemoteViews(context.packageName, layout)
            views.setImageViewBitmap(R.id.widget_background,
                background(context, palette, model, size, widthDp, heightDp))
            views.setOnClickPendingIntent(R.id.widget_root, open(context, 7700, null))

            // Header over the sky.
            views.setTextColor(R.id.widget_title, palette.onSky)
            views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_title))
            if (size == Size.LARGE) {
                views.setTextColor(R.id.widget_date, palette.onSkyMuted)
                views.setTextViewText(R.id.widget_date, dateLabel(today))
            }
            val headline: String
            val detail: String
            when {
                empty -> {
                    headline = context.getString(R.string.widget_clear_day)
                    detail = context.getString(R.string.widget_clear_body)
                }
                model!!.earned -> {
                    headline = context.getString(R.string.widget_freedom_earned)
                    detail = context.getString(R.string.widget_all_kept_body)
                }
                else -> {
                    headline = context.getString(R.string.widget_kept, model.kept, model.eligible)
                    detail = if (model.allKept) context.getString(R.string.widget_day_complete)
                        else context.resources.getQuantityString(R.plurals.widget_more_to_sun, model.remaining, model.remaining)
                }
            }
            when (size) {
                Size.SMALL -> {
                    views.setTextColor(R.id.widget_status, palette.onSky)
                    views.setTextViewText(R.id.widget_status, if (empty) "–" else "${model!!.kept}/${model.eligible}")
                }
                else -> {
                    views.setTextColor(R.id.widget_status, palette.onSky)
                    views.setTextViewText(R.id.widget_status, headline)
                    if (size == Size.LARGE) {
                        views.setTextColor(R.id.widget_detail, palette.onSkyMuted)
                        views.setTextViewText(R.id.widget_detail, detail)
                    }
                }
            }

            // Commitments (large: up to four; medium: the next two open ones).
            if (size != Size.SMALL) {
                // As many rows as fit: the list gets 60% of the height, less the chip.
                val max = if (size == Size.LARGE) ((heightDp * .6f - 44) / 36).toInt().coerceIn(1, 4) else 2
                val shown = when {
                    empty -> emptyList()
                    model!!.earned && size == Size.MEDIUM -> emptyList()
                    size == Size.MEDIUM -> WidgetModel.visible(model.rows, max).filter { !it.kept && !it.excused }
                    else -> WidgetModel.visible(model.rows, max)
                }
                rowIds.forEachIndexed { slot, ids ->
                    if (slot >= max) return@forEachIndexed
                    val item = shown.getOrNull(slot)
                    if (item == null) { views.setViewVisibility(ids[0], View.GONE); return@forEachIndexed }
                    val done = item.kept || item.excused
                    views.setViewVisibility(ids[0], View.VISIBLE)
                    views.setImageViewBitmap(ids[1], mark(context, palette, item))
                    views.setTextViewText(ids[2], item.name)
                    views.setTextColor(ids[2], if (done) palette.muted else palette.foreground)
                    views.setInt(ids[2], "setPaintFlags",
                        if (item.kept) Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG else Paint.ANTI_ALIAS_FLAG)
                    views.setInt(ids[0], "setBackgroundResource", when {
                        done -> 0
                        palette.dark -> R.drawable.widget_row_dark
                        else -> R.drawable.widget_row_light
                    })
                    if (size == Size.LARGE) {
                        views.setTextViewText(ids[3], item.area ?: "")
                        views.setTextColor(ids[3], if (done || item.areaColour == null) palette.muted
                            else areaInk(item.areaColour, palette.dark))
                    }
                    views.setContentDescription(ids[0], if (item.kept) context.getString(R.string.widget_kept_row, item.name)
                        else context.getString(R.string.widget_keep_row, item.name))
                    views.setOnClickPendingIntent(ids[0], open(context, 7710 + slot,
                        if (done) null else WidgetModel.keepPayload(model!!.date, item)))
                }
                if (size == Size.MEDIUM) {
                    views.setTextColor(R.id.widget_up_next, palette.muted)
                    views.setTextViewText(R.id.widget_up_next, when {
                        empty -> context.getString(R.string.widget_clear_body)
                        model!!.earned || shown.isEmpty() -> detail
                        else -> context.getString(R.string.widget_up_next)
                    })
                }
                if (size == Size.LARGE) {
                    val more = if (empty) 0 else model!!.rows.size - shown.size
                    views.setViewVisibility(R.id.widget_more, if (more > 0) View.VISIBLE else View.GONE)
                    views.setTextColor(R.id.widget_more, palette.muted)
                    views.setTextViewText(R.id.widget_more, context.getString(R.string.widget_more, more))
                }
            }

            // Bottom chip: Freedom state, or Plan tomorrow on an empty day.
            val chip = when {
                empty -> context.getString(R.string.widget_plan_tomorrow)
                model!!.earned && size == Size.SMALL -> context.getString(R.string.widget_freedom_earned)
                model.earned -> context.getString(R.string.widget_unlocked_since, model.freedomTime)
                model.freedomTime != null -> if (size == Size.SMALL)
                    context.getString(R.string.widget_unlock_short, model.freedomTime)
                    else context.getString(R.string.widget_unlock, model.freedomTime)
                else -> null
            }
            if (chip == null) views.setViewVisibility(R.id.widget_chip, View.GONE) else {
                views.setViewVisibility(R.id.widget_chip, View.VISIBLE)
                val earned = model?.earned == true
                val (ink, fill) = when {
                    empty -> palette.onAccent to palette.accent
                    size == Size.SMALL -> palette.onSky to Color.TRANSPARENT
                    earned -> palette.gold to withAlpha(palette.gold, .18f)
                    else -> palette.accent to withAlpha(palette.accent, .16f)
                }
                val icon = when { empty -> Icon.ARROW; earned -> Icon.UNLOCKED; else -> Icon.LOCK }
                views.setImageViewBitmap(R.id.widget_chip, chip(context, chip, ink, fill, icon, size == Size.SMALL))
                views.setContentDescription(R.id.widget_chip, chip)
                if (empty) views.setOnClickPendingIntent(R.id.widget_chip,
                    open(context, 7720, JSONObject().put("screen", "plan").toString()))
            }
            return views
        }

        private fun dateLabel(date: LocalDate): String {
            val locale = Locale.getDefault()
            val pattern = android.text.format.DateFormat.getBestDateTimePattern(locale, "EEEEdMMMM")
            return java.time.format.DateTimeFormatter.ofPattern(pattern, locale).format(date)
        }

        private fun withAlpha(color: Int, alpha: Float) =
            Color.argb((alpha * 255).toInt(), Color.red(color), Color.green(color), Color.blue(color))

        /** An Area colour readable on the widget's background. */
        private fun areaInk(colour: Int, dark: Boolean): Int {
            val hsv = FloatArray(3)
            Color.colorToHSV(colour, hsv)
            hsv[2] = if (dark) 0.92f else 0.48f
            hsv[1] = min(hsv[1], if (dark) .45f else .8f)
            return Color.HSVToColor(hsv)
        }

        private fun density(context: Context) = min(context.resources.displayMetrics.density, 2.5f)

        /** Sky (theme-tinted, sun by progress) over the themed ground, with rounded corners. */
        private fun background(context: Context, palette: WidgetPalette, model: WidgetModel?, size: Size,
                               widthDp: Int, heightDp: Int): Bitmap {
            val d = density(context)
            val w = (widthDp.coerceIn(110, 600) * d).toInt()
            val h = (heightDp.coerceIn(110, 600) * d).toInt()
            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val radius = 28 * d
            canvas.clipPath(Path().apply { addRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), radius, radius, Path.Direction.CW) })
            canvas.drawColor(palette.background)
            val skyW = if (size == Size.MEDIUM) (w * .4f).toInt() else w
            val skyH = when (size) {
                Size.LARGE -> (h * .48f).toInt()
                else -> h
            }
            val progress = if (model == null || model.rows.isEmpty()) 0f else model.progress
            // The earned sun burst needs room; smaller sizes show a raised sun instead.
            val sky = DaylockSkyView(context, palette.accent, palette.background, palette.dark, progress,
                model?.earned == true && size == Size.LARGE)
            sky.measure(View.MeasureSpec.makeMeasureSpec(skyW, View.MeasureSpec.EXACTLY),
                View.MeasureSpec.makeMeasureSpec(skyH, View.MeasureSpec.EXACTLY))
            sky.layout(0, 0, skyW, skyH)
            canvas.save()
            canvas.clipRect(0, 0, skyW, skyH)
            sky.draw(canvas)
            canvas.restore()
            return bitmap
        }

        /** The commitment's circle: open (accent ring) or kept (gold with a tick). */
        private fun mark(context: Context, palette: WidgetPalette, row: WidgetRow): Bitmap {
            val d = density(context)
            val s = (22 * d).toInt()
            val bitmap = Bitmap.createBitmap(s, s, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            val c = s / 2f
            when {
                row.kept -> {
                    paint.color = palette.gold
                    canvas.drawCircle(c, c, c, paint)
                    paint.color = if (palette.dark) Color.parseColor("#3A1D05") else Color.WHITE
                    paint.style = Paint.Style.STROKE; paint.strokeWidth = 2.2f * d
                    paint.strokeCap = Paint.Cap.ROUND; paint.strokeJoin = Paint.Join.ROUND
                    canvas.drawPath(Path().apply {
                        moveTo(s * .27f, s * .52f); lineTo(s * .44f, s * .68f); lineTo(s * .74f, s * .34f)
                    }, paint)
                }
                row.excused -> {
                    paint.color = palette.muted; paint.style = Paint.Style.STROKE; paint.strokeWidth = 2 * d
                    canvas.drawCircle(c, c, c - d, paint)
                    canvas.drawLine(s * .3f, c, s * .7f, c, paint)
                }
                else -> {
                    paint.color = palette.accent; paint.style = Paint.Style.STROKE; paint.strokeWidth = 2 * d
                    canvas.drawCircle(c, c, c - d, paint)
                }
            }
            return bitmap
        }

        private enum class Icon { LOCK, UNLOCKED, ARROW }

        /** The bottom chip as one image: pill, icon and text, sized to the text. */
        private fun chip(context: Context, text: String, ink: Int, fill: Int, icon: Icon, compact: Boolean): Bitmap {
            val d = density(context)
            val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = ink
                textSize = (if (compact) 11f else 12f) * context.resources.displayMetrics.scaledDensity / context.resources.displayMetrics.density * d
                typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
            }
            val pad = if (fill == Color.TRANSPARENT) 0f else 10 * d
            val iconSize = 12 * d
            val gap = 6 * d
            val h = (if (compact) 18 else 28) * d
            val rtl = android.text.TextUtils.getLayoutDirectionFromLocale(Locale.getDefault()) == View.LAYOUT_DIRECTION_RTL
            val w = pad * 2 + iconSize + gap + textPaint.measureText(text)
            val bitmap = Bitmap.createBitmap(w.toInt() + 1, h.toInt(), Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            if (fill != Color.TRANSPARENT) canvas.drawRoundRect(RectF(0f, 0f, w, h), h / 2, h / 2,
                Paint(Paint.ANTI_ALIAS_FLAG).apply { color = fill })
            val iconLeft = if (rtl) w - pad - iconSize else pad
            val textLeft = if (rtl) pad else pad + iconSize + gap
            val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = ink; style = Paint.Style.STROKE; strokeWidth = 1.6f * d
                strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND
            }
            val top = (h - iconSize) / 2
            when (icon) {
                Icon.ARROW -> canvas.drawPath(Path().apply {
                    val y = top + iconSize / 2
                    val (a, b) = if (rtl) iconLeft + iconSize to iconLeft else iconLeft to iconLeft + iconSize
                    moveTo(a, y); lineTo(b, y)
                    val back = if (rtl) iconSize * .4f else -iconSize * .4f
                    moveTo(b + back, y - iconSize * .4f); lineTo(b, y); lineTo(b + back, y + iconSize * .4f)
                }, stroke)
                else -> {
                    canvas.drawRoundRect(RectF(iconLeft + iconSize * .15f, top + iconSize * .45f,
                        iconLeft + iconSize * .85f, top + iconSize), 2 * d, 2 * d, stroke)
                    val shackle = RectF(iconLeft + iconSize * .3f, top, iconLeft + iconSize * .7f, top + iconSize * .8f)
                    canvas.drawArc(shackle, 180f, if (icon == Icon.LOCK) 180f else 140f, false, stroke)
                    if (icon == Icon.LOCK) canvas.drawLine(shackle.right, shackle.centerY(), shackle.right, top + iconSize * .45f, stroke)
                    canvas.drawLine(shackle.left, shackle.centerY(), shackle.left, top + iconSize * .45f, stroke)
                }
            }
            val baseline = h / 2 - (textPaint.descent() + textPaint.ascent()) / 2
            canvas.drawText(text, textLeft, baseline, textPaint)
            return bitmap
        }
    }
}
