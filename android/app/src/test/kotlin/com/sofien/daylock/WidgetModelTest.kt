package com.sofien.daylock

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetModelTest {
    private val prefs = ReminderPreferences(true, true, true, true, 21 * 60, 18 * 60)
    private fun task(name: String, outcome: String = "incomplete") = ReminderTask(name, outcome, null, null)
    private val snapshot = ReminderSnapshot(prefs, true, 18, 0,
        ReminderPlan("2026-11-16", true, listOf(task("Read", "completed"), task("Gym"), task("Call", "excused"),
            task("Write"), task("Run"), task("Cook"))),
        ReminderPlan("2026-11-17", true, listOf(task("Morning run"))))

    @Test fun todaysCountsExcludeExcused() {
        val model = WidgetModel.from(snapshot, true, "2026-11-16")!!
        assertEquals(1, model.kept)
        assertEquals(5, model.eligible)
        assertEquals("18:00", model.freedomTime)
        assertFalse(model.allKept)
    }

    @Test fun afterMidnightTheSavedTomorrowIsToday() {
        val model = WidgetModel.from(snapshot, true, "2026-11-17")!!
        assertEquals(listOf("Morning run"), model.rows.map { it.name })
        assertNull(WidgetModel.from(snapshot, true, "2026-11-19"))
        assertNull(WidgetModel.from(snapshot, false, "2026-11-16"))
        assertNull(WidgetModel.from(null, true, "2026-11-16"))
    }

    @Test fun openCommitmentsComeFirstAndKeepTheirIndex() {
        val shown = WidgetModel.visible(WidgetModel.from(snapshot, true, "2026-11-16")!!.rows)
        assertEquals(listOf("Gym", "Write", "Run", "Cook"), shown.map { it.name })
        assertEquals(listOf(1, 3, 4, 5), shown.map { it.index })
    }

    @Test fun keepPayloadIdentifiesTheExactCommitment() {
        val row = WidgetRow(3, "Write", false, false)
        val json = JSONObject(WidgetModel.keepPayload("2026-11-16", row))
        assertEquals("today", json.getString("screen"))
        assertEquals("2026-11-16", json.getString("date"))
        assertEquals(3, json.getInt("taskIndex"))
        assertEquals("Write", json.getString("taskName"))
        assertEquals("keep", json.getString("action"))
    }

    @Test fun everythingKeptIsAllKept() {
        val done = snapshot.copy(today = ReminderPlan("2026-11-16", true, listOf(task("A", "completed"), task("B", "excused"))))
        assertTrue(WidgetModel.from(done, true, "2026-11-16")!!.allKept)
    }

    @Test fun freedomIsEarnedOnlyWhenAllKeptTomorrowCommittedAndTimeReached() {
        val kept = snapshot.copy(today = ReminderPlan("2026-11-16", true, listOf(task("A", "completed"))))
        assertFalse(WidgetModel.from(kept, true, "2026-11-16", 17 * 60 + 59)!!.earned)
        assertTrue(WidgetModel.from(kept, true, "2026-11-16", 18 * 60)!!.earned)
        val uncommitted = kept.copy(tomorrow = kept.tomorrow.copy(committed = false))
        assertFalse(WidgetModel.from(uncommitted, true, "2026-11-16", 20 * 60)!!.earned)
        val partly = snapshot
        assertFalse(WidgetModel.from(partly, true, "2026-11-16", 20 * 60)!!.earned)
        // After midnight the saved tomorrow's own tomorrow is unknown: never earned.
        val rolled = kept.copy(tomorrow = ReminderPlan("2026-11-17", true, listOf(task("B", "completed"))))
        assertFalse(WidgetModel.from(rolled, true, "2026-11-17", 20 * 60)!!.earned)
    }

    @Test fun areasTravelThroughTheSnapshot() {
        val withArea = snapshot.copy(today = ReminderPlan("2026-11-16", true,
            listOf(ReminderTask("Gym", "incomplete", null, null, areaName = "Body", areaColour = 0x348e88))))
        val decoded = ReminderCodec.snapshot(ReminderCodec.encode(withArea))
        val row = WidgetModel.from(decoded, true, "2026-11-16")!!.rows.single()
        assertEquals("Body", row.area)
        assertEquals(0x348e88, row.areaColour)
        val old = ReminderCodec.encode(snapshot)
        assertNull(WidgetModel.from(ReminderCodec.snapshot(old), true, "2026-11-16")!!.rows.first().area)
    }
}
