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
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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