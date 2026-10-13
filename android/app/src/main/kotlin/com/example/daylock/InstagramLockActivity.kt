package com.example.daylock

import android.app.Activity
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.window.OnBackInvokedDispatcher
import org.json.JSONObject

// A clearly branded, ordinary Activity in Daylock's own task. No overlays, traps,
// fake system/Instagram UI, content inspection, or Flutter engine required.
class InstagramLockActivity : Activity() {
    private val main = Handler(Looper.getMainLooper())
    private var resumed = false
    private var attempt = 0L
    private val observer: () -> Unit = { refresh() }
    private val clockBoundary = Runnable { refresh() }
    private var lastRender: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DetectionRuntime.attach(this)
        attempt = intent.getLongExtra("attempt", 0)
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT) { goHome() }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        attempt = intent.getLongExtra("attempt", 0)
        if (resumed) DetectionRuntime.lockResumed(attempt)
        refresh()
    }

    override fun onResume() {
        super.onResume()
        resumed = true
        DetectionRuntime.addObserver(observer)
        DetectionRuntime.lockResumed(attempt)
        refresh()
    }

    override fun onPause() {
        resumed = false
        main.removeCallbacks(clockBoundary)
        DetectionRuntime.removeObserver(observer)
        DetectionRuntime.lockPaused(attempt)
        super.onPause()
    }

    @Deprecated("Handled by predictive back on Android 13+")
    override fun onBackPressed() { goHome() }

    private fun refresh() {
        if (!resumed) return
        main.removeCallbacks(clockBoundary)
        DetectionRuntime.worker.execute {
            val freedom = DetectionRuntime.store.eligibility()
            val blocked = InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled,
                DetectionRuntime.isEnabled(), freedom) == InstagramRestriction.BLOCK
            val appearance = DetectionRuntime.store.lockAppearance()
            main.post {
                if (!resumed || isFinishing) return@post
                val signature = "$blocked|${freedom.state}|${freedom.reason}|${freedom.conditions?.toMap()}|$appearance"
                if (signature != lastRender) { lastRender = signature; render(blocked, freedom, appearance) }
                // Only while this screen is visible. At most one update per minute;
                // broadcasts/save/permission changes notify us immediately.
                main.removeCallbacks(clockBoundary)
                val nextMinute = 60_000 - System.currentTimeMillis() % 60_000 + 25
                main.postDelayed(clockBoundary, minOf(nextMinute, freedom.nextChangeInMs?.plus(25) ?: nextMinute))
            }
        }
    }

    private fun render(blocked: Boolean, freedom: NativeFreedomResult, appearance: JSONObject?) {
        val useDark = when (appearance?.optString("mode", "dark")) {
            "light" -> false
            "system" -> resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
            else -> true
        }
        val palette = appearance?.optJSONObject(if (useDark) "dark" else "light")
        fun color(key: String, fallback: String) = palette?.optLong(key)?.takeIf { it != 0L }?.toInt() ?: Color.parseColor(fallback)
        val screenBackground = color("background", if (useDark) "#171321" else "#F8F6FC")
        val ink = color("foreground", if (useDark) "#F8F6FC" else "#211A2E")
        val muted = color("muted", if (useDark) "#BEB5CF" else "#62586F")
        val accent = color("accent", if (useDark) "#A78BDB" else "#7054A4")
        val onAccent = color("onAccent", if (useDark) "#171321" else "#FFFFFF")
        window.decorView.setBackgroundColor(screenBackground)
        @Suppress("DEPRECATION")
        if (Build.VERSION.SDK_INT >= 30) {
            window.insetsController?.setSystemBarsAppearance(
                if (useDark) 0 else android.view.WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or android.view.WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS,
                android.view.WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or android.view.WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS)
        } else {
            window.statusBarColor = screenBackground
            window.navigationBarColor = screenBackground
            window.decorView.systemUiVisibility = if (useDark) 0 else View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        }
        val scroll = ScrollView(this).apply { setBackgroundColor(screenBackground); isFillViewport = true }
        val body = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }
        scroll.addView(body)
        scroll.setOnApplyWindowInsetsListener { view, insets ->
            if (Build.VERSION.SDK_INT >= 30) {
                val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
                view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            } else {
                @Suppress("DEPRECATION")
                view.setPadding(insets.systemWindowInsetLeft, insets.systemWindowInsetTop, insets.systemWindowInsetRight, insets.systemWindowInsetBottom)
            }
            insets
        }
        fun text(value: String, size: Float, color: Int = ink, bold: Boolean = false, spacing: Int = 12) {
            body.addView(TextView(this).apply {
                this.text = value; textSize = size; setTextColor(color)
                typeface = Typeface.create("sans-serif", if (bold) Typeface.BOLD else Typeface.NORMAL)
                setPadding(0, 0, 0, dp(spacing))
            }, LinearLayout.LayoutParams(-1, -2))
        }
        text("DAYLOCK", 15f, accent, true, 24)
        text(if (blocked) "Instagram is locked." else if (freedom.state == "earned") "Freedom earned." else if (freedom.state == "unknown") "Refresh Freedom status." else "Restriction paused.", 36f, ink, true, 16)
        text(when {
            blocked -> "Freedom is not earned yet. Keep your commitments, then come back."
            freedom.state == "earned" -> "Your Freedom conditions are satisfied. Instagram is available."
            freedom.state == "disabled" -> "Freedom Control is off. Instagram is available."
            freedom.state == "unknown" -> "Daylock cannot establish current Freedom status. Open Daylock to reconcile your plans, or disable Instagram blocking below. This recovery prompt is shown once for this unresolved state; reopening Instagram is allowed while recovery is needed."
            else -> "Instagram blocking or Accessibility access is off. Instagram is available."
        }, 17f, muted, spacing = 28)
        if (freedom.reason == "rollover_reconciled") text("A new local day has started. Using your saved plan for this date; open Daylock to archive history and prepare the following day.", 15f, muted)
        text("FREEDOM CONDITIONS", 13f, accent, true, 16)
        val conditions = freedom.conditions
        fun condition(value: String, ready: Boolean?) = text("${when (ready) { true -> "✓"; false -> "○"; null -> "—" }}  $value", 17f, if (ready == true) accent else ink, spacing = 16)
        val timeLabel = conditions?.let { String.format(java.util.Locale.ROOT, "%02d:%02d", it.hour, it.minute) }
        condition("Freedom Time reached${timeLabel?.let { " · $it" } ?: " · refresh needed"}", conditions?.timeReached)
        condition(if (conditions == null) "Eligible commitments completed · refresh needed"
            else if (conditions.eligibleCount == 0) "No eligible commitments"
            else "Eligible commitments completed · ${conditions.completedCount} / ${conditions.eligibleCount}", conditions?.commitmentsCompleted)
        condition("Tomorrow’s plan committed", conditions?.tomorrowCommitted)
        if (conditions?.eligibleCount == 0) text("Empty or all-excused days do not automatically earn Freedom.", 15f, muted)
        text("", 8f, spacing = 8)
        fun button(label: String, primary: Boolean, action: () -> Unit) {
            body.addView(Button(this).apply {
                this.text = label; textSize = 16f; isAllCaps = false
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                setTextColor(if (primary) onAccent else accent)
                minimumHeight = dp(52)
                setPadding(dp(16), dp(14), dp(16), dp(14))
                background = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE; cornerRadius = dp(14).toFloat()
                    setColor(if (primary) accent else screenBackground)
                    if (!primary) setStroke(dp(1), accent)
                }
                gravity = Gravity.CENTER
                setOnClickListener { action() }
            }, LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(12) })
        }
        button("Open Daylock", true) {
            startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP))
            finish()
        }
        button("Return to Home", false) { goHome() }
        if (DetectionRuntime.blockingEnabled) button("Disable Instagram blocking", false) {
            DetectionRuntime.stateRevision.incrementAndGet()
            DetectionRuntime.worker.execute {
                val saved = DetectionRuntime.changeBlocking(false)
                DetectionRuntime.emit()
                main.post {
                    if (!saved) android.widget.Toast.makeText(this, "Blocking disabled for this session. Revoke Accessibility if saving keeps failing.", android.widget.Toast.LENGTH_LONG).show()
                    goHome()
                }
            }
        }
        text("You remain in control. Disable Instagram blocking in Daylock Settings or revoke Accessibility access at any time.", 14f, muted)
        button("Accessibility Settings", false) { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)); finish() }
        setContentView(scroll)
        var acknowledged = false
        scroll.viewTreeObserver.addOnDrawListener {
            if (!acknowledged) {
                acknowledged = true
                main.post { if (resumed && !isFinishing) DetectionRuntime.lockDrawn(attempt, freedom.state == "unknown") }
            }
        }
        scroll.requestApplyInsets()
    }

    private fun goHome() {
        runCatching { startActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
        finish()
    }
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
