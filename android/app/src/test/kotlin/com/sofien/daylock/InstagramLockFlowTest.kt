package com.sofien.daylock

import org.junit.Assert.*
import org.junit.Test

class InstagramLockFlowTest {
    @Test fun launchRequestIsNotEvidenceOfAVisibleActivity() {
        val flow = InstagramLockFlow()
        assertTrue(flow.begin(1, 1000))
        assertFalse(flow.confirmed)
        assertTrue(flow.needsHome(1))
        assertTrue(flow.settle(1)) // Silent Android denial: use fallback, no retry.
    }
    @Test fun resumedActivityPreventsCompetingHomeButNeedsFocusAndDraw() {
        val flow = InstagramLockFlow()
        flow.begin(1, 1000)
        flow.resumed(1)
        assertFalse(flow.needsHome(1))
        assertFalse(flow.confirm(1, true))
        flow.focused(1, true)
        assertFalse(flow.confirm(1, true))
        flow.drawn(1)
        assertTrue(flow.confirm(1, true))
        assertFalse(flow.settle(1))
        assertFalse(flow.confirm(1, true))
    }
    @Test fun drawBeforeFocusIsAlsoConfirmedOnlyAfterFocus() {
        val flow = InstagramLockFlow()
        flow.begin(1, 1000)
        flow.resumed(1)
        flow.drawn(1)
        assertFalse(flow.confirm(1, true))
        flow.focused(1, true)
        assertTrue(flow.confirm(1, true))
    }
    @Test fun lockedScreenCannotConfirmAndUnlockRequiresFreshFocus() {
        val flow = InstagramLockFlow()
        flow.begin(1, 1000)
        flow.resumed(1); flow.drawn(1); flow.focused(1, true)
        assertFalse(flow.confirm(1, false))
        flow.focused(1, false)
        assertFalse(flow.confirm(1, true))
        flow.focused(1, true)
        assertTrue(flow.confirm(1, true))
    }
    @Test fun pauseBeforeFirstDrawDoesNotConfirmVisibility() {
        val flow = InstagramLockFlow()
        flow.begin(1, 1000)
        flow.resumed(1); flow.focused(1, true); flow.paused(1); flow.drawn(1)
        assertFalse(flow.confirm(1, true))
        assertTrue(flow.settle(1))
    }
    @Test fun repeatedRapidLaunchesNeverCreateConcurrentOrRepeatedActivities() {
        val flow = InstagramLockFlow()
        assertTrue(flow.begin(1, 1000))
        repeat(100) { assertFalse(flow.begin(it + 2L, 1100)) }
        flow.settle(1)
        assertFalse(flow.begin(2, 3999))
        assertTrue(flow.begin(2, 4000))
    }
    @Test fun oldLifecycleAndTimeoutCannotConfirmOrSettleNewAttempt() {
        val flow = InstagramLockFlow()
        flow.begin(1, 1000); flow.settle(1); flow.begin(2, 4000)
        flow.resumed(1); flow.focused(1, true); flow.drawn(1)
        assertFalse(flow.confirm(1, true))
        assertFalse(flow.settle(1))
        assertFalse(flow.needsHome(1))
        assertTrue(flow.needsHome(2))
    }
    @Test fun serviceDisconnectRejectsAllOldCallbacksAndRetainsCooldown() {
        val flow = InstagramLockFlow()
        flow.begin(1, 1000); flow.disconnect()
        assertFalse(flow.isCurrent(1)); assertFalse(flow.needsHome(1)); assertFalse(flow.settle(1))
        assertFalse(flow.begin(2, 1100))
        assertTrue(flow.begin(2, 4000))
    }
    @Test fun newProcessHasNoAuthorityForAnOldRestoredActivity() {
        val flow = InstagramLockFlow()
        assertFalse(flow.isCurrent(1234))
        assertFalse(flow.confirm(1234, true))
        assertTrue(flow.begin(2000, 1000))
    }
    @Test fun returningFocusRestoresVisibilityWithoutDuplicateAcknowledgement() {
        val flow = InstagramLockFlow()
        flow.begin(1, 1000); flow.resumed(1); flow.focused(1, true); flow.drawn(1)
        assertTrue(flow.confirm(1, true))
        flow.paused(1)
        assertFalse(flow.visible(1, true))
        flow.resumed(1); flow.focused(1, true)
        assertTrue(flow.visible(1, true))
        assertFalse(flow.confirm(1, true))
    }
    @Test fun notificationCooldownIsFiveMinutesAcrossProcessOrServiceRestarts() {
        val persisted = InstagramNoticeStamp(1_000_000, 10_000, 7)
        assertTrue(InstagramFallbackPolicy.allowed(null, persisted))
        repeat(100) { assertFalse(InstagramFallbackPolicy.allowed(persisted, persisted.copy(elapsedMs = 10_100))) }
        assertFalse(InstagramFallbackPolicy.allowed(persisted, persisted.copy(elapsedMs = 309_999)))
        assertTrue(InstagramFallbackPolicy.allowed(persisted, persisted.copy(elapsedMs = 310_000)))
    }
    @Test fun sameBootWallClockChangesDoNotBypassNotificationThrottle() {
        val old = InstagramNoticeStamp(1_000_000, 10_000, 7)
        assertFalse(InstagramFallbackPolicy.allowed(old, InstagramNoticeStamp(100, 10_100, 7)))
        assertFalse(InstagramFallbackPolicy.allowed(old, InstagramNoticeStamp(9_000_000, 10_100, 7)))
    }
    @Test fun rebootUsesPersistedWallTimeAndBackwardClockAllowsOnlyOneNewNotice() {
        val old = InstagramNoticeStamp(1_000_000, 10_000, 7)
        assertFalse(InstagramFallbackPolicy.allowed(old, InstagramNoticeStamp(1_100_000, 100, 8)))
        assertTrue(InstagramFallbackPolicy.allowed(old, InstagramNoticeStamp(1_300_000, 100, 8)))
        val corrected = InstagramNoticeStamp(900_000, 100, 8)
        assertTrue(InstagramFallbackPolicy.allowed(old, corrected))
        assertFalse(InstagramFallbackPolicy.allowed(corrected, corrected.copy(elapsedMs = 200)))
    }
}
