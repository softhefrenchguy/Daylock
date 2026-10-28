package com.example.daylock

import android.content.Context
import android.graphics.*
import android.view.View

/** Decorative counterpart of Flutter's DaylockIllustration, without starting an engine. */
class DaylockLockArtwork(context: Context, private val accent: Int) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    init { importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO }
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.save()
        canvas.scale(width / 160f, height / 160f)
        paint.shader = RadialGradient(80f, 80f, 76f, intArrayOf((accent and 0xffffff) or 0x55000000, accent and 0xffffff), null, Shader.TileMode.CLAMP)
        canvas.drawCircle(80f, 80f, 76f, paint)
        paint.shader = null
        canvas.save(); canvas.rotate(-25f, 80f, 80f)
        paint.color = (accent and 0xffffff) or 0x55000000; paint.style = Paint.Style.STROKE; paint.strokeWidth = 1f
        canvas.drawRoundRect(18f, 33f, 142f, 127f, 40f, 40f, paint)
        canvas.restore()
        canvas.save(); canvas.rotate(10f, 80f, 80f)
        paint.style = Paint.Style.FILL; paint.color = Color.WHITE
        paint.shader = LinearGradient(40f, 40f, 120f, 120f, intArrayOf(blend(accent, Color.WHITE, .25f), accent, blend(accent, Color.rgb(56, 19, 99), .55f)), null, Shader.TileMode.CLAMP)
        canvas.drawRoundRect(41f, 40f, 119f, 120f, 20f, 20f, paint)
        paint.shader = null; paint.color = (accent and 0xffffff) or 0xcc000000.toInt()
        paint.style = Paint.Style.STROKE; paint.strokeWidth = 2f
        canvas.drawRoundRect(41f, 40f, 119f, 120f, 20f, 20f, paint)
        paint.color = Color.WHITE; paint.strokeWidth = 3.5f
        canvas.drawRoundRect(65f, 76f, 95f, 101f, 3f, 3f, paint)
        canvas.drawArc(RectF(70f, 61f, 90f, 86f), 180f, 180f, false, paint)
        paint.style = Paint.Style.FILL; canvas.drawCircle(80f, 86f, 2.8f, paint)
        canvas.drawRoundRect(78.7f, 86f, 81.3f, 94f, 1f, 1f, paint)
        canvas.restore()
        paint.color = accent
        for ((x, y, radius) in listOf(Triple(19f, 65f, 7f), Triple(127f, 32f, 5f), Triple(142f, 119f, 4f), Triple(35f, 140f, 3f))) {
            val star = Path().apply { moveTo(x, y-radius); lineTo(x+radius*.3f, y-radius*.3f); lineTo(x+radius, y); lineTo(x+radius*.3f, y+radius*.3f); lineTo(x, y+radius); lineTo(x-radius*.3f, y+radius*.3f); lineTo(x-radius, y); lineTo(x-radius*.3f, y-radius*.3f); close() }
            canvas.drawPath(star, paint)
        }
        canvas.restore()
    }
    private fun blend(base: Int, overlay: Int, amount: Float) = Color.rgb(
        (Color.red(base) * (1 - amount) + Color.red(overlay) * amount).toInt(),
        (Color.green(base) * (1 - amount) + Color.green(overlay) * amount).toInt(),
        (Color.blue(base) * (1 - amount) + Color.blue(overlay) * amount).toInt())
}
