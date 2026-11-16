package com.sofien.daylock

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Saves and opens Daylock backup files with Android's own document screens
 * (no storage permission). The file content is produced and checked in Dart.
 */
class BackupBridge(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        private const val SAVE = 7601
        private const val OPEN = 7602
        private const val MAX_BYTES = 20 * 1024 * 1024
    }

    private val channel = MethodChannel(messenger, "daylock/backup")
    private val io = Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result? = null
    private var content: String? = null

    init {
        channel.setMethodCallHandler { call, result ->
            if (pending != null) { result.error("BUSY", "A backup file screen is already open.", null); return@setMethodCallHandler }
            when (call.method) {
                "save" -> {
                    val args = call.arguments as Map<*, *>
                    content = args["content"] as String
                    pending = result
                    launch(Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE)
                        .setType("application/json").putExtra(Intent.EXTRA_TITLE, args["name"] as String), SAVE)
                }
                "open" -> {
                    pending = result
                    launch(Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE)
                        .setType("*/*").putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain",
                            "application/octet-stream")), OPEN)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launch(intent: Intent, request: Int) {
        try { activity.startActivityForResult(intent, request) }
        catch (_: Exception) { finish { it.error("UNAVAILABLE", "No file screen is available on this device.", null) } }
    }

    private fun finish(deliver: (MethodChannel.Result) -> Unit) {
        val result = pending ?: return
        pending = null
        content = null
        activity.runOnUiThread { deliver(result) }
    }

    /** True when the result belonged to the backup bridge. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE && requestCode != OPEN) return false
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) { finish { it.success(null) }; return true }
        val text = content
        io.execute {
            try {
                if (requestCode == SAVE) {
                    activity.contentResolver.openOutputStream(uri, "wt")!!.use { it.write(text!!.toByteArray()) }
                    finish { it.success(true) }
                } else {
                    val bytes = activity.contentResolver.openInputStream(uri)!!.use { input ->
                        val buffer = input.readBytes()
                        check(buffer.size <= MAX_BYTES) { "too large" }
                        buffer
                    }
                    finish { it.success(String(bytes, Charsets.UTF_8)) }
                }
            } catch (_: Exception) {
                finish { it.error("IO", "The file could not be read or written.", null) }
            }
        }
        return true
    }
}
