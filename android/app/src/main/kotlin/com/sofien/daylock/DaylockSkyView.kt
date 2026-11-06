package com.sofien.daylock

import android.content.Context
import android.graphics.*
import android.view.View
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Native counterpart of Flutter's DaylockScene: a sky over layered hills with a
 * sun that rises with progress. Decorative only; the adjacent text carries the
 * meaning. Drawn without starting a Flutter engine.
 */
class DaylockSkyView(
    context: Context,
    private val accent: Int,
    private val background: Int,
    private val dark: Boolean,
    private val progress: Float,
    private val earned: Boolean,
) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    init { importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val density = resources.displayMetrics.density
        fun d(v: Float) = v * density

        val sky = when {
            earned && dark -> intArrayOf(tone(.22f, .55f), tone(.36f, .5f, 20f), Color.parseColor("#E2708A"), Color.parseColor("#FFB877"))
            earned -> intArrayOf(tone(.93f, .6f), Color.parseColor("#FFD6E4"), Color.parseColor("#FFCFA0"))
            dark -> intArrayOf(background, tone(.22f, .55f), tone(.33f, .55f, 10f))
            else -> intArrayOf(tone(.95f, .7f), tone(.92f, .55f, 30f), Color.parseColor("#FFDCC8"))
        }
        paint.shader = LinearGradient(0f, 0f, 0f, h, sky, null, Shader.TileMode.CLAMP)
        canvas.drawRect(0f, 0f, w, h, paint)

        val sunX = w * .77f
        val horizon = h - d(80f)
        val radius = d(if (earned) 46f else 34f)
        val p = progress.coerceIn(0f, 1f)
        val sunY = if (earned) h * .38f else horizon + d(46f) - (horizon + d(46f) - h * .40f) * p

        val glowColor = if (earned) Color.parseColor("#FFE0A0") else if (dark) Color.parseColor("#FF8FD2") else Color.parseColor("#FFC8A0")
        val strength = if (earned) .85f else .35f + .35f * p
        paint.shader = RadialGradient(
            sunX, min(sunY, horizon + d(10f)), max(w, h) * .9f,
            intArrayOf(withAlpha(glowColor, strength), withAlpha(accent, strength * .3f), Color.TRANSPARENT),
            floatArrayOf(0f, .45f, 1f), Shader.TileMode.CLAMP,
        )
        canvas.drawRect(0f, 0f, w, h, paint)
        paint.shader = null

        if (dark && !earned) {
            val stars = arrayOf(
                floatArrayOf(.10f, .16f, 1.2f, .55f), floatArrayOf(.49f, .10f, 1f, .45f),
                floatArrayOf(.64f, .27f, 1.3f, .40f), floatArrayOf(.31f, .37f, 1f, .35f),
                floatArrayOf(.86f, .15f, 1.2f, .40f), floatArrayOf(.20f, .55f, 1f, .30f),
            )
            for (s in stars) {
                paint.color = withAlpha(Color.WHITE, s[3] * (1 - p))
                canvas.drawCircle(w * s[0], h * s[1], d(s[2]), paint)
            }
        }

        if (earned) {
            paint.color = withAlpha(Color.parseColor("#FFF0CF"), .8f)
            paint.strokeWidth = d(5f)
            paint.strokeCap = Paint.Cap.ROUND
            for (i in 0 until 7) {
                val angle = Math.PI + i * Math.PI / 6
                val inner = radius + d(14f)
                val outer = radius + d(28f)
                canvas.drawLine(
                    sunX + cos(angle).toFloat() * inner, sunY + sin(angle).toFloat() * inner,
                    sunX + cos(angle).toFloat() * outer, sunY + sin(angle).toFloat() * outer, paint,
                )
            }
        }
        val sunColors = when {
            earned -> intArrayOf(Color.WHITE, Color.parseColor("#FFF0CF"), Color.parseColor("#FFC27A"))
            dark -> intArrayOf(Color.parseColor("#FFFAF3"), Color.parseColor("#FFD2EA"), Color.parseColor("#EC8FFF"))
            else -> intArrayOf(Color.WHITE, Color.parseColor("#FFE6C6"), Color.parseColor("#FFB37A"))
        }
        paint.shader = RadialGradient(sunX - radius * .15f, sunY - radius * .25f, radius * 1.1f, sunColors, floatArrayOf(0f, .55f, 1f), Shader.TileMode.CLAMP)
        canvas.drawCircle(sunX, sunY, radius, paint)
        paint.shader = null

        fun hill(v: FloatArray, color: Int) {
            val sx = w / 390f
            val path = Path().apply {
                moveTo(0f, h - d(v[0]))
                cubicTo(v[1] * sx, h - d(v[2]), v[3] * sx, h - d(v[4]), v[5] * sx, h - d(v[6]))
                cubicTo(v[7] * sx, h - d(v[8]), v[9] * sx, h - d(v[10]), w, h - d(v[11]))
                lineTo(w, h); lineTo(0f, h); close()
            }
            paint.color = color
            canvas.drawPath(path, paint)
        }
        hill(floatArrayOf(66f, 70f, 94f, 140f, 92f, 205f, 72f, 262f, 55f, 322f, 86f, 96f),
            if (dark) tone(.40f, .5f) else tone(.84f, .55f))
        hill(floatArrayOf(42f, 80f, 66f, 150f, 54f, 232f, 40f, 300f, 28f, 352f, 56f, 60f),
            if (dark) tone(.27f, .55f) else tone(.74f, .5f))
        hill(floatArrayOf(18f, 90f, 34f, 190f, 12f, 270f, 20f, 330f, 26f, 366f, 32f, 30f), background)
    }

    private fun withAlpha(color: Int, alpha: Float) =
        Color.argb((alpha.coerceIn(0f, 1f) * 255).toInt(), Color.red(color), Color.green(color), Color.blue(color))

    /** A colour with the accent's hue at the given HSL lightness and saturation. */
    private fun tone(lightness: Float, saturation: Float, shift: Float = 0f): Int {
        val hsl = rgbToHsl(accent)
        val sat = if (hsl[1] < .08f) 0f else saturation
        return hslToRgb((hsl[0] + shift) % 360f, sat, lightness)
    }

    private fun rgbToHsl(color: Int): FloatArray {
        val r = Color.red(color) / 255f
        val g = Color.green(color) / 255f
        val b = Color.blue(color) / 255f
        val mx = max(r, max(g, b))
        val mn = min(r, min(g, b))
        val l = (mx + mn) / 2f
        if (mx == mn) return floatArrayOf(0f, 0f, l)
        val delta = mx - mn
        val s = if (l > .5f) delta / (2f - mx - mn) else delta / (mx + mn)
        val hue = when (mx) {
            r -> ((g - b) / delta + (if (g < b) 6f else 0f))
            g -> ((b - r) / delta + 2f)
            else -> ((r - g) / delta + 4f)
        } * 60f
        return floatArrayOf(hue, s, l)
    }

    private fun hslToRgb(h: Float, s: Float, l: Float): Int {
        val c = (1f - abs(2f * l - 1f)) * s
        val x = c * (1f - abs((h / 60f) % 2f - 1f))
        val m = l - c / 2f
        val (r, g, b) = when {
            h < 60f -> Triple(c, x, 0f)
            h < 120f -> Triple(x, c, 0f)
            h < 180f -> Triple(0f, c, x)
            h < 240f -> Triple(0f, x, c)
            h < 300f -> Triple(x, 0f, c)
            else -> Triple(c, 0f, x)
        }
        return Color.rgb(((r + m) * 255).toInt(), ((g + m) * 255).toInt(), ((b + m) * 255).toInt())
    }
}
