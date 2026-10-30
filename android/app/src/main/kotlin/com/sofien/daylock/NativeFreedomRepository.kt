package com.sofien.daylock

import org.json.JSONObject

// One atomic record owns both controls, dated inputs and the synchronisation revision.
// Kept separate from Android preferences so restart/failure/codec tests use this code.
data class NativeFreedomRecord(
    val revision: Long = 0,
    val blockingEnabled: Boolean = false,
    val freedom: NativeFreedomState? = null,
    val reason: String = "missing",
) {
    init { require(revision >= 0 && revision < Long.MAX_VALUE) }
}

object NativeFreedomCodec {
    private fun number(value: Any): Long {
        require(value is Int || value is Long)
        return (value as Number).toLong()
    }
    private fun int(value: Any): Int {
        val result = number(value)
        require(result in Int.MIN_VALUE.toLong()..Int.MAX_VALUE.toLong())
        return result.toInt()
    }
    fun fromInput(input: Map<*, *>): NativeFreedomState {
        val tomorrow = input["tomorrowPlan"] as Map<*, *>?
        return NativeFreedomState(
            input["date"] as String, input["enabled"] as Boolean,
            int(input["hour"]!!), int(input["minute"]!!),
            int(input["eligibleCount"]!!), int(input["completedCount"]!!),
            input["tomorrowCommitted"] as Boolean, input["runningFocus"] as Boolean,
            input["focusCompletesAtMs"]?.let { number(it) },
            tomorrow?.let { NativePlanSummary(it["date"] as String, int(it["eligibleCount"]!!), int(it["completedCount"]!!)) },
        )
    }
    private fun inputs(value: NativeFreedomState): Map<String, Any?> = mapOf(
        "date" to value.date, "enabled" to value.enabled, "hour" to value.hour, "minute" to value.minute,
        "eligibleCount" to value.eligibleCount, "completedCount" to value.completedCount,
        "tomorrowCommitted" to value.tomorrowCommitted, "runningFocus" to value.runningFocus,
        "focusCompletesAtMs" to value.focusCompletesAtMs,
        "tomorrowPlan" to value.tomorrowPlan?.let { mapOf("date" to it.date, "eligibleCount" to it.eligibleCount, "completedCount" to it.completedCount) },
    )
    fun encode(record: NativeFreedomRecord): String = JSONObject().apply {
        put("version", 2); put("revision", record.revision); put("blockingEnabled", record.blockingEnabled)
        put("reason", record.reason)
        put("freedom", record.freedom?.let { JSONObject(inputs(it)) } ?: JSONObject.NULL)
    }.toString()

    fun decode(raw: String): NativeFreedomRecord {
        val json = JSONObject(raw)
        require(int(json.get("version")) == 2)
        val freedom = if (json.isNull("freedom")) null else {
            val fields = json.getJSONObject("freedom")
            val input = mutableMapOf<String, Any>()
            for (key in fields.keys()) {
                if (fields.isNull(key)) continue
                input[key] = if (key == "tomorrowPlan") {
                    val tomorrow = fields.getJSONObject(key)
                    mapOf("date" to tomorrow.get("date"), "eligibleCount" to tomorrow.get("eligibleCount"),
                        "completedCount" to tomorrow.get("completedCount"))
                } else fields.get(key)
            }
            fromInput(input)
        }
        return NativeFreedomRecord(number(json.get("revision")), json.get("blockingEnabled") as Boolean,
            freedom, json.get("reason") as String)
    }
}

class NativeRevisionConflict : IllegalStateException("Native state changed before publication")

class NativeFreedomRepository(
    private val read: () -> String?,
    private val write: (String, Boolean) -> Boolean,
    private val legacyBlocking: () -> Boolean = { false },
    private val hasLegacySnapshot: () -> Boolean = { false },
) {
    @Volatile private var current: NativeFreedomRecord? = null
    @Volatile private var writeFailed = false
    // All mutations/loading are serialized by DetectionRuntime.worker.
    fun record(): NativeFreedomRecord {
        current?.let { return it }
        val loaded = try {
            val raw = read()
            if (raw == null) NativeFreedomRecord(blockingEnabled = legacyBlocking(),
                reason = if (hasLegacySnapshot()) "upgrade_refresh_required" else "missing")
            else NativeFreedomCodec.decode(raw)
        } catch (_: Exception) {
            NativeFreedomRecord(blockingEnabled = runCatching(legacyBlocking).getOrDefault(false), reason = "invalid_snapshot")
        }
        current = loaded
        return loaded
    }
    private fun commit(value: NativeFreedomRecord): Boolean {
        val saved = runCatching { write(NativeFreedomCodec.encode(value), value.blockingEnabled) }.getOrDefault(false)
        writeFailed = !saved
        if (saved) current = value
        return saved
    }
    fun invalidate(reason: String): Boolean {
        val previous = record()
        return commit(previous.copy(revision = previous.revision + 1, freedom = null, reason = reason))
    }
    fun publish(value: NativeFreedomState, expectedRevision: Long): Boolean {
        val previous = record()
        if (previous.revision != expectedRevision) throw NativeRevisionConflict()
        return commit(previous.copy(revision = previous.revision + 1, freedom = value, reason = "synchronised"))
    }
    fun setBlocking(enabled: Boolean): Boolean {
        val previous = record()
        return commit(previous.copy(revision = previous.revision + 1, blockingEnabled = enabled))
    }
    fun eligibility(now: DetectionClock): NativeFreedomResult {
        val value = record()
        if (writeFailed) return NativeFreedomResult("unknown", "save_failed")
        return DetectionPolicy.evaluate(value.freedom, now, value.reason)
    }
}
