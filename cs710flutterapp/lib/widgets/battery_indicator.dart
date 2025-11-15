import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/battery_state_provider.dart';
import '../providers/connection_state_provider.dart';

/// Widget for displaying battery status
class BatteryIndicator extends ConsumerWidget {
  const BatteryIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStateNotifierProvider);
    final batteryState = ref.watch(batteryStateNotifierProvider);

    // Only show if reader is connected
    if (!connectionState.isReady) {
      return const SizedBox.shrink();
    }

    final level = batteryState.level;
    if (level == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBatteryColor(batteryState.levelStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBatteryColor(batteryState.levelStatus).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBatteryIcon(level, batteryState.isCharging, batteryState.levelStatus),
          const SizedBox(width: 6),
          Text(
            'Battery: $level%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _getBatteryColor(batteryState.levelStatus),
            ),
          ),
        ],
      ),
    );
  }

  /// Build battery icon based on level and charging state
  Widget _buildBatteryIcon(int level, bool isCharging, BatteryLevelStatus status) {
    IconData iconData;
    Color color = _getBatteryColor(status);

    if (isCharging) {
      iconData = Icons.battery_charging_full;
      color = Colors.green;
    } else if (level >= 90) {
      iconData = Icons.battery_full;
    } else if (level >= 70) {
      iconData = Icons.battery_6_bar;
    } else if (level >= 50) {
      iconData = Icons.battery_5_bar;
    } else if (level >= 30) {
      iconData = Icons.battery_3_bar;
    } else if (level >= 20) {
      iconData = Icons.battery_2_bar;
    } else {
      iconData = Icons.battery_1_bar;
    }

    return Icon(
      iconData,
      size: 18,
      color: color,
    );
  }

  /// Get color based on battery level status
  Color _getBatteryColor(BatteryLevelStatus status) {
    switch (status) {
      case BatteryLevelStatus.full:
      case BatteryLevelStatus.good:
        return Colors.green;
      case BatteryLevelStatus.medium:
        return Colors.yellow[700]!;
      case BatteryLevelStatus.low:
        return Colors.orange;
      case BatteryLevelStatus.critical:
        return Colors.red;
      case BatteryLevelStatus.unknown:
        return Colors.grey;
    }
  }
}
