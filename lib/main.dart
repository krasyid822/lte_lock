import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'helpers/app_helpers.dart';

void main() {
  runApp(const LTETestingMenuApp());
}

class LTETestingMenuApp extends StatelessWidget {
  const LTETestingMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LTE Testing Menu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const TestingMenuScreen(),
    );
  }
}

class TestingMenuScreen extends StatefulWidget {
  const TestingMenuScreen({super.key});

  @override
  State<TestingMenuScreen> createState() => _TestingMenuScreenState();
}

class _TestingMenuScreenState extends State<TestingMenuScreen> {
  static const platform = MethodChannel('ltelock.rasyid/testing_menu');
  
  bool isLoading = false;
  String statusMessage = 'Tekan tombol untuk membuka menu testing';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      bool permissionsGranted = await PermissionHelper.requestAllPermissions(context);
      
      if (permissionsGranted) {
        setState(() {
          statusMessage = 'Permissions berhasil diberikan. Siap membuka testing menu.';
        });
      } else {
        setState(() {
          statusMessage = 'Beberapa permissions diperlukan untuk akses optimal.';
        });
      }
    }
  }

  Future<void> _openTestingMenu() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Membuka testing menu...';
    });

    try {
      await platform.invokeMethod('openTestingMenu');
      if (mounted) {
        setState(() {
          isLoading = false;
          statusMessage = 'Testing menu berhasil dibuka!';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Testing menu berhasil dibuka!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          statusMessage = 'Error: ${e.message}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LTE Testing Menu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo/lte-lock.png',
                height: 120,
                width: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.signal_cellular_4_bar,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Title
            Text(
              'LTE Testing Menu Access',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Aplikasi ini memungkinkan Anda mengakses menu testing Android yang sebelumnya tersedia melalui kode dial *#*#4636#*#*',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Status message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Main button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _openTestingMenu,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.settings_applications, size: 28),
                label: Text(
                  isLoading ? 'Membuka...' : 'Buka Testing Menu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Help text
            Text(
              'Menu testing berisi informasi jaringan, cell tower, signal strength, dan pengaturan radio lainnya.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const Spacer(),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.android,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Compatible with Android API 21+',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
