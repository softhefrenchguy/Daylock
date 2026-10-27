package com.example.daylock

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class NativeFreedomRepositoryTest {
    private val clock = DetectionClock(1_800_000_000_000L, 100_000L, 7, "2026-10-13", "Asia/Qatar", 10_800_000, 18 * 60)
    private val state = NativeFreedomState(clock.date, true, 18, 0, 3, 2, true, false,
        tomorrowPlan = NativePlanSummary("2026-10-14", 2, 0))
    private var disk: String? = null
    private var choice = true
    private var fail = false
    private fun repository(legacy: Boolean = false) = NativeFreedomRepository(
        read = { disk }, write = { value, blocking -> if (fail) false else { disk = value; choice = blocking; true } },
        legacyBlocking = { choice }, hasLegacySnapshot = { legacy },
    )
    private fun saved(value: NativeFreedomState = state): NativeFreedomRepository {
        val result = repository()
        assertTrue(result.publish(value, 0))
        return result
    }
    @Test fun roundTripPreservesInputsRevisionControlsAndNoEarnedBoolean() {
        val record = NativeFreedomRecord(7, true, state, "synchronised")
        val json = NativeFreedomCodec.encode(record)
        assertEquals(record, NativeFreedomCodec.decode(json))
        assertFalse(JSONObject(json).has("earned"))
        assertFalse(json.contains("captured"))
        assertFalse(json.contains("wallMs"))
    }
    @Test fun persistedStateBlocksImmediatelyAndAfterFiveThirtyAnd120Minutes() {
        saved()
        for (minutes in listOf(0L, 5L, 30L, 120L)) {
            val freshService = repository()
            val now = clock.copy(wallMs = clock.wallMs + minutes * 60000)
            assertEquals(InstagramRestriction.BLOCK, InstagramBlockingPolicy.decide(
                freshService.record().blockingEnabled, true, freshService.eligibility(now)))
        }
    }
    @Test fun earnedStateSurvivesServiceRestartAndRebootButUsesCurrentTime() {
        saved(state.copy(completedCount = 3))
        assertEquals("earned", repository().eligibility(clock.copy(bootCount = 8, elapsedMs = 0)).state)
        assertEquals("notEarned", repository().eligibility(clock.copy(minuteOfDay = 17 * 60)).state)
    }
    @Test fun midnightReconcilesFromPersistedTomorrowAndNeverChangesDiskHistory() {
        saved(state.copy(completedCount = 3))
        val previous = disk
        val result = repository().eligibility(clock.copy(date = "2026-10-14"))
        assertEquals("rollover_reconciled", result.reason)
        assertEquals(2, result.conditions!!.eligibleCount)
        assertEquals(0, result.conditions.completedCount)
        assertFalse(result.conditions.tomorrowCommitted)
        assertEquals(previous, disk)
        assertEquals("unknown", repository().eligibility(clock.copy(date = "2026-10-15")).state)
    }
    @Test fun missingAndCorruptRecordsNeverClaimEarnedAndAllowDisabling() {
        for (raw in listOf(null, "{broken", "{}", """{"version":99}""")) {
            disk = raw
            choice = true
            val result = repository()
            assertEquals("unknown", result.eligibility(clock).state)
            assertTrue(result.record().blockingEnabled)
            assertTrue(result.setBlocking(false))
            assertFalse(repository().record().blockingEnabled)
        }
    }
    @Test fun legacyExpiringCacheRequiresOneRefreshWithoutChangingBlockingChoice() {
        val result = repository(legacy = true)
        assertEquals("upgrade_refresh_required", result.eligibility(clock).reason)
        assertTrue(result.record().blockingEnabled)
        assertTrue(result.publish(state, 0))
        assertEquals("notEarned", repository().eligibility(clock).state)
    }
    @Test fun malformedCountsDatesBooleansAndRevisionCannotBecomeValidState() {
        val original = NativeFreedomCodec.encode(NativeFreedomRecord(1, true, state))
        val invalid = listOf(
            JSONObject(original).put("revision", -1),
            JSONObject(original).put("revision", 1.5),
            JSONObject(original).put("blockingEnabled", "true"),
            JSONObject(original).apply { getJSONObject("freedom").put("completedCount", 4) },
            JSONObject(original).apply { getJSONObject("freedom").put("hour", 24) },
            JSONObject(original).apply { getJSONObject("freedom").put("date", "2026-02-30") },
        )
        for (value in invalid) {
            disk = value.toString()
            assertEquals("invalid_snapshot", repository().eligibility(clock).reason)
        }
    }
    @Test fun invalidationIsDurableUntilSuccessfulPlannerPublication() {
        val result = saved(state.copy(completedCount = 3))
        assertTrue(result.invalidate("planner_refresh_required"))
        assertEquals(2, result.record().revision)
        assertEquals("unknown", repository().eligibility(clock).state)
        assertTrue(result.publish(state, 2))
        assertEquals(3, repository().record().revision)
        assertEquals("notEarned", repository().eligibility(clock).state)
    }
    @Test fun stalePublicationCannotOverwriteNewerBlockingOrPlanSettings() {
        val result = saved()
        val stale = result.record().revision
        assertTrue(result.setBlocking(false))
        val previous = disk
        try { result.publish(state.copy(completedCount = 3), stale); fail("Stale publish accepted") }
        catch (_: NativeRevisionConflict) { }
        assertEquals(previous, disk)
        assertFalse(result.record().blockingEnabled)
    }
    @Test fun blockingSettingsRevisionAndFreedomInputsAreWrittenTogether() {
        val result = saved()
        assertTrue(result.setBlocking(false))
        val record = NativeFreedomCodec.decode(disk!!)
        assertEquals(2, record.revision)
        assertFalse(record.blockingEnabled)
        assertEquals(state, record.freedom)
        assertTrue(result.setBlocking(true))
        assertEquals(3, repository().record().revision)
    }
    @Test fun freedomSettingsAndOutcomeUpdatesReplaceTheWholeRecord() {
        val result = saved()
        assertTrue(result.publish(state.copy(enabled = false), 1))
        assertEquals("disabled", repository().eligibility(clock).state)
        assertTrue(result.publish(state.copy(completedCount = 3, hour = 19), 2))
        assertEquals("notEarned", repository().eligibility(clock).state)
        assertTrue(result.publish(state.copy(eligibleCount = 2, completedCount = 2), 3))
        assertEquals("earned", repository().eligibility(clock).state)
        assertTrue(result.publish(state.copy(eligibleCount = 2, completedCount = 1), 4))
        assertEquals("notEarned", repository().eligibility(clock).state)
    }
    @Test fun failedWriteDoesNotPublishUnsavedRevisionOrChangeDisk() {
        val result = saved()
        val previous = disk
        fail = true
        assertFalse(result.publish(state.copy(completedCount = 3), 1))
        assertEquals(previous, disk)
        assertEquals(1, result.record().revision)
        assertEquals("save_failed", result.eligibility(clock).reason)
        fail = false
        assertTrue(result.publish(state.copy(completedCount = 3), 1))
        assertEquals("earned", repository().eligibility(clock).state)
    }
    @Test fun longRunningFocusDeadlineAndExcusesRoundTripAcrossRestarts() {
        val due = clock.wallMs + 60 * 60000
        val result = saved(state.copy(runningFocus = true, focusCompletesAtMs = due))
        assertEquals("notEarned", repository().eligibility(clock).state)
        assertEquals("notEarned", repository().eligibility(clock.copy(wallMs = due)).state)
        assertTrue(result.publish(state.copy(eligibleCount = 2, completedCount = 2), 1))
        assertNull(repository().record().freedom!!.focusCompletesAtMs)
        assertEquals("earned", repository().eligibility(clock).state)
    }
}
