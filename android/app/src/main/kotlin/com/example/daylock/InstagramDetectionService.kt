package com.example.daylock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import android.app.KeyguardManager
import android.os.PowerManager

class InstagramDetectionService : AccessibilityService() {
    private val gate = InstagramEventGate()
    private val foreground = InstagramForegroundGuard()
    private val main = Handler(Looper.getMainLooper())
    private var lastRecoveryNoticeMs = -30_000L
    private val recoveryGate = InstagramRecoveryGate()

    override fun onCreate() {
        super.onCreate()
        DetectionRuntime.attach(this)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInfo = serviceInfo.apply { packageNames = null }
        DetectionRuntime.setConnected(true)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        // Pane appearance/disappearance/title changes are not app foreground changes.
        if (event.contentChangeTypes != 0) return
        val target = event.packageName?.toString() == InstagramEventGate.PACKAGE_NAME &&
            InstagramBlockingPolicy.isForegroundWindow(event.isFullScreen, event.contentChangeTypes)
        // Only a boolean survives this comparison. Non-Instagram names are not retained.
        if (!target) {
            foreground.observe(false)
            gate.reset()
            return
        }
        foreground.observe(true)
        if (!DetectionRuntime.isEnabled()) return
        // Never access event.text, event.source, rootInActiveWindow or window contents.
        if (gate.accept(event.packageName?.toString(), event.eventType, SystemClock.elapsedRealtime())) {
            DetectionRuntime.setConnected(true)
            val token = foreground.token()
            DetectionRuntime.worker.execute {
                if (!foreground.matches(token) || !DetectionRuntime.isEnabled()) return@execute
                DetectionRuntime.recordDetectionOnWorker()
                DetectionRuntime.emit()
            }
            evaluateAndEnforce(token)
        }
    }

    private fun evaluateAndEnforce(token: Long, retries: Int = 0) {
        DetectionRuntime.worker.execute {
            if (!foreground.matches(token) || !DetectionRuntime.isEnabled()) return@execute
            val stateRevision = DetectionRuntime.stateRevision.get()
            // Load/validate on the worker. The UI-thread recheck uses the in-memory cache.
            DetectionRuntime.store.eligibility()
            main.post {
                if (!foreground.matches(token) || !unlockedAndInteractive() ||
                    !DetectionRuntime.isEnabled() || DetectionRuntime.lockVisible) return@post
                if (stateRevision != DetectionRuntime.stateRevision.get()) {
                    // One bounded retry behind the queued state write, not a polling loop.
                    if (retries == 0) evaluateAndEnforce(token, 1)
                    return@post
                }
                val freedom = DetectionRuntime.store.eligibility()
                when (InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled, true, freedom)) {
                    InstagramRestriction.ALLOW -> recoveryGate.reset()
                    InstagramRestriction.RECOVER -> {
                        if (recoveryGate.offer(DetectionRuntime.store.revision(), DetectionRuntime.store.clock().date, freedom.reason)) {
                            leaveInstagram()
                            return@post
                        }
                        DetectionRuntime.reportRestriction("state_unknown")
                        val elapsed = SystemClock.elapsedRealtime()
                        if (elapsed - lastRecoveryNoticeMs >= 30_000) {
                            lastRecoveryNoticeMs = elapsed
                            Toast.makeText(this, "Daylock: blocking paused. Open Daylock to refresh Freedom status.", Toast.LENGTH_LONG).show()
                        }
                    }
                    InstagramRestriction.BLOCK -> { recoveryGate.reset(); leaveInstagram() }
                }
            }
        }
    }

    private fun leaveInstagram() {
        val attempt = DetectionRuntime.nextLockAttempt()
        // HOME is a system navigation action, not a gesture/overlay on Instagram.
        if (!runCatching { performGlobalAction(GLOBAL_ACTION_HOME) }.getOrDefault(false)) {
            DetectionRuntime.reportRestriction("home_failed")
            return
        }
        DetectionRuntime.reportRestriction("home_only")
        try {
            startActivity(Intent(this, InstagramLockActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("attempt", attempt)
            })
        } catch (_: Exception) {
            DetectionRuntime.reportRestriction("lock_launch_failed")
            return
        }
        // Android 15/OEMs can deny BAL without throwing. One acknowledgement check,
        // never a retry loop, and never another HOME action against a different app.
        main.postDelayed({
            if (DetectionRuntime.acknowledgedLockAttempt != attempt) {
                DetectionRuntime.reportRestriction("lock_launch_unconfirmed")
            }
        }, 1500)
    }

    private fun unlockedAndInteractive(): Boolean = runCatching {
        getSystemService(PowerManager::class.java).isInteractive &&
            !getSystemService(KeyguardManager::class.java).isKeyguardLocked
    }.getOrDefault(false)

    // Android is asking to interrupt feedback, not notifying an unbind. There is
    // no spoken/haptic feedback to stop; connection state changes on unbind/destroy.
    override fun onInterrupt() = Unit
    override fun onUnbind(intent: Intent?): Boolean {
        foreground.observe(false)
        DetectionRuntime.setConnected(false)
        return super.onUnbind(intent)
    }
    override fun onDestroy() {
        foreground.observe(false)
        DetectionRuntime.setConnected(false)
        super.onDestroy()
    }
}
