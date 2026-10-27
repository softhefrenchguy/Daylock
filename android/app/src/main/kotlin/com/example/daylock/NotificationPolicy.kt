package com.example.daylock

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

data class ReminderPreferences(val plan: Boolean, val commitments: Boolean, val freedom: Boolean,
    val focus: Boolean, val planMinute: Int, val commitmentMinute: Int) {
    init { require(planMinute in 0..1439 && commitmentMinute in 0..1439) }
}
data class ReminderTask(val name: String, val outcome: String, val minimumMinutes: Int?, val deadlineMs: Long?) {
    init {
        require(outcome in setOf("incomplete", "completed", "excused"))
        require(minimumMinutes == null || minimumMinutes > 0)
        require(deadlineMs == null || (minimumMinutes != null && deadlineMs > 0 && outcome != "excused"))
    }
    val eligible get() = outcome != "excused"
    fun complete(now: Long) = outcome == "completed"
}
data class ReminderPlan(val date: String, val committed: Boolean, val tasks: List<ReminderTask>) {
    init { nextPlanDate(date) }
}
data class ReminderSnapshot(val preferences: ReminderPreferences, val freedomEnabled: Boolean,
    val freedomHour: Int, val freedomMinute: Int, val today: ReminderPlan, val tomorrow: ReminderPlan) {
    init {
        require(freedomHour in 0..23 && freedomMinute in 0..59)
        require(tomorrow.date == nextPlanDate(today.date))
    }
    fun plan(date: String): ReminderPlan? = when (date) {
        today.date -> today
        tomorrow.date -> tomorrow
        else -> null
    }
    // Flutter settles a due timer by clearing focusStartedAt. Retain only a due
    // deadline for that same dated/indexed task when it became completed. This
    // preserves the completion alert if the UI beats the inexact receiver.
    fun retainingDueFocus(previous: ReminderSnapshot?, now: Long): ReminderSnapshot {
        if (previous?.today?.date != today.date || !preferences.focus || !previous.preferences.focus) return this
        val tasks = today.tasks.mapIndexed { index, task ->
            val old = previous.today.tasks.getOrNull(index)
            if (task.outcome == "completed" && task.deadlineMs == null && old?.name == task.name &&
                old.minimumMinutes == task.minimumMinutes && old.deadlineMs != null && old.deadlineMs <= now)
                task.copy(deadlineMs = old.deadlineMs) else task
        }
        return copy(today = today.copy(tasks = tasks))
    }
}

object ReminderCodec {
    fun snapshot(json: JSONObject): ReminderSnapshot {
        require(json.getInt("version") == 1)
        val p = json.getJSONObject("preferences")
        val f = json.getJSONObject("freedom")
        fun plan(value: JSONObject): ReminderPlan {
            val tasks = value.getJSONArray("tasks")
            return ReminderPlan(value.getString("date"), value.getBoolean("committed"),
                (0 until tasks.length()).map { i ->
                    val t = tasks.getJSONObject(i)
                    ReminderTask(t.getString("name"), t.getString("outcome"),
                        if (t.isNull("minimumMinutes")) null else t.getInt("minimumMinutes"),
                        if (t.isNull("deadlineMs")) null else t.getLong("deadlineMs"))
                })
        }
        return ReminderSnapshot(ReminderPreferences(p.getBoolean("planTomorrow"), p.getBoolean("commitments"),
            p.getBoolean("freedom"), p.getBoolean("focus"), p.getInt("planMinute"), p.getInt("commitmentMinute")),
            f.getBoolean("enabled"), f.getInt("hour"), f.getInt("minute"),
            plan(json.getJSONObject("today")), plan(json.getJSONObject("tomorrow")))
    }
    fun encode(value: ReminderSnapshot): JSONObject {
        fun plan(p: ReminderPlan) = JSONObject().put("date", p.date).put("committed", p.committed)
            .put("tasks", JSONArray(p.tasks.map { t -> JSONObject().put("name", t.name).put("outcome", t.outcome)
                .put("minimumMinutes", t.minimumMinutes ?: JSONObject.NULL).put("deadlineMs", t.deadlineMs ?: JSONObject.NULL) }))
        val p = value.preferences
        return JSONObject().put("version", 1)
            .put("preferences", JSONObject().put("planTomorrow", p.plan).put("commitments", p.commitments)
                .put("freedom", p.freedom).put("focus", p.focus).put("planMinute", p.planMinute).put("commitmentMinute", p.commitmentMinute))
            .put("freedom", JSONObject().put("enabled", value.freedomEnabled).put("hour", value.freedomHour).put("minute", value.freedomMinute))
            .put("today", plan(value.today)).put("tomorrow", plan(value.tomorrow))
    }
}

