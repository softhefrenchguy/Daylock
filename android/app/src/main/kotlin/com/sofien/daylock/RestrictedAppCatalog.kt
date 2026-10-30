package com.sofien.daylock

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.provider.Settings
import java.io.ByteArrayOutputStream
import java.text.Collator

/** Launchable apps in this Android profile only. No inventory uploads or QUERY_ALL_PACKAGES. */
class RestrictedAppCatalog(private val context: Context) {
    private val pm = context.packageManager
    private fun launcher(packageName: String? = null) = Intent(Intent.ACTION_MAIN)
        .addCategory(Intent.CATEGORY_LAUNCHER).apply { if (packageName != null) setPackage(packageName) }
    @Suppress("DEPRECATION")
    fun installedAt(packageName: String): Long? = try { pm.getPackageInfo(packageName, 0).firstInstallTime }
        catch (_: PackageManager.NameNotFoundException) { null }
    @Suppress("DEPRECATION")
    private fun protectedPackages(): Set<String> = buildSet {
        add(context.packageName)
        // Exclude every HOME-capable app, including launchers not currently the default.
        val intents = listOf(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME),
            Intent(Settings.ACTION_SETTINGS), Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS),
            Intent(Settings.ACTION_SECURITY_SETTINGS), Intent(Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")),
            Intent("android.intent.action.MANAGE_PERMISSIONS"),
            Intent(Intent.ACTION_DIAL, Uri.parse("tel:")), Intent("android.intent.action.EMERGENCY_DIAL"),
            Intent(Intent.ACTION_DELETE, Uri.parse("package:${context.packageName}")),
            Intent(Intent.ACTION_VIEW).setDataAndType(Uri.parse("content://daylock/preview.apk"), "application/vnd.android.package-archive"),
        )
        for (intent in intents) {
            pm.queryIntentActivities(intent, PackageManager.MATCH_ALL).forEach { add(it.activityInfo.packageName) }
            pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)?.activityInfo?.packageName?.let { add(it) }
        }
        pm.queryIntentServices(Intent("android.view.InputMethod"), PackageManager.MATCH_ALL)
            .forEach { add(it.serviceInfo.packageName) }
    }
    @Suppress("DEPRECATION")
    private fun candidate(packageName: String): RestrictableCandidate? {
        val launchable = pm.queryIntentActivities(launcher(packageName), 0).any { it.activityInfo.enabled && it.activityInfo.exported }
        if (!launchable) return null
        val info = try { pm.getApplicationInfo(packageName, 0) } catch (_: PackageManager.NameNotFoundException) { return null }
        return RestrictableCandidate(packageName, pm.getApplicationLabel(info).toString()
            .filterNot { it.isISOControl() }.take(100).ifBlank { packageName }, installedAt(packageName) ?: return null,
            info.uid, info.flags and ApplicationInfo.FLAG_PERSISTENT != 0, info.enabled)
    }
    fun supported(packageName: String): RestrictableCandidate? = candidate(packageName)?.takeIf {
        RestrictedAppPolicy.allowed(it, context.packageName, protectedPackages())
    }
    @Suppress("DEPRECATION")
    fun discover(): List<RestrictableCandidate> {
        val protected = protectedPackages()
        val collator = Collator.getInstance()
        return pm.queryIntentActivities(launcher(), 0).map { it.activityInfo.packageName }.distinct()
            .mapNotNull { candidate(it) }.filter { RestrictedAppPolicy.allowed(it, context.packageName, protected) }
            .sortedWith { a, b -> collator.compare(a.label, b.label).takeIf { it != 0 } ?: a.packageName.compareTo(b.packageName) }
    }
    fun label(packageName: String): String = runCatching {
        pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
            .filterNot { it.isISOControl() }.take(100).ifBlank { "This app" }
    }.getOrDefault("This app")
    fun row(app: RestrictableCandidate): Map<String, Any?> = mapOf(
        "packageName" to app.packageName, "name" to app.label, "icon" to runCatching {
            val drawable = pm.getApplicationIcon(app.packageName)
            val bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
            drawable.setBounds(0, 0, 64, 64); drawable.draw(Canvas(bitmap))
            ByteArrayOutputStream().use { out -> bitmap.compress(Bitmap.CompressFormat.PNG, 100, out); bitmap.recycle(); out.toByteArray() }
        }.getOrNull())
}
