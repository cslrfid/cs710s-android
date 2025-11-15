import 'package:flutter/material.dart';
import '../models/rfid_tag.dart';
import '../utils/formatters.dart';

/// List item widget for displaying RFID tag information
class TagListItem extends StatelessWidget {
  final RfidTag tag;
  final VoidCallback? onTap;

  const TagListItem({
    super.key,
    required this.tag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          AppFormatters.formatEpc(tag.epc),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(
                  icon: Icons.signal_cellular_alt,
                  label: AppFormatters.formatRssi(tag.rssi),
                  color: _getRssiColor(tag.rssi),
                ),
                const SizedBox(width: 8),
                _buildChip(
                  icon: Icons.repeat,
                  label: 'Count: ${tag.count}',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.formatTimestamp(tag.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }

  /// Build leading icon
  Widget _buildLeadingIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.nfc,
        color: Colors.green,
        size: 24,
      ),
    );
  }

  /// Build info chip
  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on RSSI strength
  Color _getRssiColor(double rssi) {
    if (rssi >= -40) return Colors.green;
    if (rssi >= -50) return Colors.lightGreen;
    if (rssi >= -60) return Colors.orange;
    return Colors.red;
  }
}
