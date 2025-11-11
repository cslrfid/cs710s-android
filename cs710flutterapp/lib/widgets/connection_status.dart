import 'package:flutter/material.dart';
import '../providers/connection_state_provider.dart' as conn_provider;

/// Widget for displaying connection status in app bar
class ConnectionStatus extends StatelessWidget {
  final conn_provider.ConnectionState connectionState;

  const ConnectionStatus({
    super.key,
    required this.connectionState,
  });

  @override
  Widget build(BuildContext context) {
    return _buildStatusIndicator();
  }

  /// Build status indicator based on connection state
  Widget _buildStatusIndicator() {
    switch (connectionState.status) {
      case conn_provider.ConnectionStatus.disconnected:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 20,
              color: Colors.grey,
            ),
            SizedBox(width: 4),
            Text(
              'Disconnected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        );

      case conn_provider.ConnectionStatus.connecting:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Connecting...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ],
        );

      case conn_provider.ConnectionStatus.connected:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth_connected,
              size: 20,
              color: Colors.orange,
            ),
            SizedBox(width: 4),
            Text(
              'Connected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ],
        );

      case conn_provider.ConnectionStatus.initializing:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ],
        );

      case conn_provider.ConnectionStatus.ready:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 20,
              color: Colors.green,
            ),
            SizedBox(width: 4),
            Text(
              'Ready',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }
}
