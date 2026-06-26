package com.example.alpen_app_sya

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "alpen/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel).setMethodCallHandler { call, result ->
            if (call.method != "saveToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val fileName = call.argument<String>("fileName") ?: "dokumen.pdf"
                val mimeType = call.argument<String>("mimeType") ?: "application/pdf"
                val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                val savedName = saveToDownloads(fileName, mimeType, bytes)
                result.success(savedName)
            } catch (error: Exception) {
                result.error("DOWNLOAD_FAILED", error.message, null)
            }
        }
    }

    private fun saveToDownloads(fileName: String, mimeType: String, bytes: ByteArray): String {
        val safeName = fileName.replace(Regex("[\\\\/:*?\"<>|]"), "_")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, safeName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Tidak dapat membuat file download")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Tidak dapat menulis file download")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return safeName
        }

        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDir.exists()) downloadsDir.mkdirs()
        val target = File(downloadsDir, safeName)
        FileOutputStream(target).use { it.write(bytes) }
        return safeName
    }
}
