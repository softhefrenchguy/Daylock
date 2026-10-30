package com.sofien.daylock

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
    private var restrictedPackage: String? = null
    private val observer: () -> Unit = { refresh() }
    private val clockBoundary = Runnable { refresh() }
    private var lastRender: String? = null
    private var actionsExpanded = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DetectionRuntime.attach(this)
        attempt = intent.getLongExtra("attempt", 0)
        restrictedPackage = intent.getStringExtra("restrictedPackage")
        InstagramLockLog.event("activity_created", attempt)
        if (!DetectionRuntime.lockFlow.mayPresent(attempt, restrictedPackage, DetectionRuntime.foregroundRestrictedPackage)) { finish(); return }
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT) { goHome() }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        attempt = intent.getLongExtra("attempt", 0)
        restrictedPackage = intent.getStringExtra("restrictedPackage")
        if (!DetectionRuntime.lockFlow.mayPresent(attempt, restrictedPackage, DetectionRuntime.foregroundRestrictedPackage)) { finish(); return }
        lastRender = null // The new attempt needs its own draw acknowledgement.
        if (resumed) {
            DetectionRuntime.lockResumed(attempt)
            DetectionRuntime.lockFocused(attempt, window.decorView.hasWindowFocus())
        }
        refresh()
    }

    override fun onResume() {
        super.onResume()
        if (!DetectionRuntime.lockFlow.mayPresent(attempt, restrictedPackage, DetectionRuntime.foregroundRestrictedPackage)) { finish(); return }
        resumed = true
        DetectionRuntime.addObserver(observer)
        DetectionRuntime.lockResumed(attempt)
        DetectionRuntime.lockFocused(attempt, window.decorView.hasWindowFocus())
        refresh()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        DetectionRuntime.lockFocused(attempt, hasFocus)
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
            val target = restrictedPackage ?: return@execute
            val appName = DetectionRuntime.catalog.label(target)
            val blocked = DetectionRuntime.canRestrict(target) && InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled,
                DetectionRuntime.isEnabled(), freedom) == InstagramRestriction.BLOCK
            val appearance = DetectionRuntime.store.lockAppearance()
            main.post {
                if (!resumed || isFinishing) return@post
                val signature = "$blocked|${freedom.state}|${freedom.reason}|${freedom.conditions?.toMap()}|$appearance|$appName"
                if (signature != lastRender) { lastRender = signature; render(blocked, freedom, appearance, appName) }
                // Only while this screen is visible. At most one update per minute;
                // broadcasts/save/permission changes notify us immediately.
                main.removeCallbacks(clockBoundary)
                val nextMinute = 60_000 - System.currentTimeMillis() % 60_000 + 25
                main.postDelayed(clockBoundary, minOf(nextMinute, freedom.nextChangeInMs?.plus(25) ?: nextMinute))
            }
        }
    }

    private fun render(blocked: Boolean, freedom: NativeFreedomResult, appearance: JSONObject?, appName: String) {
        val useDark = when (appearance?.optString("mode", "dark")) {
            "light" -> false
            "system" -> resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
            else -> true
        }
        val palette = appearance?.optJSONObject(if (useDark) "dark" else "light")
        fun color(key: String, fallback: String) = palette?.optLong(key)?.takeIf { it != 0L }?.toInt() ?: Color.parseColor(fallback)
        val screenBackground = color("background", if (useDark) "#100D1D" else "#F8F6FC")
        val ink = color("foreground", if (useDark) "#F8F6FC" else "#211A2E")
        val muted = color("muted", if (useDark) "#BEB5CF" else "#62586F")
        val accent = color("accent", if (useDark) "#B988F0" else "#7054A4")
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
        fun tint(base: Int, overlay: Int, amount: Float): Int = Color.rgb(
            (Color.red(base) * (1 - amount) + Color.red(overlay) * amount).toInt(),
            (Color.green(base) * (1 - amount) + Color.green(overlay) * amount).toInt(),
            (Color.blue(base) * (1 - amount) + Color.blue(overlay) * amount).toInt())
        fun text(value: String, size: Float, color: Int = ink, bold: Boolean = false,
                 spacing: Int = 12, parent: LinearLayout = body, centered: Boolean = false) {
            parent.addView(TextView(this).apply {
                this.text = value; textSize = size; setTextColor(color)
                typeface = Typeface.create("sans-serif", if (bold) Typeface.BOLD else Typeface.NORMAL)
                if (centered) gravity = Gravity.CENTER
                setPadding(0, 0, 0, dp(spacing))
            }, LinearLayout.LayoutParams(-1, -2))
        }
        fun surface() = GradientDrawable(GradientDrawable.Orientation.TL_BR,
            intArrayOf(tint(screenBackground, accent, .22f), tint(screenBackground, accent, .05f))).apply {
            cornerRadius = dp(20).toFloat(); setStroke(dp(1), tint(screenBackground, accent, .6f))
        }
        text("DAYLOCK", 13f, accent, true, 8, centered = true)
        body.addView(DaylockLockArtwork(this, accent), LinearLayout.LayoutParams(dp(144), dp(144)).apply { gravity = Gravity.CENTER_HORIZONTAL })
        text(if (blocked) "Not yet." else if (freedom.state == "earned") "Freedom earned." else if (freedom.state == "unknown") "Refresh Freedom status." else "Restriction paused.", 36f, ink, true, 8, centered = true)
        text(when {
            blocked -> "You've made a commitment."
            freedom.state == "earned" -> "Your Freedom conditions are satisfied."
            freedom.state == "disabled" -> "Freedom Control is off."
            freedom.state == "unknown" -> "Open Daylock to reconcile your plans."
            else -> "App restrictions are paused or this app is no longer selected."
        }, 17f, muted, spacing = 12, centered = true)
        text(if (blocked) "$appName is restricted until Freedom is earned."
            else if (freedom.state == "unknown") "$appName is available while recovery is needed."
            else "$appName is available.", 14f, muted, spacing = 24, centered = true)
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; setPadding(dp(16), dp(16), dp(16), dp(8)); background = surface()
        }
        body.addView(card, LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(20) })
        text("FREEDOM", 12f, accent, true, 14, parent = card)
        val conditions = freedom.conditions
        fun condition(value: String, ready: Boolean?) {
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.TOP }
            row.addView(TextView(this).apply {
                this.text = when (ready) { true -> "\u2713"; false -> "\u25cb"; null -> "\u2014" }
                textSize = 20f; setTextColor(if (ready == true) accent else muted)
                contentDescription = when(ready) { true -> "Satisfied"; false -> "Remaining"; null -> "Unknown" }
            }, LinearLayout.LayoutParams(dp(28), -2))
            row.addView(TextView(this).apply { this.text = value; textSize = 15f; setTextColor(ink); setPadding(0, dp(2), 0, dp(14)) }, LinearLayout.LayoutParams(0, -2, 1f))
            card.addView(row)
        }
        val timeLabel = conditions?.let { String.format(java.util.Locale.ROOT, "%02d:%02d", it.hour, it.minute) }
        condition("Freedom Time reached${timeLabel?.let { " \u00b7 $it" } ?: " \u00b7 refresh needed"}", conditions?.timeReached)
        condition(if (conditions == null) "Eligible commitments completed \u00b7 refresh needed"
            else if (conditions.eligibleCount == 0) "No eligible commitments"
            else "Eligible commitments completed \u00b7 ${conditions.completedCount} / ${conditions.eligibleCount}", conditions?.commitmentsCompleted)
        condition("Tomorrow\u2019s plan committed", conditions?.tomorrowCommitted)
        if (conditions?.eligibleCount == 0) text("Empty or all-excused days do not automatically earn Freedom.", 13f, muted, parent = card)
        if (freedom.reason == "rollover_reconciled") text("A new local day has started. Open Daylock to archive history and prepare the following day.", 13f, muted)
        fun button(label: String, primary: Boolean, parent: LinearLayout = body, action: () -> Unit): Button {
            val view = Button(this).apply {
                this.text = label; textSize = 15f; isAllCaps = false
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                setTextColor(if (primary) onAccent else accent)
                minimumHeight = dp(52); setPadding(dp(16), dp(12), dp(16), dp(12))
                background = if (primary) GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,
                    intArrayOf(tint(accent, Color.WHITE, .22f), accent)).apply { cornerRadius = dp(16).toFloat() }
                    else surface()
                gravity = Gravity.CENTER; setOnClickListener { action() }
            }
            parent.addView(view, LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(10) })
            return view
        }
        button("Return to Daylock", true) {
            startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP))
            finish()
        }
        val secondary = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; visibility = if (actionsExpanded) View.VISIBLE else View.GONE }
        lateinit var expand: Button
        expand = button(if (actionsExpanded) "Other actions \u2303" else "Other actions \u2304", false) {
            actionsExpanded = !actionsExpanded
            secondary.visibility = if (actionsExpanded) View.VISIBLE else View.GONE
            expand.text = if (actionsExpanded) "Other actions \u2303" else "Other actions \u2304"
        }
        body.addView(secondary)
        text("Return Home, disable blocking or change Accessibility access.", 13f, muted)
        button("Return to Home", false, secondary) { goHome() }
        if (DetectionRuntime.blockingEnabled) button("Disable app restrictions", false, secondary) {
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
        button("Accessibility Settings", false, secondary) { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)); finish() }
        text("You remain in control. Disable blocking or revoke Accessibility access at any time.", 13f, muted, parent = secondary)
        setContentView(scroll)
        var acknowledged = false
        val drawnAttempt = attempt
        scroll.viewTreeObserver.addOnDrawListener {
            if (!acknowledged) {
                acknowledged = true
                main.post { if (resumed && !isFinishing) DetectionRuntime.lockDrawn(drawnAttempt, freedom.state == "unknown") }
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
