package com.sofien.daylock

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val main = Handler(Looper.getMainLooper())
    private var methods: MethodChannel? = null
    private var events: EventChannel? = null
    private var notifications: NotificationBridge? = null
    private var stopwatchClock: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        stopwatchClock = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "daylock/stopwatch_clock").apply {
            setMethodCallHandler { call, result ->
                if (call.method != "read") result.notImplemented()
                else result.success(mapOf(
                    "elapsedMs" to android.os.SystemClock.elapsedRealtime(),
                    "bootCount" to Settings.Global.getInt(contentResolver, Settings.Global.BOOT_COUNT, -1)))
            }
        }
        notifications = NotificationBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        DetectionRuntime.attach(this)
        methods = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "daylock/instagram_detection").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "openAppSettings") {
                    try {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            android.net.Uri.parse("package:$packageName")))
                        result.success(null)
                    } catch (_: Exception) { result.error("SETTINGS_UNAVAILABLE", "Open Daylock App info manually.", null) }
                } else if (call.method == "openAccessibilitySettings") {
                    try {
                        val detail = Intent("android.settings.ACCESSIBILITY_DETAILS_SETTINGS").putExtra(
                            "android.intent.extra.COMPONENT_NAME",
                            android.content.ComponentName(this@MainActivity, InstagramDetectionService::class.java).flattenToString())
                        try { startActivity(detail) }
                        catch (_: Exception) { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }
                        result.success(null)
                    } catch (_: Exception) { result.error("SETTINGS_UNAVAILABLE", "Open Android Accessibility Settings manually.", null) }
                } else if (call.method in listOf("getStatus", "publishSnapshot", "invalidateSnapshot", "setBlockingEnabled", "publishAppearance", "getInstalledApps", "setRestrictedApp", "testRestrictedApp")) {
                    if (call.method in listOf("publishSnapshot", "invalidateSnapshot", "setBlockingEnabled", "setRestrictedApp")) {
                        DetectionRuntime.stateRevision.incrementAndGet()
                    }
                    DetectionRuntime.worker.execute {
                        try {
                            var apps: List<Map<String, Any?>>? = null
                            var testIntent: Intent? = null
                            when (call.method) {
                                "testRestrictedApp" -> {
                                    val target = (call.arguments as Map<*, *>)["packageName"] as String
                                    check(DetectionRuntime.isEnabled() && DetectionRuntime.connected &&
                                        DetectionRuntime.canRestrict(target) &&
                                        InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled, true,
                                            DetectionRuntime.store.eligibility()) == InstagramRestriction.BLOCK)
                                    testIntent = checkNotNull(packageManager.getLaunchIntentForPackage(target))
                                    // Clear historical evidence before a fresh real app-opening test.
                                    DetectionRuntime.store.reportRestriction("test_requested")
                                    DetectionRuntime.store.reportLockLaunch("not_attempted")
                                    DetectionRuntime.store.reportHomeAction("not_attempted")
                                }
                                "getInstalledApps" -> apps = DetectionRuntime.refreshApps().map { DetectionRuntime.catalog.row(it) }
                                "getStatus" -> runCatching { DetectionRuntime.refreshApps() }
                                "setRestrictedApp" -> {
                                    val args = call.arguments as Map<*, *>
                                    DetectionRuntime.selectApp(args["packageName"] as String, args["selected"] as Boolean)
                                }
                                "publishSnapshot" -> check(DetectionRuntime.store.publish(call.arguments as Map<*, *>))
                                "invalidateSnapshot" -> check(DetectionRuntime.store.invalidate("planner_refresh_required"))
                                "setBlockingEnabled" -> check(DetectionRuntime.changeBlocking((call.arguments as Map<*, *>)["enabled"] as Boolean))
                                "publishAppearance" -> check(DetectionRuntime.store.publishAppearance(call.arguments as Map<*, *>))
                            }
                            val status = DetectionRuntime.status()
                            main.post {
                                try {
                                    result.success(if (apps == null) status else mapOf("status" to status, "apps" to apps))
                                    testIntent?.let { startActivity(it) }
                                } catch (_: Exception) {
                                    DetectionRuntime.reportRestriction("lock_launch_failed")
                                }
                            }
                            DetectionRuntime.emit()
                        } catch (it: Exception) {
                            if (call.method in listOf("publishSnapshot", "invalidateSnapshot") && it !is NativeRevisionConflict) DetectionRuntime.store.invalidate("save_failed")
                            main.post { result.error("DETECTION_STATE_FAILED", "Native detection state is unavailable.", null) }
                            DetectionRuntime.emit()
                        }
                    }
                } else result.notImplemented()
            }
        }
        events = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "daylock/instagram_detection/events").apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    DetectionRuntime.sink = sink
                    DetectionRuntime.worker.execute { DetectionRuntime.emit() }
                }
                override fun onCancel(arguments: Any?) { DetectionRuntime.sink = null }
            })
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        stopwatchClock?.setMethodCallHandler(null)
        stopwatchClock = null
        notifications?.close()
        notifications = null
        methods?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        DetectionRuntime.sink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        notifications?.onIntent(intent)
    }
}
