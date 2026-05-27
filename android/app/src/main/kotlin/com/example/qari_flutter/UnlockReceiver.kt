package com.example.qari_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

// Restarts ScreenWatchService after device reboot if active memorization was enabled.
class UnlockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        // Flutter shared_preferences stores keys with "flutter." prefix
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val active = prefs.getBoolean("flutter.activeMemorization", false)

        if (active) {
            val serviceIntent = Intent(context, ScreenWatchService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}
