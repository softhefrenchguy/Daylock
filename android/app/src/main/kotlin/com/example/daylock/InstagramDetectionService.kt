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
    private var serviceActive = false
    private var lastEnforcedToken = -1L

    override fun onCreate() {
        super.onCreate()
        if (android.os.Build.VERSION.SDK_INT >= 36 &&
            applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            android.os.StrictMode.setVmPolicy(android.os.StrictMode.VmPolicy.Builder(android.os.StrictMode.getVmPolicy())
                .detectBlockedBackgroundActivityLaunch().penaltyLog().build())
        }
        DetectionRuntime.attach(this)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInfo = serviceInfo.apply { packageNames = null }
        serviceActive = true
        InstagramLockLog.event("service_connected")
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
            InstagramLockLog.event("instagram_foreground", detail = "session=${foreground.token()}")
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
                if (!serviceActive || !foreground.matches(token) || !unlockedAndInteractive() ||
                    !DetectionRuntime.isEnabled() || DetectionRuntime.lockVisible) return@post
                if (stateRevision != DetectionRuntime.stateRevision.get()) {
                    // One bounded retry behind the queued state write, not a polling loop.
                    if (retries == 0) evaluateAndEnforce(token, 1)
                    return@post
                }
                val freedom = DetectionRuntime.store.eligibility()
                InstagramLockLog.event("freedom_evaluated", detail = "state=${freedom.state} reason=${freedom.reason}")
                when (InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled, true, freedom)) {
                    InstagramRestriction.ALLOW -> recoveryGate.reset()
                    InstagramRestriction.RECOVER -> {
                        if (recoveryGate.offer(DetectionRuntime.store.revision(), DetectionRuntime.store.clock().date, freedom.reason)) {
                            leaveInstagram(token, stateRevision)
                            return@post
                        }
                        DetectionRuntime.reportRestriction("state_unknown")
                        val elapsed = SystemClock.elapsedRealtime()
                        if (elapsed - lastRecoveryNoticeMs >= 30_000) {
                            lastRecoveryNoticeMs = elapsed
                            Toast.makeText(this, "Daylock: blocking paused. Open Daylock to refresh Freedom status.", Toast.LENGTH_LONG).show()
                        }
                    }
                    InstagramRestriction.BLOCK -> { recoveryGate.reset(); leaveInstagram(token, stateRevision) }
                }
            }
        }
    }

    private fun leaveInstagram(token: Long, stateRevision: Long) {
        // One navigation attempt per observed Instagram foreground session.
        if (lastEnforcedToken == token) return
        lastEnforcedToken = token
        val attempt = DetectionRuntime.nextLockAttempt()
        if (!DetectionRuntime.lockFlow.begin(attempt, SystemClock.elapsedRealtime())) {
            InstagramLockLog.event("launch_throttled", attempt)
            requestHome(token, stateRevision, attempt)
            DetectionRuntime.lockFallback(null)
            return
        }
        // Do not issue HOME and startActivity back-to-back: HOME is asynchronous
        // and can cover/stop the noHistory activity we have just launched.
        InstagramLockLog.event("lock_launch_attempt", attempt, "sequence=activity_first")
        DetectionRuntime.reportRestriction("lock_launch_requested")
        try {
            startActivity(Intent(this, InstagramLockActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("attempt", attempt)
            })
            InstagramLockLog.event("lock_launch_returned", attempt, "visible=unconfirmed")
        } catch (error: Exception) {
            InstagramLockLog.event("lock_launch_exception", attempt,
                "type=${error.javaClass.simpleName} security_exception=${error is SecurityException}")
            DetectionRuntime.reportRestriction("lock_launch_failed")
            DetectionRuntime.lockFlow.settle(attempt)
            requestHome(token, stateRevision, attempt)
            DetectionRuntime.lockFallback(attempt)
            return
        }
        main.postDelayed({
            if (DetectionRuntime.lockFlow.needsHome(attempt)) requestHome(token, stateRevision, attempt)
        }, InstagramLockFlow.HOME_GRACE_MS)
        // Silent BAL denial has no app callback on Android 15. A timeout is an
        // observation, not proof of a particular Android/OEM denial reason.
        main.postDelayed({
            if (serviceActive && DetectionRuntime.lockFlow.settle(attempt)) {
                InstagramLockLog.event("lock_launch_unconfirmed", attempt, "cause=unknown_bal_or_oem_possible")
                DetectionRuntime.reportRestriction("lock_launch_unconfirmed")
                DetectionRuntime.lockFallback(attempt)
            }
        }, InstagramLockFlow.CONFIRM_MS)
    }

    private fun requestHome(token: Long, revision: Long, attempt: Long) {
        if (!serviceActive || !foreground.matches(token) || !unlockedAndInteractive() ||
            revision != DetectionRuntime.stateRevision.get() || !DetectionRuntime.isEnabled() ||
            InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled, true,
                DetectionRuntime.store.eligibility()) == InstagramRestriction.ALLOW) {
            InstagramLockLog.event("home_skipped", attempt, "reason=foreground_screen_or_state_changed")
            return
        }
        InstagramLockLog.event("home_requested", attempt)
        val accepted = try { performGlobalAction(GLOBAL_ACTION_HOME) } catch (error: Exception) {
            InstagramLockLog.event("home_exception", attempt, "type=${error.javaClass.simpleName}")
            false
        }
        InstagramLockLog.event("home_result", attempt, "accepted=$accepted")
        DetectionRuntime.reportRestriction(if (accepted) "home_only" else "home_failed")
    }

    private fun unlockedAndInteractive(): Boolean = runCatching {
        getSystemService(PowerManager::class.java).isInteractive &&
            !getSystemService(KeyguardManager::class.java).isKeyguardLocked
    }.getOrDefault(false)

    // Android is asking to interrupt feedback, not notifying an unbind. There is
    // no spoken/haptic feedback to stop; connection state changes on unbind/destroy.
    override fun onInterrupt() = Unit
    override fun onUnbind(intent: Intent?): Boolean {
        serviceActive = false
        main.removeCallbacksAndMessages(null)
        InstagramLockLog.event("service_unbound")
        foreground.observe(false)
        DetectionRuntime.setConnected(false)
        return super.onUnbind(intent)
    }
    override fun onDestroy() {
        serviceActive = false
        main.removeCallbacksAndMessages(null)
        InstagramLockLog.event("service_destroyed")
        foreground.observe(false)
        DetectionRuntime.setConnected(false)
        super.onDestroy()
    }
}
