package com.sofien.daylock

import android.app.Instrumentation
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Build
import java.text.Collator

/** Read-only integration against the real PackageManager on a disposable emulator. */
class RestrictedAppsInstrumentation : Instrumentation() {
    override fun onCreate(arguments: Bundle?) { super.onCreate(arguments); start() }
    override fun onStart() {
        val report = Bundle()
        try {
            check(Build.HARDWARE.contains("ranchu") || Build.HARDWARE.contains("goldfish")) { "Run on an emulator only" }
            val context = targetContext
            val catalog = RestrictedAppCatalog(context)
            val apps = catalog.discover()
            val packages = apps.map { it.packageName }.toSet()
            check("com.daylock.fixture.alpha" in packages && "com.daylock.fixture.beta" in packages)
            check("com.daylock.fixture.gamma" in packages)
            check(context.packageName !in packages)
            check("com.android.settings" !in packages)
            val home = context.packageManager.resolveActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), 0)
            check(home?.activityInfo?.packageName !in packages)
            val collator = Collator.getInstance()
            check(apps.zipWithNext().all { (a,b) -> collator.compare(a.label,b.label) <= 0 })
            for (pkg in listOf("com.daylock.fixture.alpha", "com.daylock.fixture.beta")) {
                val app = checkNotNull(catalog.supported(pkg))
                check(app.installedAt > 0 && (catalog.row(app)["icon"] as ByteArray).isNotEmpty())
            }
            check(catalog.supported(context.packageName) == null)
            check(catalog.supported("com.android.settings") == null)
            check(catalog.supported("com.daylock.missing.app") == null)
            report.putString("result", "PASS: real PackageManager discovery, sorting, icons, installation identity and exclusions")
            finish(android.app.Activity.RESULT_OK, report)
        } catch (failure: Throwable) {
            report.putString("failure", failure.toString())
            finish(android.app.Activity.RESULT_CANCELED, report)
        }
    }
}
