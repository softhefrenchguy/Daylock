package com.example.daylock

import org.junit.Assert.*
import org.junit.Test

class DetectionPolicyTest {
    private val clock = DetectionClock(1_800_000_000_000L, 100_000L, 7, "2026-10-13", "Asia/Qatar", 10_800_000, 18 * 60)
    private val state = NativeFreedomState(clock.date, true, 18, 0, 3, 3, true, false)
    private fun evaluate(value: NativeFreedomState? = state, now: DetectionClock = clock) = DetectionPolicy.evaluate(value, now)

    @Test fun completedCurrentDayEarns() { assertEquals("earned", evaluate().state) }
    @Test fun noElapsedTimeoutForEarnedOrIncompleteState() {
        for (minutes in listOf(0L, 5L, 30L, 120L)) {
            val later = clock.copy(wallMs = clock.wallMs + minutes * 60000, elapsedMs = clock.elapsedMs + minutes * 60000)
            assertEquals("earned", evaluate(now = later).state)
            assertEquals("notEarned", evaluate(state.copy(completedCount = 2), later).state)
        }
    }
    @Test fun missingIsUnknown() { assertEquals("unknown", evaluate(null).state) }
    @Test fun disabledControlRemainsAllowedAfterDateChanges() {
        assertEquals("disabled", evaluate(state.copy(enabled = false), clock.copy(date = "2026-11-01")).state)
    }
    @Test fun unfinishedCommitmentsAndUncommittedTomorrowDoNotEarn() {
        assertEquals("notEarned", evaluate(state.copy(completedCount = 2)).state)
        assertEquals("notEarned", evaluate(state.copy(tomorrowCommitted = false)).state)
    }
    @Test fun emptyAndAllExcusedAreNeutralNotAutomaticFreedom() {
        val result = evaluate(state.copy(eligibleCount = 0, completedCount = 0))
        assertEquals("notEarned", result.state)
        assertEquals("no_eligible_commitments", result.reason)
        assertFalse(result.conditions!!.commitmentsCompleted)
    }
    @Test fun excusesAreExcludedNotAddedToCompletedCount() {
        assertEquals("earned", evaluate(state.copy(eligibleCount = 2, completedCount = 2)).state)
        assertEquals("notEarned", evaluate(state.copy(eligibleCount = 2, completedCount = 1)).state)
    }
    @Test fun timeThresholdIsInclusiveAndUsesCurrentClockWithoutFlutter() {
        assertEquals("notEarned", evaluate(now = clock.copy(minuteOfDay = 17 * 60 + 59)).state)
        assertEquals("earned", evaluate(now = clock.copy(minuteOfDay = 18 * 60)).state)
    }
    @Test fun currentTimezoneAndDstMinuteReplaceCaptureTime() {
        assertEquals("notEarned", evaluate(now = clock.copy(zoneId = "Europe/London", minuteOfDay = 16 * 60)).state)
        assertEquals("earned", evaluate(now = clock.copy(zoneOffsetMs = 14_400_000, minuteOfDay = 19 * 60)).state)
    }
    @Test fun clockGoingBackReevaluatesTimeWithoutDiscardingCounts() {
        assertEquals("notEarned", evaluate(now = clock.copy(wallMs = clock.wallMs - 3_600_000, minuteOfDay = 17 * 60)).state)
    }
    @Test fun rebootAndUnknownBootCountDoNotInvalidateDurableDatedInputs() {
        for (boot in listOf(8, -1)) assertEquals("earned", evaluate(now = clock.copy(bootCount = boot, elapsedMs = 0)).state)
    }
    @Test fun yesterdayCannotUnlockNewDateWithoutReconciliation() {
        assertEquals("date_changed", evaluate(now = clock.copy(date = "2026-10-14", minuteOfDay = 0)).reason)
    }
    @Test fun midnightUsesSavedTomorrowNotYesterdayAndRequiresNextDayCommitment() {
        val value = state.copy(tomorrowPlan = NativePlanSummary("2026-10-14", 2, 0))
        val result = evaluate(value, clock.copy(date = "2026-10-14", minuteOfDay = 18 * 60))
        assertEquals("notEarned", result.state)
        assertEquals("rollover_reconciled", result.reason)
        assertEquals("2026-10-14", result.planDate)
        assertEquals(0, result.conditions!!.completedCount)
        assertEquals(2, result.conditions.eligibleCount)
        assertFalse(result.conditions.tomorrowCommitted)
        assertEquals("2026-10-13", value.date)
    }
    @Test fun uncommittedEmptyTomorrowRepresentsNewDayWithoutInventingWork() {
        val result = evaluate(state.copy(tomorrowCommitted = false,
            tomorrowPlan = NativePlanSummary("2026-10-14", 0, 0)), clock.copy(date = "2026-10-14"))
        assertEquals("notEarned", result.state)
        assertEquals(0, result.conditions!!.eligibleCount)
        assertFalse(result.conditions.commitmentsCompleted)
    }
    @Test fun missedDaysAndTimezoneMovingToUnrepresentedDateRequireRecovery() {
        val value = state.copy(tomorrowPlan = NativePlanSummary("2026-10-14", 2, 0))
        for (date in listOf("2026-10-12", "2026-10-15", "2027-01-01")) {
            assertEquals("unknown", evaluate(value, clock.copy(date = date)).state)
        }
    }
    @Test fun monthYearLeapDayTransitionsAreCalendarBased() {
        for ((date, next) in listOf("2026-10-31" to "2026-11-01", "2026-12-31" to "2027-01-01",
            "2028-02-28" to "2028-02-29", "2028-02-29" to "2028-03-01")) {
            assertEquals(next, nextPlanDate(date))
            val value = state.copy(date = date, tomorrowPlan = NativePlanSummary(next, 1, 0))
            assertEquals(next, evaluate(value, clock.copy(date = next)).planDate)
        }
    }
    @Test fun longFocusCompletesWithoutFlutterAndNeverDoubleCounts() {
        val value = state.copy(completedCount = 2, runningFocus = true, focusCompletesAtMs = clock.wallMs + 120 * 60000)
        assertEquals("notEarned", evaluate(value).state)
        val due = clock.copy(wallMs = value.focusCompletesAtMs!!)
        repeat(10) { assertEquals("notEarned", evaluate(value, due).state) }
        assertEquals(2, value.completedCount)
        assertEquals("notEarned", evaluate(value, due.copy(wallMs = due.wallMs - 1)).state)
    }
    @Test fun priorDaysRunningFocusNeverLeaksIntoNextPlan() {
        val value = state.copy(completedCount = 2, runningFocus = true, focusCompletesAtMs = clock.wallMs + 1000,
            tomorrowPlan = NativePlanSummary("2026-10-14", 1, 0))
        val result = evaluate(value, clock.copy(wallMs = clock.wallMs + 86400000, date = "2026-10-14"))
        assertEquals(0, result.conditions!!.completedCount)
    }
    @Test fun focusMissingDeadlineHasExplicitRecovery() {
        assertEquals("conditions_remaining", evaluate(state.copy(completedCount = 2, runningFocus = true)).reason)
    }
    @Test fun invalidCountsTimesDatesAndUnrelatedTomorrowAreRejected() {
        for (create in listOf<() -> NativeFreedomState>(
            { state.copy(completedCount = 4) }, { state.copy(eligibleCount = -1) },
            { state.copy(hour = 24) }, { state.copy(minute = 60) }, { state.copy(date = "2026-02-30") },
            { state.copy(tomorrowPlan = NativePlanSummary("2026-10-15", 1, 0)) },
        )) try { create(); fail("Invalid state accepted") } catch (_: IllegalArgumentException) { }
    }
    @Test fun InstagramWindowEventIsAccepted() {
        assertTrue(InstagramEventGate().accept("com.instagram.android", 32, 0, setOf("com.instagram.android")))
    }
    @Test fun unrelatedPackagesAndEventTypesAreIgnored() {
        val gate = InstagramEventGate()
        assertFalse(gate.accept("com.example.daylock", 32, 0, setOf("com.instagram.android")))
        assertFalse(gate.accept("com.instagram.android", 2048, 0, setOf("com.instagram.android")))
        assertFalse(gate.accept(null, 32, 0, setOf("com.instagram.android")))
        assertTrue(gate.accept("com.instagram.android", 32, 0, setOf("com.instagram.android")))
    }
    @Test fun repeatedBurstIsCoalescedAndLaterOpeningIsAccepted() {
        val gate = InstagramEventGate()
        assertTrue(gate.accept("com.instagram.android", 32, 1000, setOf("com.instagram.android")))
        for (now in listOf(1000L, 1100L, 2000L, 3999L)) assertFalse(gate.accept("com.instagram.android", 32, now, setOf("com.instagram.android")))
        assertTrue(gate.accept("com.instagram.android", 32, 4000, setOf("com.instagram.android")))
    }
    @Test fun restartedServiceHasAnIndependentGate() {
        assertTrue(InstagramEventGate().accept("com.instagram.android", 32, 1000, setOf("com.instagram.android")))
        assertTrue(InstagramEventGate().accept("com.instagram.android", 32, 1100, setOf("com.instagram.android")))
    }
    @Test fun recoveryPromptDoesNotRepeatForSameUnknownState() {
        val gate = InstagramRecoveryGate()
        assertTrue(gate.offer(10, clock.date, "date_changed"))
        repeat(100) { assertFalse(gate.offer(10, clock.date, "date_changed")) }
        assertTrue(gate.offer(11, clock.date, "date_changed"))
        assertTrue(gate.offer(11, "2026-10-14", "date_changed"))
    }
}
