package com.example.daylock

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.SystemClock

/** Emulator visual fixture only. Copy to src/debug temporarily, never src/main.
 * Opens the real lock Activity using its real persisted state and policy.
 * Does not seed plans, change permissions, enable blocking or alter eligibility.
 * This verifies presentation/actions, not Accessibility background-launch reliability.
 */
class LockScreenPreviewActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DetectionRuntime.attach(this)
        DetectionRuntime.worker.execute {
            runOnUiThread {
                val attempt = DetectionRuntime.nextLockAttempt()
                if (DetectionRuntime.lockFlow.begin(attempt, SystemClock.elapsedRealtime())) {
                    startActivity(Intent(this, InstagramLockActivity::class.java).putExtra("attempt", attempt))
                    DetectionRuntime.lockFlow.settle(attempt)
                }
                finish()
            }
        }
    }
}
