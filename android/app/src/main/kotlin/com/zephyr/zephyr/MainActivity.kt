package com.zephyr.zephyr

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.apache.commons.compress.archivers.sevenz.SevenZArchiveEntry
import org.apache.commons.compress.archivers.sevenz.SevenZFile
import org.apache.commons.compress.archivers.sevenz.SevenZOutputFile
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val storageChannel = "zephyr/android_storage"
    private val backupChannel = "zephyr/purewriter_backup"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Let Flutter draw under status + gesture nav bars (true edge-to-edge).
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            @Suppress("DEPRECATION")
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasFullAccess" -> result.success(hasFullExternalStorageAccess())
                    "requestFullAccess" -> {
                        requestFullExternalStorageAccess()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, backupChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "restorePwb" -> {
                        try {
                            val pwbPath = call.argument<String>("pwbPath")
                            val destinationPath = call.argument<String>("destinationPath")
                            if (pwbPath.isNullOrEmpty() || destinationPath.isNullOrEmpty()) {
                                result.error("bad_args", "pwbPath and destinationPath required", null)
                                return@setMethodCallHandler
                            }
                            restorePwb(File(pwbPath), File(destinationPath))
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("restore_failed", error.message, null)
                        }
                    }
                    "createPwb" -> {
                        try {
                            val roomDbPath = call.argument<String>("roomDbPath")
                            val pwbPath = call.argument<String>("pwbPath")
                            if (roomDbPath.isNullOrEmpty() || pwbPath.isNullOrEmpty()) {
                                result.error("bad_args", "roomDbPath and pwbPath required", null)
                                return@setMethodCallHandler
                            }
                            createPwb(File(roomDbPath), File(pwbPath))
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("create_failed", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasFullExternalStorageAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }
    }

    private fun requestFullExternalStorageAccess() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
    }

    private fun restorePwb(pwb: File, destination: File) {
        SevenZFile.builder().setFile(pwb).get().use { archive ->
            var entry: SevenZArchiveEntry? = archive.nextEntry
            var restored = false
            while (entry != null) {
                val name = entry.name ?: ""
                if (!entry.isDirectory && name.lowercase().endsWith(".db")) {
                    destination.parentFile?.mkdirs()
                    FileOutputStream(destination).use { output ->
                        val buffer = ByteArray(64 * 1024)
                        var read: Int
                        while (archive.read(buffer).also { read = it } > 0) {
                            output.write(buffer, 0, read)
                        }
                    }
                    restored = true
                    break
                }
                entry = archive.nextEntry
            }
            if (!restored) {
                throw IllegalStateException("PureWriter backup contains no .db database.")
            }
        }
    }

    private fun createPwb(roomDb: File, pwb: File) {
        if (!roomDb.isFile) {
            throw IllegalStateException("Room database not found: ${roomDb.path}")
        }
        pwb.parentFile?.mkdirs()
        if (pwb.exists()) {
            pwb.delete()
        }
        SevenZOutputFile(pwb).use { archive ->
            val entry = archive.createArchiveEntry(roomDb, "PureWriterBackup.db")
            archive.putArchiveEntry(entry)
            FileInputStream(roomDb).use { input ->
                val buffer = ByteArray(64 * 1024)
                var read: Int
                while (input.read(buffer).also { read = it } > 0) {
                    archive.write(buffer, 0, read)
                }
            }
            archive.closeArchiveEntry()
        }
    }
}
