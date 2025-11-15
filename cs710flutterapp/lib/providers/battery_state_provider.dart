import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/battery_info.dart';
import '../models/rfid_error.dart';
import '../services/battery_service.dart';
import 'scan_state_provider.dart';

part 'battery_state_provider.g.dart';

/// Battery level status enum
enum BatteryLevelStatus {
  unknown, // No battery info available
  critical, // < 10%
  low, // 10-19%
  medium, // 20-49%
  good, // 50-89%
  full, // >= 90%
}

/// Battery state model
class BatteryState {
  final BatteryInfo? battery;
  final bool isMonitoring;
  final RfidError? error;

  const BatteryState({
    this.battery,
    this.isMonitoring = false,
    this.error,
  });

  BatteryState copyWith({
    BatteryInfo? battery,
    bool? isMonitoring,
    RfidError? error,
  }) {
    return BatteryState(
      battery: battery ?? this.battery,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      error: error ?? this.error,
    );
  }

  BatteryState clearError() {
    return copyWith(error: null);
  }

  /// Get battery level (0-100)
  int? get level => battery?.level;

  /// Check if charging
  bool get isCharging => battery?.charging ?? false;

  /// Get battery level status
  BatteryLevelStatus get levelStatus {
    final level = this.level;
    if (level == null) return BatteryLevelStatus.unknown;
    if (level < 10) return BatteryLevelStatus.critical;
    if (level < 20) return BatteryLevelStatus.low;
    if (level < 50) return BatteryLevelStatus.medium;
    if (level < 90) return BatteryLevelStatus.good;
    return BatteryLevelStatus.full;
  }

  /// Check if battery is low (< 20%)
  bool get isLowBattery => levelStatus == BatteryLevelStatus.low;

  /// Check if battery is critical (< 10%)
  bool get isCriticalBattery => levelStatus == BatteryLevelStatus.critical;

  /// Get battery color for UI
  /// Returns: 'green', 'yellow', 'orange', 'red', 'grey'
  String get batteryColor {
    switch (levelStatus) {
      case BatteryLevelStatus.full:
      case BatteryLevelStatus.good:
        return 'green';
      case BatteryLevelStatus.medium:
        return 'yellow';
      case BatteryLevelStatus.low:
        return 'orange';
      case BatteryLevelStatus.critical:
        return 'red';
      case BatteryLevelStatus.unknown:
        return 'grey';
    }
  }

  /// Get battery icon name
  String get batteryIcon {
    final level = this.level;
    if (level == null) return 'battery_unknown';

    if (isCharging) {
      return 'battery_charging_full';
    }

    if (level >= 90) return 'battery_full';
    if (level >= 70) return 'battery_6_bar';
    if (level >= 50) return 'battery_5_bar';
    if (level >= 30) return 'battery_3_bar';
    if (level >= 20) return 'battery_2_bar';
    return 'battery_1_bar';
  }

  /// Get battery status text
  String get statusText {
    final battery = this.battery;
    if (battery == null) return 'Unknown';

    final levelText = '${battery.level}%';
    final statusText = battery.charging ? 'Charging' : 'Discharging';
    return '$levelText ($statusText)';
  }

  /// Get display string
  String get displayString {
    return battery?.displayString ?? 'N/A';
  }
}

/// Provide BatteryService instance
@riverpod
BatteryService batteryService(BatteryServiceRef ref) {
  final rfidService = ref.watch(rfidServiceProvider);
  final service = BatteryService(rfidService);
  service.initialize();

  // Dispose on provider disposal
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Battery state provider
@riverpod
class BatteryStateNotifier extends _$BatteryStateNotifier {
  @override
  BatteryState build() {
    final service = ref.watch(batteryServiceProvider);

    // Listen to battery updates stream
    service.battery.listen((battery) {
      state = state.copyWith(battery: battery);
    });

    // Listen to monitoring state stream
    service.isMonitoring.listen((isMonitoring) {
      state = state.copyWith(isMonitoring: isMonitoring);
    });

    // Listen to errors stream
    service.errors.listen((error) {
      state = state.copyWith(error: error);
    });

    return const BatteryState();
  }

  /// Start battery monitoring (polls every 5 seconds)
  Future<void> startMonitoring() async {
    final service = ref.read(batteryServiceProvider);
    try {
      await service.startMonitoring();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to start battery monitoring',
          type: RfidErrorType.unknown,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Stop battery monitoring
  Future<void> stopMonitoring() async {
    final service = ref.read(batteryServiceProvider);
    try {
      await service.stopMonitoring();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to stop battery monitoring',
          type: RfidErrorType.unknown,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Manually refresh battery info (one-time query)
  Future<void> refreshBatteryInfo() async {
    final service = ref.read(batteryServiceProvider);
    try {
      await service.refreshBatteryInfo();
    } catch (e) {
      state = state.copyWith(
        error: RfidError(
          message: 'Failed to refresh battery info',
          type: RfidErrorType.unknown,
          cause: e.toString(),
        ),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }

  /// Get battery level for UI display
  int? getBatteryLevel() {
    return state.level;
  }

  /// Check if charging
  bool isCharging() {
    return state.isCharging;
  }

  /// Get battery level status
  BatteryLevelStatus getBatteryLevelStatus() {
    return state.levelStatus;
  }

  /// Check if battery is low
  bool isLowBattery() {
    return state.isLowBattery;
  }

  /// Check if battery is critical
  bool isCriticalBattery() {
    return state.isCriticalBattery;
  }

  /// Get battery color for UI
  String getBatteryColor() {
    return state.batteryColor;
  }

  /// Get battery icon name
  String getBatteryIcon() {
    return state.batteryIcon;
  }

  /// Get battery status text
  String getStatusText() {
    return state.statusText;
  }

  /// Get display string
  String getDisplayString() {
    return state.displayString;
  }
}
