package com.example.daylock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Reconcile selections only; never starts an Activity or enables Accessibility. */
class RestrictedPackagesReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in setOf(Intent.ACTION_PACKAGE_FULLY_REMOVED, Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED)) return
        DetectionRuntime.attach(context)
        DetectionRuntime.stateRevision.incrementAndGet()
        val pending = goAsync()
        DetectionRuntime.worker.execute {
            try { DetectionRuntime.packageChanged(intent.data?.schemeSpecificPart, intent.action == Intent.ACTION_PACKAGE_FULLY_REMOVED) }
            finally { pending.finish() }
        }
    }
}
