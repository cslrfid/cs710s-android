import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scan_state_provider.dart';
import '../providers/connection_state_provider.dart' as conn_provider;
import '../providers/permission_provider.dart';
import '../widgets/reader_list_item.dart';
import '../widgets/loading_overlay.dart';

/// Reader scanning and connection screen
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Check permissions and auto-start scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndScan();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Stop scanning when leaving screen
    // Call stopScan before dispose to avoid using ref after disposal
    try {
      final scanNotifier = ref.read(scanStateNotifierProvider.notifier);
      scanNotifier.stopScan();
    } catch (e) {
      // Ignore errors if already disposed
      print('Warning: Could not stop scan on dispose: $e');
    }
    super.dispose();
  }

  Future<void> _checkPermissionsAndScan() async {
    final permissionService = ref.read(permissionServiceProvider);
    final hasPermissions = await permissionService.ensurePermissions();

    if (!hasPermissions && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth and Location permissions are required to scan for readers'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    await _startScan();
  }

  Future<void> _startScan() async {
    final scanNotifier = ref.read(scanStateNotifierProvider.notifier);
    await scanNotifier.startScan();
  }

  Future<void> _stopScan() async {
    final scanNotifier = ref.read(scanStateNotifierProvider.notifier);
    await scanNotifier.stopScan();
  }

  Future<void> _connectToReader(String address) async {
    final connectionNotifier = ref.read(conn_provider.connectionStateNotifierProvider.notifier);

    // Stop scanning first
    await _stopScan();

    // Show loading overlay
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingOverlay(message: 'Connecting...'),
    );

    try {
      await connectionNotifier.connect(address);

      // Wait for connection to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Check if connection succeeded
      final connectionState = ref.read(conn_provider.connectionStateNotifierProvider);
      if (connectionState.isReady) {
        // Navigate back to main screen
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connected to ${connectionState.connectedReader?.name ?? "reader"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (connectionState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: ${connectionState.error!.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanStateNotifierProvider);
    final connectionState = ref.watch(conn_provider.connectionStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan for Readers'),
        actions: [
          if (scanState.isScanning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopScan,
              tooltip: 'Stop Scanning',
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
              tooltip: 'Start Scanning',
            ),
        ],
      ),
      body: Column(
        children: [
          // Scan status banner
          _buildStatusBanner(scanState, connectionState),

          // Reader list
          Expanded(
            child: _buildReaderList(scanState),
          ),
        ],
      ),
    );
  }

  /// Build status banner
  Widget _buildStatusBanner(ScanState scanState, conn_provider.ConnectionState connectionState) {
    if (connectionState.status == conn_provider.ConnectionStatus.connecting) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.blue[100],
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Connecting to reader...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (scanState.isScanning) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.green[100],
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Scanning... (${scanState.readers.length} readers found)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (scanState.readers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.orange[100],
        child: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No readers found. Make sure Bluetooth is enabled and the reader is powered on.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue[50],
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            'Found ${scanState.readers.length} reader(s). Tap to connect.',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Build reader list
  Widget _buildReaderList(ScanState scanState) {
    if (scanState.readers.isEmpty && !scanState.isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Readers Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the refresh button to scan again',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Start Scanning'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: scanState.readers.length,
      itemBuilder: (context, index) {
        final reader = scanState.readers[index];
        return ReaderListItem(
          reader: reader,
          onTap: () => _connectToReader(reader.address),
        );
      },
    );
  }
}