data class ReminderMessage(val category: String, val title: String, val body: String,
    val date: String, val taskIndex: Int? = null, val taskName: String? = null) {
    val id get() = when (category) { "plan" -> 7401; "commitments" -> 7402; "freedom" -> 7403; else -> 7404 }
    fun payload(): String = JSONObject().put("screen", if (category == "plan") "plan" else "today")
        .put("date", date).put("taskIndex", taskIndex ?: JSONObject.NULL).put("taskName", taskName ?: JSONObject.NULL).toString()
}
data class ReminderDecision(val keys: Set<String>, val message: ReminderMessage?)
data class ReminderEvaluation(val decisions: List<ReminderDecision>, val nextAlarmMs: Long?)

/** Pure policy: evaluates actual dated state at delivery, not a pre-rendered
 * daily message. Zoned calendar dates handle DST gaps/overlaps and clock changes.
 * Reuses the same native Freedom policy used by the existing FreedomService bridge.
 */
object NotificationPolicy {
    fun evaluate(s: ReminderSnapshot?, valid: Boolean, seen: Set<String>, now: Long, zone: ZoneId,
        allowed: Set<String>): ReminderEvaluation {
        if (!valid || s == null || allowed.isEmpty()) return ReminderEvaluation(emptyList(), null)
        val local = Instant.ofEpochMilli(now).atZone(zone)
        val date = local.toLocalDate()
        val day = date.toString()
        if (day < s.today.date) return ReminderEvaluation(emptyList(), date.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli())
        val p = s.preferences
        val today = s.plan(day)
        val tomorrowCommitted = s.plan(date.plusDays(1).toString())?.committed == true
        val eligible = today?.tasks?.count { it.eligible } ?: 0
        val complete = today?.tasks?.count { it.eligible && it.complete(now) } ?: 0
        val remaining = eligible - complete
        val enabled = buildSet {
            if (p.plan) add("plan")
            if (p.commitments) add("commitments")
            if (p.freedom && s.freedomEnabled) add("freedom")
            // The old Focus-completion preference is retained on disk only.
            // Optional stopwatches have no completion deadline or timer alert.
        }.intersect(allowed)
        if (enabled.isEmpty()) return ReminderEvaluation(emptyList(), null)
        val decisions = mutableListOf<ReminderDecision>()
        val upcoming = mutableListOf<Long>()
        fun at(minute: Int) = date.atTime(LocalTime.of(minute / 60, minute % 60)).atZone(zone).toInstant().toEpochMilli()
        fun daily(category: String, minute: Int, message: () -> ReminderMessage?) {
            if (category !in enabled) return
            val key = "$day|$category"
            if (key in seen) return
            val time = at(minute)
            if (now >= time) decisions.add(ReminderDecision(setOf(key), message())) else upcoming.add(time)
        }
        daily("plan", p.planMinute) {
            if (tomorrowCommitted) null else ReminderMessage("plan", "Plan tomorrow",
                "Tomorrow isn't committed yet. Take a moment to plan your day.", day)
        }
        daily("commitments", p.commitmentMinute) {
            if (remaining == 0) null else ReminderMessage("commitments", "Keep your commitments",
                "You have $remaining commitment${if (remaining == 1) "" else "s"} left to complete today.", day)
        }
        if ("freedom" in enabled) {
            val time = at(s.freedomHour * 60 + s.freedomMinute)
            val result = DetectionPolicy.evaluate(NativeFreedomState(day, s.freedomEnabled,
                s.freedomHour, s.freedomMinute, eligible, complete, tomorrowCommitted, false),
                DetectionClock(now, 0, 0, day, zone.id, local.offset.totalSeconds * 1000, local.hour * 60 + local.minute))
            val timeKey = "$day|freedom"
            val earnedKey = "$day|earned"
            if (now >= time && result.state == "earned" && earnedKey !in seen) {
                decisions.add(ReminderDecision(setOf(timeKey, earnedKey), ReminderMessage("freedom", "Freedom earned",
                    "You've completed your commitments and committed tomorrow. Enjoy your Freedom Time.", day)))
            } else if (now >= time && timeKey !in seen) {
                val body = if (eligible == 0) "Today has no eligible commitments. Freedom can't be earned today."
                    else if (remaining > 0 && !tomorrowCommitted) "Finish your remaining commitments and commit tomorrow to earn Freedom."
                    else if (remaining > 0) "Finish your remaining commitments to earn Freedom."
                    else "Commit tomorrow's plan to earn Freedom."
                decisions.add(ReminderDecision(setOf(timeKey), ReminderMessage("freedom", "Freedom Time is here", body, day)))
            } else if (now < time && timeKey !in seen) upcoming.add(time)
        }
        // One wake at midnight reconciles dates even when Flutter never opens.
        // No repeating service, polling job or exact-alarm permission is used.
        if (enabled.isNotEmpty()) {
            upcoming.add(date.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli())
        }
        return ReminderEvaluation(decisions, upcoming.filter { it > now }.minOrNull())
    }
}

