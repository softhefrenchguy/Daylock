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
        val useDark = when (appearance?.optString("mode", "system")) {
            "light" -> false
            "dark" -> true
            else -> resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        }
        val palette = appearance?.optJSONObject(if (useDark) "dark" else "light")
        fun color(key: String, fallback: String) = palette?.optLong(key)?.takeIf { it != 0L }?.toInt() ?: Color.parseColor(fallback)
        val screenBackground = color("background", if (useDark) "#120E26" else "#F8F4FD")
        val ink = color("foreground", if (useDark) "#F5F1FF" else "#1B1330")
        val muted = color("muted", if (useDark) "#C4BBE0" else "#5E5478")
        val accent = color("accent", if (useDark) "#C08BFF" else "#6A3FC0")
        val onAccent = color("onAccent", if (useDark) "#1D1036" else "#FFFFFF")
        val gold = Color.parseColor(if (useDark) "#FFC27A" else "#E38A2B")
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
        fun tint(base: Int, overlay: Int, amount: Float): Int = Color.rgb(
            (Color.red(base) * (1 - amount) + Color.red(overlay) * amount).toInt(),
            (Color.green(base) * (1 - amount) + Color.green(overlay) * amount).toInt(),
            (Color.blue(base) * (1 - amount) + Color.blue(overlay) * amount).toInt())
        val cardColor = if (useDark) tint(screenBackground, accent, .12f) else Color.WHITE
        // The rounded display face bundled for Flutter, reused here without an engine.
        val display = runCatching { Typeface.createFromAsset(assets, "flutter_assets/assets/fonts/Nunito-900.ttf") }
            .getOrElse { Typeface.create("sans-serif-black", Typeface.NORMAL) }
        val displayBold = runCatching { Typeface.createFromAsset(assets, "flutter_assets/assets/fonts/Nunito-800.ttf") }
            .getOrElse { Typeface.create("sans-serif", Typeface.BOLD) }

        val scroll = ScrollView(this).apply { setBackgroundColor(screenBackground); isFillViewport = true }
        val page = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        scroll.addView(page)

        val conditions = freedom.conditions
        val progress = when {
            conditions == null || conditions.eligibleCount == 0 -> 0f
            else -> conditions.completedCount.toFloat() / conditions.eligibleCount
        }
        val earned = freedom.state == "earned"
        val header = android.widget.FrameLayout(this)
        header.addView(DaylockSkyView(this, accent, screenBackground, useDark, progress, earned),
            android.widget.FrameLayout.LayoutParams(-1, -1))
        val headerText = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(20), dp(24), 0)
        }
        header.addView(headerText, android.widget.FrameLayout.LayoutParams(-1, -2))
        page.addView(header, LinearLayout.LayoutParams(-1, dp(if (earned) 300 else 250)))

        val body = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(4), dp(24), dp(24))
        }
        page.addView(body, LinearLayout.LayoutParams(-1, -2))

        scroll.setOnApplyWindowInsetsListener { _, insets ->
            val top: Int; val left: Int; val right: Int; val bottom: Int
            if (Build.VERSION.SDK_INT >= 30) {
                val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
                top = bars.top; left = bars.left; right = bars.right; bottom = bars.bottom
            } else {
                @Suppress("DEPRECATION")
                run { top = insets.systemWindowInsetTop; left = insets.systemWindowInsetLeft; right = insets.systemWindowInsetRight; bottom = insets.systemWindowInsetBottom }
            }
            // The sky runs under the status bar; text and buttons stay clear of it.
            headerText.setPadding(dp(24) + left, dp(20) + top, dp(24) + right, 0)
            header.layoutParams = header.layoutParams.apply { height = dp(if (earned) 300 else 250) + top }
            body.setPadding(dp(24) + left, dp(4), dp(24) + right, dp(24) + bottom)
            insets
        }

        fun text(value: String, size: Float, color: Int = ink, face: Typeface? = null,
                 spacing: Int = 12, parent: LinearLayout = body) {
            parent.addView(TextView(this).apply {
                this.text = value; textSize = size; setTextColor(color)
                typeface = face ?: Typeface.create("sans-serif", Typeface.NORMAL)
                setLineSpacing(0f, 1.15f)
                setPadding(0, 0, 0, dp(spacing))
            }, LinearLayout.LayoutParams(-1, -2))
        }
        val skyInk = if (useDark) Color.parseColor("#F7F3FF") else ink
        val skyMuted = if (useDark) Color.parseColor("#DCD3F2") else muted
        text("DAYLOCK", 13f, skyMuted, displayBold, 2, headerText)
        text("$appName is locked", 15f, skyInk, null, 0, headerText)

        text(if (blocked) "Not yet." else if (earned) "Freedom earned." else if (freedom.state == "unknown") "Refresh Freedom status." else "Restriction paused.",
            44f, ink, display, 4)
        text(when {
            blocked -> "Keep your word first."
            earned -> "Your Freedom conditions are satisfied."
            freedom.state == "disabled" -> "Freedom Control is off."
            freedom.state == "unknown" -> "Open Daylock to reconcile your plans."
            else -> "App restrictions are paused or this app is no longer selected."
        }, 18f, muted, spacing = 6)
        text(if (blocked) "$appName opens again once Freedom is earned."
            else if (freedom.state == "unknown") "$appName is available while recovery is needed."
            else "$appName is available.", 15f, muted, spacing = 22)

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; setPadding(dp(18), dp(18), dp(18), dp(8))
            background = GradientDrawable().apply { cornerRadius = dp(22).toFloat(); setColor(cardColor) }
            if (!useDark) elevation = dp(2).toFloat()
        }
        body.addView(card, LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(20) })
        text("Freedom", 20f, ink, displayBold, 12, card)
        fun condition(value: String, ready: Boolean?) {
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
            row.addView(TextView(this).apply {
                this.text = when (ready) { true -> "✓"; false -> ""; null -> "—" }
                textSize = 13f; gravity = Gravity.CENTER
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                setTextColor(if (ready == true) Color.parseColor("#3A1D05") else muted)
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    if (ready == true) setColor(gold) else { setColor(Color.TRANSPARENT); setStroke(dp(2), tint(muted, cardColor, .3f)) }
                }
                contentDescription = when (ready) { true -> "Satisfied"; false -> "Remaining"; null -> "Unknown" }
            }, LinearLayout.LayoutParams(dp(22), dp(22)).apply { rightMargin = dp(12) })
            row.addView(TextView(this).apply { this.text = value; textSize = 15f; setTextColor(ink) }, LinearLayout.LayoutParams(0, -2, 1f))
            card.addView(row, LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(12) })
        }
        val timeLabel = conditions?.let { String.format(java.util.Locale.ROOT, "%02d:%02d", it.hour, it.minute) }
        condition("Freedom Time reached${timeLabel?.let { " · $it" } ?: " · refresh needed"}", conditions?.timeReached)
        condition(if (conditions == null) "Eligible commitments completed · refresh needed"
            else if (conditions.eligibleCount == 0) "No eligible commitments"
            else "Eligible commitments completed · ${conditions.completedCount} / ${conditions.eligibleCount}", conditions?.commitmentsCompleted)
        condition("Tomorrow’s plan committed", conditions?.tomorrowCommitted)
        if (conditions?.eligibleCount == 0) text("Empty or all-excused days do not automatically earn Freedom.", 13f, muted, parent = card)
        if (freedom.reason == "rollover_reconciled") text("A new local day has started. Open Daylock to archive history and prepare the following day.", 13f, muted)
        fun button(label: String, primary: Boolean, parent: LinearLayout = body, action: () -> Unit): Button {
            val view = Button(this).apply {
                this.text = label; textSize = 16f; isAllCaps = false
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                setTextColor(if (primary) onAccent else ink)
                minimumHeight = dp(54); stateListAnimator = null
                setPadding(dp(16), dp(12), dp(16), dp(12))
                background = GradientDrawable().apply {
                    cornerRadius = dp(28).toFloat()
                    setColor(if (primary) accent else cardColor)
                }
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
        text("Return Home, disable blocking or change Accessibility access.", 13f, muted, spacing = 10)
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
