import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'helpers/app_helpers.dart';

void main() {
  runApp(const LTE4GOptimizerApp());
}

class LTE4GOptimizerApp extends StatelessWidget {
  const LTE4GOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4G Performance Optimizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('4G Performance Optimizer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'Monitor'),
            Tab(icon: Icon(Icons.tune), text: 'Optimize'),
            Tab(icon: Icon(Icons.network_check), text: 'Network'),
            Tab(icon: Icon(Icons.info), text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PerformanceMonitorTab(),
          OptimizationTab(),
          NetworkStabilityTab(),
          RadioInfoTab(),
        ],
      ),
    );
  }
}

// Tab 1: Performance Monitor
class PerformanceMonitorTab extends StatefulWidget {
  const PerformanceMonitorTab({super.key});

  @override
  State<PerformanceMonitorTab> createState() => _PerformanceMonitorTabState();
}

class _PerformanceMonitorTabState extends State<PerformanceMonitorTab> {
  static const platform = MethodChannel('com.example.lte_lock/performance');

  Map<String, dynamic> performanceData = {};
  bool isMonitoring = false;
  Timer? _monitoringTimer;
  List<double> signalHistory = [];
  List<double> speedHistory = [];
  List<double> latencyHistory = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      bool permissionsGranted = await PermissionHelper.requestAllPermissions(
        context,
      );
      if (permissionsGranted) {
        _startMonitoring();
      }
    }
  }

  void _startMonitoring() {
    setState(() {
      isMonitoring = true;
    });

    _monitoringTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updatePerformanceData();
    });

    _updatePerformanceData();
  }

  void _stopMonitoring() {
    setState(() {
      isMonitoring = false;
    });
    _monitoringTimer?.cancel();
  }

  Future<void> _updatePerformanceData() async {
    try {
      final result = await platform.invokeMethod('getPerformanceData');
      if (mounted) {
        setState(() {
          performanceData = Map<String, dynamic>.from(result);

          // Update history
          if (performanceData['signalStrength'] != null) {
            signalHistory.add(performanceData['signalStrength'].toDouble());
            if (signalHistory.length > 20) signalHistory.removeAt(0);
          }

          if (performanceData['downloadSpeed'] != null) {
            speedHistory.add(performanceData['downloadSpeed'].toDouble());
            if (speedHistory.length > 20) speedHistory.removeAt(0);
          }

          if (performanceData['latency'] != null) {
            latencyHistory.add(performanceData['latency'].toDouble());
            if (latencyHistory.length > 20) latencyHistory.removeAt(0);
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating performance data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Control Panel
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isMonitoring
                        ? _stopMonitoring
                        : _startMonitoring,
                    icon: Icon(isMonitoring ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      isMonitoring ? 'Stop Monitor' : 'Start Monitor',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        signalHistory.clear();
                        speedHistory.clear();
                        latencyHistory.clear();
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Data'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Performance Metrics
          Expanded(
            child: ListView(
              children: [
                _buildMetricCard(
                  'Signal Strength',
                  '${performanceData['signalStrength'] ?? 'N/A'} dBm',
                  Icons.signal_cellular_4_bar,
                  _getSignalColor(performanceData['signalStrength']),
                  signalHistory,
                ),

                _buildMetricCard(
                  'Download Speed',
                  '${performanceData['downloadSpeed'] ?? 'N/A'} Mbps',
                  Icons.download,
                  Colors.blue,
                  speedHistory,
                ),

                _buildMetricCard(
                  'Upload Speed',
                  '${performanceData['uploadSpeed'] ?? 'N/A'} Mbps',
                  Icons.upload,
                  Colors.green,
                  null,
                ),

                _buildMetricCard(
                  'Latency (Ping)',
                  '${performanceData['latency'] ?? 'N/A'} ms',
                  Icons.timer,
                  _getLatencyColor(performanceData['latency']),
                  latencyHistory,
                ),

                _buildMetricCard(
                  'Jitter',
                  '${performanceData['jitter'] ?? 'N/A'} ms',
                  Icons.timeline,
                  _getJitterColor(performanceData['jitter']),
                  null,
                ),

                _buildMetricCard(
                  'Packet Loss',
                  '${performanceData['packetLoss'] ?? 'N/A'}%',
                  Icons.warning,
                  _getPacketLossColor(performanceData['packetLoss']),
                  null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    List<double>? history,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (history != null && history.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: CustomPaint(
                  painter: SimpleLinePainter(history, color),
                  size: Size.infinite,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSignalColor(dynamic signal) {
    if (signal == null) return Colors.grey;
    int value = signal is int ? signal : int.tryParse(signal.toString()) ?? 0;
    if (value > -70) return Colors.green;
    if (value > -85) return Colors.orange;
    return Colors.red;
  }

  Color _getLatencyColor(dynamic latency) {
    if (latency == null) return Colors.grey;
    double value = latency is double
        ? latency
        : double.tryParse(latency.toString()) ?? 0;
    if (value < 50) return Colors.green;
    if (value < 100) return Colors.orange;
    return Colors.red;
  }

  Color _getJitterColor(dynamic jitter) {
    if (jitter == null) return Colors.grey;
    double value = jitter is double
        ? jitter
        : double.tryParse(jitter.toString()) ?? 0;
    if (value < 10) return Colors.green;
    if (value < 20) return Colors.orange;
    return Colors.red;
  }

  Color _getPacketLossColor(dynamic packetLoss) {
    if (packetLoss == null) return Colors.grey;
    double value = packetLoss is double
        ? packetLoss
        : double.tryParse(packetLoss.toString()) ?? 0;
    if (value < 1) return Colors.green;
    if (value < 3) return Colors.orange;
    return Colors.red;
  }
}

// Tab 2: Optimization
class OptimizationTab extends StatefulWidget {
  const OptimizationTab({super.key});

  @override
  State<OptimizationTab> createState() => _OptimizationTabState();
}

class _OptimizationTabState extends State<OptimizationTab> {
  static const platform = MethodChannel('com.example.lte_lock/optimization');

  bool isOptimizing = false;
  Map<String, bool> optimizationSettings = {
    'force4G': false,
    'preferHighBand': false,
    'aggressiveHandover': false,
    'lowLatencyMode': false,
    'backgroundOptimization': false,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '4G Network Optimization',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Force 4G Only'),
                    subtitle: const Text('Lock network to 4G/LTE only'),
                    value: optimizationSettings['force4G']!,
                    onChanged: (value) {
                      setState(() {
                        optimizationSettings['force4G'] = value;
                      });
                      _applyOptimization('force4G', value);
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Prefer High Band'),
                    subtitle: const Text(
                      'Prioritize higher frequency bands for better speed',
                    ),
                    value: optimizationSettings['preferHighBand']!,
                    onChanged: (value) {
                      setState(() {
                        optimizationSettings['preferHighBand'] = value;
                      });
                      _applyOptimization('preferHighBand', value);
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Aggressive Handover'),
                    subtitle: const Text('Quick switching between cell towers'),
                    value: optimizationSettings['aggressiveHandover']!,
                    onChanged: (value) {
                      setState(() {
                        optimizationSettings['aggressiveHandover'] = value;
                      });
                      _applyOptimization('aggressiveHandover', value);
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Low Latency Mode'),
                    subtitle: const Text(
                      'Optimize for gaming and real-time apps',
                    ),
                    value: optimizationSettings['lowLatencyMode']!,
                    onChanged: (value) {
                      setState(() {
                        optimizationSettings['lowLatencyMode'] = value;
                      });
                      _applyOptimization('lowLatencyMode', value);
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Background Optimization'),
                    subtitle: const Text('Continuous network optimization'),
                    value: optimizationSettings['backgroundOptimization']!,
                    onChanged: (value) {
                      setState(() {
                        optimizationSettings['backgroundOptimization'] = value;
                      });
                      _applyOptimization('backgroundOptimization', value);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _optimizeAll,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Auto Optimize'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetOptimizations,
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _applyOptimization(String setting, bool value) async {
    try {
      await platform.invokeMethod('applyOptimization', {
        'setting': setting,
        'value': value,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$setting ${value ? 'enabled' : 'disabled'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _optimizeAll() async {
    setState(() {
      isOptimizing = true;
    });

    try {
      await platform.invokeMethod('optimizeAll');

      // Update all settings to optimized state
      setState(() {
        optimizationSettings['force4G'] = true;
        optimizationSettings['preferHighBand'] = true;
        optimizationSettings['aggressiveHandover'] = true;
        optimizationSettings['lowLatencyMode'] = true;
        optimizationSettings['backgroundOptimization'] = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All optimizations applied!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() {
        isOptimizing = false;
      });
    }
  }

  Future<void> _resetOptimizations() async {
    try {
      await platform.invokeMethod('resetOptimizations');

      setState(() {
        optimizationSettings.updateAll((key, value) => false);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All optimizations reset!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// Tab 3: Network Stability
class NetworkStabilityTab extends StatefulWidget {
  const NetworkStabilityTab({super.key});

  @override
  State<NetworkStabilityTab> createState() => _NetworkStabilityTabState();
}

class _NetworkStabilityTabState extends State<NetworkStabilityTab> {
  static const platform = MethodChannel('com.example.lte_lock/stability');

  bool isStabilityModeActive = false;
  Map<String, dynamic> stabilityMetrics = {};
  Timer? _stabilityTimer;

  @override
  void initState() {
    super.initState();
    _updateStabilityMetrics();
  }

  @override
  void dispose() {
    _stabilityTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateStabilityMetrics() async {
    try {
      final result = await platform.invokeMethod('getStabilityMetrics');
      if (mounted) {
        setState(() {
          stabilityMetrics = Map<String, dynamic>.from(result);
        });
      }
    } catch (e) {
      debugPrint('Error updating stability metrics: $e');
    }
  }

  Future<void> _toggleStabilityMode() async {
    try {
      if (isStabilityModeActive) {
        await platform.invokeMethod('disableStabilityMode');
        _stabilityTimer?.cancel();
      } else {
        await platform.invokeMethod('enableStabilityMode');
        _stabilityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _updateStabilityMetrics();
        });
      }

      setState(() {
        isStabilityModeActive = !isStabilityModeActive;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stability mode ${isStabilityModeActive ? 'enabled' : 'disabled'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Stability Control
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Network Stability Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: isStabilityModeActive,
                        onChanged: (value) => _toggleStabilityMode(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prevents connection drops and maintains optimal signal quality',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stability Metrics
          Expanded(
            child: ListView(
              children: [
                _buildStabilityCard(
                  'Connection Uptime',
                  '${stabilityMetrics['uptime'] ?? '0'} minutes',
                  Icons.timer,
                  Colors.green,
                ),

                _buildStabilityCard(
                  'Handover Count',
                  '${stabilityMetrics['handoverCount'] ?? '0'}',
                  Icons.swap_horiz,
                  Colors.blue,
                ),

                _buildStabilityCard(
                  'Signal Drops',
                  '${stabilityMetrics['signalDrops'] ?? '0'}',
                  Icons.signal_cellular_off,
                  Colors.red,
                ),

                _buildStabilityCard(
                  'Data Reconnections',
                  '${stabilityMetrics['dataReconnections'] ?? '0'}',
                  Icons.refresh,
                  Colors.orange,
                ),

                _buildStabilityCard(
                  'Average Signal Quality',
                  '${stabilityMetrics['avgSignalQuality'] ?? 'Unknown'}',
                  Icons.signal_cellular_4_bar,
                  Colors.green,
                ),

                _buildStabilityCard(
                  'Network Stability Score',
                  '${stabilityMetrics['stabilityScore'] ?? '0'}%',
                  Icons.assessment,
                  _getStabilityScoreColor(stabilityMetrics['stabilityScore']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getStabilityScoreColor(dynamic score) {
    if (score == null) return Colors.grey;
    double value = score is double
        ? score
        : double.tryParse(score.toString()) ?? 0;
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.orange;
    return Colors.red;
  }
}

// Tab 4: Radio Info (reuse from original)
class RadioInfoTab extends StatefulWidget {
  const RadioInfoTab({super.key});

  @override
  State<RadioInfoTab> createState() => _RadioInfoTabState();
}

class _RadioInfoTabState extends State<RadioInfoTab> {
  static const platform = MethodChannel('com.example.lte_lock/radio_info');

  Map<String, dynamic> radioInfo = {};
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      bool permissionsGranted = await PermissionHelper.requestAllPermissions(
        context,
      );

      if (permissionsGranted) {
        _getRadioInfo();
      } else {
        setState(() {
          errorMessage = 'Izin diperlukan untuk mengakses informasi radio';
        });
      }
    }
  }

  Future<void> _getRadioInfo() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await platform.invokeMethod('getRadioInfo');
      if (mounted) {
        setState(() {
          radioInfo = Map<String, dynamic>.from(result);
          isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: ${e.message}';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openTestingMenu() async {
    try {
      await platform.invokeMethod('openTestingMenu');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membuka menu testing...')),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  Widget _buildInfoCard(
    String title,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: valueColor) : null,
        title: Text(title),
        subtitle: Text(value),
        trailing: valueColor != null
            ? Icon(Icons.circle, color: valueColor, size: 12)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Control buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openTestingMenu,
                      icon: const Icon(Icons.settings_applications),
                      label: const Text('Buka Testing Menu'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getRadioInfo,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Info'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Error message
          if (errorMessage.isNotEmpty)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Radio info display
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : radioInfo.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada data radio info. Tekan refresh untuk mencoba lagi.',
                    ),
                  )
                : ListView(
                    children: [
                      _buildInfoCard(
                        'Network Type',
                        NetworkTypeHelper.getNetworkTypeDescription(
                          radioInfo['networkType'] ?? 'Unknown',
                        ),
                        icon: NetworkTypeHelper.getNetworkTypeIcon(
                          radioInfo['networkClass'] ?? '',
                        ),
                        valueColor: NetworkTypeHelper.getNetworkTypeColor(
                          radioInfo['networkClass'] ?? '',
                        ),
                      ),

                      _buildInfoCard(
                        'Signal Strength',
                        '${radioInfo['signalStrength'] ?? 'Unknown'} dBm (${SignalStrengthHelper.getSignalQuality(radioInfo['signalStrength']?.toString() ?? '')})',
                        icon: Icons.signal_cellular_4_bar,
                        valueColor: SignalStrengthHelper.getSignalColor(
                          radioInfo['signalStrength']?.toString() ?? '',
                        ),
                      ),

                      _buildInfoCard(
                        'Operator',
                        radioInfo['operator'] ?? 'Unknown',
                      ),
                      _buildInfoCard('MCC', radioInfo['mcc'] ?? 'Unknown'),
                      _buildInfoCard('MNC', radioInfo['mnc'] ?? 'Unknown'),
                      _buildInfoCard(
                        'Cell ID',
                        radioInfo['cellId']?.toString() ?? 'Unknown',
                      ),
                      _buildInfoCard(
                        'LAC/TAC',
                        radioInfo['lac']?.toString() ?? 'Unknown',
                      ),
                      _buildInfoCard(
                        'Data State',
                        radioInfo['dataState'] ?? 'Unknown',
                      ),
                      _buildInfoCard(
                        'Data Activity',
                        radioInfo['dataActivity'] ?? 'Unknown',
                      ),
                      _buildInfoCard(
                        'Roaming',
                        radioInfo['isRoaming']?.toString() ?? 'Unknown',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for simple line charts
class SimpleLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SimpleLinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Find min/max for scaling
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) return;

    // Draw line
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
