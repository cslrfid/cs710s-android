import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// Platform channel wrapper for RFID operations
/// Communicates with RfidPlatformChannel.kt via MethodChannel and EventChannels
class RfidChannel {
  // Method channel for synchronous calls
  static const _methodChannel = MethodChannel(AppConstants.methodChannel);

  // Event channels for asynchronous streams
  static const _scanEvents =
      EventChannel(AppConstants.scanEventsChannel);
  static const _connectionEvents =
      EventChannel(AppConstants.connectionEventsChannel);
  static const _inventoryEvents =
      EventChannel(AppConstants.inventoryEventsChannel);
  static const _geigerEvents =
      EventChannel(AppConstants.geigerEventsChannel);
  static const _barcodeEvents =
      EventChannel(AppConstants.barcodeEventsChannel);
  static const _batteryEvents =
      EventChannel(AppConstants.batteryEventsChannel);
  static const _triggerEvents =
      EventChannel(AppConstants.triggerEventsChannel);
  static const _configEvents =
      EventChannel(AppConstants.configEventsChannel);

  // ========== SCANNING METHODS ==========

  /// Start scanning for RFID readers
  Future<void> startScan() async {
    await _methodChannel.invokeMethod('startScan');
  }

  /// Stop scanning for RFID readers
  Future<void> stopScan() async {
    await _methodChannel.invokeMethod('stopScan');
  }

  /// Check if currently scanning
  Future<bool> isScanning() async {
    return await _methodChannel.invokeMethod<bool>('isScanning') ?? false;
  }

  // ========== CONNECTION METHODS ==========

  /// Connect to RFID reader by address
  Future<void> connect(String address) async {
    await _methodChannel.invokeMethod('connect', {'address': address});
  }

  /// Disconnect from current reader
  Future<void> disconnect() async {
    await _methodChannel.invokeMethod('disconnect');
  }

  /// Check if connected to a reader
  Future<bool> isConnected() async {
    return await _methodChannel.invokeMethod<bool>('isConnected') ?? false;
  }

  /// Get currently connected reader (returns null if not connected)
  Future<Map<String, dynamic>?> getConnectedReader() async {
    final result =
        await _methodChannel.invokeMethod<Map<Object?, Object?>>('getConnectedReader');
    return result?.cast<String, dynamic>();
  }

  // ========== INVENTORY METHODS ==========

  /// Start RFID tag inventory
  Future<void> startInventory() async {
    await _methodChannel.invokeMethod('startInventory');
  }

  /// Stop RFID tag inventory
  Future<void> stopInventory() async {
    await _methodChannel.invokeMethod('stopInventory');
  }

  /// Check if currently inventorying
  Future<bool> isInventorying() async {
    return await _methodChannel.invokeMethod<bool>('isInventorying') ?? false;
  }

  // ========== GEIGER SEARCH METHODS ==========

  /// Start Geiger search for specific tag
  /// [epc] Target EPC to search for
  /// [memoryBank] Memory bank (1=EPC, 2=TID, 3=User)
  Future<void> startGeigerSearch(String epc, int memoryBank) async {
    await _methodChannel.invokeMethod('startGeigerSearch', {
      'epc': epc,
      'memoryBank': memoryBank,
    });
  }

  /// Stop Geiger search
  Future<void> stopGeigerSearch() async {
    await _methodChannel.invokeMethod('stopGeigerSearch');
  }

  /// Check if currently searching
  Future<bool> isSearching() async {
    return await _methodChannel.invokeMethod<bool>('isSearching') ?? false;
  }

  // ========== BARCODE METHODS ==========

  /// Start barcode scanning
  Future<void> startBarcodeScan() async {
    await _methodChannel.invokeMethod('startBarcodeScan');
  }

  /// Stop barcode scanning
  Future<void> stopBarcodeScan() async {
    await _methodChannel.invokeMethod('stopBarcodeScan');
  }

  /// Check if barcode scanning is active
  Future<bool> isBarcodeScanning() async {
    return await _methodChannel.invokeMethod<bool>('isBarcodeScanning') ??
        false;
  }

  // ========== BATTERY METHODS ==========

  /// Get current battery info (returns null if not available)
  Future<Map<String, dynamic>?> getBatteryInfo() async {
    final result =
        await _methodChannel.invokeMethod<Map<Object?, Object?>>('getBatteryInfo');
    return result?.cast<String, dynamic>();
  }

