package com.example.daylock

/** Main-thread presentation state, independent of Freedom and the blocking decision. */
class InstagramLockFlow {
    companion object {
        const val HOME_GRACE_MS = 300L
        const val CONFIRM_MS = 1500L
        const val LAUNCH_COOLDOWN_MS = 3000L
    }
    @Volatile var attempt = 0L
        private set
    @Volatile var confirmed = false
        private set
    private var pending = false
    private var resumed = false
    private var focused = false
    private var drawn = false
    private var lastLaunchMs: Long? = null

    fun begin(id: Long, now: Long): Boolean {
        if (pending || lastLaunchMs?.let { now >= it && now - it < LAUNCH_COOLDOWN_MS } == true) return false
        attempt = id
        lastLaunchMs = now
        pending = true
        resumed = false
        focused = false
        drawn = false
        confirmed = false
        return true
    }
    fun isCurrent(id: Long) = id != 0L && attempt == id
    fun resumed(id: Long) { if (isCurrent(id)) resumed = true }
    fun paused(id: Long) { if (isCurrent(id)) { resumed = false; focused = false } }
    fun focused(id: Long, value: Boolean) { if (isCurrent(id)) focused = value }
    fun drawn(id: Long) { if (isCurrent(id)) drawn = true }
    fun visible(id: Long, interactiveAndUnlocked: Boolean) =
        isCurrent(id) && resumed && focused && drawn && interactiveAndUnlocked
    fun confirm(id: Long, interactiveAndUnlocked: Boolean): Boolean {
        if (confirmed || !visible(id, interactiveAndUnlocked)) return false
        confirmed = true
        return true
    }
    fun needsHome(id: Long) = isCurrent(id) && !resumed && !confirmed
    fun settle(id: Long): Boolean {
        if (!isCurrent(id)) return false
        pending = false
        return !confirmed
    }
    fun disconnect() {
        attempt = 0
        pending = false
        resumed = false
        focused = false
        drawn = false
        confirmed = false
        // Retain launch cooldown across a service rebind in this process.
    }
}

data class InstagramNoticeStamp(val wallMs: Long, val elapsedMs: Long, val boot: Int)

object InstagramFallbackPolicy {
    const val COOLDOWN_MS = 5 * 60_000L
    fun allowed(previous: InstagramNoticeStamp?, now: InstagramNoticeStamp): Boolean {
        if (previous == null) return true
        val age = if (now.boot >= 0 && now.boot == previous.boot && now.elapsedMs >= previous.elapsedMs)
            now.elapsedMs - previous.elapsedMs else now.wallMs - previous.wallMs
        // A clock correction across reboot permits one new notice, then monotonic
        // throttling applies again. Ordinary wall-clock changes cannot bypass it.
        return age < 0 || age >= COOLDOWN_MS
    }
}

enum class InstagramNoticeResult { POSTED, PERMISSION_DENIED, THROTTLED, INVALID_RECORD, SAVE_FAILED }

/** Injected durable ledger and renderer allow testing the actual dispatch order. */
class InstagramNoticeDelivery(
    private val read: () -> InstagramNoticeStamp?,
    private val reserve: (InstagramNoticeStamp) -> Boolean,
    private val post: () -> Unit,
) {
    fun deliver(permissionAllowed: Boolean, now: InstagramNoticeStamp): InstagramNoticeResult {
        if (!permissionAllowed) return InstagramNoticeResult.PERMISSION_DENIED
        val previous = try { read() } catch (_: Exception) { return InstagramNoticeResult.INVALID_RECORD }
        if (!InstagramFallbackPolicy.allowed(previous, now)) return InstagramNoticeResult.THROTTLED
        if (!runCatching { reserve(now) }.getOrDefault(false)) return InstagramNoticeResult.SAVE_FAILED
        // Reserve before posting: even process death or a platform exception cannot
        // produce a notification flood after restart. A failed post may lose one notice.
        post()
        return InstagramNoticeResult.POSTED
    }
}
