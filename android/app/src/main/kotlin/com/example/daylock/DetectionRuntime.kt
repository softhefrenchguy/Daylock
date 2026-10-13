package com.example.daylock

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
    @Volatile var lockVisible = false
        private set
    @Volatile var visibleLockAttempt = 0L
        private set
    private val observers = mutableSetOf<() -> Unit>()
    private val attemptCounter = AtomicLong(System.nanoTime())
    @Volatile var acknowledgedLockAttempt = 0L
        private set
    fun nextLockAttempt(): Long = attemptCounter.incrementAndGet()

    fun attach(source: Context) {
        if (::context.isInitialized) return
        context = source.applicationContext
        store = DetectionStore(context)
        worker.execute { blockingEnabled = store.blockingEnabled(); emit() }
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
        if (!enabled) connected = false
        stateRevision.incrementAndGet()
        lastEnabled = enabled
        worker.execute {
            emit()
        }
    }

    fun setConnected(value: Boolean) {
        if (connected == value) return
        connected = value
        if (!value) stateRevision.incrementAndGet()
        worker.execute { emit() }
    }

    fun recordDetectionOnWorker() {
        detectionSaveFailed = !runCatching { store.recordDetection() }.getOrDefault(false)
    }

    fun changeBlocking(enabled: Boolean): Boolean {
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
        lockVisible = true
        visibleLockAttempt = attempt
    }
    fun lockDrawn(attempt: Long, recovery: Boolean) {
        acknowledgedLockAttempt = attempt
        reportRestriction(if (recovery) "recovery_shown" else "lock_shown")
    }
    fun lockPaused(attempt: Long) {
        if (visibleLockAttempt == attempt) lockVisible = false
    }
    fun addObserver(observer: () -> Unit) { observers.add(observer) }
    fun removeObserver(observer: () -> Unit) { observers.remove(observer) }

    // Access store only from the serial worker, including MethodChannel calls.
    fun status(): Map<String, Any?> {
        val enabled = isEnabled()
        return mapOf("supported" to true, "enabled" to enabled, "connected" to (enabled && connected),
            "lastDetection" to store.lastDetection(), "freedom" to runCatching { store.eligibility() }
                .getOrDefault(NativeFreedomResult("unknown", "native_unavailable")).toMap(),
            "revision" to store.revision(), "detectionSaveFailed" to detectionSaveFailed, "blockingEnabled" to blockingEnabled,
            "lastRestriction" to store.lastRestriction(), "blockingSaveFailed" to blockingSaveFailed)
    }

    fun emit() {
        val value = status()
        main.post { sink?.success(value); observers.toList().forEach { it() } }
    }
}
