package com.sofien.daylock

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.time.LocalDate

/**
 * Debug builds only: renders the home screen widget for sample plans in
 * every size, colour theme and light/dark mode, for visual review.
 *   adb shell am start -n com.sofien.daylock.debug/com.sofien.daylock.WidgetPreviewActivity --es theme ocean
 */
class WidgetPreviewActivity : Activity() {
    private val palettes = mapOf(
        "violet" to listOf(WidgetPalette(true, 0xFF120E26.toInt(), 0xFFF5F1FF.toInt(), 0xFFC4BBE0.toInt(), 0xFFC08BFF.toInt(), 0xFF1D1036.toInt()), WidgetPalette(false, 0xFFF8F4FD.toInt(), 0xFF1B1330.toInt(), 0xFF5E5478.toInt(), 0xFF6A3FC0.toInt(), 0xFFFFFFFF.toInt())),
        "ocean" to listOf(WidgetPalette(true, 0xFF111923.toInt(), 0xFFF3F8FE.toInt(), 0xFFAFBED0.toInt(), 0xFF82B6EC.toInt(), 0xFF111923.toInt()), WidgetPalette(false, 0xFFF4F8FD.toInt(), 0xFF152336.toInt(), 0xFF52657C.toInt(), 0xFF27649C.toInt(), 0xFFFFFFFF.toInt())),
        "forest" to listOf(WidgetPalette(true, 0xFF121C17.toInt(), 0xFFF3FAF5.toInt(), 0xFFB0C4B7.toInt(), 0xFF8CCBA6.toInt(), 0xFF121C17.toInt()), WidgetPalette(false, 0xFFF5F9F5.toInt(), 0xFF182A1F.toInt(), 0xFF53685B.toInt(), 0xFF2E704A.toInt(), 0xFFFFFFFF.toInt())),
        "ember" to listOf(WidgetPalette(true, 0xFF211712.toInt(), 0xFFFFF7F0.toInt(), 0xFFD0B7A6.toInt(), 0xFFEBA776.toInt(), 0xFF211712.toInt()), WidgetPalette(false, 0xFFFCF7F2.toInt(), 0xFF302118.toInt(), 0xFF755C49.toInt(), 0xFF985025.toInt(), 0xFFFFFFFF.toInt())),
        "rose" to listOf(WidgetPalette(true, 0xFF21151D.toInt(), 0xFFFFF4FA.toInt(), 0xFFCEB2C4.toInt(), 0xFFE7A0C2.toInt(), 0xFF21151D.toInt()), WidgetPalette(false, 0xFFFCF5F9.toInt(), 0xFF321E2A.toInt(), 0xFF76576B.toInt(), 0xFFA13C70.toInt(), 0xFFFFFFFF.toInt())),
        "mono" to listOf(WidgetPalette(true, 0xFF171717.toInt(), 0xFFF5F5F5.toInt(), 0xFFBBBBBB.toInt(), 0xFFCCCCCC.toInt(), 0xFF171717.toInt()), WidgetPalette(false, 0xFFF8F8F8.toInt(), 0xFF202020.toInt(), 0xFF626262.toInt(), 0xFF505050.toInt(), 0xFFFFFFFF.toInt())),
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val theme = intent.getStringExtra("theme") ?: "violet"
        val dark = intent.getBooleanExtra("dark", true)
        val state = intent.getStringExtra("state") ?: "progress"
        val palette = palettes.getValue(theme)[if (dark) 0 else 1]
        val today = LocalDate.of(2026, 11, 16)
        fun row(i: Int, name: String, kept: Boolean, area: String, colour: Int) =
            WidgetRow(i, name, kept, false, area, colour)
        val rows = listOf(
            row(0, "Read 20 pages of Kahneman", true, "Mind", 0xFF9473C6.toInt()),
            row(1, "Gym, upper body", false, "Body", 0xFF348E88.toInt()),
            row(2, "Send the internship application", false, "Career", 0xFFAD802B.toInt()),
            row(3, "Call Grandma", true, "Life", 0xFFC16E8B.toInt()),
        )
        val model = when (state) {
            "empty" -> null
            "earned" -> WidgetModel(today.toString(), rows.map { it.copy(kept = true) }, 4, 4, "18:00", earned = true)
            else -> WidgetModel(today.toString(), rows, 2, 4, "18:00")
        }
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 320, 32, 48)
            setBackgroundColor(if (dark) Color.parseColor("#2B2B33") else Color.parseColor("#D9D9E0"))
        }
        val d = resources.displayMetrics.density
        for ((w, h) in listOf(330 to 290, 330 to 160, 150 to 150)) {
            column.addView(TextView(this).apply { text = "$theme · ${if (dark) "dark" else "light"} · ${w}×$h dp"; setTextColor(Color.GRAY) })
            val host = FrameLayout(this)
            host.addView(DaylockWidget.build(this, w, h, model, palette, today).apply(this, host),
                FrameLayout.LayoutParams((w * d).toInt(), (h * d).toInt()))
            column.addView(host, LinearLayout.LayoutParams(-2, -2).apply { bottomMargin = 40 })
        }
        setContentView(ScrollView(this).apply { addView(column) })
    }
}
