package com.sofien.daylock

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityManager
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.Executors
import java.util.TimeZone
import java.util.concurrent.atomic.AtomicLong

// Application-scoped; the service continues without a Flutter engine/activity.
object DetectionRuntime {
    private lateinit var context: Context
    lateinit var store: DetectionStore
        private set
    lateinit var catalog: RestrictedAppCatalog
        private set
    private lateinit var selections: RestrictedAppsRepository
    @Volatile var selection: RestrictedSelection = RestrictedSelection(0, emptyMap())
        private set
    private var selectionSaveFailed = false
    private var pendingSelection: Pair<String, Boolean>? = null
    @Volatile var selectionError: String? = null
        private set
    @Volatile var restrictionsReady = false
        private set
    fun isSelected(packageName: String?) = restrictionsReady && selectionError == null && packageName in selection.packages
    // Worker only: recheck installation identity and protected components before navigation.
    fun canRestrict(packageName: String): Boolean = isSelected(packageName) && runCatching {
        catalog.supported(packageName)?.let { RestrictedAppPolicy.currentInstallation(selection.packages, it) } == true
    }.getOrDefault(false)
    fun refreshApps(): List<RestrictableCandidate> {
        try {
            selections.record()
            val apps = catalog.discover()
            selection = selections.reconcile(apps.associate { it.packageName to it.installedAt })
            pendingSelection?.let { (packageName, wanted) ->
                val app = apps.firstOrNull { it.packageName == packageName }
                // A removed or newly protected app cannot be selected. Otherwise
                // retry the explicit choice after a transient save/discovery failure.
                if (!wanted || app != null) selection = selections.select(packageName, wanted, app?.installedAt)
                pendingSelection = null
                selectionSaveFailed = false
            }
            if (!selectionSaveFailed) selectionError = null
            return apps
        } catch (error: Exception) {
            selectionError = "Could not load or save restricted apps. Restrictions are paused. Refresh to retry."
            throw error
        } finally { restrictionsReady = true }
    }
    fun selectApp(packageName: String, selected: Boolean) {
        pendingSelection = packageName to selected
        try {
            val app = if (selected) checkNotNull(catalog.supported(packageName)) { "App unavailable or protected" } else null
            selection = selections.select(packageName, selected, app?.installedAt)
            selectionSaveFailed = false
            pendingSelection = null
            selectionError = null
        } catch (error: Exception) {
            selectionSaveFailed = true
            selectionError = "App selection could not be saved. Restrictions are paused. Refresh to retry."
            throw error
        }
    }
    fun packageChanged(packageName: String?, removed: Boolean) {
        try {
            if (removed && packageName != null) selection = selections.removed(packageName)
            refreshApps()
        } catch (_: Exception) { /* Keep durable selections and surface the error; never guess an inventory. */ }
        emit()
    }
    private val main = Handler(Looper.getMainLooper())
    val worker = Executors.newSingleThreadExecutor()
    @Volatile var connected = false
        private set
    @Volatile var sink: EventChannel.EventSink? = null
    private var lastEnabled = false
    private var detectionSaveFailed = false
    private var blockingSaveFailed = false
    val stateRevision = AtomicLong()
    @Volatile var blockingEnabled = false
        private set
    @Volatile var foregroundRestrictedPackage: String? = null
    @Volatile var lockVisible = false
        private set
    @Volatile var visibleLockAttempt = 0L
        private set
    private val observers = mutableSetOf<() -> Unit>()
    private val attemptCounter = AtomicLong(System.nanoTime())
    val lockFlow = InstagramLockFlow()
    private var lockRecovery = false
    @Volatile var acknowledgedLockAttempt = 0L
        private set
    fun nextLockAttempt(): Long = attemptCounter.incrementAndGet()

