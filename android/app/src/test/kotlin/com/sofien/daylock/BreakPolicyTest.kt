package com.sofien.daylock

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BreakPolicyTest {
    private val start = BreakRecord("2026-11-16", 1_000_000L, 50_000L, 7, "com.instagram.android",
        "Instagram", "Messaging my sister back")

    @Test fun oneBreakPerLocalDay() {
        assertTrue(BreakPolicy.canStart(emptyList(), "2026-11-16", "Need to reply"))
        assertFalse(BreakPolicy.canStart(listOf(start), "2026-11-16", "Need to reply"))
        assertTrue(BreakPolicy.canStart(listOf(start), "2026-11-17", "Need to reply"))
    }

    @Test fun aReasonIsRequired() {
        assertFalse(BreakPolicy.canStart(emptyList(), "2026-11-16", "  "))
        assertFalse(BreakPolicy.canStart(emptyList(), "2026-11-16", "ok"))
        assertFalse(BreakPolicy.canStart(emptyList(), "2026-11-16", "x".repeat(201)))
        assertTrue(BreakPolicy.canStart(emptyList(), "2026-11-16", "  why  "))
    }

    @Test fun lastsFifteenMinutesOnTheMonotonicClock() {
        assertEquals(BreakPolicy.DURATION_MS, BreakPolicy.remainingMs(start, 1_000_000L, 50_000L, 7))
        assertEquals(5 * 60_000L, BreakPolicy.remainingMs(start, 1_000_000L, 50_000L + 10 * 60_000L, 7))
        assertEquals(0, BreakPolicy.remainingMs(start, 1_000_000L, 50_000L + 16 * 60_000L, 7))
    }

    @Test fun changingTheWallClockCannotStretchABreak() {
        // Wall clock moved back an hour, but 20 real minutes passed.
        assertEquals(0, BreakPolicy.remainingMs(start, 1_000_000L - 3_600_000L, 50_000L + 20 * 60_000L, 7))
    }

    @Test fun afterARebootTheWallClockIsUsedAndCapped() {
        assertEquals(10 * 60_000L, BreakPolicy.remainingMs(start, 1_000_000L + 5 * 60_000L, 1_000L, 8))
        assertEquals(0, BreakPolicy.remainingMs(start, 1_000_000L - 1, 1_000L, 8))
        assertEquals(0, BreakPolicy.remainingMs(null, 1, 1, 1))
    }

    @Test fun logRoundTripsAndStaysBounded() {
        val log = (1..70).fold(emptyList<BreakRecord>()) { acc, i -> BreakPolicy.append(acc, start.copy(startWallMs = i.toLong())) }
        assertEquals(BreakPolicy.MAX_LOG, log.size)
        assertEquals(70L, log.last().startWallMs)
        assertEquals(log, BreakPolicy.decode(BreakPolicy.encode(log)))
        assertEquals(emptyList<BreakRecord>(), BreakPolicy.decode("{broken"))
    }
}
