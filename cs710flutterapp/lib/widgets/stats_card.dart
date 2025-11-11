import 'package:flutter/material.dart';

/// Card widget for displaying statistics
class StatsCard extends StatelessWidget {
  final String title;
  final Map<String, String> stats;
  final Color? backgroundColor;
  final Widget? trailing; // Optional widget to show on the right of title

  const StatsCard({
    super.key,
    required this.title,
    required this.stats,
    this.backgroundColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: backgroundColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with optional trailing widget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),

            // Stats grid
            _buildStatsGrid(context),
          ],
        ),
      ),
    );
  }

  /// Build stats grid
  Widget _buildStatsGrid(BuildContext context) {
    final entries = stats.entries.toList();

    // Use 2 columns for better layout
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      final leftEntry = entries[i];
      final rightEntry = i + 1 < entries.length ? entries[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  label: leftEntry.key,
                  value: leftEntry.value,
                ),
              ),
              if (rightEntry != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: rightEntry.key,
                    value: rightEntry.value,
                  ),
                ),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  /// Build individual stat item
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
        ),
      ],
    );
  }
}
