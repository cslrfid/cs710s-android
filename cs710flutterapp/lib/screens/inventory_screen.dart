import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_state_provider.dart';
import '../providers/connection_state_provider.dart';
import '../widgets/tag_list_item.dart';
import '../widgets/stats_card.dart';
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
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Stop inventory when leaving screen
    final rfidNotifier = ref.read(rfidInventoryStateNotifierProvider.notifier);
    final barcodeNotifier =
        ref.read(barcodeInventoryStateNotifierProvider.notifier);
    rfidNotifier.stopInventory();
    barcodeNotifier.stopBarcodeScan();
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
          const Divider(),
          SwitchListTile(
            title: const Text('Ascending Order'),
            value: _sortAscending,
            onChanged: (value) {
              setState(() {
                _sortAscending = value;
              });
            },
          ),
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
        // Stats card
        if (rfidState.stats != null)
          StatsCard(
            title: 'RFID Statistics',
            stats: {
              'Unique Tags': rfidState.uniqueTagCount.toString(),
              'Total Reads': rfidState.totalReads.toString(),
              'Read Rate': rfidState.stats!.readRate > 0
                  ? AppFormatters.formatReadRate(rfidState.stats!.readRate)
                  : 'N/A',
              'Elapsed Time': AppFormatters.formatElapsedTime(
                rfidState.stats!.elapsedSeconds,
              ),
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
      ascending: _sortAscending,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedTags.length,
      itemBuilder: (context, index) {
        final tag = sortedTags[index];
        return TagListItem(tag: tag);
      },
    );
  }

  /// Build barcode scanning tab
  Widget _buildBarcodeTab() {
    final barcodeState = ref.watch(barcodeInventoryStateNotifierProvider);

    return Column(
      children: [
        // Stats card
        if (barcodeState.stats != null)
          StatsCard(
            title: 'Barcode Statistics',
            stats: {
              'Unique Barcodes': barcodeState.uniqueBarcodeCount.toString(),
              'Total Scans': barcodeState.stats!.totalScans.toString(),
              'Elapsed Time': AppFormatters.formatElapsedTime(
                barcodeState.stats!.elapsedSeconds,
              ),
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