data class ReminderRecord(val snapshot: ReminderSnapshot? = null, val valid: Boolean = false,
    val seen: Set<String> = emptySet(), val lastDate: String = "")

/** Atomic file-backed record. Injected I/O lets tests simulate reboot and failure. */
class ReminderRepository(private val read: () -> String?, private val write: (String) -> Boolean) {
    var failed = false
        private set
    fun load(): ReminderRecord = try {
        val raw = read()
        if (raw == null) ReminderRecord() else {
            val j = JSONObject(raw)
            require(j.getInt("version") == 1)
            val seen = j.getJSONArray("seen")
            ReminderRecord(if (j.isNull("snapshot")) null else ReminderCodec.snapshot(j.getJSONObject("snapshot")),
                j.getBoolean("valid"), (0 until seen.length()).map { seen.getString(it) }.toSet(), j.optString("lastDate"))
        }
    } catch (_: Exception) { failed = true; ReminderRecord() }
    fun save(record: ReminderRecord) {
        val json = JSONObject().put("version", 1).put("valid", record.valid)
            .put("snapshot", record.snapshot?.let(ReminderCodec::encode) ?: JSONObject.NULL)
            .put("seen", JSONArray(record.seen.toList())).put("lastDate", record.lastDate).toString()
        failed = !runCatching { write(json) }.getOrDefault(false)
        check(!failed) { "Notification state could not be persisted" }
    }
    fun invalidate() { save(load().copy(valid = false)) }
    fun publish(snapshot: ReminderSnapshot, now: Long) {
        val old = load()
        save(old.copy(snapshot = snapshot.retainingDueFocus(old.snapshot, now), valid = true))
    }
    fun consume(keys: Set<String>, date: String) {
        val old = load()
        val all = old.seen + keys
        // Keep the 64 most recent local dates, including backward clock travel.
        val dates = all.map { it.substringBefore('|') }.distinct().sortedDescending().take(64).toSet()
        save(old.copy(seen = all.filter { it.substringBefore('|') in dates }.toSet(), lastDate = date))
    }
}
