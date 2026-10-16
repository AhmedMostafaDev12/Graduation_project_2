package org.AI.remori

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.util.Locale

/** Volatile, next-occurrence-only delivery while D1 is alive. No alarms or disk data. */
object ReminderNotifications {
    const val TOKEN = "remori.reminderToken"
    const val ACTION = "remori.reminderAction"
    private const val CHANNEL = "remori_reminders"
    private const val ID = 102
    private val handler = Handler(Looper.getMainLooper())
    private var task: Runnable? = null
    private var token: String? = null
    private var shown = false

    fun clear(context: Context) {
        task?.let { handler.removeCallbacks(it) }
        task = null
        token = null
        shown = false
        context.getSystemService(NotificationManager::class.java).cancel(ID)
    }

    fun update(context: Context, data: Map<*, *>?) {
        if (data == null || !RemoriRelayService.running()) { clear(context); return }
        val receipt = data["token"] as? String ?: return
        val due = (data["due"] as? Number)?.toLong() ?: return
        val title = data["title"] as? String ?: return
        val time = data["time"] as? String ?: return
        val language = if (data["language"] == "en") "en" else "ar"
        if (token != receipt) { clear(context); token = receipt }
        if (shown || task != null) return
        task?.let { handler.removeCallbacks(it) }
        val work = Runnable {
            task = null
            if (token != receipt || !RemoriRelayService.running() || !RemoriRelayService.permitted(context)) return@Runnable
            val config = android.content.res.Configuration(context.resources.configuration)
            config.setLocale(Locale(language))
            val local = context.createConfigurationContext(config)
            val manager = context.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
                NotificationChannel(CHANNEL, local.getString(R.string.reminder_channel), NotificationManager.IMPORTANCE_HIGH))
            fun pending(action: String, code: Int): PendingIntent {
                val intent = Intent(context, MainActivity::class.java)
                    .setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    .setAction("remori.reminder.$receipt.$action")
                    .putExtra(TOKEN, receipt).putExtra(ACTION, action)
                return PendingIntent.getActivity(context, code, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            }
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL) else Notification.Builder(context)
            val notice = builder.setSmallIcon(R.drawable.ic_relay_notification)
                .setContentTitle(title).setContentText(time).setShowWhen(false)
                .setContentIntent(pending("open", 201)).setAutoCancel(true)
                .setCategory(Notification.CATEGORY_REMINDER).setPriority(Notification.PRIORITY_HIGH)
                .setVisibility(Notification.VISIBILITY_PRIVATE)
                .addAction(Notification.Action.Builder(null, local.getString(R.string.reminder_taken), pending("taken", 202)).build())
                .addAction(Notification.Action.Builder(null, local.getString(R.string.reminder_later), pending("later", 203)).build())
                .build()
            try { manager.notify(ID, notice); shown = true } catch (_: RuntimeException) { /* Permission revoked. */ }
        }
        task = work
        handler.postDelayed(work, (due - System.currentTimeMillis()).coerceAtLeast(0))
    }
}
