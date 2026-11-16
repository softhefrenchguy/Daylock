package com.sofien.daylock

import org.json.JSONArray
import org.json.JSONObject

/**
 * A deliberate "earned break" from the lock screen: wait, give a reason, and
 * the selected app opens for a short time. One per local day, always logged.
 */
data class BreakRecord(
    val date: String,
    val startWallMs: Long,
    val startElapsedMs: Long,
    val boot: Int,
    val packageName: String,
    val appName: String,
    val reason: String,
)

object BreakPolicy {
    const val DURATION_MS = 15 * 60_000L
    const val WAIT_MS = 60_000L
    const val MIN_REASON = 3
    const val MAX_REASON = 200
    const val MAX_LOG = 60

    fun usedToday(log: List<BreakRecord>, today: String) = log.any { it.date == today }

    fun validReason(reason: String) = reason.trim().length in MIN_REASON..MAX_REASON

    fun canStart(log: List<BreakRecord>, today: String, reason: String) =
        !usedToday(log, today) && validReason(reason)

    /**
     * Time left on the latest break. Uses the monotonic clock within one boot,
     * so changing the wall clock can't stretch a break; falls back to the wall
     * clock across a reboot. Never more than [DURATION_MS].
     */
    fun remainingMs(last: BreakRecord?, nowWallMs: Long, nowElapsedMs: Long, boot: Int): Long {
        if (last == null) return 0
        val passed = if (boot >= 0 && boot == last.boot && nowElapsedMs >= last.startElapsedMs)
            nowElapsedMs - last.startElapsedMs else nowWallMs - last.startWallMs
        if (passed < 0) return 0
        return (DURATION_MS - passed).coerceIn(0, DURATION_MS)
    }

    fun append(log: List<BreakRecord>, record: BreakRecord) = (log + record).takeLast(MAX_LOG)

    fun encode(log: List<BreakRecord>): String = JSONArray(log.map {
        JSONObject().put("date", it.date).put("wall", it.startWallMs).put("elapsed", it.startElapsedMs)
            .put("boot", it.boot).put("package", it.packageName).put("app", it.appName).put("reason", it.reason)
    }).toString()

    fun decode(raw: String?): List<BreakRecord> {
        if (raw.isNullOrBlank()) return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val j = array.getJSONObject(i)
                BreakRecord(j.getString("date"), j.getLong("wall"), j.getLong("elapsed"), j.getInt("boot"),
                    j.getString("package"), j.optString("app"), j.getString("reason"))
            }
        }.getOrDefault(emptyList())
    }
}
