package com.sofien.daylock

import android.content.Context
import android.os.SystemClock
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

// Durable native inputs. Never rewrites Flutter planner/history/authentication storage.
class DetectionStore(private val context: Context) {
    private val preferences = context.getSharedPreferences("daylock.instagram_detection.v1", Context.MODE_PRIVATE)
    private val repository = NativeFreedomRepository(
        read = { preferences.getString("nativeState", null) },
        write = { raw, blocking -> preferences.edit().putString("nativeState", raw)
            .putBoolean("blockingEnabled", blocking).commit() },
        legacyBlocking = { preferences.getBoolean("blockingEnabled", false) },
        hasLegacySnapshot = { preferences.contains("snapshot") },
    )

    fun selectionRepository(catalog: RestrictedAppCatalog) = RestrictedAppsRepository(
        read = { preferences.getString("restrictedApps.v1", null) },
        write = { preferences.edit().putString("restrictedApps.v1", it).commit() },
        legacyEnabled = { blockingEnabled() }, installedAt = { catalog.installedAt(it) })

    fun clock(): DetectionClock {
        val wall = System.currentTimeMillis()
        val zone = TimeZone.getDefault()
        val calendar = Calendar.getInstance(zone).apply { timeInMillis = wall }
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).apply { timeZone = zone }
        return DetectionClock(wall, SystemClock.elapsedRealtime(), -1, dateFormat.format(calendar.time), zone.id,
            zone.getOffset(wall), calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE))
    }

    fun publish(input: Map<*, *>): Boolean = repository.publish(
        NativeFreedomCodec.fromInput(input), (input["expectedRevision"] as Number).toLong())
    fun invalidate(reason: String): Boolean = repository.invalidate(reason)
    fun eligibility(now: DetectionClock = clock()): NativeFreedomResult = repository.eligibility(now)
    fun revision(): Long = repository.record().revision
    fun blockingEnabled(): Boolean = repository.record().blockingEnabled
    fun setBlockingEnabled(enabled: Boolean): Boolean = repository.setBlocking(enabled)
    fun reportRestriction(value: String): Boolean = runCatching {
        preferences.edit().putString("lastRestriction", value).commit()
    }.getOrDefault(false)
    fun lastRestriction(): String? = preferences.getString("lastRestriction", null)
    fun publishAppearance(value: Map<*, *>): Boolean = runCatching {
        val mode = value["mode"] as String
        require(mode in listOf("dark", "light", "system"))
        for (variant in listOf("dark", "light")) {
            val colors = value[variant] as Map<*, *>
            for (key in listOf("background", "foreground", "muted", "accent", "onAccent", "outline")) require(colors[key] is Number)
        }
        preferences.edit().putString("lockAppearance", JSONObject(value).toString()).commit()
    }.getOrDefault(false)
    fun lockAppearance(): JSONObject? = runCatching {
        preferences.getString("lockAppearance", null)?.let { JSONObject(it) }
    }.getOrNull()

    fun recordDetection(packageName: String): Boolean {
        val now = clock()
        val result = eligibility(now)
        // One overwritten record, no package history, screen text or node content.
        val json = JSONObject().apply {
            put("detectedAtMs", now.wallMs); put("packageName", packageName)
            put("freedomState", result.state); put("freedomReason", result.reason)
        }
        return preferences.edit().putString("lastDetection", json.toString()).commit()
    }

    fun lastDetection(): Map<String, Any?>? = try {
        preferences.getString("lastDetection", null)?.let {
            val json = JSONObject(it)
            mapOf("packageName" to json.optString("packageName", RestrictedAppsRepository.LEGACY_INSTAGRAM), "detectedAtMs" to json.getLong("detectedAtMs"), "freedomState" to json.getString("freedomState"),
                "freedomReason" to json.getString("freedomReason"))
        }
    } catch (_: Exception) { null }

}
