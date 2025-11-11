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
      _listenToConnectionState();
    });
  }

  /// Listen to connection state and auto-navigate when READY
  void _listenToConnectionState() {
    ref.listenManual(
      conn_provider.connectionStateNotifierProvider,
      (previous, next) {
        if (!mounted) return;

        // Show loading overlay when connecting or initializing
        if (next.status == conn_provider.ConnectionStatus.connecting ||
            next.status == conn_provider.ConnectionStatus.initializing) {
          // Check if we need to show the dialog (not already showing)
          if (previous?.status != conn_provider.ConnectionStatus.connecting &&
              previous?.status != conn_provider.ConnectionStatus.initializing) {
            final message = next.status == conn_provider.ConnectionStatus.connecting
                ? 'Connecting to reader...'
                : 'Initializing reader...';

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => LoadingOverlay(message: message),
            );
          } else {
            // Update the message if transitioning between connecting and initializing
            // Close current dialog and show new one
            Navigator.of(context, rootNavigator: true).pop();
            final message = next.status == conn_provider.ConnectionStatus.connecting
                ? 'Connecting to reader...'
                : 'Initializing reader...';

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => LoadingOverlay(message: message),
            );
          }
        }

        // Stop scanning when reader is connected
        if (next.isConnected && !previous!.isConnected) {
          _stopScan();
        }

        // Auto-navigate to home screen when reader is ready
        if (next.status == conn_provider.ConnectionStatus.ready) {
          // Close loading dialog if showing
          if (previous?.status == conn_provider.ConnectionStatus.connecting ||
              previous?.status == conn_provider.ConnectionStatus.initializing) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connected to ${next.connectedReader?.name ?? "reader"}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate back to home screen
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }

        // Handle connection failure
        if (next.status == conn_provider.ConnectionStatus.disconnected &&
            previous?.status != conn_provider.ConnectionStatus.disconnected) {
          // Close loading dialog if showing
          if (previous?.status == conn_provider.ConnectionStatus.connecting ||
              previous?.status == conn_provider.ConnectionStatus.initializing) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Show error message if connection failed
          if (next.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connection failed: ${next.error!.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
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

    try {
      // Start connection (don't show loading dialog here, let status banner handle it)
      await connectionNotifier.connect(address);
    } catch (e) {
      if (!mounted) return;
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
          // Hide scan buttons when connected
          if (!connectionState.isConnected)
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
          // Connected reader card (shown when connected)
          if (connectionState.isConnected)
            _buildConnectedReaderCard(connectionState),

          // Scan status banner (only show when not connected)
          if (!connectionState.isConnected)
            _buildStatusBanner(scanState, connectionState),

          // Reader list or connection message
          Expanded(
            child: connectionState.isConnected
                ? _buildConnectedMessage()
                : _buildReaderList(scanState),
          ),
        ],
      ),
    );
  }

  /// Build connected reader card
  Widget _buildConnectedReaderCard(conn_provider.ConnectionState connectionState) {
    final reader = connectionState.connectedReader;
    if (reader == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: Colors.green[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Connected Reader',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reader.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              reader.address,
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _disconnectReader,
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _disconnectReader() async {
    final connectionNotifier = ref.read(conn_provider.connectionStateNotifierProvider.notifier);

    try {
      await connectionNotifier.disconnect();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disconnected from reader'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnect error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Build message when connected
  Widget _buildConnectedMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Reader Connected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the disconnect button above to scan for other readers',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build status banner
  Widget _buildStatusBanner(ScanState scanState, conn_provider.ConnectionState connectionState) {
    // Show connecting/initializing banner
    if (connectionState.status == conn_provider.ConnectionStatus.connecting ||
        connectionState.status == conn_provider.ConnectionStatus.initializing) {
      final message = connectionState.status == conn_provider.ConnectionStatus.connecting
          ? 'Connecting to reader...'
          : 'Initializing reader...';

      return Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.blue[100],
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
