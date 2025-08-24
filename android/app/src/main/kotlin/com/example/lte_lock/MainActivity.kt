package com.example.lte_lock

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.*
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.util.Log
import android.net.Network
import android.net.NetworkInfo
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*
import kotlin.collections.HashMap
import kotlin.random.Random
import java.net.InetAddress
import java.io.IOException
import kotlinx.coroutines.*

class MainActivity: FlutterActivity() {
    private val RADIO_CHANNEL = "com.example.lte_lock/radio_info"
    private val PERFORMANCE_CHANNEL = "com.example.lte_lock/performance"
    private val OPTIMIZATION_CHANNEL = "com.example.lte_lock/optimization"
    private val STABILITY_CHANNEL = "com.example.lte_lock/stability"
    
    private lateinit var telephonyManager: TelephonyManager
    private lateinit var subscriptionManager: SubscriptionManager
    private lateinit var connectivityManager: ConnectivityManager
    
    // Performance monitoring
    private var isPerformanceMonitoring = false
    private var performanceCoroutine: Job? = null
    
    // Stability monitoring
    private var isStabilityModeActive = false
    private var stabilityStartTime = 0L
    private var handoverCount = 0
    private var signalDrops = 0
    private var dataReconnections = 0
    private var signalQualitySum = 0.0
    private var signalQualityCount = 0

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
        connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        
        // Radio Info Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RADIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRadioInfo" -> {
                    try {
                        val radioInfo = getRadioInfo()
                        result.success(radioInfo)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get radio info: ${e.message}", null)
                    }
                }
                "openTestingMenu" -> {
                    try {
                        openTestingMenu()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open testing menu: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Performance Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERFORMANCE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPerformanceData" -> {
                    try {
                        val performanceData = getPerformanceData()
                        result.success(performanceData)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get performance data: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Optimization Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OPTIMIZATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "applyOptimization" -> {
                    try {
                        val setting = call.argument<String>("setting") ?: ""
                        val value = call.argument<Boolean>("value") ?: false
                        applyOptimization(setting, value)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to apply optimization: ${e.message}", null)
                    }
                }
                "optimizeAll" -> {
                    try {
                        optimizeAll()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to optimize all: ${e.message}", null)
                    }
                }
                "resetOptimizations" -> {
                    try {
                        resetOptimizations()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to reset optimizations: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Stability Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STABILITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStabilityMetrics" -> {
                    try {
                        val metrics = getStabilityMetrics()
                        result.success(metrics)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get stability metrics: ${e.message}", null)
                    }
                }
                "enableStabilityMode" -> {
                    try {
                        enableStabilityMode()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to enable stability mode: ${e.message}", null)
                    }
                }
                "disableStabilityMode" -> {
                    try {
                        disableStabilityMode()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to disable stability mode: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasPermission(permission: String): Boolean {
        return ActivityCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    // Radio Info Methods (existing)
    private fun getRadioInfo(): Map<String, Any?> {
        val info = mutableMapOf<String, Any?>()
        
        try {
            if (!hasPermission(Manifest.permission.READ_PHONE_STATE)) {
                throw SecurityException("READ_PHONE_STATE permission not granted")
            }

            // Basic telephony info
            info["operator"] = telephonyManager.networkOperatorName
            info["mcc"] = telephonyManager.networkOperator?.take(3) ?: "Unknown"
            info["mnc"] = telephonyManager.networkOperator?.drop(3) ?: "Unknown"
            info["isRoaming"] = telephonyManager.isNetworkRoaming
            info["dataState"] = getDataStateString(telephonyManager.dataState)
            info["dataActivity"] = getDataActivityString(telephonyManager.dataActivity)
            
            // Network type and technology
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                info["networkType"] = getNetworkTypeString(telephonyManager.dataNetworkType)
                info["radioTechnology"] = getRadioTechnologyString(telephonyManager.dataNetworkType)
                info["networkClass"] = getNetworkClassString(telephonyManager.dataNetworkType)
            } else {
                @Suppress("DEPRECATION")
                info["networkType"] = getNetworkTypeString(telephonyManager.networkType)
                @Suppress("DEPRECATION")
                info["radioTechnology"] = getRadioTechnologyString(telephonyManager.networkType)
                @Suppress("DEPRECATION")
                info["networkClass"] = getNetworkClassString(telephonyManager.networkType)
            }

            // Cell info for API 17+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                getCellInfo(info)
            }

            // Signal strength
            getSignalStrength(info)
            
        } catch (e: SecurityException) {
            info["error"] = "Permission denied: ${e.message}"
        } catch (e: Exception) {
            info["error"] = "Error getting radio info: ${e.message}"
        }
        
        return info
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
    private fun getCellInfo(info: MutableMap<String, Any?>) {
        try {
            val cellInfoList = telephonyManager.allCellInfo
            if (cellInfoList != null && cellInfoList.isNotEmpty()) {
                val cellInfo = cellInfoList[0]
                
                when (cellInfo) {
                    is CellInfoLte -> {
                        info["cellId"] = cellInfo.cellIdentity.ci
                        info["lac"] = cellInfo.cellIdentity.tac
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            info["signalStrength"] = cellInfo.cellSignalStrength.rsrp
                        }
                    }
                    is CellInfoGsm -> {
                        info["cellId"] = cellInfo.cellIdentity.cid
                        info["lac"] = cellInfo.cellIdentity.lac
                        info["signalStrength"] = cellInfo.cellSignalStrength.dbm
                    }
                    is CellInfoWcdma -> {
                        info["cellId"] = cellInfo.cellIdentity.cid
                        info["lac"] = cellInfo.cellIdentity.lac
                        info["signalStrength"] = cellInfo.cellSignalStrength.dbm
                    }
                    is CellInfoCdma -> {
                        info["cellId"] = cellInfo.cellIdentity.basestationId
                        info["signalStrength"] = cellInfo.cellSignalStrength.dbm
                    }
                    else -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            when (cellInfo) {
                                is CellInfoNr -> {
                                    val nrCellIdentity = cellInfo.cellIdentity as CellIdentityNr
                                    info["cellId"] = nrCellIdentity.nci
                                    info["lac"] = nrCellIdentity.tac
                                    info["signalStrength"] = cellInfo.cellSignalStrength.dbm
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            info["cellInfoError"] = "Failed to get cell info: ${e.message}"
        }
    }

    private fun getSignalStrength(info: MutableMap<String, Any?>) {
        try {
            // Signal strength is already captured in getCellInfo for newer APIs
            // This is fallback for older devices
            if (!info.containsKey("signalStrength")) {
                info["signalStrength"] = "Unknown"
            }
        } catch (e: Exception) {
            info["signalStrengthError"] = "Failed to get signal strength: ${e.message}"
        }
    }

    private fun openTestingMenu() {
        try {
            val intent = android.content.Intent()
            intent.setClassName("com.android.settings", "com.android.settings.RadioInfo")
            startActivity(intent)
        } catch (e: Exception) {
            // Try alternative intents for different Android versions
            try {
                val intent = android.content.Intent()
                intent.action = "android.intent.action.MAIN"
                intent.setClassName("com.android.phone", "com.android.phone.settings.RadioInfo")
                startActivity(intent)
            } catch (e2: Exception) {
                try {
                    // Try Samsung specific
                    val intent = android.content.Intent()
                    intent.setClassName("com.samsung.android.app.telephonyui", "com.samsung.android.app.telephonyui.netsettings.ui.NetSettingsActivity")
                    startActivity(intent)
                } catch (e3: Exception) {
                    // Try generic testing menu
                    try {
                        val intent = android.content.Intent()
                        intent.action = "android.intent.action.MAIN"
                        intent.setClassName("com.android.settings", "com.android.settings.TestingSettings")
                        startActivity(intent)
                    } catch (e4: Exception) {
                        throw Exception("Unable to open testing menu. This feature may not be available on this device.")
                    }
                }
            }
        }
    }

    // Performance Monitoring Methods
    private fun getPerformanceData(): Map<String, Any?> {
        val data = mutableMapOf<String, Any?>()
        
        try {
            // Get current signal strength
            val radioInfo = getRadioInfo()
            data["signalStrength"] = radioInfo["signalStrength"] ?: "Unknown"
            
            // Simulate network speed and latency (in real app, use actual network tests)
            data["downloadSpeed"] = getSimulatedDownloadSpeed()
            data["uploadSpeed"] = getSimulatedUploadSpeed()
            data["latency"] = getSimulatedLatency()
            data["jitter"] = getSimulatedJitter()
            data["packetLoss"] = getSimulatedPacketLoss()
            
            // Network state
            val networkInfo = connectivityManager.activeNetworkInfo
            data["isConnected"] = networkInfo?.isConnected ?: false
            data["connectionType"] = networkInfo?.typeName ?: "Unknown"
            
        } catch (e: Exception) {
            data["error"] = "Failed to get performance data: ${e.message}"
        }
        
        return data
    }

    private fun getSimulatedDownloadSpeed(): Double {
        // In real implementation, perform actual speed test
        return Random.nextDouble(10.0, 100.0) // Simulate 10-100 Mbps
    }

    private fun getSimulatedUploadSpeed(): Double {
        // In real implementation, perform actual speed test
        return Random.nextDouble(5.0, 50.0) // Simulate 5-50 Mbps
    }

    private fun getSimulatedLatency(): Double {
        // In real implementation, ping actual servers
        return Random.nextDouble(20.0, 100.0) // Simulate 20-100ms
    }

    private fun getSimulatedJitter(): Double {
        return Random.nextDouble(1.0, 20.0) // Simulate 1-20ms jitter
    }

    private fun getSimulatedPacketLoss(): Double {
        return Random.nextDouble(0.0, 5.0) // Simulate 0-5% packet loss
    }

    // Optimization Methods
    private fun applyOptimization(setting: String, value: Boolean) {
        // Note: Most of these require system-level permissions on API 36
        // This is simulated behavior for demonstration
        when (setting) {
            "force4G" -> {
                if (value) {
                    // Try to force 4G only mode
                    // On API 36, this typically requires system app privileges
                    Log.d("LTEOptimizer", "Attempting to force 4G only mode")
                } else {
                    Log.d("LTEOptimizer", "Disabling 4G only mode")
                }
            }
            "preferHighBand" -> {
                Log.d("LTEOptimizer", "${if (value) "Enabling" else "Disabling"} high band preference")
            }
            "aggressiveHandover" -> {
                Log.d("LTEOptimizer", "${if (value) "Enabling" else "Disabling"} aggressive handover")
            }
            "lowLatencyMode" -> {
                Log.d("LTEOptimizer", "${if (value) "Enabling" else "Disabling"} low latency mode")
            }
            "backgroundOptimization" -> {
                Log.d("LTEOptimizer", "${if (value) "Enabling" else "Disabling"} background optimization")
            }
        }
    }

    private fun optimizeAll() {
        // Apply all optimizations
        applyOptimization("force4G", true)
        applyOptimization("preferHighBand", true)
        applyOptimization("aggressiveHandover", true)
        applyOptimization("lowLatencyMode", true)
        applyOptimization("backgroundOptimization", true)
    }

    private fun resetOptimizations() {
        // Reset all optimizations
        applyOptimization("force4G", false)
        applyOptimization("preferHighBand", false)
        applyOptimization("aggressiveHandover", false)
        applyOptimization("lowLatencyMode", false)
        applyOptimization("backgroundOptimization", false)
    }

    // Stability Methods
    private fun getStabilityMetrics(): Map<String, Any?> {
        val metrics = mutableMapOf<String, Any?>()
        
        try {
            if (isStabilityModeActive) {
                val uptime = (System.currentTimeMillis() - stabilityStartTime) / (1000 * 60) // minutes
                metrics["uptime"] = uptime
                metrics["handoverCount"] = handoverCount
                metrics["signalDrops"] = signalDrops
                metrics["dataReconnections"] = dataReconnections
                
                val avgSignalQuality = if (signalQualityCount > 0) {
                    signalQualitySum / signalQualityCount
                } else {
                    0.0
                }
                metrics["avgSignalQuality"] = String.format("%.1f", avgSignalQuality)
                
                // Calculate stability score (0-100)
                val stabilityScore = calculateStabilityScore()
                metrics["stabilityScore"] = stabilityScore
            } else {
                metrics["uptime"] = 0
                metrics["handoverCount"] = 0
                metrics["signalDrops"] = 0
                metrics["dataReconnections"] = 0
                metrics["avgSignalQuality"] = "N/A"
                metrics["stabilityScore"] = 0
            }
        } catch (e: Exception) {
            metrics["error"] = "Failed to get stability metrics: ${e.message}"
        }
        
        return metrics
    }

    private fun enableStabilityMode() {
        isStabilityModeActive = true
        stabilityStartTime = System.currentTimeMillis()
        handoverCount = 0
        signalDrops = 0
        dataReconnections = 0
        signalQualitySum = 0.0
        signalQualityCount = 0
        
        // Start monitoring network stability
        startStabilityMonitoring()
    }

    private fun disableStabilityMode() {
        isStabilityModeActive = false
        stopStabilityMonitoring()
    }

    private fun startStabilityMonitoring() {
        // In real implementation, register network callbacks and monitor signal changes
        // For now, simulate periodic updates
        Log.d("LTEOptimizer", "Starting stability monitoring")
    }

    private fun stopStabilityMonitoring() {
        // Stop all monitoring
        Log.d("LTEOptimizer", "Stopping stability monitoring")
    }

    private fun calculateStabilityScore(): Int {
        if (!isStabilityModeActive) return 0
        
        val uptime = (System.currentTimeMillis() - stabilityStartTime) / (1000 * 60) // minutes
        if (uptime < 1) return 100 // Not enough data
        
        // Base score
        var score = 100.0
        
        // Penalize for signal drops
        score -= (signalDrops * 10.0)
        
        // Penalize for excessive handovers
        val handoverRate = handoverCount.toDouble() / uptime
        if (handoverRate > 2) { // More than 2 handovers per minute is bad
            score -= ((handoverRate - 2) * 15.0)
        }
        
        // Penalize for data reconnections
        score -= (dataReconnections * 15.0)
        
        return maxOf(0, minOf(100, score.toInt()))
    }

    // Helper methods (same as before)
    private fun getNetworkTypeString(networkType: Int): String {
        return when (networkType) {
            TelephonyManager.NETWORK_TYPE_GPRS -> "GPRS"
            TelephonyManager.NETWORK_TYPE_EDGE -> "EDGE"
            TelephonyManager.NETWORK_TYPE_UMTS -> "UMTS"
            TelephonyManager.NETWORK_TYPE_CDMA -> "CDMA"
            TelephonyManager.NETWORK_TYPE_EVDO_0 -> "EVDO_0"
            TelephonyManager.NETWORK_TYPE_EVDO_A -> "EVDO_A"
            TelephonyManager.NETWORK_TYPE_1xRTT -> "1xRTT"
            TelephonyManager.NETWORK_TYPE_HSDPA -> "HSDPA"
            TelephonyManager.NETWORK_TYPE_HSUPA -> "HSUPA"
            TelephonyManager.NETWORK_TYPE_HSPA -> "HSPA"
            TelephonyManager.NETWORK_TYPE_IDEN -> "iDEN"
            TelephonyManager.NETWORK_TYPE_EVDO_B -> "EVDO_B"
            TelephonyManager.NETWORK_TYPE_LTE -> "LTE"
            TelephonyManager.NETWORK_TYPE_EHRPD -> "eHRPD"
            TelephonyManager.NETWORK_TYPE_HSPAP -> "HSPA+"
            TelephonyManager.NETWORK_TYPE_GSM -> "GSM"
            TelephonyManager.NETWORK_TYPE_TD_SCDMA -> "TD_SCDMA"
            TelephonyManager.NETWORK_TYPE_IWLAN -> "IWLAN"
            else -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    when (networkType) {
                        TelephonyManager.NETWORK_TYPE_NR -> "5G NR"
                        else -> "Unknown ($networkType)"
                    }
                } else {
                    "Unknown ($networkType)"
                }
            }
        }
    }

    private fun getRadioTechnologyString(networkType: Int): String {
        return when (networkType) {
            TelephonyManager.NETWORK_TYPE_GPRS,
            TelephonyManager.NETWORK_TYPE_EDGE,
            TelephonyManager.NETWORK_TYPE_GSM -> "GSM"
            TelephonyManager.NETWORK_TYPE_UMTS,
            TelephonyManager.NETWORK_TYPE_HSDPA,
            TelephonyManager.NETWORK_TYPE_HSUPA,
            TelephonyManager.NETWORK_TYPE_HSPA,
            TelephonyManager.NETWORK_TYPE_HSPAP,
            TelephonyManager.NETWORK_TYPE_TD_SCDMA -> "WCDMA"
            TelephonyManager.NETWORK_TYPE_CDMA,
            TelephonyManager.NETWORK_TYPE_EVDO_0,
            TelephonyManager.NETWORK_TYPE_EVDO_A,
            TelephonyManager.NETWORK_TYPE_EVDO_B,
            TelephonyManager.NETWORK_TYPE_1xRTT,
            TelephonyManager.NETWORK_TYPE_EHRPD -> "CDMA"
            TelephonyManager.NETWORK_TYPE_LTE -> "LTE"
            TelephonyManager.NETWORK_TYPE_IWLAN -> "IWLAN"
            else -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    when (networkType) {
                        TelephonyManager.NETWORK_TYPE_NR -> "5G NR"
                        else -> "Unknown"
                    }
                } else {
                    "Unknown"
                }
            }
        }
    }

    private fun getNetworkClassString(networkType: Int): String {
        return when (networkType) {
            TelephonyManager.NETWORK_TYPE_GPRS,
            TelephonyManager.NETWORK_TYPE_EDGE,
            TelephonyManager.NETWORK_TYPE_CDMA,
            TelephonyManager.NETWORK_TYPE_1xRTT,
            TelephonyManager.NETWORK_TYPE_IDEN,
            TelephonyManager.NETWORK_TYPE_GSM -> "2G"
            TelephonyManager.NETWORK_TYPE_UMTS,
            TelephonyManager.NETWORK_TYPE_EVDO_0,
            TelephonyManager.NETWORK_TYPE_EVDO_A,
            TelephonyManager.NETWORK_TYPE_HSDPA,
            TelephonyManager.NETWORK_TYPE_HSUPA,
            TelephonyManager.NETWORK_TYPE_HSPA,
            TelephonyManager.NETWORK_TYPE_EVDO_B,
            TelephonyManager.NETWORK_TYPE_EHRPD,
            TelephonyManager.NETWORK_TYPE_HSPAP,
            TelephonyManager.NETWORK_TYPE_TD_SCDMA -> "3G"
            TelephonyManager.NETWORK_TYPE_LTE,
            TelephonyManager.NETWORK_TYPE_IWLAN -> "4G"
            else -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    when (networkType) {
                        TelephonyManager.NETWORK_TYPE_NR -> "5G"
                        else -> "Unknown"
                    }
                } else {
                    "Unknown"
                }
            }
        }
    }

    private fun getDataStateString(dataState: Int): String {
        return when (dataState) {
            TelephonyManager.DATA_DISCONNECTED -> "Disconnected"
            TelephonyManager.DATA_CONNECTING -> "Connecting"
            TelephonyManager.DATA_CONNECTED -> "Connected"
            TelephonyManager.DATA_SUSPENDED -> "Suspended"
            else -> "Unknown"
        }
    }

    private fun getDataActivityString(dataActivity: Int): String {
        return when (dataActivity) {
            TelephonyManager.DATA_ACTIVITY_NONE -> "None"
            TelephonyManager.DATA_ACTIVITY_IN -> "In"
            TelephonyManager.DATA_ACTIVITY_OUT -> "Out"
            TelephonyManager.DATA_ACTIVITY_INOUT -> "In/Out"
            TelephonyManager.DATA_ACTIVITY_DORMANT -> "Dormant"
            else -> "Unknown"
        }
    }
}
