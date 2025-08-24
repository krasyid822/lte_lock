import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionHelper {
  static Future<bool> requestAllPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // List of permissions needed
    List<Permission> permissions = [
      Permission.phone,
      Permission.location,
      Permission.locationWhenInUse,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted && context.mounted) {
      // Show dialog explaining why permissions are needed
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: const Text(
            'Aplikasi ini memerlukan izin akses telephony dan lokasi untuk '
            'mengakses informasi radio dan jaringan. Tanpa izin ini, '
            'aplikasi tidak dapat berfungsi dengan baik.\n\n'
            'Silakan berikan izin melalui pengaturan aplikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
    }

    return allGranted;
  }

  static Future<bool> checkPermissions() async {
    if (!Platform.isAndroid) return true;

    final phonePermission = await Permission.phone.status;
    final locationPermission = await Permission.location.status;

    return phonePermission.isGranted && locationPermission.isGranted;
  }
}

class NetworkTypeHelper {
  static String getNetworkTypeDescription(String networkType) {
    switch (networkType.toUpperCase()) {
      case 'LTE':
        return '4G LTE - Long Term Evolution';
      case '5G NR':
        return '5G NR - New Radio';
      case 'HSPA+':
        return '3.5G HSPA+ - Evolved High Speed Packet Access';
      case 'HSPA':
        return '3.5G HSPA - High Speed Packet Access';
      case 'WCDMA':
      case 'UMTS':
        return '3G UMTS/WCDMA - Universal Mobile Telecommunications System';
      case 'EDGE':
        return '2.75G EDGE - Enhanced Data rates for GSM Evolution';
      case 'GPRS':
        return '2.5G GPRS - General Packet Radio Service';
      case 'GSM':
        return '2G GSM - Global System for Mobile Communications';
      case 'CDMA':
        return 'CDMA - Code Division Multiple Access';
      default:
        return networkType;
    }
  }

  static Color getNetworkTypeColor(String networkClass) {
    switch (networkClass) {
      case '5G':
        return Colors.purple;
      case '4G':
        return Colors.green;
      case '3G':
        return Colors.orange;
      case '2G':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getNetworkTypeIcon(String networkClass) {
    switch (networkClass) {
      case '5G':
        return Icons.signal_cellular_4_bar;
      case '4G':
        return Icons.signal_cellular_4_bar;
      case '3G':
        return Icons.signal_cellular_alt;
      case '2G':
        return Icons.signal_cellular_alt;
      default:
        return Icons.signal_cellular_0_bar;
    }
  }
}

class SignalStrengthHelper {
  static String getSignalQuality(String signalStrength) {
    if (signalStrength == 'Not available' || signalStrength == 'Unknown') {
      return 'Tidak tersedia';
    }

    try {
      int dbm = int.parse(signalStrength.replaceAll(' dBm', ''));
      if (dbm >= -70) {
        return 'Sangat Baik';
      } else if (dbm >= -85) {
        return 'Baik';
      } else if (dbm >= -100) {
        return 'Cukup';
      } else {
        return 'Buruk';
      }
    } catch (e) {
      return 'Tidak diketahui';
    }
  }

  static Color getSignalColor(String signalStrength) {
    String quality = getSignalQuality(signalStrength);
    switch (quality) {
      case 'Sangat Baik':
        return Colors.green;
      case 'Baik':
        return Colors.lightGreen;
      case 'Cukup':
        return Colors.orange;
      case 'Buruk':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
