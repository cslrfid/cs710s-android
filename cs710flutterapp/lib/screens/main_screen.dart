import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connection_state_provider.dart' as conn_provider;
import '../providers/battery_state_provider.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/connection_status.dart' as conn_widget;

/// Main navigation screen with drawer
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(conn_provider.connectionStateNotifierProvider);
    final batteryState = ref.watch(batteryStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CS710S Quick Start'),
        actions: [
          // Battery indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: BatteryIndicator(batteryState: batteryState),
          ),
          // Connection status
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: conn_widget.ConnectionStatus(connectionState: connectionState),
          ),
        ],
      ),
      drawer: _buildDrawer(context, connectionState),
      body: _buildHomeContent(context, connectionState),
    );
  }

  /// Build navigation drawer
  Widget _buildDrawer(BuildContext context, conn_provider.ConnectionState connectionState) {
    final isConnected = connectionState.isReady;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.nfc,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'CS710S Quick Start',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  connectionState.isReady
                      ? 'Connected to ${connectionState.connectedReader?.name ?? "Reader"}'
                      : 'Not Connected',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bluetooth_searching),
            title: const Text('Scan & Connect'),
            subtitle: const Text('Find and connect to RFID reader'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/scan');
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Inventory'),
            subtitle: const Text('RFID tag and barcode scanning'),
            enabled: isConnected,
            onTap: isConnected
                ? () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/inventory');
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.location_searching),
            title: const Text('Locate Tag'),
            subtitle: const Text('Find specific tag with Geiger mode'),
            enabled: isConnected,
            onTap: isConnected
                ? () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/geiger');
                  }
                : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// Build home screen content
  Widget _buildHomeContent(BuildContext context, conn_provider.ConnectionState connectionState) {
    final isConnected = connectionState.isReady;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected ? Icons.check_circle : Icons.bluetooth_disabled,
              size: 80,
              color: isConnected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              isConnected ? 'Reader Connected' : 'No Reader Connected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (isConnected && connectionState.connectedReader != null)
              Text(
                connectionState.connectedReader!.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            const SizedBox(height: 32),
            if (!isConnected) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/scan');
                },
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Scan for Readers'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ] else ...[
              _buildQuickActionCard(
                context,
                icon: Icons.inventory,
                title: 'Start Inventory',
                subtitle: 'Scan RFID tags and barcodes',
                onTap: () => Navigator.pushNamed(context, '/inventory'),
              ),
              const SizedBox(height: 16),
              _buildQuickActionCard(
                context,
                icon: Icons.location_searching,
                title: 'Locate Tag',
                subtitle: 'Find specific tag with Geiger mode',
                onTap: () => Navigator.pushNamed(context, '/geiger'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build quick action card
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Show about dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'CS710S Quick Start',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.nfc, size: 48),
      children: [
        const Text(
          'Flutter application for CS710S RFID reader operations.\n\n'
          'Features:\n'
          '• Bluetooth reader scanning and connection\n'
          '• RFID tag inventory\n'
          '• Barcode scanning\n'
          '• Tag locating with Geiger mode\n'
          '• Battery monitoring\n'
          '• Trigger key support',
        ),
      ],
    );
  }
}
