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
                    "getDeviceName" -> result.success(deviceDisplayName())
                    else -> result.notImplemented()
                }
            }
    }

    private fun deviceDisplayName(): String {
        val named = try {
            Settings.Global.getString(contentResolver, Settings.Global.DEVICE_NAME)
        } catch (_: Exception) {
            null
        }
        if (!named.isNullOrBlank()) return named.trim()
        return Build.MODEL.orEmpty().ifBlank { "Android" }
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
}
