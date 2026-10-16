package org.AI.remori

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import java.util.Locale

/** D1 foundation only. No credentials, patient identifiers, BLE or sync jobs. */
class RemoriRelayService : Service() {
    companion object {
        const val OPEN_PATIENT = "remori.openPatient"
        private const val CHANNEL = "remori_relay"
        private const val NOTICE_ID = 101
        private var instance: RemoriRelayService? = null
        private var desired = false

        fun permitted(context: Context): Boolean {
            if (Build.VERSION.SDK_INT >= 31 &&
                context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) return false
            if (Build.VERSION.SDK_INT >= 33 &&
                context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false
            val manager = context.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= 24 && !manager.areNotificationsEnabled()) return false
            if (Build.VERSION.SDK_INT >= 26 && manager.getNotificationChannel(CHANNEL)?.importance == NotificationManager.IMPORTANCE_NONE) return false
            return true
        }

        fun apply(context: Context, language: String, link: String, simulated: Boolean, mayStart: Boolean): Boolean {
            if (!permitted(context)) { stop(context); return false }
            val intent = Intent(context, RemoriRelayService::class.java)
                .putExtra("language", language).putExtra("link", link).putExtra("simulated", simulated)
            val running = instance
            if (running != null && desired) return running.render(intent)
            if (!mayStart) return false
            desired = true
            return try {
                if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent) else context.startService(intent)
                true
            } catch (_: RuntimeException) { stop(context); false }
        }

        fun stop(context: Context) {
            desired = false
            context.stopService(Intent(context, RemoriRelayService::class.java))
            context.getSystemService(NotificationManager::class.java).cancel(NOTICE_ID)
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!desired || intent == null || !render(intent)) stopSelf()
        return START_NOT_STICKY
    }

    private fun render(intent: Intent): Boolean {
        if (!desired || !permitted(this)) { desired = false; stopSelf(); return false }
        val language = if (intent.getStringExtra("language") == "en") "en" else "ar"
        val config = android.content.res.Configuration(resources.configuration)
        config.setLocale(Locale(language))
        val localized = createConfigurationContext(config)
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(CHANNEL, localized.getString(R.string.relay_channel), NotificationManager.IMPORTANCE_LOW))
        }
        // Private channel; Flutter's release-safe connection provider owns this
        // flag. Profile simulations must also be labelled as simulations.
        val simulated = intent.getBooleanExtra("simulated", false)
        val link = intent.getStringExtra("link")
        val title = when {
            simulated -> R.string.relay_simulation
            link == "connected" -> R.string.relay_connected
            link == "connecting" -> R.string.relay_connecting
            else -> R.string.relay_disconnected
        }
        val body = when (link) {
            "connected" -> if (simulated) R.string.relay_simulation_connected_body else R.string.relay_pending_body
            "connecting" -> if (simulated) R.string.relay_simulation_connecting_body else R.string.relay_pending_body
            else -> if (simulated) R.string.relay_simulation_disconnected_body else R.string.relay_pending_body
        }
        val open = Intent(this, MainActivity::class.java)
            .setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            .putExtra(OPEN_PATIENT, true)
        val pending = PendingIntent.getActivity(this, NOTICE_ID, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
        val notification = builder.setSmallIcon(R.drawable.ic_relay_notification)
            .setContentTitle(localized.getString(title)).setContentText(localized.getString(body))
            .setStyle(Notification.BigTextStyle().bigText(localized.getString(body)))
            .setContentIntent(pending).setOngoing(true).setOnlyAlertOnce(true)
            .setShowWhen(false).setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PRIVATE).setPriority(Notification.PRIORITY_LOW).build()
        return try {
            if (Build.VERSION.SDK_INT >= 29) startForeground(NOTICE_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
            else startForeground(NOTICE_ID, notification)
            true
        } catch (_: RuntimeException) { desired = false; stopSelf(); false }
    }

    override fun onTaskRemoved(rootIntent: Intent?) { desired = false; stopSelf() }

    override fun onDestroy() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        if (instance === this) instance = null
        super.onDestroy()
    }
}
