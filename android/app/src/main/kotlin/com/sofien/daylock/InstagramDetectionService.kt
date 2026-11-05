package com.sofien.daylock

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
    private var windowRevision = 0L

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
        val packageName = event.packageName?.toString()
        // Keep the raw platform value for deciding when a *different* Activity
        // has definitely replaced a pending selected app. It is deliberately
        // not required for recognizing the selected app itself; HyperOS can
        // report false for ordinary app Activities.
        val fullScreen = event.isFullScreen
        val revision = ++windowRevision
        if (!DetectionRuntime.restrictionsReady) {
            // Startup is queued behind native selection loading. No app history is retained.
            DetectionRuntime.worker.execute {
                main.post { if (serviceActive && revision == windowRevision) handleWindow(packageName, fullScreen) }
            }
        } else handleWindow(packageName, fullScreen)
    }

    private fun handleWindow(packageName: String?, fullScreen: Boolean) {
        // Xiaomi/HyperOS can report isFullScreen=false for a normal selected-app
        // Activity. Package identity plus a real window-state transition is enough
        // to evaluate the voluntary restriction; no window contents are inspected.
        val target = packageName?.takeIf {
            it != this.packageName && DetectionRuntime.isSelected(it) &&
                InstagramBlockingPolicy.isForegroundWindow(fullScreen, 0)
        }
        // Daylock's own Activity appears while a lock-screen attempt is starting.
        // Preserve its target for that short pending transition, otherwise a fast
        // OEM event can make the lock Activity reject itself before it is drawn.
        if (target == null && packageName == this.packageName) {
            if (!DetectionRuntime.lockFlow.isPresenting(foreground.targetPackage)) {
                foreground.observe(null)
                gate.reset()
            }
            return
        }
        if (target == null) {
            // Non-full-screen system/OEM windows must not cancel a pending selected
            // target. A definite other full-screen Activity still cancels it.
            if (InstagramBlockingPolicy.isDefiniteOtherForegroundWindow(fullScreen, 0)) {
                foreground.observe(null)
                gate.reset()
            }
            return
        }
        if (foreground.targetPackage != target) gate.reset()
        foreground.observe(target)
        DetectionRuntime.foregroundRestrictedPackage = target
        if (target == null || !DetectionRuntime.blockingEnabled || !DetectionRuntime.isEnabled()) return
        // Never access event.text, event.source, rootInActiveWindow or window contents.
        if (gate.accept(target, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, SystemClock.elapsedRealtime(), DetectionRuntime.selection.packages.keys)) {
            InstagramLockLog.event("restricted_app_foreground", detail = "session=${foreground.token()}")
            DetectionRuntime.setConnected(true)
            val token = foreground.token()
            DetectionRuntime.worker.execute {
                if (!foreground.matches(token)) {
                    DetectionRuntime.reportRestrictionOnWorker("skipped_foreground_changed_before_eligibility")
                    DetectionRuntime.emit()
                    return@execute
                }
                if (!DetectionRuntime.isEnabled()) {
                    DetectionRuntime.reportRestrictionOnWorker("skipped_accessibility_disabled")
                    DetectionRuntime.emit()
                    return@execute
                }
                if (!DetectionRuntime.canRestrict(target)) {
                    DetectionRuntime.reportRestrictionOnWorker("skipped_selection_unavailable")
                    DetectionRuntime.emit()
                    return@execute
                }
                DetectionRuntime.recordDetectionOnWorker(target)
                DetectionRuntime.reportRestrictionOnWorker("detected_selected_app")
                DetectionRuntime.emit()
            }
            evaluateAndEnforce(token, target)
        }
    }

    private fun evaluateAndEnforce(token: Long, packageName: String, retries: Int = 0) {
        DetectionRuntime.worker.execute {
            if (!foreground.matches(token)) {
                DetectionRuntime.reportRestrictionOnWorker("skipped_foreground_changed_before_eligibility")
                DetectionRuntime.emit()
                return@execute
            }
            if (!DetectionRuntime.isEnabled()) {
                DetectionRuntime.reportRestrictionOnWorker("skipped_accessibility_disabled")
                DetectionRuntime.emit()
                return@execute
            }
            if (!DetectionRuntime.canRestrict(packageName)) {
                DetectionRuntime.reportRestrictionOnWorker("skipped_selection_unavailable")
                DetectionRuntime.emit()
                return@execute
            }
            val stateRevision = DetectionRuntime.stateRevision.get()
            // Load/validate on the worker. The UI-thread recheck uses the in-memory cache.
            val eligibility = DetectionRuntime.store.eligibility()
            DetectionRuntime.reportRestrictionOnWorker("eligibility_${eligibility.state}")
            DetectionRuntime.emit()
            main.post {
                val skip = when {
                    !serviceActive -> "skipped_service_inactive"
                    !foreground.matches(token) -> "skipped_foreground_changed_before_navigation"
                    !unlockedAndInteractive() -> "skipped_device_not_interactive"
                    !DetectionRuntime.isEnabled() -> "skipped_accessibility_disabled"
                    !DetectionRuntime.isSelected(packageName) -> "skipped_selection_unavailable"
                    DetectionRuntime.lockVisible -> "skipped_lock_already_visible"
                    else -> null
                }
                if (skip != null) {
                    DetectionRuntime.reportRestriction(skip)
                    return@post
                }
                if (stateRevision != DetectionRuntime.stateRevision.get()) {
                    // One bounded retry behind the queued state write, not a polling loop.
                    if (retries == 0) {
                        DetectionRuntime.reportRestriction("retrying_state_changed")
                        evaluateAndEnforce(token, packageName, 1)
                    } else DetectionRuntime.reportRestriction("skipped_state_changed")
                    return@post
                }
                val freedom = DetectionRuntime.store.eligibility()
                InstagramLockLog.event("freedom_evaluated", detail = "state=${freedom.state} reason=${freedom.reason}")
                when (InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled, true, freedom)) {
                    InstagramRestriction.ALLOW -> {
                        recoveryGate.reset()
                        DetectionRuntime.reportRestriction("skipped_freedom_${freedom.state}")
                    }
                    InstagramRestriction.RECOVER -> {
                        DetectionRuntime.reportRestriction("restriction_recovery")
                        if (recoveryGate.offer(DetectionRuntime.store.revision(), DetectionRuntime.store.clock().date, freedom.reason)) {
                            leaveSelectedApp(token, stateRevision, packageName)
                            return@post
                        }
                        DetectionRuntime.reportRestriction("state_unknown")
                        val elapsed = SystemClock.elapsedRealtime()
                        if (elapsed - lastRecoveryNoticeMs >= 30_000) {
                            lastRecoveryNoticeMs = elapsed
                            Toast.makeText(this, "Daylock: blocking paused. Open Daylock to refresh Freedom status.", Toast.LENGTH_LONG).show()
                        }
                    }
                    InstagramRestriction.BLOCK -> {
                        recoveryGate.reset()
                        DetectionRuntime.reportRestriction("restriction_triggered")
                        leaveSelectedApp(token, stateRevision, packageName)
                    }
                }
            }
        }
    }

    private fun leaveSelectedApp(token: Long, stateRevision: Long, packageName: String) {
        // One navigation attempt per observed selected-app foreground session.
        if (lastEnforcedToken == token) return
        lastEnforcedToken = token
        val attempt = DetectionRuntime.nextLockAttempt()
        if (!DetectionRuntime.lockFlow.begin(attempt, SystemClock.elapsedRealtime(), packageName)) {
            InstagramLockLog.event("launch_throttled", attempt)
            DetectionRuntime.reportRestriction("skipped_launch_throttled")
            requestHome(token, stateRevision, attempt, packageName)
            DetectionRuntime.lockFallback(null, packageName)
            return
        }
        // Do not issue HOME and startActivity back-to-back: HOME is asynchronous
        // and can cover/stop the noHistory activity we have just launched.
        InstagramLockLog.event("lock_launch_attempt", attempt, "sequence=activity_first")
        DetectionRuntime.reportRestriction("lock_launch_requested")
        DetectionRuntime.reportLockLaunch("attempted")
        try {
            startActivity(Intent(this, InstagramLockActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("attempt", attempt)
                putExtra("restrictedPackage", packageName)
            })
            InstagramLockLog.event("lock_launch_returned", attempt, "visible=unconfirmed")
            DetectionRuntime.reportLockLaunch("requested_unconfirmed")
        } catch (error: Exception) {
            InstagramLockLog.event("lock_launch_exception", attempt,
                "type=${error.javaClass.simpleName} security_exception=${error is SecurityException}")
            DetectionRuntime.reportRestriction("lock_launch_failed")
            DetectionRuntime.reportLockLaunch("failed_exception")
            DetectionRuntime.lockFlow.settle(attempt)
            requestHome(token, stateRevision, attempt, packageName)
            DetectionRuntime.lockFallback(attempt, packageName)
            return
        }
        main.postDelayed({
            if (DetectionRuntime.lockFlow.needsHome(attempt)) requestHome(token, stateRevision, attempt, packageName)
        }, InstagramLockFlow.HOME_GRACE_MS)
        // Silent BAL denial has no app callback on Android 15. A timeout is an
        // observation, not proof of a particular Android/OEM denial reason.
        main.postDelayed({
            if (serviceActive && DetectionRuntime.lockFlow.settle(attempt)) {
                InstagramLockLog.event("lock_launch_unconfirmed", attempt, "cause=unknown_bal_or_oem_possible")
                DetectionRuntime.reportRestriction("lock_launch_unconfirmed")
                DetectionRuntime.reportLockLaunch("unconfirmed")
                DetectionRuntime.lockFallback(attempt, packageName)
            }
        }, InstagramLockFlow.CONFIRM_MS)
    }

    private fun requestHome(token: Long, revision: Long, attempt: Long, packageName: String) {
        if (!serviceActive || !foreground.matches(token) || !unlockedAndInteractive() ||
            revision != DetectionRuntime.stateRevision.get() || !DetectionRuntime.isEnabled() || !DetectionRuntime.isSelected(packageName) ||
            InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled, true,
                DetectionRuntime.store.eligibility()) == InstagramRestriction.ALLOW) {
            InstagramLockLog.event("home_skipped", attempt, "reason=foreground_screen_or_state_changed")
            return
        }
        InstagramLockLog.event("home_requested", attempt)
        DetectionRuntime.reportHomeAction("attempted")
        val accepted = try { performGlobalAction(GLOBAL_ACTION_HOME) } catch (error: Exception) {
            InstagramLockLog.event("home_exception", attempt, "type=${error.javaClass.simpleName}")
            false
        }
        InstagramLockLog.event("home_result", attempt, "accepted=$accepted")
        DetectionRuntime.reportHomeAction(if (accepted) "accepted" else "rejected")
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
        foreground.observe(null)
        DetectionRuntime.foregroundRestrictedPackage = null
        DetectionRuntime.setConnected(false)
        return super.onUnbind(intent)
    }
    override fun onDestroy() {
        serviceActive = false
        main.removeCallbacksAndMessages(null)
        InstagramLockLog.event("service_destroyed")
        foreground.observe(null)
        DetectionRuntime.foregroundRestrictedPackage = null
        DetectionRuntime.setConnected(false)
        super.onDestroy()
    }
}