    fun attach(source: Context) {
        if (::context.isInitialized) return
        context = source.applicationContext
        store = DetectionStore(context)
        catalog = RestrictedAppCatalog(context)
        selections = store.selectionRepository(catalog)
        InstagramLockLog.enabled = context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE != 0
        worker.execute {
            blockingEnabled = store.blockingEnabled()
            runCatching { refreshApps() }
            emit()
        }
        val packages = object : BroadcastReceiver() {
            override fun onReceive(source: Context?, intent: Intent?) {
                if (intent == null || intent.getBooleanExtra(Intent.EXTRA_REPLACING, false) && intent.action == Intent.ACTION_PACKAGE_REMOVED) return
                stateRevision.incrementAndGet()
                worker.execute { packageChanged(intent.data?.schemeSpecificPart, intent.action == Intent.ACTION_PACKAGE_REMOVED) }
            }
        }
        val packageFilter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED); addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_REPLACED); addAction(Intent.ACTION_PACKAGE_CHANGED); addDataScheme("package")
        }
        if (Build.VERSION.SDK_INT >= 33) context.registerReceiver(packages, packageFilter, Context.RECEIVER_NOT_EXPORTED)
        else context.registerReceiver(packages, packageFilter)
        lastEnabled = isEnabled()
        val manager = context.getSystemService(AccessibilityManager::class.java)
        manager.addAccessibilityStateChangeListener { notifyPermissionChange() }
        if (Build.VERSION.SDK_INT >= 33) {
            manager.addAccessibilityServicesStateChangeListener(context.mainExecutor) { notifyPermissionChange() }
        }
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                stateRevision.incrementAndGet()
                worker.execute {
                    if (intent?.action == Intent.ACTION_TIMEZONE_CHANGED) TimeZone.setDefault(null)
                    // Dates and time are reevaluated from durable inputs; never discard
                    // valid plan counts because the clock/zone changed or time elapsed.
                    emit()
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_TIME_CHANGED); addAction(Intent.ACTION_TIMEZONE_CHANGED); addAction(Intent.ACTION_DATE_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= 33) context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        else context.registerReceiver(receiver, filter)
    }

    fun isEnabled(): Boolean = runCatching {
        val target = ComponentName(context, InstagramDetectionService::class.java)
        val manager = context.getSystemService(AccessibilityManager::class.java)
        manager.isEnabled && manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK).any {
            val info = it.resolveInfo.serviceInfo
            ComponentName(info.packageName, info.name) == target
        }
    }.getOrDefault(false)

    private fun notifyPermissionChange() {
        val enabled = isEnabled()
        if (!enabled) {
            connected = false
            lockFlow.disconnect()
            foregroundRestrictedPackage = null
            lockVisible = false
        }
        stateRevision.incrementAndGet()
        lastEnabled = enabled
        worker.execute {
            emit()
        }
    }

    fun setConnected(value: Boolean) {
        if (connected == value) return
        connected = value
        if (!value) {
            stateRevision.incrementAndGet()
            lockFlow.disconnect()
            foregroundRestrictedPackage = null
            lockVisible = false
        }
        worker.execute { emit() }
    }

    fun recordDetectionOnWorker(packageName: String) {
        detectionSaveFailed = !runCatching { store.recordDetection(packageName) }.getOrDefault(false)
    }

    fun changeBlocking(enabled: Boolean): Boolean {
        if (enabled && selectionError != null) return false
        if (!enabled) blockingEnabled = false // Honour disabling even on disk failure.
        val saved = store.setBlockingEnabled(enabled)
        blockingSaveFailed = !saved
        if (saved) blockingEnabled = enabled
        return saved
    }

    fun reportRestriction(value: String) {
        worker.execute { store.reportRestriction(value); emit() }
    }

    fun lockResumed(attempt: Long) {
        if (!lockFlow.isCurrent(attempt)) return
        lockFlow.resumed(attempt)
        visibleLockAttempt = attempt
        InstagramLockLog.event("activity_resumed", attempt)
        confirmLock(attempt)
    }
    fun lockDrawn(attempt: Long, recovery: Boolean) {
        if (!lockFlow.isCurrent(attempt)) return
        lockRecovery = recovery
        lockFlow.drawn(attempt)
        InstagramLockLog.event("activity_drawn", attempt)
        confirmLock(attempt)
    }
    fun lockFocused(attempt: Long, focused: Boolean) {
        lockFlow.focused(attempt, focused)
        if (!focused && visibleLockAttempt == attempt) lockVisible = false
        InstagramLockLog.event("activity_focus", attempt, "focused=$focused")
        confirmLock(attempt)
    }
    private fun confirmLock(attempt: Long) {
        val interactive = runCatching {
            context.getSystemService(android.os.PowerManager::class.java).isInteractive &&
                !context.getSystemService(android.app.KeyguardManager::class.java).isKeyguardLocked
        }.getOrDefault(false)
        if (!lockFlow.isCurrent(attempt)) return
        lockVisible = lockFlow.visible(attempt, interactive)
        if (!lockFlow.confirm(attempt, interactive)) return
        acknowledgedLockAttempt = attempt
        InstagramLockLog.event("lock_visible_confirmed", attempt, "evidence=resumed_focused_drawn_unlocked")
        val recovery = lockRecovery
        worker.execute {
            runCatching { InstagramLockFeedback.cancel(context) }
            store.reportRestriction(if (recovery) "recovery_shown" else "lock_shown")
            emit()
        }
    }
    fun lockPaused(attempt: Long) {
        lockFlow.paused(attempt)
        InstagramLockLog.event("activity_paused", attempt)
        if (visibleLockAttempt == attempt) lockVisible = false
    }
    fun lockFallback(attempt: Long?, packageName: String) {
        worker.execute {
            runCatching { InstagramLockFeedback.show(context, attempt, packageName) }.onFailure {
                InstagramLockLog.event("fallback_exception", attempt ?: 0, "type=${it.javaClass.simpleName}")
            }
            emit()
        }
    }
    fun addObserver(observer: () -> Unit) { observers.add(observer) }
    fun removeObserver(observer: () -> Unit) { observers.remove(observer) }

    // Access store only from the serial worker, including MethodChannel calls.
    fun status(): Map<String, Any?> {
        val enabled = isEnabled()
        return mapOf("supported" to true, "enabled" to enabled, "connected" to (enabled && connected),
            "lastDetection" to store.lastDetection(), "freedom" to runCatching { store.eligibility() }
                .getOrDefault(NativeFreedomResult("unknown", "native_unavailable")).toMap(),
            "selectedPackages" to selection.packages.keys.toList(), "selectionRevision" to selection.revision,
            "selectionError" to selectionError, "removedAppCount" to selection.removedCount,
            "revision" to store.revision(), "detectionSaveFailed" to detectionSaveFailed, "blockingEnabled" to blockingEnabled,
            "lastRestriction" to store.lastRestriction(), "blockingSaveFailed" to blockingSaveFailed)
    }

    fun emit() {
        runCatching { InstagramLockFeedback.reconcile(context) }
        val value = status()
        main.post { sink?.success(value); observers.toList().forEach { it() } }
    }
}
