package com.example.qari_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import androidx.core.app.NotificationCompat

class ScreenWatchService : Service() {

    private var screenReceiver: BroadcastReceiver? = null

    companion object {
        private const val WATCH_CHANNEL_ID = "qari_screen_watch"
        private const val WATCH_NOTIF_ID   = 1003
    }

    override fun onCreate() {
        super.onCreate()
        createChannel()
        startForeground(WATCH_NOTIF_ID, buildPersistentNotification())
        registerScreenReceiver()
    }

    override fun onDestroy() {
        super.onDestroy()
        screenReceiver?.let { unregisterReceiver(it) }
        screenReceiver = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(NotificationChannel(
                WATCH_CHANNEL_ID,
                "Qari фонда жұмыс",
                NotificationManager.IMPORTANCE_MIN
            ).apply { setShowBadge(false) })
        }
    }

    private fun buildPersistentNotification(): Notification =
        NotificationCompat.Builder(this, WATCH_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Qari")
            .setContentText("Белсенді жаттау қосылған")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setSilent(true)
            .setOngoing(true)
            .build()

    private fun registerScreenReceiver() {
        screenReceiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                if (intent.action == Intent.ACTION_SCREEN_ON) {
                    showLearningScreen()
                }
            }
        }
        registerReceiver(screenReceiver, IntentFilter(Intent.ACTION_SCREEN_ON))
    }

    // SYSTEM_ALERT_WINDOW is an explicit exemption from background activity start
    // restrictions on Android 12+. Combined with the foreground service (exemption
    // on Android 10–11), startActivity works without any notification popup.
    // MainActivity has showWhenLocked + turnScreenOn so it appears over the lock screen.
    private fun showLearningScreen() {
        val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            Settings.canDrawOverlays(this) else true

        if (!canDraw) return

        val activityIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra("from_unlock", true)
        }
        startActivity(activityIntent)
    }
}
