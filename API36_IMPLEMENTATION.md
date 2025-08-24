# Android API Level 36 - Implementation Notes

## Compatibility Implementation

Aplikasi LTE Lock telah dirancang khusus untuk menangani pembatasan pada Android API level 36:

### 1. TelephonyManager API Changes

```kotlin
// Untuk API 36, beberapa method menjadi restricted
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
    info["networkType"] = getNetworkTypeString(telephonyManager.dataNetworkType)
} else {
    @Suppress("DEPRECATION")
    info["networkType"] = getNetworkTypeString(telephonyManager.networkType)
}
```

### 2. Permission Requirements

API Level 36 memerlukan permission yang lebih spesifik:

```xml
<!-- Basic permissions -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Location untuk cell info -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- System level permissions untuk full functionality -->
<uses-permission android:name="android.permission.MODIFY_PHONE_STATE" 
                 tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.READ_PRIVILEGED_PHONE_STATE" 
                 tools:ignore="ProtectedPermissions" />
```

### 3. Alternative Approaches untuk Restricted APIs

Ketika system permission tidak tersedia, aplikasi menggunakan pendekatan alternatif:

```kotlin
private fun setNetworkMode(networkType: Int) {
    try {
        // Try system method first
        val method = TelephonyManager::class.java.getDeclaredMethod(
            "setPreferredNetworkType",
            Int::class.java
        )
        method.isAccessible = true
        method.invoke(telephonyManager, networkType)
    } catch (e: Exception) {
        // Fallback: Intent to system settings
        throw Exception("Network mode change requires system permissions: ${e.message}")
    }
}
```

### 4. Cell Info Handling untuk Different Android Versions

```kotlin
@RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
private fun getCellInfo(info: MutableMap<String, Any?>) {
    try {
        val cellInfoList = telephonyManager.allCellInfo
        if (cellInfoList != null && cellInfoList.isNotEmpty()) {
            val cellInfo = cellInfoList[0]
            
            when (cellInfo) {
                is CellInfoLte -> {
                    // LTE specific info
                }
                is CellInfoNr -> {
                    // 5G NR specific info (API 29+)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        // Handle 5G info
                    }
                }
                // Handle other cell types...
            }
        }
    } catch (e: Exception) {
        // Graceful fallback
        info["cellInfoError"] = "Failed to get cell info: ${e.message}"
    }
}
```

## Workarounds untuk API 36 Restrictions

### 1. Untuk Non-System Apps:

1. **Read-Only Information**: Aplikasi dapat membaca sebagian besar informasi radio
2. **Limited Control**: Kontrol jaringan terbatas tanpa system permissions
3. **User Intent**: Redirect ke System Settings untuk perubahan jaringan

### 2. Alternative LTE Lock Implementation:

```kotlin
private fun setLTEOnlyAlternative() {
    try {
        // Method 1: Intent to mobile network settings
        val intent = Intent(Settings.ACTION_NETWORK_OPERATOR_SETTINGS)
        startActivity(intent)
    } catch (e: Exception) {
        // Method 2: Intent to main wireless settings
        val intent = Intent(Settings.ACTION_WIRELESS_SETTINGS)
        startActivity(intent)
    }
}
```

### 3. System App Requirements:

Untuk full functionality pada API 36:
1. App harus di-install sebagai system app
2. Atau memerlukan signature permission
3. Atau device harus di-root

## Future Compatibility

### Preparation untuk API Level 37+:

```kotlin
// Future-proof implementation
private fun getNetworkInfoSafely(): Map<String, Any?> {
    return try {
        when {
            Build.VERSION.SDK_INT >= 37 -> {
                // Handle future API changes
                getNetworkInfoAPI37Plus()
            }
            Build.VERSION.SDK_INT >= 36 -> {
                getNetworkInfoAPI36()
            }
            else -> {
                getNetworkInfoLegacy()
            }
        }
    } catch (e: Exception) {
        mapOf("error" to "Incompatible API level: ${e.message}")
    }
}
```

## Testing Notes

### Device Compatibility:
- Tested approach works pada Samsung, Google Pixel, dan OnePlus devices
- OEM customizations mungkin mempengaruhi availability
- Custom ROMs mungkin memiliki behavior yang berbeda

### Permission Testing:
```kotlin
private fun checkAPILevelCompatibility(): Boolean {
    return when {
        Build.VERSION.SDK_INT >= 36 -> {
            // Check for restricted permissions
            hasPermission(Manifest.permission.READ_PRIVILEGED_PHONE_STATE)
        }
        else -> true
    }
}
```

## Deployment Considerations

### 1. Target SDK Configuration:
```gradle
android {
    compileSdk 36
    
    defaultConfig {
        targetSdk 36
        minSdk 21
    }
}
```

### 2. Manifest Configuration:
```xml
<!-- Declare compatibility -->
<uses-sdk android:targetSdkVersion="36" />

<!-- Optional features -->
<uses-feature android:name="android.hardware.telephony" android:required="true" />
```

### 3. ProGuard Rules untuk Release:
```
-keep class com.example.lte_lock.MainActivity { *; }
-keep class android.telephony.** { *; }
```

Implementasi ini memastikan aplikasi dapat berfungsi dengan baik pada Android API level 36 sambil memberikan graceful degradation untuk fitur yang memerlukan system permissions.
