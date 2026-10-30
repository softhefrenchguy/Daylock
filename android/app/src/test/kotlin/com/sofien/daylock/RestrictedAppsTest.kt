package com.sofien.daylock

import org.junit.Assert.*
import org.junit.Test

class RestrictedAppsTest {
    private var disk: String? = null
    private var failWrites = false
    private val installed = mutableMapOf("com.instagram.android" to 10L, "com.google.android.youtube" to 20L)
    private fun repository(legacy: Boolean = false) = RestrictedAppsRepository({ disk },
        { if (failWrites) false else { disk = it; true } }, { legacy }, { installed[it] })
    @Test fun migrationPreservesEnabledInstagramWithoutTouchingMasterOrFreedom() {
        var master = true
        val freedom = "existing-independent-freedom-state"
        val repo = RestrictedAppsRepository({ disk }, { disk = it; true }, { master }, { installed[it] })
        assertEquals(mapOf("com.instagram.android" to 10L), repo.record().packages)
        assertTrue(master); assertEquals("existing-independent-freedom-state", freedom)
        val migrated = disk
        assertEquals(repo.record(), repository(true).record())
        assertEquals(migrated, disk)
        master = false
        assertEquals(repo.record(), repository(false).record())
    }
    @Test fun disabledMigrationRemainsEmptyEvenIfMasterLaterEnables() {
        assertTrue(repository(false).record().packages.isEmpty())
        assertTrue(repository(true).record().packages.isEmpty())
    }
    @Test fun multipleChoicesSurviveNativeProcessRestartAndRebootRead() {
        val repo = repository()
        repo.select("com.instagram.android", true, 10)
        repo.select("com.google.android.youtube", true, 20)
        repeat(5) { assertEquals(installed, repository().record().packages) }
        repo.select("com.instagram.android", false)
        assertEquals(setOf("com.google.android.youtube"), repository().record().packages.keys)
    }
    @Test fun rapidDeltasDoNotOverwriteOtherAppChoices() {
        val repo = repository()
        repeat(30) {
            repo.select("com.instagram.android", true, 10)
            repo.select("com.google.android.youtube", true, 20)
            repo.select("com.instagram.android", false)
        }
        assertEquals(mapOf("com.google.android.youtube" to 20L), repository().record().packages)
    }
    @Test fun updatesKeepSelectionButUninstallAndReinstallRequireReselection() {
        val repo = repository(true)
        assertEquals(1, repo.reconcile(installed).packages.size)
        repo.removed("com.instagram.android")
        assertEquals(1, repo.record().removedCount)
        assertTrue(repo.reconcile(installed).packages.isEmpty())
        repo.select("com.instagram.android", true, 10)
        installed["com.instagram.android"] = 99L // Uninstall/reinstall while Daylock was stopped.
        assertTrue(repository().reconcile(installed).packages.isEmpty())
        assertEquals(1, repository().record().removedCount)
    }
    @Test fun absentLegacyAppAndNoLongerSupportedAppsAreRemoved() {
        installed.remove("com.instagram.android")
        val repo = repository(true)
        assertEquals(setOf("com.instagram.android"), repo.record().packages.keys)
        assertTrue(repo.reconcile(installed).packages.isEmpty())
    }
    @Test fun failedWriteRetainsAuthoritativeDiskAndRetryIsSafe() {
        val repo = repository(true); val old = repo.record()
        failWrites = true
        try { repo.select("com.instagram.android", false); fail("write accepted") } catch (_: IllegalStateException) { }
        assertEquals(old, repository().record())
        failWrites = false
        repo.select("com.instagram.android", false)
        assertTrue(repository().record().packages.isEmpty())
    }
    @Test fun corruptRecordNeverSilentlyMigratesOrActivatesNewTargets() {
        disk = "broken"
        try { repository(true).record(); fail("accepted corrupt data") } catch (_: Exception) { }
        assertEquals("broken", disk)
    }
    @Test fun exclusionUsesPackagesComponentsAndUidNotDisplayNames() {
        val good = RestrictableCandidate("com.example.game", "Android Settings", 1, 10200, false, true)
        assertTrue(RestrictedAppPolicy.allowed(good, "com.sofien.daylock", emptySet()))
        for (pkg in listOf("com.sofien.daylock", "android", "com.android.settings", "com.android.systemui", "com.vendor.home", "com.vendor.permission")) {
            assertFalse(RestrictedAppPolicy.allowed(good.copy(packageName = pkg), "com.sofien.daylock", setOf("com.vendor.home", "com.vendor.permission")))
        }
        assertFalse(RestrictedAppPolicy.allowed(good.copy(uid = 1000), "com.sofien.daylock", emptySet()))
        assertFalse(RestrictedAppPolicy.allowed(good.copy(persistent = true), "com.sofien.daylock", emptySet()))
        assertFalse(RestrictedAppPolicy.allowed(good.copy(launchable = false), "com.sofien.daylock", emptySet()))
    }
    @Test fun selectedInstallationMustStillMatch() {
        val app = RestrictableCandidate("com.example.game", "Game", 10, 10200, false, true)
        assertTrue(RestrictedAppPolicy.currentInstallation(mapOf(app.packageName to 10L), app))
        assertFalse(RestrictedAppPolicy.currentInstallation(emptyMap(), app))
        assertFalse(RestrictedAppPolicy.currentInstallation(mapOf(app.packageName to 1L), app))
    }
    @Test fun rapidSelectedAppSwitchCancelsEarlierPendingNavigation() {
        val guard = InstagramForegroundGuard()
        guard.observe("com.instagram.android"); val first = guard.token()
        guard.observe("com.google.android.youtube"); val second = guard.token()
        assertFalse(guard.matches(first)); assertTrue(guard.matches(second))
        guard.observe(null); assertFalse(guard.matches(second))
        guard.observe("com.instagram.android"); assertFalse(guard.matches(first))
    }
    @Test fun onlySelectedWindowEventsEnterTheExistingGate() {
        val gate = InstagramEventGate(); val selected = installed.keys
        assertFalse(gate.accept("com.other.app", 32, 0, selected))
        assertTrue(gate.accept("com.instagram.android", 32, 0, selected))
        assertFalse(gate.accept("com.instagram.android", 32, 1, selected))
        gate.reset()
        assertTrue(gate.accept("com.google.android.youtube", 32, 2, selected))
        assertFalse(gate.accept("com.google.android.youtube", 32, 9999, emptySet()))
    }
    @Test fun activityIdentityMustMatchNativeAttemptNotArbitraryExtras() {
        val flow = InstagramLockFlow()
        flow.begin(1, 0, "com.instagram.android")
        assertTrue(flow.matchesTarget(1, "com.instagram.android"))
        assertTrue(flow.mayPresent(1, "com.instagram.android", "com.instagram.android"))
        assertFalse(flow.mayPresent(1, "com.instagram.android", "com.google.android.youtube"))
        assertFalse(flow.mayPresent(1, "com.instagram.android", null))
        assertFalse(flow.matchesTarget(1, "com.google.android.youtube"))
        assertFalse(flow.matchesTarget(2, "com.instagram.android"))
        assertFalse(flow.matchesTarget(1, null))
        flow.disconnect(); assertFalse(flow.matchesTarget(1, "com.instagram.android"))
    }
}
