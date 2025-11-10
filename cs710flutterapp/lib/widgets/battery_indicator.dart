import 'package:flutter/material.dart';
import '../providers/battery_state_provider.dart';

/// Widget for displaying battery status in app bar
class BatteryIndicator extends StatelessWidget {
  final BatteryState batteryState;

  const BatteryIndicator({
    super.key,
    required this.batteryState,
  });

  @override
  Widget build(BuildContext context) {
    final level = batteryState.level;

    if (level == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBatteryIcon(level, batteryState.isCharging),
        const SizedBox(width: 4),
        Text(
          '$level%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _getBatteryColor(batteryState.levelStatus),
          ),
        ),
      ],
    );
  }

  /// Build battery icon based on level and charging state
  Widget _buildBatteryIcon(int level, bool isCharging) {
    IconData iconData;
    Color color = _getBatteryColor(batteryState.levelStatus);

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
      size: 20,
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
