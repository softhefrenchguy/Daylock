package com.example.daylock

import org.junit.Assert.*
import org.junit.Test
import java.time.ZoneId
import java.time.ZonedDateTime

class NotificationPolicyTest {
    private val zone = ZoneId.of("Europe/London")
    private val channels = setOf("plan", "commitments", "freedom", "focus")
    private fun time(text: String, z: ZoneId = zone) = java.time.LocalDateTime.parse(text).atZone(z).toInstant().toEpochMilli()
    private fun task(name: String = "Walk", outcome: String = "incomplete", deadline: Long? = null) =
        ReminderTask(name, outcome, if (deadline == null) null else 45, deadline)
    private fun snapshot(tasks: List<ReminderTask> = listOf(task()), committed: Boolean = false,
        prefs: ReminderPreferences = ReminderPreferences(true, true, true, true, 1200, 840),
        enabled: Boolean = true, date: String = "2026-10-14") = ReminderSnapshot(prefs, enabled, 18, 0,
        ReminderPlan(date, true, tasks), ReminderPlan(nextPlanDate(date), committed, listOf(task("Tomorrow"))))
    private fun eval(s: ReminderSnapshot, clock: String = "2026-10-14T20:00:00",
        seen: Set<String> = emptySet(), allowed: Set<String> = channels) =
        NotificationPolicy.evaluate(s, true, seen, time(clock), zone, allowed)
    private fun messages(e: ReminderEvaluation) = e.decisions.mapNotNull { it.message }
    private fun consumed(e: ReminderEvaluation) = e.decisions.flatMap { it.keys }.toSet()

