import 'package:flutter/material.dart';
import '../models/rfid_reader.dart';
import '../utils/formatters.dart';

/// List item widget for displaying RFID reader information
class ReaderListItem extends StatelessWidget {
  final RfidReader reader;
  final VoidCallback onTap;

  const ReaderListItem({
    super.key,
    required this.reader,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          reader.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Address: ${reader.address}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            Text(
              'RSSI: ${AppFormatters.formatRssi(reader.rssi.toDouble())}',
              style: TextStyle(
                color: _getRssiColor(reader.rssi),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSignalStrengthIndicator(reader.rssi),
            const SizedBox(height: 4),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  /// Build leading icon based on reader type
  Widget _buildLeadingIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.nfc,
        color: Colors.blue,
        size: 28,
      ),
    );
  }

  /// Build signal strength indicator
  Widget _buildSignalStrengthIndicator(int rssi) {
    final signalBars = _getSignalBars(rssi);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < signalBars;
        return Container(
          width: 4,
          height: 4 + (index * 3),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive ? _getRssiColor(rssi) : Colors.grey[300],
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  /// Get number of signal bars (0-4) based on RSSI
  int _getSignalBars(int rssi) {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }

  /// Get color based on RSSI strength
  Color _getRssiColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -60) return Colors.lightGreen;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }
}
