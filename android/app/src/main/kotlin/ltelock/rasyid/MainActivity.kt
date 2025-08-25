package ltelock.rasyid

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ltelock.rasyid/testing_menu"
    private val TAG = "LTETestingMenu"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openTestingMenu" -> {
                    try {
                        openTestingMenu()
                        result.success("Testing menu opened successfully")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to open testing menu: ${e.message}")
                        result.error("ERROR", "Failed to open testing menu: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openTestingMenu() {
        try {
            // Method 1: Try standard RadioInfo intent
            val intent1 = Intent()
            intent1.setClassName("com.android.settings", "com.android.settings.RadioInfo")
            intent1.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent1)
            Log.d(TAG, "Opened testing menu via com.android.settings.RadioInfo")
            return
        } catch (e: Exception) {
            Log.w(TAG, "Method 1 failed: ${e.message}")
        }

        try {
            // Method 2: Try phone app RadioInfo
            val intent2 = Intent()
            intent2.action = "android.intent.action.MAIN"
            intent2.setClassName("com.android.phone", "com.android.phone.settings.RadioInfo")
            intent2.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent2)
            Log.d(TAG, "Opened testing menu via com.android.phone.settings.RadioInfo")
            return
        } catch (e: Exception) {
            Log.w(TAG, "Method 2 failed: ${e.message}")
        }

        try {
            // Method 3: Try Samsung specific
            val intent3 = Intent()
            intent3.setClassName("com.samsung.android.app.telephonyui", "com.samsung.android.app.telephonyui.netsettings.ui.NetSettingsActivity")
            intent3.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent3)
            Log.d(TAG, "Opened testing menu via Samsung telephonyui")
            return
        } catch (e: Exception) {
            Log.w(TAG, "Method 3 failed: ${e.message}")
        }

        try {
            // Method 4: Try generic testing settings
            val intent4 = Intent()
            intent4.action = "android.intent.action.MAIN"
            intent4.setClassName("com.android.settings", "com.android.settings.TestingSettings")
            intent4.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent4)
            Log.d(TAG, "Opened testing menu via com.android.settings.TestingSettings")
            return
        } catch (e: Exception) {
            Log.w(TAG, "Method 4 failed: ${e.message}")
        }

        try {
            // Method 5: Try dialer with secret code (may not work on newer Android)
            val intent5 = Intent(Intent.ACTION_CALL)
            intent5.data = android.net.Uri.parse("tel:*%23*%234636%23*%23*")
            intent5.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent5)
            Log.d(TAG, "Opened testing menu via dialer code")
            return
        } catch (e: Exception) {
            Log.w(TAG, "Method 5 failed: ${e.message}")
        }

        try {
            // Method 6: Last resort - try to open device info
            val intent6 = Intent()
            intent6.action = "android.settings.DEVICE_INFO_SETTINGS"
            intent6.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent6)
            Log.d(TAG, "Opened device info settings as fallback")
            return
        } catch (e: Exception) {
            Log.w(TAG, "Method 6 failed: ${e.message}")
        }

        // If all methods fail
        throw Exception("Testing menu tidak tersedia pada device ini. Fitur mungkin dibatasi oleh OEM atau Android security policy.")
    }
}