    @Test fun planOnlyWhenTomorrowIsNotCommitted() {
        assertTrue(messages(eval(snapshot())).any { it.category == "plan" })
        assertFalse(messages(eval(snapshot(committed = true))).any { it.category == "plan" })
        assertFalse(messages(eval(snapshot(), "2026-10-14T19:59:59")).any { it.category == "plan" })
    }
    @Test fun reminderCountsOnlyUnfinishedEligibleTasks() {
        val result = eval(snapshot(listOf(task(), task("Done", "completed"), task("Excused", "excused"))), "2026-10-14T14:00:00")
        assertEquals("You have 1 commitment left to complete today.", messages(result).single().body)
        val plural = messages(eval(snapshot(listOf(task(), task("Other"))), "2026-10-14T14:00:00")).single()
        assertTrue(plural.body.contains("2 commitments"))
    }
    @Test fun emptyCompletedAndAllExcusedDaysHaveNoCommitmentReminder() {
        for (tasks in listOf(emptyList(), listOf(task(outcome = "completed")), listOf(task(outcome = "excused")))) {
            assertTrue(messages(eval(snapshot(tasks), "2026-10-14T14:00:00")).isEmpty())
        }
    }
    @Test fun everyToggleIndependentlySuppressesItsCategory() {
        val original = snapshot(listOf(task(deadline = time("2026-10-14T19:00:00"))))
        val p = original.preferences
        val variants = mapOf("plan" to p.copy(plan = false), "commitments" to p.copy(commitments = false),
            "freedom" to p.copy(freedom = false), "focus" to p.copy(focus = false))
        for ((category, prefs) in variants) {
            assertFalse(messages(eval(original.copy(preferences = prefs))).any { it.category == category })
        }
        assertTrue(messages(eval(original.copy(preferences = p.copy(plan = false, commitments = false, freedom = false, focus = false)))).isEmpty())
        assertNull(eval(original.copy(preferences = p.copy(plan = false, commitments = false, freedom = false, focus = false))).nextAlarmMs)
    }
    @Test fun timeChangeReplacesTheNextAlarm() {
        val p = ReminderPreferences(true, false, false, false, 1200, 840)
        assertEquals(time("2026-10-14T20:00:00"), eval(snapshot(prefs = p), "2026-10-14T13:00:00").nextAlarmMs)
        assertEquals(time("2026-10-14T21:15:00"), eval(snapshot(prefs = p.copy(planMinute = 1275)), "2026-10-14T13:00:00").nextAlarmMs)
        assertEquals(time("2026-10-14T15:30:00"), eval(snapshot(prefs = p.copy(plan = false, commitments = true, commitmentMinute = 930)), "2026-10-14T13:00:00").nextAlarmMs)
    }
    @Test fun freedomControlOffSuppressesFreedomEvenWithNotificationPreferenceOn() {
        assertFalse(messages(eval(snapshot(enabled = false))).any { it.category == "freedom" })
    }
    @Test fun freedomEarnedAtTimeAndOnlyOnceAfterLaterTransitions() {
        val incomplete = snapshot(committed = true)
        val first = eval(incomplete, "2026-10-14T18:00:00")
        assertEquals("Freedom Time is here", messages(first).last().title)
        val earned = incomplete.copy(today = incomplete.today.copy(tasks = listOf(task(outcome = "completed"))))
        val later = eval(earned, "2026-10-14T18:30:00", consumed(first))
        assertEquals("Freedom earned", messages(later).single().title)
        val seen = consumed(first) + consumed(later)
        assertTrue(messages(eval(incomplete, "2026-10-14T19:00:00", seen)).isEmpty())
        assertTrue(messages(eval(earned, "2026-10-14T19:30:00", seen)).isEmpty())
        assertFalse(messages(later).single().body.contains("Instagram"))
        assertEquals("Freedom earned", messages(eval(earned, "2026-10-14T18:00:00")).last().title)
    }
    @Test fun noEligibleCommitmentsNeverEarnFreedom() {
        for (tasks in listOf(emptyList(), listOf(task(outcome = "excused")))) {
            val freedom = messages(eval(snapshot(tasks, committed = true), "2026-10-14T18:00:00")).single()
            assertEquals("Freedom Time is here", freedom.title)
            assertTrue(freedom.body.contains("no eligible"))
        }
        val result = messages(eval(snapshot(listOf(task(outcome = "completed"), task("Ex", "excused")), committed = true), "2026-10-14T18:00:00"))
        assertEquals("Freedom earned", result.single().title)
    }
    @Test fun freedomExplainsTheActualMissingCondition() {
        val body = messages(eval(snapshot(listOf(task(outcome = "completed"))), "2026-10-14T18:00:00")).single().body
        assertEquals("Commit tomorrow's plan to earn Freedom.", body)
    }
    @Test fun dueFocusCompletesCountsAndCanEarnFreedomInTheBackground() {
        val s = snapshot(listOf(task("Study maths", deadline = time("2026-10-14T18:45:00"))), committed = true)
        val first = eval(s, "2026-10-14T18:00:00")
        assertEquals(time("2026-10-14T18:45:00"), first.nextAlarmMs)
        val due = eval(s, "2026-10-14T18:45:00", consumed(first))
        assertEquals(setOf("Freedom earned", "Focus complete"), messages(due).map { it.title }.toSet())
        assertTrue(messages(due).last().body.contains("45-minute minimum for Study maths"))
        assertTrue(messages(eval(s, "2026-10-14T18:46:00", consumed(first) + consumed(due))).isEmpty())
    }
    @Test fun focusDisabledStillSchedulesFreedomTransitionAtItsExistingDeadline() {
        val s = snapshot(listOf(task(deadline = time("2026-10-14T18:45:00"))), committed = true)
        val disabled = s.copy(preferences = s.preferences.copy(focus = false))
        val first = eval(disabled, "2026-10-14T18:00:00")
        assertEquals(time("2026-10-14T18:45:00"), first.nextAlarmMs)
        val due = messages(eval(disabled, "2026-10-14T18:45:00", consumed(first)))
        assertEquals(listOf("Freedom earned"), due.map { it.title })
    }
    @Test fun pauseResumeResetExcuseAndEarlyCompletionCancelOldDeadline() {
        val prefs = ReminderPreferences(false, false, false, true, 1200, 840)
        val s = snapshot(listOf(task(deadline = time("2026-10-14T13:45:00"))), prefs = prefs)
        assertEquals(time("2026-10-14T13:45:00"), eval(s, "2026-10-14T13:00:00").nextAlarmMs)
        for (outcome in listOf("incomplete", "excused", "completed")) {
            val stopped = s.copy(today = s.today.copy(tasks = listOf(ReminderTask("Walk", outcome, 45, null))))
            assertNull(eval(stopped, "2026-10-14T13:00:00").nextAlarmMs)
            assertTrue(messages(eval(stopped)).isEmpty())
        }
        val resumed = s.copy(today = s.today.copy(tasks = listOf(task(deadline = time("2026-10-14T14:15:00")))))
        assertTrue(messages(eval(resumed, "2026-10-14T13:45:00")).isEmpty())
        assertEquals(time("2026-10-14T14:15:00"), eval(resumed, "2026-10-14T13:45:00").nextAlarmMs)
    }
    @Test fun uiSettlementRetainsOnlyGenuinelyDueFocus() {
        val deadline = time("2026-10-14T13:45:00")
        val running = snapshot(listOf(task(deadline = deadline)))
        val completed = running.copy(today = running.today.copy(tasks = listOf(ReminderTask("Walk", "completed", 45, null))))
        assertNull(completed.retainingDueFocus(running, deadline - 1).today.tasks.single().deadlineMs)
        val settled = completed.retainingDueFocus(running, deadline)
        assertEquals(deadline, settled.today.tasks.single().deadlineMs)
        assertEquals("Focus complete", messages(eval(settled, "2026-10-14T13:45:00")).single().title)
    }
    @Test fun midnightPromotesOnlyActualTomorrowAndNeverUsesHistory() {
        val s = snapshot(listOf(task(deadline = time("2026-10-14T23:59:00"))))
        val after = messages(eval(s, "2026-10-15T14:00:00"))
        assertEquals(1, after.size)
        assertEquals("commitments", after.single().category)
        assertFalse(messages(eval(s, "2026-10-16T14:00:00")).any { it.category == "commitments" })
        assertFalse(messages(eval(s, "2026-10-15T20:00:00")).any { it.category == "focus" })
    }
    @Test fun disablingFocusCannotRetainAnAlreadyCompletedAlertForLaterEnable() {
        val deadline = time("2026-10-14T13:45:00")
        val running = snapshot(listOf(task(deadline = deadline)))
        val completed = running.copy(today = running.today.copy(tasks = listOf(ReminderTask("Walk", "completed", 45, null))))
        val off = completed.copy(preferences = completed.preferences.copy(focus = false)).retainingDueFocus(running, deadline)
        assertNull(off.today.tasks.single().deadlineMs)
        val onAgain = completed.retainingDueFocus(off, deadline + 60000)
        assertNull(onAgain.today.tasks.single().deadlineMs)
    }
    @Test fun reminderSuppressionConsumesTheDailySlotAndPreventsDuplicates() {
        val s = snapshot(listOf(task(outcome = "completed")), committed = true)
        val first = eval(s)
        assertTrue(consumed(first).contains("2026-10-14|plan"))
        assertTrue(consumed(first).contains("2026-10-14|commitments"))
        assertTrue(messages(eval(s, seen = consumed(first))).isEmpty())
    }
    @Test fun deniedPermissionAndBlockedCategoriesDoNotScheduleOrDeliver() {
        val s = snapshot()
        assertEquals(ReminderEvaluation(emptyList(), null), eval(s, allowed = emptySet()))
        assertEquals(setOf("plan"), messages(eval(s, allowed = setOf("plan"))).map { it.category }.toSet())
        assertEquals(ReminderEvaluation(emptyList(), null), NotificationPolicy.evaluate(s, false, emptySet(), time("2026-10-14T20:00:00"), zone, channels))
    }
    @Test fun localWallTimeIsRecalculatedWhenTimezoneChanges() {
        val p = ReminderPreferences(true, false, false, false, 1200, 840)
        val s = snapshot(prefs = p)
        val now = time("2026-10-14T12:00:00")
        val london = NotificationPolicy.evaluate(s, true, emptySet(), now, zone, channels).nextAlarmMs
        val newYork = NotificationPolicy.evaluate(s, true, emptySet(), now, ZoneId.of("America/New_York"), channels).nextAlarmMs
        assertEquals(5 * 3600000L, newYork!! - london!!)
    }
    @Test fun dstSpringGapShiftsForwardAndAutumnOverlapDoesNotDuplicate() {
        val p = ReminderPreferences(true, false, false, false, 90, 840)
        val spring = snapshot(prefs = p, date = "2026-03-29")
        val result = eval(spring, "2026-03-29T00:15:00")
        val local = InstantHelper.local(result.nextAlarmMs!!, zone)
        assertEquals(2, local.hour)
        assertEquals(30, local.minute)
        val fall = snapshot(prefs = p, date = "2026-10-25")
        val firstTime = ZonedDateTime.parse("2026-10-25T01:30:00+01:00[Europe/London]").toInstant().toEpochMilli()
        val first = NotificationPolicy.evaluate(fall, true, emptySet(), firstTime, zone, channels)
        val second = NotificationPolicy.evaluate(fall, true, consumed(first), firstTime + 3600000, zone, channels)
        assertEquals(1, messages(first).size)
        assertTrue(messages(second).isEmpty())
    }
    @Test fun backwardClockCannotRepeatADeliveredReminder() {
        val s = snapshot()
        val first = eval(s)
        assertFalse(messages(eval(s, "2026-10-14T19:00:00", consumed(first))).any { it.category == "plan" })
        assertTrue(messages(eval(s, seen = consumed(first))).isEmpty())
    }
    @Test fun rebootReloadsStateDeduplicationAndFutureScheduling() {
        var disk: String? = null
        val repository = ReminderRepository({ disk }, { disk = it; true })
        val s = snapshot()
        repository.publish(s, time("2026-10-14T13:00:00"))
        val before = eval(s, "2026-10-14T14:00:00")
        repository.consume(consumed(before), "2026-10-14")
        val rebooted = ReminderRepository({ disk }, { disk = it; true }).load()
        assertTrue(rebooted.valid)
        val after = NotificationPolicy.evaluate(rebooted.snapshot, rebooted.valid, rebooted.seen, time("2026-10-14T14:01:00"), zone, channels)
        assertTrue(messages(after).isEmpty())
        assertEquals(time("2026-10-14T18:00:00"), after.nextAlarmMs)
    }
    @Test fun crashDuringPlannerSaveRemainsInvalidAfterRebootAndCanRecover() {
        var disk: String? = null
        var writable = true
        val r = ReminderRepository({ disk }, { if (writable) disk = it; writable })
        r.publish(snapshot(), time("2026-10-14T13:00:00"))
        r.invalidate()
        assertFalse(ReminderRepository({ disk }, { true }).load().valid)
        writable = false
        assertThrows(IllegalStateException::class.java) { r.publish(snapshot(), time("2026-10-14T20:00:00")) }
        assertFalse(ReminderRepository({ disk }, { true }).load().valid)
        writable = true
        r.publish(snapshot(committed = true), time("2026-10-14T20:00:00"))
        assertTrue(r.load().valid)
        assertFalse(messages(eval(r.load().snapshot!!)).any { it.category == "plan" })
    }
    @Test fun codecPreservesEverythingNeededForBackgroundFocusAndRejectsCorruption() {
        val s = snapshot(listOf(task(deadline = time("2026-10-14T18:45:00"))))
        assertEquals(s, ReminderCodec.snapshot(ReminderCodec.encode(s)))
        assertFalse(ReminderRepository({ "broken" }, { true }).load().valid)
        assertThrows(IllegalArgumentException::class.java) { ReminderPreferences(true, true, true, true, 1440, 840) }
    }
    @Test fun tapPayloadRoutesPlanAndDatedFocusWithoutAnyPlannerMutation() {
        val plan = messages(eval(snapshot())).first { it.category == "plan" }
        assertEquals("plan", org.json.JSONObject(plan.payload()).getString("screen"))
        val focus = ReminderMessage("focus", "Focus complete", "Done", "2026-10-14", 2, "Study")
        val payload = org.json.JSONObject(focus.payload())
        assertEquals("today", payload.getString("screen"))
        assertEquals(2, payload.getInt("taskIndex"))
        assertEquals("Study", payload.getString("taskName"))
    }
}

private object InstantHelper {
    fun local(ms: Long, zone: ZoneId) = java.time.Instant.ofEpochMilli(ms).atZone(zone)
}
