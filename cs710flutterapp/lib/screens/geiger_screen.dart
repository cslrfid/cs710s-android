import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/geiger_state_provider.dart';
import '../providers/connection_state_provider.dart';
import '../providers/scan_state_provider.dart';
import '../widgets/battery_indicator.dart';
import '../utils/formatters.dart';

/// Geiger search screen for locating specific tags
class GeigerScreen extends ConsumerStatefulWidget {
  const GeigerScreen({super.key});

  @override
  ConsumerState<GeigerScreen> createState() => _GeigerScreenState();
}

class _GeigerScreenState extends ConsumerState<GeigerScreen> {
  final TextEditingController _epcController = TextEditingController();
  StreamSubscription? _triggerSubscription;

  @override
  void initState() {
    super.initState();
    // Check if EPC was passed as argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['epc'] != null) {
        _epcController.text = args['epc'] as String;
      }

      // Enable trigger key monitoring
      _enableTriggerKey();
    });
  }

  @override
  void dispose() {
    _epcController.dispose();
    // Stop search when leaving screen
    // Use ref before calling super.dispose() to avoid "ref after disposal" error
    try {
      final geigerNotifier = ref.read(geigerStateNotifierProvider.notifier);
      geigerNotifier.stopGeigerSearch();

      // Disable trigger monitoring
      _disableTriggerKey();
    } catch (e) {
      print('Warning: Could not stop geiger search on dispose: $e');
    }
    super.dispose();
  }

  Future<void> _startSearch() async {
    final epc = _epcController.text.trim();
    if (epc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an EPC to search for'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final geigerNotifier = ref.read(geigerStateNotifierProvider.notifier);

    // Reset proximity to zero before starting search
    geigerNotifier.resetProximity();

    // Always use EPC memory bank (1)
    await geigerNotifier.startGeigerSearch(epc, memoryBank: 1);
  }

  Future<void> _stopSearch() async {
    final geigerNotifier = ref.read(geigerStateNotifierProvider.notifier);
    await geigerNotifier.stopGeigerSearch();
  }

  /// Enable trigger key monitoring
  /// Trigger will automatically start/stop Geiger search when pressed/released
  Future<void> _enableTriggerKey() async {
    final connectionState = ref.read(connectionStateNotifierProvider);
    if (!connectionState.isReady) {
      return;
    }

    try {
      final rfidService = ref.read(rfidServiceProvider);
      await rfidService.enableTrigger(autoInventory: false);

      // Listen to trigger events and simulate button press
      _triggerSubscription = rfidService.triggerEvents.listen((event) {
        final geigerState = ref.read(geigerStateNotifierProvider);

        if (event.pressed) {
          // Trigger pressed - start search if not already running
          if (!geigerState.isSearching) {
            _startSearch();
          }
        } else {
          // Trigger released - stop search if running
          if (geigerState.isSearching) {
            _stopSearch();
          }
        }
      });
    } catch (e) {
      print('Warning: Could not enable trigger key: $e');
    }
  }

  /// Disable trigger key monitoring
  Future<void> _disableTriggerKey() async {
    try {
      await _triggerSubscription?.cancel();
      _triggerSubscription = null;

      final rfidService = ref.read(rfidServiceProvider);
      await rfidService.disableTrigger();
    } catch (e) {
      print('Warning: Could not disable trigger key: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionStateNotifierProvider);
    final geigerState = ref.watch(geigerStateNotifierProvider);

    if (!connectionState.isReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Locate Tag')),
        body: const Center(
          child: Text('Please connect to a reader first'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locate Tag (Geiger Mode)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Battery indicator
            const Center(child: BatteryIndicator()),
            const SizedBox(height: 16),

            // EPC Input
            _buildEpcInput(geigerState),

            const SizedBox(height: 16),

            // Control Buttons
            _buildControlButtons(geigerState),

            const SizedBox(height: 24),

            // Proximity Indicator - always visible
            _buildProximityIndicator(geigerState),
          ],
        ),
      ),
    );
  }

  /// Build EPC input field
  Widget _buildEpcInput(GeigerState geigerState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target EPC',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _epcController,
          enabled: !geigerState.isSearching,
          decoration: const InputDecoration(
            hintText: 'Enter EPC (e.g., E280117...)',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ],
    );
  }

  /// Build control buttons
  Widget _buildControlButtons(GeigerState geigerState) {
    return ElevatedButton.icon(
      onPressed: geigerState.isSearching ? _stopSearch : _startSearch,
      icon: Icon(
        geigerState.isSearching ? Icons.stop : Icons.location_searching,
      ),
      label: Text(
        geigerState.isSearching ? 'Stop Search' : 'Start Search',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            geigerState.isSearching ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  /// Build proximity indicator
  Widget _buildProximityIndicator(GeigerState geigerState) {
    final proximity = geigerState.proximity;
    final bars = geigerState.proximityBars;
    final description = geigerState.proximityDescription;
    final isTagFound = geigerState.isTagFound;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Proximity percentage
            Text(
              '${proximity.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getProximityColor(proximity),
                  ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _getProximityColor(proximity),
                    fontWeight: FontWeight.w500,
                  ),
            ),

            const SizedBox(height: 20),

            // Proximity bars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final isActive = index < bars;
                return Container(
                  width: 40,
                  height: isActive ? 60 + (index * 10) : 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _getProximityColor(proximity)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Linear progress indicator
            LinearProgressIndicator(
              value: proximity / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProximityColor(proximity),
              ),
              minHeight: 10,
            ),

            const SizedBox(height: 16),

            // Tag found indicator
            if (isTagFound)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Tag Found',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get color based on proximity
  Color _getProximityColor(double proximity) {
    if (proximity < 20) return Colors.grey;           // Very Far
    if (proximity < 40) return Colors.yellow[700]!;   // Far
    if (proximity < 60) return Colors.orange[400]!;   // Medium
    if (proximity < 80) return Colors.orange[700]!;   // Close
    return Colors.green;                               // Very Close
  }
}
