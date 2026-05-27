package com.example.qari_flutter

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.qari_flutter/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableOverlay" -> {
                    startScreenWatchService()
                    result.success(true)
                }
                "disableOverlay" -> {
                    stopScreenWatchService()
                    result.success(true)
                }
                "isFromUnlock" -> {
                    // intent is always current — updated in onNewIntent
                    val fromUnlock = intent?.getBooleanExtra("from_unlock", false) ?: false
                    result.success(fromUnlock)
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                            1002
                        )
                    }
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(canDraw)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "requestBatteryOptimization" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                        !pm.isIgnoringBatteryOptimizations(packageName)) {
                        try {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        } catch (_: Exception) {
                            // Fallback: open battery settings
                            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                        }
                    }
                    result.success(true)
                }
                "minimizeApp" -> {
                    moveTaskToBack(true)
                    result.success(true)
                }
                "saveWidgetData" -> {
                    val key = call.argument<String>("key") ?: ""
                    val value = call.argument<Any>("value")
                    val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                    val editor = prefs.edit()
                    when (value) {
                        is String  -> editor.putString(key, value)
                        is Long    -> editor.putInt(key, value.toInt())
                        is Int     -> editor.putInt(key, value)
                        is Boolean -> editor.putBoolean(key, value)
                        else       -> editor.putString(key, value?.toString() ?: "")
                    }
                    editor.commit()
                    result.success(true)
                }
                "updateWidget" -> {
                    val manager = AppWidgetManager.getInstance(this)
                    val component = ComponentName(this, QariWidget::class.java)
                    for (id in manager.getAppWidgetIds(component)) {
                        QariWidget.updateWidget(this, manager, id)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // When app is already running (singleTop), system calls onNewIntent instead of onCreate.
    // Update the intent so isFromUnlock returns the correct value.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun startScreenWatchService() {
        val serviceIntent = Intent(this, ScreenWatchService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopScreenWatchService() {
        stopService(Intent(this, ScreenWatchService::class.java))
    }
}