  /// Start battery monitoring (polls every 5 seconds)
  Future<void> startBatteryMonitoring() async {
    await _methodChannel.invokeMethod('startBatteryMonitoring');
  }

  /// Stop battery monitoring
  Future<void> stopBatteryMonitoring() async {
    await _methodChannel.invokeMethod('stopBatteryMonitoring');
  }

  /// Check if battery monitoring is active
  Future<bool> isBatteryMonitoringActive() async {
    return await _methodChannel
            .invokeMethod<bool>('isBatteryMonitoringActive') ??
        false;
  }

  // ========== TRIGGER METHODS ==========

  /// Enable trigger key support
  /// [autoInventory] If true, SDK automatically starts/stops inventory.
  ///                 If false, app handles trigger events manually.
  Future<void> enableTrigger(bool autoInventory) async {
    await _methodChannel.invokeMethod('enableTrigger', {
      'autoInventory': autoInventory,
    });
  }

  /// Disable trigger key support
  Future<void> disableTrigger() async {
    await _methodChannel.invokeMethod('disableTrigger');
  }

  /// Get current trigger button state
  Future<bool> getTriggerState() async {
    return await _methodChannel.invokeMethod<bool>('getTriggerState') ?? false;
  }

  /// Check if trigger monitoring is active
  Future<bool> isTriggerMonitoringActive() async {
    return await _methodChannel
            .invokeMethod<bool>('isTriggerMonitoringActive') ??
        false;
  }

  // ========== CONFIGURATION METHODS ==========

  /// Get current reader configuration
  Future<Map<String, dynamic>> getConfiguration() async {
    final result = await _methodChannel
        .invokeMethod<Map<Object?, Object?>>('getConfiguration');
    return result?.cast<String, dynamic>() ?? {};
  }

  /// Apply reader configuration
  Future<void> applyConfiguration(Map<String, dynamic> config) async {
    await _methodChannel.invokeMethod('applyConfiguration', config);
  }

  // ========== EVENT STREAMS ==========

  /// Convert Map<Object?, Object?> to Map<String, dynamic>
  /// This is needed because EventChannel sends Map<Object?, Object?> but we need Map<String, dynamic>
  static Map<String, dynamic> _convertMap(dynamic event) {
    final Map<String, dynamic> result = {};
    if (event is! Map) return result;

    event.forEach((key, value) {
      if (key is String) {
        if (value is Map) {
          // Recursively convert nested maps
          final Map<String, dynamic> nestedMap = {};
          value.forEach((k, v) {
            if (k is String) {
              nestedMap[k] = v;
            }
          });
          result[key] = nestedMap;
        } else {
          result[key] = value;
        }
      }
    });
    return result;
  }

  /// Stream of scan events (reader discovered, scan error)
  Stream<Map<String, dynamic>> get scanEvents {
    print('📱 Flutter: Subscribing to scan events stream');
    return _scanEvents.receiveBroadcastStream().map((event) {
      print('📱 Flutter: Raw event received from native: $event');
      return _convertMap(event);
    });
  }

  /// Stream of connection events (connecting, connected, ready, disconnected, failed)
  Stream<Map<String, dynamic>> get connectionEvents =>
      _connectionEvents.receiveBroadcastStream().map(_convertMap);

  /// Stream of inventory events (tag read, round update, stopped, error)
  Stream<Map<String, dynamic>> get inventoryEvents =>
      _inventoryEvents.receiveBroadcastStream().map(_convertMap);

  /// Stream of Geiger events (proximity update, started, stopped, error)
  Stream<Map<String, dynamic>> get geigerEvents =>
      _geigerEvents.receiveBroadcastStream().map(_convertMap);

  /// Stream of barcode events (barcode scanned, stats update, error)
  Stream<Map<String, dynamic>> get barcodeEvents =>
      _barcodeEvents.receiveBroadcastStream().map(_convertMap);

  /// Stream of battery events (battery update)
  Stream<Map<String, dynamic>> get batteryEvents =>
      _batteryEvents.receiveBroadcastStream().map(_convertMap);

  /// Stream of trigger events (trigger state changed)
  Stream<Map<String, dynamic>> get triggerEvents =>
      _triggerEvents.receiveBroadcastStream().map(_convertMap);

  /// Stream of configuration events (configured, failed)
  Stream<Map<String, dynamic>> get configEvents =>
      _configEvents.receiveBroadcastStream().map(_convertMap);
}
