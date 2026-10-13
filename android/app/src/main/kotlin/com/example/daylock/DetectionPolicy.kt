package com.example.daylock

import java.util.Calendar
import java.util.GregorianCalendar
import java.util.Locale
import java.util.TimeZone

// No Android/UI dependencies: the background decision and event gate are unit-testable.
data class DetectionClock(
    val wallMs: Long,
    val elapsedMs: Long,
    val bootCount: Int,
    val date: String,
    val zoneId: String,
    val zoneOffsetMs: Int,
    val minuteOfDay: Int,
)

// Calendar components, not elapsed 24-hour periods. Works on Android API 24+.
fun nextPlanDate(date: String): String {
    require(Regex("\\d{4}-\\d{2}-\\d{2}").matches(date))
    val parts = date.split("-").map { it.toInt() }
    val calendar = GregorianCalendar(TimeZone.getTimeZone("UTC")).apply {
        clear()
        isLenient = false
        set(parts[0], parts[1] - 1, parts[2])
    }
    calendar.timeInMillis // Validate February/month/year boundaries strictly.
    calendar.add(Calendar.DAY_OF_MONTH, 1)
    return String.format(Locale.ROOT, "%04d-%02d-%02d", calendar.get(Calendar.YEAR),
        calendar.get(Calendar.MONTH) + 1, calendar.get(Calendar.DAY_OF_MONTH))
}

data class NativePlanSummary(val date: String, val eligibleCount: Int, val completedCount: Int) {
    init { nextPlanDate(date); require(eligibleCount >= 0 && completedCount in 0..eligibleCount) }
}

data class NativeFreedomState(
    val date: String,
    val enabled: Boolean,
    val hour: Int,
    val minute: Int,
    val eligibleCount: Int,
    val completedCount: Int,
    val tomorrowCommitted: Boolean,
    val runningFocus: Boolean,
    val focusCompletesAtMs: Long? = null,
    val tomorrowPlan: NativePlanSummary? = null,
) {
    init {
        nextPlanDate(date)
        require(hour in 0..23 && minute in 0..59)
        require(eligibleCount >= 0 && completedCount in 0..eligibleCount)
        require(focusCompletesAtMs == null || (runningFocus && focusCompletesAtMs > 0 && completedCount < eligibleCount))
        require(tomorrowPlan == null || tomorrowPlan.date == nextPlanDate(date))
    }
}

data class NativeFreedomConditions(
    val timeReached: Boolean, val hour: Int, val minute: Int,
    val completedCount: Int, val eligibleCount: Int, val tomorrowCommitted: Boolean,
) {
    val commitmentsCompleted get() = eligibleCount > 0 && completedCount == eligibleCount
    fun toMap(): Map<String, Any> = mapOf("timeReached" to timeReached, "hour" to hour, "minute" to minute,
        "completedCount" to completedCount, "eligibleCount" to eligibleCount,
        "commitmentsCompleted" to commitmentsCompleted, "tomorrowCommitted" to tomorrowCommitted)
}

data class NativeFreedomResult(val state: String, val reason: String,
    val conditions: NativeFreedomConditions? = null, val nextChangeInMs: Long? = null,
    val planDate: String? = null) {
    fun toMap(): Map<String, Any?> = mapOf("state" to state, "reason" to reason, "planDate" to planDate,
        "conditions" to conditions?.toMap())
}

