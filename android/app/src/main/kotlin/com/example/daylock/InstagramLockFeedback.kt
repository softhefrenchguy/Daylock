package com.example.daylock

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject

/** Fixed diagnostic fields only: no screen contents, task names, or app history. */
object InstagramLockLog {
    fun event(name: String, attempt: Long = 0, detail: String = "") {
        Log.i("DaylockInstagramLock", "event=$name attempt=$attempt sdk=${Build.VERSION.SDK_INT} $detail")
    }
}

object InstagramLockFeedback {
    const val CHANNEL = "daylock_instagram_lock"
    const val ID = 7450 // Does not overlap notification scheduler ids 7400..7404.
    private const val STAMP = "lockFallbackNotice"

    fun cancel(context: Context) { NotificationManagerCompat.from(context).cancel(ID) }

    // Called only on DetectionRuntime.worker; cancellation uses the same queue.
    fun reconcile(context: Context) {
        if (!DetectionRuntime.connected || InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled,
                DetectionRuntime.isEnabled(), DetectionRuntime.store.eligibility()) != InstagramRestriction.BLOCK) cancel(context)
    }

    fun show(context: Context, attempt: Long?) {
        if (!DetectionRuntime.connected || DetectionRuntime.lockVisible ||
            (attempt != null && (!DetectionRuntime.lockFlow.isCurrent(attempt) || DetectionRuntime.lockFlow.confirmed)) ||
            InstagramBlockingPolicy.decide(DetectionRuntime.blockingEnabled, DetectionRuntime.isEnabled(),
                DetectionRuntime.store.eligibility()) != InstagramRestriction.BLOCK) return
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(
            CHANNEL, "Instagram lock notices", NotificationManager.IMPORTANCE_DEFAULT).apply {
            description = "Explains Instagram blocking when the Daylock lock screen could not be shown"
        })
        val permitted = NotificationManagerCompat.from(context).areNotificationsEnabled() &&
            (Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) &&
            (Build.VERSION.SDK_INT < 26 || manager.getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE)
        // Additive key in the already backup-excluded native preferences. Never
        // change nativeState, planner data, appearance, or notification preferences.
        val prefs = context.getSharedPreferences("daylock.instagram_detection.v1", Context.MODE_PRIVATE)
        val now = InstagramNoticeStamp(System.currentTimeMillis(), SystemClock.elapsedRealtime(),
            Settings.Global.getInt(context.contentResolver, Settings.Global.BOOT_COUNT, -1))
        val delivery = InstagramNoticeDelivery(read = {
            prefs.getString(STAMP, null)?.let { JSONObject(it) }?.let {
                InstagramNoticeStamp(it.getLong("wall"), it.getLong("elapsed"), it.getInt("boot"))
            }
        }, reserve = { value ->
            val stamp = JSONObject().put("wall", value.wallMs).put("elapsed", value.elapsedMs).put("boot", value.boot).toString()
            prefs.edit().putString(STAMP, stamp).commit()
        }, post = {
        val tap = PendingIntent.getActivity(context, ID,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        // Direct user-tapped activity PendingIntent. No trampoline, full-screen
        // intent, manual send(), or grant of unrestricted background launch rights.
        manager.notify(ID, NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_daylock).setContentTitle("Instagram is locked")
            .setContentText("Complete your Daylock commitments to earn Freedom.")
            .setStyle(NotificationCompat.BigTextStyle().bigText("Complete your Daylock commitments to earn Freedom."))
            .setContentIntent(tap).setAutoCancel(true).setOnlyAlertOnce(true)
            .setTimeoutAfter(InstagramFallbackPolicy.COOLDOWN_MS)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE).setPriority(NotificationCompat.PRIORITY_DEFAULT).build())
        })
        val result = delivery.deliver(permitted, now)
        InstagramLockLog.event("fallback_result", attempt ?: 0, "result=$result delivery=system_settings_apply")
        when (result) {
            InstagramNoticeResult.POSTED -> DetectionRuntime.store.reportRestriction("lock_fallback_posted")
            InstagramNoticeResult.PERMISSION_DENIED -> DetectionRuntime.store.reportRestriction("lock_fallback_unavailable")
            else -> Unit
        }
    }
}
