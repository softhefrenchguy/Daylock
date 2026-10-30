package com.sofien.daylock

import org.junit.Assert.*
import org.junit.Test

class InstagramBlockingPolicyTest {
    private val clock = DetectionClock(1_800_000_000_000L, 100_000L, 7, "2026-10-13", "Asia/Qatar", 10_800_000, 18 * 60)
    private val snapshot = NativeFreedomState(clock.date, true, 18, 0, 3, 2, true, false)
    private fun decide(value: NativeFreedomState? = snapshot, now: DetectionClock = clock,
        enabled: Boolean = true, permission: Boolean = true) = InstagramBlockingPolicy.decide(enabled, permission, DetectionPolicy.evaluate(value, now))

    @Test fun freshIncompleteCommitmentsBlock() { assertEquals(InstagramRestriction.BLOCK, decide()) }
    @Test fun earnedFreedomAllows() { assertEquals(InstagramRestriction.ALLOW, decide(snapshot.copy(completedCount = 3))) }
    @Test fun freedomControlOffAllows() { assertEquals(InstagramRestriction.ALLOW, decide(snapshot.copy(enabled = false))) }
    @Test fun blockingOffAlwaysAllowsEvenWithMissingState() {
        assertEquals(InstagramRestriction.ALLOW, decide(enabled = false))
        assertEquals(InstagramRestriction.ALLOW, decide(null, enabled = false))
    }
    @Test fun permissionDisabledOrRevokedNeverNavigates() {
        assertEquals(InstagramRestriction.ALLOW, decide(permission = false))
        assertEquals(InstagramRestriction.ALLOW, decide(null, permission = false))
    }
    @Test fun missingStateRecoversWithoutBlocking() { assertEquals(InstagramRestriction.RECOVER, decide(null)) }
    @Test fun fiveMinutesDoesNotRemoveValidRestriction() {
        val later = clock.copy(wallMs = clock.wallMs + 300_000, elapsedMs = clock.elapsedMs + 300_000)
        assertEquals(InstagramRestriction.BLOCK, decide(now = later))
    }
    @Test fun localMidnightRecoversUntilRolloverSync() { assertEquals(InstagramRestriction.RECOVER, decide(now = clock.copy(date = "2026-10-14"))) }
    @Test fun timezoneChangeUsesCurrentLocalTime() { assertEquals(InstagramRestriction.BLOCK, decide(now = clock.copy(zoneId = "Europe/London", minuteOfDay = 17 * 60))) }
    @Test fun rebootRecoversButRetainsTheOptInChoice() { assertEquals(InstagramRestriction.BLOCK, decide(now = clock.copy(bootCount = 8))) }
    @Test fun uncommittedTomorrowBlocks() { assertEquals(InstagramRestriction.BLOCK, decide(snapshot.copy(completedCount = 3, tomorrowCommitted = false))) }
    @Test fun timeIsReevaluatedNotPermanentlyEarned() {
        val complete = snapshot.copy(completedCount = 3)
        assertEquals(InstagramRestriction.BLOCK, decide(complete, clock.copy(minuteOfDay = 17 * 60 + 59)))
        assertEquals(InstagramRestriction.ALLOW, decide(complete, clock.copy(minuteOfDay = 18 * 60)))
    }
    @Test fun emptyAndAllExcusedRemainNotEarned() {
        assertEquals(InstagramRestriction.BLOCK, decide(snapshot.copy(eligibleCount = 0, completedCount = 0)))
        val conditions = DetectionPolicy.evaluate(snapshot.copy(eligibleCount = 0, completedCount = 0), clock).conditions!!
        assertFalse(conditions.commitmentsCompleted)
    }
    @Test fun excusesAreExcludedWithoutBeingCompleted() {
        assertEquals(InstagramRestriction.ALLOW, decide(snapshot.copy(eligibleCount = 3, completedCount = 3)))
        assertEquals(InstagramRestriction.BLOCK, decide(snapshot.copy(eligibleCount = 3, completedCount = 2)))
    }
    @Test fun runningStopwatchRemainsBlockedUntilManuallyCompleted() { assertEquals(InstagramRestriction.BLOCK, decide(snapshot.copy(runningFocus = true))) }
    @Test fun focusDeadlineBlocksBeforeMinimumAndAllowsAtMinimumWithoutFlutterUi() {
        val value = snapshot.copy(runningFocus = true, focusCompletesAtMs = clock.wallMs + 60_000)
        assertEquals(InstagramRestriction.BLOCK, decide(value))
        val due = clock.copy(wallMs = clock.wallMs + 60_000, elapsedMs = clock.elapsedMs + 60_000)
        assertEquals(InstagramRestriction.BLOCK, decide(value, due))
        repeat(10) { assertEquals(2, DetectionPolicy.evaluate(value, due).conditions!!.completedCount) }
        assertEquals(2, value.completedCount)
    }
    @Test fun focusCompletionCannotOverrideOtherIncompleteCommitments() {
        val value = snapshot.copy(completedCount = 1, runningFocus = true, focusCompletesAtMs = clock.wallMs)
        assertEquals(InstagramRestriction.BLOCK, decide(value))
    }
    @Test fun lockConditionsExposeEachRemainingRule() {
        val value = DetectionPolicy.evaluate(snapshot.copy(tomorrowCommitted = false), clock.copy(minuteOfDay = 17 * 60))
        val conditions = value.conditions!!
        assertFalse(conditions.timeReached)
        assertFalse(conditions.commitmentsCompleted)
        assertFalse(conditions.tomorrowCommitted)
        assertEquals(2, conditions.completedCount)
        assertEquals(3, conditions.eligibleCount)
        assertEquals(18, conditions.hour)
        assertNull(DetectionPolicy.evaluate(null, clock).conditions)
    }
    @Test fun focusSchedulesAnExactVisibleScreenUpdateWithoutExpiry() {
        assertNull(DetectionPolicy.evaluate(snapshot, clock).nextChangeInMs)
        assertNull(DetectionPolicy.evaluate(snapshot.copy(runningFocus = true,
            focusCompletesAtMs = clock.wallMs + 500), clock).nextChangeInMs)
    }
    @Test fun fullWindowRequiredAndPaneEventsAreNotForegroundChanges() {
        assertTrue(InstagramBlockingPolicy.isForegroundWindow(true, 0))
        assertFalse(InstagramBlockingPolicy.isForegroundWindow(false, 0))
        for (pane in listOf(8, 16, 32)) assertFalse(InstagramBlockingPolicy.isForegroundWindow(true, pane))
    }
    @Test fun repeatedTargetEventsDoNotCreateNewForegroundSessions() {
        val scope = InstagramForegroundGuard()
        scope.observe("com.instagram.android")
        val token = scope.token()
        repeat(100) { scope.observe("com.instagram.android") }
        assertTrue(scope.matches(token))
    }
    @Test fun switchingToAnyOtherApplicationCancelsPendingNavigation() {
        val scope = InstagramForegroundGuard()
        scope.observe("com.instagram.android")
        val token = scope.token()
        scope.observe(null)
        assertFalse(scope.matches(token))
        scope.observe("com.instagram.android")
        assertFalse(scope.matches(token))
        assertTrue(scope.matches(scope.token()))
    }
    @Test fun quickReentryFromHomeOrLockScreenIsNotSuppressedByOldCooldown() {
        val gate = InstagramEventGate()
        assertTrue(gate.accept(RestrictedAppsRepository.LEGACY_INSTAGRAM, 32, 1000, setOf("com.instagram.android")))
        assertFalse(gate.accept(RestrictedAppsRepository.LEGACY_INSTAGRAM, 32, 1100, setOf("com.instagram.android")))
        gate.reset()
        assertTrue(gate.accept(RestrictedAppsRepository.LEGACY_INSTAGRAM, 32, 1200, setOf("com.instagram.android")))
    }
    @Test fun serviceRestartBeginsWithNoForegroundOrNavigationAuthority() {
        val scope = InstagramForegroundGuard()
        assertFalse(scope.matches(scope.token()))
    }
}
