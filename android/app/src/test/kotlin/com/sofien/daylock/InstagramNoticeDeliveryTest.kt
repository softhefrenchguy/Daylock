package com.sofien.daylock

import org.junit.Assert.*
import org.junit.Test

class InstagramNoticeDeliveryTest {
    private val now = InstagramNoticeStamp(1_000_000, 10_000, 7)

    @Test fun deniedPermissionOrChannelDoesNotReadReserveOrPost() {
        val delivery = InstagramNoticeDelivery({ error("must not read") }, { error("must not reserve") }, { error("must not post") })
        assertEquals(InstagramNoticeResult.PERMISSION_DENIED, delivery.deliver(false, now))
    }
    @Test fun permissionGrantedLaterCanPostAndReservationPrecedesRendering() {
        val events = mutableListOf<String>()
        val delivery = InstagramNoticeDelivery({ null }, { events.add("saved"); true }, { events.add("posted") })
        delivery.deliver(false, now)
        assertTrue(events.isEmpty())
        assertEquals(InstagramNoticeResult.POSTED, delivery.deliver(true, now))
        assertEquals(listOf("saved", "posted"), events)
    }
    @Test fun restartReadsPersistedReservationAndSuppressesRapidReopens() {
        var saved: InstagramNoticeStamp? = null
        var count = 0
        fun restarted() = InstagramNoticeDelivery({ saved }, { saved = it; true }, { count++ })
        assertEquals(InstagramNoticeResult.POSTED, restarted().deliver(true, now))
        repeat(50) { assertEquals(InstagramNoticeResult.THROTTLED, restarted().deliver(true, now.copy(elapsedMs = 10_100))) }
        assertEquals(1, count)
    }
    @Test fun failedPersistenceDoesNotSendANotification() {
        val delivery = InstagramNoticeDelivery({ null }, { false }, { error("must not post") })
        assertEquals(InstagramNoticeResult.SAVE_FAILED, delivery.deliver(true, now))
    }
    @Test fun invalidLedgerFailsClosedWithoutReplacingIt() {
        val delivery = InstagramNoticeDelivery({ error("corrupt") }, { error("must not replace") }, { error("must not post") })
        assertEquals(InstagramNoticeResult.INVALID_RECORD, delivery.deliver(true, now))
    }
    @Test fun platformExceptionCannotCauseAPostingLoopAfterRestart() {
        var saved: InstagramNoticeStamp? = null
        val first = InstagramNoticeDelivery({ saved }, { saved = it; true }, { throw SecurityException("revoked during delivery") })
        assertThrows(SecurityException::class.java) { first.deliver(true, now) }
        val restarted = InstagramNoticeDelivery({ saved }, { error("must not reserve") }, { error("must not post") })
        assertEquals(InstagramNoticeResult.THROTTLED, restarted.deliver(true, now))
    }
}
