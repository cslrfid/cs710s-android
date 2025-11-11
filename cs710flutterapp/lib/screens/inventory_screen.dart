import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_state_provider.dart';
import '../providers/connection_state_provider.dart';
import '../providers/scan_state_provider.dart';
import '../models/rfid_configuration.dart';
import '../widgets/tag_list_item.dart';
import '../widgets/stats_card.dart';
import '../widgets/battery_indicator.dart';
import '../utils/formatters.dart';

/// Inventory screen for RFID tags and barcodes
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SortBy _sortBy = SortBy.timestamp;
  StreamSubscription? _triggerSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Apply reader configuration when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyReaderConfiguration();
      _enableTriggerKey();
    });
  }

  /// Apply reader configuration when inventory page loads
  /// Configuration matches cs710aquickstart defaults
  Future<void> _applyReaderConfiguration() async {
    final connectionState = ref.read(connectionStateNotifierProvider);

    // Only configure if reader is connected
    if (!connectionState.isReady) {
      return;
    }

    try {
      // Build configuration using fluent API
      final config = RfidConfiguration.builder()
          .powerLevel(300)           // 30.0 dBm
          .session(1)                // Session 1
          .target('A')               // Target A
          .inventoryMode('COMPACT')  // Compact mode
          .qValue(7)                 // Q = 7
          .enableBeep(true)          // Enable beep
          .enableVibrate(true)       // Enable vibrate
          .build();

      final rfidService = ref.read(rfidServiceProvider);
      await rfidService.applyConfiguration(config);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reader configured successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Stop inventory when leaving screen
    // Use ref before calling super.dispose() to avoid "ref after disposal" error
    try {
      final rfidNotifier = ref.read(rfidInventoryStateNotifierProvider.notifier);
      final barcodeNotifier =
          ref.read(barcodeInventoryStateNotifierProvider.notifier);
      rfidNotifier.stopInventory();
      barcodeNotifier.stopBarcodeScan();

      // Disable trigger monitoring
      _disableTriggerKey();
    } catch (e) {
      print('Warning: Could not stop inventory on dispose: $e');
    }
    super.dispose();
  }

  Future<void> _startRfidInventory() async {
    final notifier = ref.read(rfidInventoryStateNotifierProvider.notifier);
    await notifier.startInventory();
  }

  Future<void> _stopRfidInventory() async {
    final notifier = ref.read(rfidInventoryStateNotifierProvider.notifier);
    await notifier.stopInventory();
  }

  void _clearRfidTags() {
    final notifier = ref.read(rfidInventoryStateNotifierProvider.notifier);
    notifier.clearTags();
  }

  Future<void> _startBarcodeScanning() async {
    final notifier = ref.read(barcodeInventoryStateNotifierProvider.notifier);
    await notifier.startBarcodeScan();
  }

  Future<void> _stopBarcodeScanning() async {
    final notifier = ref.read(barcodeInventoryStateNotifierProvider.notifier);
    await notifier.stopBarcodeScan();
  }

  void _clearBarcodes() {
    final notifier = ref.read(barcodeInventoryStateNotifierProvider.notifier);
    notifier.clearBarcodes();
  }

  /// Enable trigger key monitoring
  /// Trigger will automatically start/stop inventory when pressed/released
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
        final rfidState = ref.read(rfidInventoryStateNotifierProvider);

        if (event.pressed) {
          // Trigger pressed - start inventory if not already running
          if (!rfidState.isInventorying) {
            _startRfidInventory();
          }
        } else {
          // Trigger released - stop inventory if running
          if (rfidState.isInventorying) {
            _stopRfidInventory();
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

  void _navigateToLocateTag(String epc) {
    // Navigate to geiger screen with selected EPC
    Navigator.pushNamed(
      context,
      '/geiger',
      arguments: {'epc': epc},
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text(
              'Sort By',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...SortBy.values.map((sortBy) {
            return RadioListTile<SortBy>(
              title: Text(_getSortByLabel(sortBy)),
              value: sortBy,
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  String _getSortByLabel(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.epc:
        return 'EPC';
      case SortBy.rssi:
        return 'Signal Strength (RSSI)';
      case SortBy.count:
        return 'Read Count';
      case SortBy.timestamp:
        return 'Time (Most Recent)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionStateNotifierProvider);

    if (!connectionState.isReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory')),
        body: const Center(
          child: Text('Please connect to a reader first'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.nfc), text: 'RFID'),
            Tab(icon: Icon(Icons.qr_code), text: 'Barcode'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort Options',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRfidTab(),
          _buildBarcodeTab(),
        ],
      ),
    );
  }

  /// Build RFID inventory tab
  Widget _buildRfidTab() {
    final rfidState = ref.watch(rfidInventoryStateNotifierProvider);
    final notifier = ref.read(rfidInventoryStateNotifierProvider.notifier);

    return Column(
      children: [
        // Stats card - always visible
        StatsCard(
          title: 'RFID Statistics',
          trailing: const BatteryIndicator(),
          stats: {
            'Unique Tags': rfidState.uniqueTagCount.toString(),
            'Total Reads': rfidState.totalReads.toString(),
            'Read Rate': (rfidState.stats?.readRate ?? 0) > 0
                ? AppFormatters.formatReadRate(rfidState.stats!.readRate)
                : 'N/A',
          },
        ),

        // Control buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: rfidState.isInventorying
                      ? _stopRfidInventory
                      : _startRfidInventory,
                  icon: Icon(
                    rfidState.isInventorying ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(
                    rfidState.isInventorying ? 'Stop' : 'Start',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rfidState.isInventorying
                        ? Colors.red
                        : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed:
                    rfidState.tags.isEmpty ? null : _clearRfidTags,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),

        // Tag list
        Expanded(
          child: _buildTagList(rfidState, notifier),
        ),
      ],
    );
  }

  /// Build tag list
  Widget _buildTagList(
    RfidInventoryState rfidState,
    RfidInventoryStateNotifier notifier,
  ) {
    if (rfidState.tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nfc,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Tags Scanned',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap Start to begin scanning',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final sortedTags = notifier.getSortedTags(
      sortBy: _sortBy,
      ascending: true,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedTags.length,
      itemBuilder: (context, index) {
        final tag = sortedTags[index];
        return TagListItem(
          tag: tag,
          onTap: () => _navigateToLocateTag(tag.epc),
        );
      },
    );
  }

  /// Build barcode scanning tab
  Widget _buildBarcodeTab() {
    final barcodeState = ref.watch(barcodeInventoryStateNotifierProvider);

    return Column(
      children: [
        // Stats card - always visible
        StatsCard(
          title: 'Barcode Statistics',
          stats: {
            'Unique Barcodes': barcodeState.uniqueBarcodeCount.toString(),
            'Total Scans': (barcodeState.stats?.totalScans ?? 0).toString(),
            'Elapsed Time': barcodeState.stats != null
                ? AppFormatters.formatElapsedTime(barcodeState.stats!.elapsedSeconds)
                : '0s',
          },
        ),

        // Control buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: barcodeState.isScanning
                      ? _stopBarcodeScanning
                      : _startBarcodeScanning,
                  icon: Icon(
                    barcodeState.isScanning ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(
                    barcodeState.isScanning ? 'Stop' : 'Start',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: barcodeState.isScanning
                        ? Colors.red
                        : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: barcodeState.barcodes.isEmpty
                    ? null
                    : _clearBarcodes,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),

        // Barcode list
        Expanded(
          child: _buildBarcodeList(barcodeState),
        ),
      ],
    );
  }

  /// Build barcode list
  Widget _buildBarcodeList(BarcodeInventoryState barcodeState) {
    if (barcodeState.barcodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Barcodes Scanned',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap Start to begin scanning',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: barcodeState.barcodes.length,
      itemBuilder: (context, index) {
        final barcode = barcodeState.barcodes[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.qr_code),
            title: Text(
              barcode.barcode,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            subtitle: Text(
              AppFormatters.formatTimestamp(barcode.timestamp),
            ),
          ),
        );
      },
    );
  }
}
