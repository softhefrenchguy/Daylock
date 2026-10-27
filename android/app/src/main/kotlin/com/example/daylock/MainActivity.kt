package com.example.daylock

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
                if (call.method == "openAccessibilitySettings") {
                    try {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    } catch (_: Exception) { result.error("SETTINGS_UNAVAILABLE", "Open Android Accessibility Settings manually.", null) }
                } else if (call.method in listOf("getStatus", "publishSnapshot", "invalidateSnapshot", "setBlockingEnabled", "publishAppearance")) {
                    if (call.method in listOf("publishSnapshot", "invalidateSnapshot", "setBlockingEnabled")) {
                        DetectionRuntime.stateRevision.incrementAndGet()
                    }
                    DetectionRuntime.worker.execute {
                        try {
                            when (call.method) {
                                "publishSnapshot" -> check(DetectionRuntime.store.publish(call.arguments as Map<*, *>))
                                "invalidateSnapshot" -> check(DetectionRuntime.store.invalidate("planner_refresh_required"))
                                "setBlockingEnabled" -> check(DetectionRuntime.changeBlocking((call.arguments as Map<*, *>)["enabled"] as Boolean))
                                "publishAppearance" -> check(DetectionRuntime.store.publishAppearance(call.arguments as Map<*, *>))
                            }
                            val status = DetectionRuntime.status()
                            main.post { result.success(status) }
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
