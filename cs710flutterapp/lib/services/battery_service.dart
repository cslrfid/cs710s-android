import 'dart:async';
import '../models/battery_info.dart';
import '../models/rfid_error.dart';
import 'rfid_service.dart';

/// Service for managing battery monitoring
class BatteryService {
  final RfidService _rfidService;

  final _batteryController = StreamController<BatteryInfo>.broadcast();
  final _monitoringController = StreamController<bool>.broadcast();
  final _errorController = StreamController<RfidError>.broadcast();

  StreamSubscription<BatteryUpdateEvent>? _batteryEventSubscription;

  bool _isMonitoring = false;
  BatteryInfo? _currentBattery;

  BatteryService(this._rfidService);

  /// Stream of battery updates
  Stream<BatteryInfo> get battery => _batteryController.stream;

  /// Stream of monitoring state
  Stream<bool> get isMonitoring => _monitoringController.stream;

  /// Stream of battery errors
  Stream<RfidError> get errors => _errorController.stream;

  /// Get current battery info
  BatteryInfo? get currentBattery => _currentBattery;

  /// Get current monitoring state
  bool get monitoring => _isMonitoring;

  /// Get battery level percentage (0-100)
  int? get batteryLevel => _currentBattery?.level;

  /// Check if battery is charging
  bool get isCharging => _currentBattery?.charging ?? false;

  /// Check if battery level is low (< 20%)
  bool get isLowBattery => (_currentBattery?.level ?? 100) < 20;

  /// Check if battery level is critical (< 10%)
  bool get isCriticalBattery => (_currentBattery?.level ?? 100) < 10;

  /// Initialize service - start listening to battery events
  void initialize() {
    _batteryEventSubscription = _rfidService.batteryEvents.listen(
      _handleBatteryEvent,
      onError: (error) {
        _errorController.add(RfidError(
          message: 'Battery event stream error: $error',
          type: RfidErrorType.unknown,
        ));
      },
    );
  }

  /// Start battery monitoring (polls every 5 seconds)
  Future<void> startMonitoring() async {
    try {
      await _rfidService.startBatteryMonitoring();
      _isMonitoring = true;
      _monitoringController.add(true);

      // Get initial battery info
      await refreshBatteryInfo();
    } catch (e) {
      _isMonitoring = false;
      _monitoringController.add(false);
      _errorController.add(RfidError(
        message: 'Failed to start battery monitoring',
        type: RfidErrorType.unknown,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Stop battery monitoring
  Future<void> stopMonitoring() async {
    try {
      await _rfidService.stopBatteryMonitoring();
      _isMonitoring = false;
      _monitoringController.add(false);
    } catch (e) {
      _errorController.add(RfidError(
        message: 'Failed to stop battery monitoring',
        type: RfidErrorType.unknown,
        cause: e.toString(),
      ));
      rethrow;
    }
  }

  /// Manually refresh battery info (one-time query)
  Future<void> refreshBatteryInfo() async {
    try {
      final battery = await _rfidService.getBatteryInfo();
      if (battery != null) {
        _currentBattery = battery;
        _batteryController.add(battery);
      }
    } catch (e) {
      _errorController.add(RfidError(
        message: 'Failed to refresh battery info',
        type: RfidErrorType.unknown,
        cause: e.toString(),
      ));
    }
  }

  /// Handle battery update events from RfidService
  void _handleBatteryEvent(BatteryUpdateEvent event) {
    _currentBattery = event.battery;
    _batteryController.add(event.battery);
  }

  /// Get battery level icon name based on level and charging state
  String getBatteryIcon() {
    final level = batteryLevel;
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

  /// Get battery level color based on level
  /// Returns: 'green', 'yellow', 'orange', 'red'
  String getBatteryColor() {
    final level = batteryLevel;
    if (level == null) return 'grey';

    if (level >= 50) return 'green';
    if (level >= 30) return 'yellow';
    if (level >= 20) return 'orange';
    return 'red';
  }

  /// Get battery status text
  String getBatteryStatusText() {
    final battery = _currentBattery;
    if (battery == null) return 'Unknown';

    final levelText = '${battery.level}%';
    final statusText = battery.charging ? 'Charging' : 'Discharging';
    return '$levelText ($statusText)';
  }

  /// Get formatted battery display string
  String getDisplayString() {
    return _currentBattery?.displayString ?? 'N/A';
  }

  /// Dispose resources
  void dispose() {
    _batteryEventSubscription?.cancel();
    _batteryController.close();
    _monitoringController.close();
    _errorController.close();
  }
}
