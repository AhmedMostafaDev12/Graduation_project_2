package org.AI.remori

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var relayChannel: MethodChannel? = null
    private var resumed = false

    override fun onResume() { super.onResume(); resumed = true }
    override fun onPause() { resumed = false; super.onPause() }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(RemoriRelayService.OPEN_PATIENT, false)) {
            relayChannel?.invokeMethod("openPatient", null)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        relayChannel?.setMethodCallHandler(null)
        relayChannel = null
        RemoriRelayService.stop(this)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        relayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "remori/relay")
        relayChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "apply" -> result.success(RemoriRelayService.apply(this,
                    call.argument<String>("language") ?: "ar",
                    call.argument<String>("link") ?: "disconnected",
                    call.argument<Boolean>("simulated") == true,
                    resumed && call.argument<Boolean>("mayStart") == true))
                "stop" -> { RemoriRelayService.stop(this); result.success(null) }
                "takeOpenRequest" -> {
                    val open = intent?.getBooleanExtra(RemoriRelayService.OPEN_PATIENT, false) == true
                    intent?.removeExtra(RemoriRelayService.OPEN_PATIENT)
                    result.success(open)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "remori/permissions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "androidSdk" -> result.success(Build.VERSION.SDK_INT)
                    "backgroundAllowed" -> {
                        val power = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(power.isIgnoringBatteryOptimizations(packageName))
                    }
                    "openBatterySettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                            result.success(null)
                        } catch (_: ActivityNotFoundException) {
                            try {
                                startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                    Uri.parse("package:$packageName")))
                                result.success(null)
                            } catch (_: ActivityNotFoundException) {
                                result.error("SETTINGS_UNAVAILABLE", "Settings unavailable", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
