package com.sofien.daylock

import org.json.JSONObject

/** Native-only selection authority. The existing native Freedom/master record stays untouched. */
data class RestrictedSelection(val revision: Long, val packages: Map<String, Long>, val removedCount: Int = 0)

class RestrictedAppsRepository(
    private val read: () -> String?,
    private val write: (String) -> Boolean,
    private val legacyEnabled: () -> Boolean,
    private val installedAt: (String) -> Long?,
) {
    companion object { const val LEGACY_INSTAGRAM = "com.instagram.android" }
    private var cached: RestrictedSelection? = null
    fun record(): RestrictedSelection {
        cached?.let { return it }
        val raw = read()
        if (raw == null) {
            val migrated = if (legacyEnabled()) mapOf(LEGACY_INSTAGRAM to (installedAt(LEGACY_INSTAGRAM) ?: -1L)) else emptyMap()
            return save(RestrictedSelection(1, migrated))
        }
        val json = JSONObject(raw)
        require(json.getInt("version") == 1)
        val packages = json.getJSONObject("packages")
        val decoded = packages.keys().asSequence().associateWith { key ->
            require(validPackage(key)); packages.getLong(key)
        }
        return RestrictedSelection(json.getLong("revision").also { require(it >= 1) }, decoded,
            json.optInt("removedCount", 0)).also { cached = it }
    }
    private fun save(value: RestrictedSelection): RestrictedSelection {
        val raw = JSONObject().put("version", 1).put("revision", value.revision)
            .put("packages", JSONObject(value.packages)).put("removedCount", value.removedCount).toString()
        check(write(raw)) { "Selection could not be saved" }
        cached = value
        return value
    }
    fun select(packageName: String, selected: Boolean, firstInstallTime: Long? = null): RestrictedSelection {
        require(validPackage(packageName))
        val old = record()
        val next = old.packages.toMutableMap()
        if (selected) {
            require(firstInstallTime != null && firstInstallTime >= 0)
            next[packageName] = firstInstallTime
        } else next.remove(packageName)
        return save(RestrictedSelection(old.revision + 1, next))
    }
    /** Updates preserve firstInstallTime; an uninstall/reinstall must be selected again. */
    fun reconcile(supported: Map<String, Long>): RestrictedSelection {
        val old = record()
        val kept = old.packages.filter { (pkg, installation) -> supported[pkg] == installation }
        if (kept.size == old.packages.size) return old
        return save(RestrictedSelection(old.revision + 1, kept, old.packages.size - kept.size))
    }
    fun removed(packageName: String): RestrictedSelection {
        val old = record()
        if (packageName !in old.packages) return old
        return save(RestrictedSelection(old.revision + 1, old.packages - packageName, 1))
    }
}

fun validPackage(value: String) = value.length <= 255 && Regex("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+").matches(value)

/** Pure filtering boundary, shared by discovery and enforcement and exercised on the JVM. */
data class RestrictableCandidate(val packageName: String, val label: String, val installedAt: Long,
    val uid: Int, val persistent: Boolean, val launchable: Boolean)
object RestrictedAppPolicy {
    private val core = setOf("android", "com.android.systemui", "com.android.settings",
        "com.android.permissioncontroller", "com.google.android.permissioncontroller",
        "com.android.packageinstaller", "com.google.android.packageinstaller", "com.android.keyguard")
    fun allowed(app: RestrictableCandidate, ownPackage: String, protectedPackages: Set<String>) =
        validPackage(app.packageName) && app.packageName != ownPackage && app.packageName !in core &&
        app.packageName !in protectedPackages && app.uid % 100000 >= 10000 && !app.persistent && app.launchable
    fun currentInstallation(selected: Map<String, Long>, app: RestrictableCandidate) = selected[app.packageName] == app.installedAt
}