object DetectionPolicy {
    fun evaluate(snapshot: NativeFreedomState?, now: DetectionClock, missingReason: String = "missing"): NativeFreedomResult {
        if (snapshot == null) return NativeFreedomResult("unknown", missingReason)
        // Controls stay usable even if plans are from another date.
        if (!snapshot.enabled) return NativeFreedomResult("disabled", "control_off")
        // Read-only reconciliation with the last successfully persisted tomorrow.
        // Never promote yesterday's completion or invent progress for missed days.
        if (snapshot.date != now.date) {
            val tomorrow = snapshot.tomorrowPlan
            if (tomorrow == null || tomorrow.date != now.date) return NativeFreedomResult("unknown", "date_changed")
            val reconciled = evaluate(NativeFreedomState(tomorrow.date, snapshot.enabled,
                snapshot.hour, snapshot.minute, tomorrow.eligibleCount, tomorrow.completedCount,
                false, false), now)
            return reconciled.copy(reason = "rollover_reconciled")
        }
        // The visible conditions also change when a timestamp-based Focus finishes.
        val nextChangeInMs = snapshot.focusCompletesAtMs?.minus(now.wallMs)?.takeIf { it > 0 }
        val focusDue = snapshot.runningFocus && snapshot.focusCompletesAtMs != null && now.wallMs >= snapshot.focusCompletesAtMs
        val completedCount = snapshot.completedCount + if (focusDue) 1 else 0
        val conditions = NativeFreedomConditions(now.minuteOfDay >= snapshot.hour * 60 + snapshot.minute,
            snapshot.hour, snapshot.minute, completedCount, snapshot.eligibleCount, snapshot.tomorrowCommitted)
        if (snapshot.runningFocus && snapshot.focusCompletesAtMs == null) return NativeFreedomResult("unknown", "focus_needs_refresh")
        if (snapshot.eligibleCount == 0) return NativeFreedomResult("notEarned", "no_eligible_commitments", conditions, nextChangeInMs, now.date)
        val ready = now.minuteOfDay >= snapshot.hour * 60 + snapshot.minute &&
            completedCount == snapshot.eligibleCount && snapshot.tomorrowCommitted
        return NativeFreedomResult(if (ready) "earned" else "notEarned", if (ready) "conditions_satisfied" else "conditions_remaining", conditions, nextChangeInMs, now.date)
    }
}

class InstagramEventGate {
    companion object {
        const val PACKAGE_NAME = "com.instagram.android"
        const val WINDOW_STATE_CHANGED = 32
        const val COOLDOWN_MS = 3000L
    }
    private var lastAcceptedMs: Long? = null
    fun reset() { lastAcceptedMs = null }
    fun accept(packageName: String?, eventType: Int, elapsedMs: Long): Boolean {
        if (packageName != PACKAGE_NAME || eventType != WINDOW_STATE_CHANGED || elapsedMs < 0) return false
        val previous = lastAcceptedMs
        if (previous != null && elapsedMs >= previous && elapsedMs - previous < COOLDOWN_MS) return false
        lastAcceptedMs = elapsedMs
        return true
    }
}

enum class InstagramRestriction { ALLOW, BLOCK, RECOVER }

object InstagramBlockingPolicy {
    fun isForegroundWindow(fullScreen: Boolean, contentChanges: Int): Boolean = fullScreen && contentChanges == 0
    fun decide(blockingEnabled: Boolean, permissionEnabled: Boolean, freedom: NativeFreedomResult): InstagramRestriction = when {
        !blockingEnabled || !permissionEnabled -> InstagramRestriction.ALLOW
        freedom.state == "disabled" || freedom.state == "earned" -> InstagramRestriction.ALLOW
        freedom.state == "notEarned" -> InstagramRestriction.BLOCK
        else -> InstagramRestriction.RECOVER // Bounded, escapable recovery; never an endless redirect.
    }
}

// At most one recovery redirect for this unresolved state/date per process.
// Opening Instagram again is allowed, with a reminder, until state changes.
class InstagramRecoveryGate {
    private var lastKey: String? = null
    fun reset() { lastKey = null }
    fun offer(revision: Long, date: String, reason: String): Boolean {
        val key = "$revision|$date|$reason"
        if (lastKey == key) return false
        lastKey = key
        return true
    }
}

// No app names/history retained. A pending navigation is cancelled on any other window.
class InstagramForegroundGuard {
    @Volatile var targetActive = false
        private set
    @Volatile private var revision = 0L
    fun observe(isInstagram: Boolean) {
        if (targetActive != isInstagram) { targetActive = isInstagram; revision++ }
    }
    fun token(): Long = revision
    fun matches(token: Long): Boolean = targetActive && revision == token
}
