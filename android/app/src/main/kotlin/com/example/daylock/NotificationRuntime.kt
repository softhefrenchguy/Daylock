package com.example.daylock

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneId
import java.util.concurrent.Executors

/** Entirely separate from DetectionRuntime: notification permission never
 * depends on Accessibility and notifications never mutate Freedom controls. */
object NotificationRuntime {
    const val PREFS = "daylock.notifications.v1"
    const val TAP = "daylock.notification.tap"
    private const val RECORD = "record"
    private const val ALARM_ID = 7400
    val worker = Executors.newSingleThreadExecutor()
    private val categories = mapOf("plan" to "Plan Tomorrow", "commitments" to "Commitment reminders",
        "freedom" to "Freedom", "focus" to "Focus completion")

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private fun repository(context: Context) = ReminderRepository(
        { prefs(context).getString(RECORD, null) }, { prefs(context).edit().putString(RECORD, it).commit() })
    fun allowed(context: Context): Boolean = NotificationManagerCompat.from(context).areNotificationsEnabled() &&
        (Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
    private fun enabledChannels(context: Context): Set<String> {
        if (!allowed(context)) return emptySet()
        val manager = context.getSystemService(NotificationManager::class.java)
        return categories.keys.filter { category -> Build.VERSION.SDK_INT < 26 ||
            manager.getNotificationChannel("daylock_$category")?.importance != NotificationManager.IMPORTANCE_NONE }.toSet()
    }
    fun status(context: Context): Map<String, Any> {
        val manager = context.getSystemService(NotificationManager::class.java)
        return mapOf("allowed" to allowed(context), "askedBefore" to prefs(context).getBoolean("asked", false),
            "blockedChannels" to categories.keys.filter { Build.VERSION.SDK_INT >= 26 &&
                manager.getNotificationChannel("daylock_$it")?.importance == NotificationManager.IMPORTANCE_NONE })
    }
    fun markAsked(context: Context) { check(prefs(context).edit().putBoolean("asked", true).commit()) }
    private fun alarmIntent(context: Context) = PendingIntent.getBroadcast(context, ALARM_ID,
        Intent(context, NotificationAlarmReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun cancelAlarm(context: Context) { context.getSystemService(AlarmManager::class.java).cancel(alarmIntent(context)) }
    private fun clearNotifications(context: Context) {
        val manager = NotificationManagerCompat.from(context)
        (7401..7404).forEach(manager::cancel)
    }
    fun invalidate(context: Context) {
        // Cancellation happens even if committing the invalidation fails.
        cancelAlarm(context)
        clearNotifications(context)
        repository(context).invalidate()
    }
    fun publish(context: Context, raw: String) {
        repository(context).publish(ReminderCodec.snapshot(JSONObject(raw)), System.currentTimeMillis())
        refresh(context)
    }
    fun refresh(context: Context) {
        cancelAlarm(context)
        val repo = repository(context)
        var record = repo.load()
        if (!record.valid || repo.failed) { clearNotifications(context); return }
        val now = System.currentTimeMillis()
        val zone = ZoneId.systemDefault()
        val date = Instant.ofEpochMilli(now).atZone(zone).toLocalDate().toString()
        if (record.lastDate != date || !allowed(context)) clearNotifications(context)
        val channels = enabledChannels(context)
        val result = NotificationPolicy.evaluate(record.snapshot, record.valid, record.seen, now, zone, channels)
        for (decision in result.decisions) {
            // Persist before posting: a process death can miss an alert, but
            // cannot turn reboot/clock changes into duplicate notifications.
            repo.consume(decision.keys, date)
            decision.message?.let { show(context, it) }
        }
        record = repo.load()
        val next = NotificationPolicy.evaluate(record.snapshot, record.valid, record.seen, now, zone, channels).nextAlarmMs
        if (next != null) context.getSystemService(AlarmManager::class.java)
            .setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, alarmIntent(context))
    }
    private fun show(context: Context, message: ReminderMessage) {
        if (message.category !in enabledChannels(context)) return
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel("daylock_${message.category}",
                categories.getValue(message.category), NotificationManager.IMPORTANCE_DEFAULT))
        }
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(TAP, message.payload())
        }
        val tap = PendingIntent.getActivity(context, message.id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        // The Flutter plugin owns permission/channels; its underlying supported
        // AndroidX renderer also works in this receiver without a Dart engine.
        val notification = NotificationCompat.Builder(context, "daylock_${message.category}")
            .setSmallIcon(R.drawable.ic_stat_daylock).setContentTitle(message.title).setContentText(message.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message.body))
            .setContentIntent(tap).setAutoCancel(true).setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT).build()
        manager.notify(message.id, notification)
    }
    fun receive(context: Context, pending: BroadcastReceiver.PendingResult) {
        val app = context.applicationContext
        worker.execute {
            try { refresh(app) } catch (_: Exception) {
                // Fail closed; a later app resume, boot or system event retries.
                cancelAlarm(app)
                clearNotifications(app)
            } finally { pending.finish() }
        }
    }
}

class NotificationAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) { NotificationRuntime.receive(context, goAsync()) }
}
class NotificationRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) { NotificationRuntime.receive(context, goAsync()) }
}

class NotificationBridge(private val activity: MainActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "daylock/notifications")
    private val main = Handler(Looper.getMainLooper())
    private var tapReady = false
    private var pendingTap: String? = activity.intent?.getStringExtra(NotificationRuntime.TAP)
    init {
        activity.intent?.removeExtra(NotificationRuntime.TAP)
        channel.setMethodCallHandler { call, result ->
            if (call.method == "takeLaunchTap") {
                tapReady = true
                result.success(pendingTap)
                pendingTap = null
            } else {
                NotificationRuntime.worker.execute {
                    try {
                        when (call.method) {
                            "status" -> Unit
                            "refresh" -> NotificationRuntime.refresh(activity.applicationContext)
                            "markPermissionRequested" -> NotificationRuntime.markAsked(activity.applicationContext)
                            "invalidate" -> NotificationRuntime.invalidate(activity.applicationContext)
                            "publish" -> NotificationRuntime.publish(activity.applicationContext, call.arguments as String)
                            else -> { main.post { result.notImplemented() }; return@execute }
                        }
                        val value = if (call.method == "status") NotificationRuntime.status(activity.applicationContext) else null
                        main.post { result.success(value) }
                    } catch (_: Exception) {
                        main.post { result.error("NOTIFICATIONS_UNAVAILABLE", "Notification state could not be updated.", null) }
                    }
                }
            }
        }
    }
    fun onIntent(intent: Intent) {
        val payload = intent.getStringExtra(NotificationRuntime.TAP) ?: return
        intent.removeExtra(NotificationRuntime.TAP)
        if (tapReady) channel.invokeMethod("tap", payload) else pendingTap = payload
    }
    fun close() { channel.setMethodCallHandler(null) }
}
