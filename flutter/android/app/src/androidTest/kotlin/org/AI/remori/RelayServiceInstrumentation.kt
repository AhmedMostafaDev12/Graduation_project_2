package org.AI.remori

import android.Manifest
import android.app.Activity
import android.app.Instrumentation
import android.app.Notification
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle

/** SDK-only emulator smoke test; no extra test framework or real user account. */
class RelayServiceInstrumentation : Instrumentation() {
    override fun onCreate(arguments: Bundle?) { super.onCreate(arguments); start() }
    override fun onStart() {
        val report = Bundle()
        try {
            check(Build.VERSION.SDK_INT >= 33) { "Run on API 33 or newer" }
            val app = targetContext
            runOnMainSync { RemoriRelayService.stop(app) }
            check(!RemoriRelayService.permitted(app)) { "Clean install must begin without runtime permissions" }
            uiAutomation.grantRuntimePermission(app.packageName, Manifest.permission.BLUETOOTH_CONNECT)
            check(!RemoriRelayService.permitted(app)) { "Missing notification permission must block startup" }
            uiAutomation.grantRuntimePermission(app.packageName, Manifest.permission.POST_NOTIFICATIONS)
            check(RemoriRelayService.permitted(app)) { "Granted permissions should allow startup" }

            val activity = startActivitySync(Intent(app, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            Thread.sleep(1500)
            val manager = app.getSystemService(NotificationManager::class.java)
            var accepted = false
            runOnMainSync { accepted = RemoriRelayService.apply(app, "en", "connected", false, true) }
            check(accepted) { "Foreground start must be accepted" }
            waitFor { manager.activeNotifications.isNotEmpty() }
            var notice = manager.activeNotifications.single().notification
            check(notice.extras.getString(Notification.EXTRA_TITLE) == app.getString(R.string.relay_connected)) { "Connected English title" }
            check(notice.flags and Notification.FLAG_ONGOING_EVENT != 0) { "Ongoing notification" }
            check(notice.contentIntent.isImmutable) { "Immutable notification intent" }
            check(notice.extras.getString(Notification.EXTRA_TEXT) == app.getString(R.string.relay_pending_body)) { "Must not claim background sync" }

            runOnMainSync { accepted = RemoriRelayService.apply(app, "ar", "disconnected", true, false) }
            check(accepted) { "Existing service may update without requesting a new start" }
            waitFor { manager.activeNotifications.singleOrNull()?.notification?.extras?.getString(Notification.EXTRA_TITLE)?.contains("محاكاة") == true }
            notice = manager.activeNotifications.single().notification
            check(notice.extras.getString(Notification.EXTRA_TITLE)?.contains("محاكاة") == true) { "Arabic development simulation label" }
            check(notice.extras.getString(Notification.EXTRA_TEXT)?.contains("مش متصلة") == true) { "Disconnected simulation status" }

            val reminder = mapOf("token" to "test-receipt", "due" to System.currentTimeMillis() + 500,
                "title" to "Test reminder", "time" to "9:00 AM", "language" to "en")
            runOnMainSync { ReminderNotifications.update(app, reminder) }
            check(manager.activeNotifications.none { it.id == 102 }) { "Future reminder must wait" }
            waitFor { manager.activeNotifications.any { it.id == 102 } }
            val reminderNotice = manager.activeNotifications.single { it.id == 102 }.notification
            check(reminderNotice.extras.getString(Notification.EXTRA_TITLE) == "Test reminder") { "Actual reminder title" }
            check(reminderNotice.actions.map { it.title.toString() } == listOf("Taken", "Later")) { "Reminder actions" }
            check(reminderNotice.contentIntent.isImmutable && reminderNotice.actions.all { it.actionIntent.isImmutable }) { "Immutable reminder intents" }
            check(reminderNotice.visibility == Notification.VISIBILITY_PRIVATE) { "Lock-screen privacy" }
            runOnMainSync { ReminderNotifications.clear(app) }
            runOnMainSync { ReminderNotifications.update(app, reminder + mapOf("token" to "future", "due" to System.currentTimeMillis() + 3000)) }

            runOnMainSync { RemoriRelayService.stop(app) }
            waitFor { manager.activeNotifications.isEmpty() }
            Thread.sleep(3200)
            check(manager.activeNotifications.isEmpty()) { "Stopped relay must cancel pending reminders" }
            runOnMainSync { activity.moveTaskToBack(true) }
            runOnMainSync { accepted = RemoriRelayService.apply(app, "en", "connected", false, false) }
            check(!accepted && manager.activeNotifications.isEmpty()) { "No new background start" }
            runOnMainSync { activity.finishAndRemoveTask() }
            report.putString("stream", "D1/D2 native permission, foreground, reminder scheduling, actions, privacy and stop checks passed\n")
            finish(Activity.RESULT_OK, report)
        } catch (error: Throwable) {
            runOnMainSync { RemoriRelayService.stop(targetContext) }
            report.putString("stream", "D1 native smoke failure: ${error.javaClass.simpleName}: ${error.message}\n")
            finish(Activity.RESULT_CANCELED, report)
        }
    }
    private fun waitFor(predicate: () -> Boolean) {
        repeat(50) { if (predicate()) return; Thread.sleep(100) }
        error("Timed out waiting for native service state")
    }
}
