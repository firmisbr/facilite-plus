package com.firmis.facilite_plus

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.firmis.facilite_plus/backup_downloads",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val fileName = call.argument<String>("fileName")
                    @Suppress("UNCHECKED_CAST")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (fileName.isNullOrBlank() || bytes == null) {
                        result.error("INVALID_ARGS", "fileName e bytes obrigatórios", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val saved = saveToPublicDownloads(fileName, bytes)
                        if (saved != null) {
                            result.success(saved)
                        } else {
                            result.error("SAVE_FAILED", "Não foi possível salvar em Downloads", null)
                        }
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveToPublicDownloads(fileName: String, bytes: ByteArray): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: return null
            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
            } ?: return null
            "${Environment.DIRECTORY_DOWNLOADS}/$fileName"
        } else {
            @Suppress("DEPRECATION")
            val dir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS,
            )
            if (!dir.exists()) {
                dir.mkdirs()
            }
            val file = File(dir, fileName)
            file.writeBytes(bytes)
            file.absolutePath
        }
    }
}
