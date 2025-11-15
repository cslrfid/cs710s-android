import 'dart:async';
import '../platform_channels/rfid_channel.dart';
import '../models/rfid_reader.dart';
import '../models/rfid_tag.dart';
import '../models/battery_info.dart';
import '../models/rfid_configuration.dart';
import '../models/rfid_inventory_stats.dart';
import '../models/rfid_geiger_stats.dart';
import '../models/barcode_data.dart';
import '../models/barcode_stats.dart';
import '../models/rfid_error.dart';

/// Main RFID service coordinator
/// Provides high-level interface to RFID operations
class RfidService {
  final RfidChannel _channel;

  RfidService(this._channel);

  // ========== SCANNING ==========

  /// Start scanning for RFID readers
  Future<void> startScan() async {
    try {
      await _channel.startScan();
    } catch (e) {
      throw RfidServiceException('Failed to start scan: $e');
    }
  }

  /// Stop scanning for RFID readers
  Future<void> stopScan() async {
    try {
      await _channel.stopScan();
    } catch (e) {
      throw RfidServiceException('Failed to stop scan: $e');
    }
  }

  /// Check if currently scanning
  Future<bool> isScanning() async {
    try {
      return await _channel.isScanning();
    } catch (e) {
      throw RfidServiceException('Failed to check scan status: $e');
    }
  }

  /// Stream of scan events
  Stream<ScanEvent> get scanEvents {
    print('📱 RfidService: Creating scanEvents stream');
    return _channel.scanEvents.map((map) {
      print('📱 RfidService: Processing event map: $map');
      final type = map['type'] as String;
      print('📱 RfidService: Event type: $type');

      switch (type) {
        case 'readerDiscovered':
          final readerMap = map['reader'] as Map<String, dynamic>;
          print('📱 RfidService: Creating ReaderDiscoveredEvent');
          return ReaderDiscoveredEvent(RfidReader.fromMap(readerMap));
        case 'readerUpdated':
          final readerMap = map['reader'] as Map<String, dynamic>;
          print('📱 RfidService: Creating ReaderUpdatedEvent');
          return ReaderUpdatedEvent(RfidReader.fromMap(readerMap));
        case 'scanError':
          final errorMap = map['error'] as Map<String, dynamic>;
          print('📱 RfidService: Creating ScanErrorEvent');
          return ScanErrorEvent(RfidError.fromMap(errorMap));
        default:
          print('❌ RfidService: Unknown scan event type: $type');
          throw RfidServiceException('Unknown scan event type: $type');
      }
    });
  }

  // ========== CONNECTION ==========

  /// Connect to RFID reader by address
  Future<void> connect(String address) async {
    try {
      await _channel.connect(address);
    } catch (e) {
      throw RfidServiceException('Failed to connect: $e');
    }
  }

  /// Disconnect from current reader
  Future<void> disconnect() async {
    try {
      await _channel.disconnect();
    } catch (e) {
      throw RfidServiceException('Failed to disconnect: $e');
    }
  }

  /// Check if connected to a reader
  Future<bool> isConnected() async {
    try {
      return await _channel.isConnected();
    } catch (e) {
      throw RfidServiceException('Failed to check connection status: $e');
    }
  }

  /// Get currently connected reader
  Future<RfidReader?> getConnectedReader() async {
    try {
      final map = await _channel.getConnectedReader();
      return map != null ? RfidReader.fromMap(map) : null;
    } catch (e) {
      throw RfidServiceException('Failed to get connected reader: $e');
    }
  }

  /// Stream of connection events
  Stream<ConnectionEvent> get connectionEvents {
    return _channel.connectionEvents.map((map) {
      final type = map['type'] as String;
      switch (type) {
        case 'connecting':
          // 'connecting' event has no reader data
          return ConnectingEvent();
        case 'connected':
          final readerMap = map['reader'] as Map<String, dynamic>?;
          if (readerMap == null) {
            throw RfidServiceException('Connected event missing reader data');
          }
          return ConnectedEvent(RfidReader.fromMap(readerMap));
        case 'readerReady':
          final readerMap = map['reader'] as Map<String, dynamic>?;
          if (readerMap == null) {
            throw RfidServiceException('ReaderReady event missing reader data');
          }
          return ReaderReadyEvent(RfidReader.fromMap(readerMap));
        case 'disconnected':
          return DisconnectedEvent();
        case 'connectionFailed':
          final errorMap = map['error'] as Map<String, dynamic>?;
          if (errorMap == null) {
            throw RfidServiceException('ConnectionFailed event missing error data');
          }
          return ConnectionFailedEvent(RfidError.fromMap(errorMap));
        default:
          throw RfidServiceException('Unknown connection event type: $type');
      }
    });
  }

  // ========== INVENTORY ==========

  /// Start RFID tag inventory
  Future<void> startInventory() async {
    try {
      await _channel.startInventory();
    } catch (e) {
      throw RfidServiceException('Failed to start inventory: $e');
    }
  }

  /// Stop RFID tag inventory
  Future<void> stopInventory() async {
    try {
      await _channel.stopInventory();
    } catch (e) {
      throw RfidServiceException('Failed to stop inventory: $e');
    }
  }

  /// Check if currently inventorying
  Future<bool> isInventorying() async {
    try {
      return await _channel.isInventorying();
    } catch (e) {
      throw RfidServiceException('Failed to check inventory status: $e');
    }
  }

  /// Stream of inventory events
  Stream<InventoryEvent> get inventoryEvents {
    return _channel.inventoryEvents.map((map) {
      final type = map['type'] as String;
      switch (type) {
        case 'tagRead':
          final tagMap = map['tag'] as Map<String, dynamic>;
          return TagReadEvent(RfidTag.fromMap(tagMap));
        case 'inventoryRound':
          final statsMap = map['stats'] as Map<String, dynamic>;
          return InventoryRoundEvent(RfidInventoryStats.fromMap(statsMap));
        case 'inventoryStopped':
          final statsMap = map['stats'] as Map<String, dynamic>;
          return InventoryStoppedEvent(RfidInventoryStats.fromMap(statsMap));
        case 'inventoryError':
          final errorMap = map['error'] as Map<String, dynamic>;
          return InventoryErrorEvent(RfidError.fromMap(errorMap));
        default:
          throw RfidServiceException('Unknown inventory event type: $type');
      }
    });
  }

  // ========== GEIGER SEARCH ==========

  /// Start Geiger search for specific tag
  Future<void> startGeigerSearch(String epc, {int memoryBank = 1}) async {
    try {
      await _channel.startGeigerSearch(epc, memoryBank);
    } catch (e) {
      throw RfidServiceException('Failed to start Geiger search: $e');
    }
  }

  /// Stop Geiger search
  Future<void> stopGeigerSearch() async {
    try {
      await _channel.stopGeigerSearch();
    } catch (e) {
      throw RfidServiceException('Failed to stop Geiger search: $e');
    }
  }

  /// Check if currently searching
  Future<bool> isSearching() async {
    try {
      return await _channel.isSearching();
    } catch (e) {
      throw RfidServiceException('Failed to check search status: $e');
    }
  }

  /// Stream of Geiger events
  Stream<GeigerEvent> get geigerEvents {
    return _channel.geigerEvents.map((map) {
      final type = map['type'] as String;
      switch (type) {
        case 'proximityUpdate':
          final statsMap = map['stats'] as Map<String, dynamic>;
          return ProximityUpdateEvent(RfidGeigerStats.fromMap(statsMap));
        case 'geigerStarted':
          final epc = map['epc'] as String;
          return GeigerStartedEvent(epc);
        case 'geigerStopped':
          final statsMap = map['stats'] as Map<String, dynamic>;
          return GeigerStoppedEvent(RfidGeigerStats.fromMap(statsMap));
        case 'geigerError':
          final errorMap = map['error'] as Map<String, dynamic>;
          return GeigerErrorEvent(RfidError.fromMap(errorMap));
        default:
          throw RfidServiceException('Unknown Geiger event type: $type');
      }
    });
  }

  // ========== BARCODE ==========

  /// Start barcode scanning
  Future<void> startBarcodeScan() async {
    try {
      await _channel.startBarcodeScan();
    } catch (e) {
      throw RfidServiceException('Failed to start barcode scan: $e');
    }
  }

  /// Stop barcode scanning
  Future<void> stopBarcodeScan() async {
    try {
      await _channel.stopBarcodeScan();
    } catch (e) {
      throw RfidServiceException('Failed to stop barcode scan: $e');
    }
  }

  /// Check if barcode scanning is active
  Future<bool> isBarcodeScanning() async {
    try {
      return await _channel.isBarcodeScanning();
    } catch (e) {
      throw RfidServiceException('Failed to check barcode scan status: $e');
    }
  }

  /// Stream of barcode events
  Stream<BarcodeEvent> get barcodeEvents {
    return _channel.barcodeEvents.map((map) {
      final type = map['type'] as String;
      switch (type) {
        case 'barcodeScanned':
          final barcodeMap = map['barcode'] as Map<String, dynamic>;
          return BarcodeScannedEvent(BarcodeData.fromMap(barcodeMap));
        case 'barcodeStats':
          final statsMap = map['stats'] as Map<String, dynamic>;
          return BarcodeStatsEvent(BarcodeStats.fromMap(statsMap));
        case 'barcodeError':
          final errorMap = map['error'] as Map<String, dynamic>;
          return BarcodeErrorEvent(RfidError.fromMap(errorMap));
        default:
          throw RfidServiceException('Unknown barcode event type: $type');
      }
    });
  }

  // ========== BATTERY ==========

  /// Get current battery info
  Future<BatteryInfo?> getBatteryInfo() async {
    try {
      final map = await _channel.getBatteryInfo();
      return map != null ? BatteryInfo.fromMap(map) : null;
    } catch (e) {
      throw RfidServiceException('Failed to get battery info: $e');
    }
  }

  /// Start battery monitoring
  Future<void> startBatteryMonitoring() async {
    try {
      await _channel.startBatteryMonitoring();
    } catch (e) {
      throw RfidServiceException('Failed to start battery monitoring: $e');
    }
  }

  /// Stop battery monitoring
  Future<void> stopBatteryMonitoring() async {
    try {
      await _channel.stopBatteryMonitoring();
    } catch (e) {
      throw RfidServiceException('Failed to stop battery monitoring: $e');
    }
  }

  /// Check if battery monitoring is active
  Future<bool> isBatteryMonitoringActive() async {
    try {
      return await _channel.isBatteryMonitoringActive();
    } catch (e) {
      throw RfidServiceException('Failed to check battery monitoring status: $e');
    }
  }

  /// Stream of battery events
  Stream<BatteryUpdateEvent> get batteryEvents {
    return _channel.batteryEvents.map((map) {
      final batteryMap = map['battery'] as Map<String, dynamic>;
      return BatteryUpdateEvent(BatteryInfo.fromMap(batteryMap));
    });
  }

  // ========== TRIGGER ==========

  /// Enable trigger key support
  Future<void> enableTrigger({bool autoInventory = false}) async {
    try {
      await _channel.enableTrigger(autoInventory);
    } catch (e) {
      throw RfidServiceException('Failed to enable trigger: $e');
    }
  }

  /// Disable trigger key support
  Future<void> disableTrigger() async {
    try {
      await _channel.disableTrigger();
    } catch (e) {
      throw RfidServiceException('Failed to disable trigger: $e');
    }
  }

  /// Get current trigger button state
  Future<bool> getTriggerState() async {
    try {
      return await _channel.getTriggerState();
    } catch (e) {
      throw RfidServiceException('Failed to get trigger state: $e');
    }
  }

  /// Check if trigger monitoring is active
  Future<bool> isTriggerMonitoringActive() async {
    try {
      return await _channel.isTriggerMonitoringActive();
    } catch (e) {
      throw RfidServiceException('Failed to check trigger monitoring status: $e');
    }
  }

  /// Stream of trigger events
  Stream<TriggerStateChangedEvent> get triggerEvents {
    return _channel.triggerEvents.map((map) {
      final pressed = map['pressed'] as bool;
      return TriggerStateChangedEvent(pressed);
    });
  }

  // ========== CONFIGURATION ==========

  /// Get current reader configuration
  Future<RfidConfiguration> getConfiguration() async {
    try {
      final map = await _channel.getConfiguration();
      return RfidConfiguration.fromMap(map);
    } catch (e) {
      throw RfidServiceException('Failed to get configuration: $e');
    }
  }

  /// Apply reader configuration
  Future<void> applyConfiguration(RfidConfiguration config) async {
    try {
      await _channel.applyConfiguration(config.toMap());
    } catch (e) {
      throw RfidServiceException('Failed to apply configuration: $e');
    }
  }

  /// Stream of configuration events
  Stream<ConfigEvent> get configEvents {
    return _channel.configEvents.map((map) {
      final type = map['type'] as String;
      switch (type) {
        case 'configured':
          final configMap = map['config'] as Map<String, dynamic>;
          return ConfiguredEvent(RfidConfiguration.fromMap(configMap));
        case 'configFailed':
          final errorMap = map['error'] as Map<String, dynamic>;
          return ConfigFailedEvent(RfidError.fromMap(errorMap));
        default:
          throw RfidServiceException('Unknown config event type: $type');
      }
    });
  }
}

// ========== EVENT CLASSES ==========

/// Base class for scan events
sealed class ScanEvent {}

class ReaderDiscoveredEvent extends ScanEvent {
  final RfidReader reader;
  ReaderDiscoveredEvent(this.reader);
}

class ReaderUpdatedEvent extends ScanEvent {
  final RfidReader reader;
  ReaderUpdatedEvent(this.reader);
}

class ScanErrorEvent extends ScanEvent {
  final RfidError error;
  ScanErrorEvent(this.error);
}

/// Base class for connection events
sealed class ConnectionEvent {}

class ConnectingEvent extends ConnectionEvent {
  ConnectingEvent();
}

class ConnectedEvent extends ConnectionEvent {
  final RfidReader reader;
  ConnectedEvent(this.reader);
}

class ReaderReadyEvent extends ConnectionEvent {
  final RfidReader reader;
  ReaderReadyEvent(this.reader);
}

class DisconnectedEvent extends ConnectionEvent {
  DisconnectedEvent();
}

class ConnectionFailedEvent extends ConnectionEvent {
  final RfidError error;
  ConnectionFailedEvent(this.error);
}

/// Base class for inventory events
sealed class InventoryEvent {}

class TagReadEvent extends InventoryEvent {
  final RfidTag tag;
  TagReadEvent(this.tag);
}

class InventoryRoundEvent extends InventoryEvent {
  final RfidInventoryStats stats;
  InventoryRoundEvent(this.stats);
}

class InventoryStoppedEvent extends InventoryEvent {
  final RfidInventoryStats stats;
  InventoryStoppedEvent(this.stats);
}

class InventoryErrorEvent extends InventoryEvent {
  final RfidError error;
  InventoryErrorEvent(this.error);
}

/// Base class for Geiger events
sealed class GeigerEvent {}

class ProximityUpdateEvent extends GeigerEvent {
  final RfidGeigerStats stats;
  ProximityUpdateEvent(this.stats);
}

class GeigerStartedEvent extends GeigerEvent {
  final String targetEpc;
  GeigerStartedEvent(this.targetEpc);
}

class GeigerStoppedEvent extends GeigerEvent {
  final RfidGeigerStats stats;
  GeigerStoppedEvent(this.stats);
}

class GeigerErrorEvent extends GeigerEvent {
  final RfidError error;
  GeigerErrorEvent(this.error);
}

/// Base class for barcode events
sealed class BarcodeEvent {}

class BarcodeScannedEvent extends BarcodeEvent {
  final BarcodeData barcode;
  BarcodeScannedEvent(this.barcode);
}

class BarcodeStatsEvent extends BarcodeEvent {
  final BarcodeStats stats;
  BarcodeStatsEvent(this.stats);
}

class BarcodeErrorEvent extends BarcodeEvent {
  final RfidError error;
  BarcodeErrorEvent(this.error);
}

/// Battery update event
class BatteryUpdateEvent {
  final BatteryInfo battery;
  BatteryUpdateEvent(this.battery);
}

/// Trigger state changed event
class TriggerStateChangedEvent {
  final bool pressed;
  TriggerStateChangedEvent(this.pressed);
}

/// Base class for configuration events
sealed class ConfigEvent {}

class ConfiguredEvent extends ConfigEvent {
  final RfidConfiguration config;
  ConfiguredEvent(this.config);
}

class ConfigFailedEvent extends ConfigEvent {
  final RfidError error;
  ConfigFailedEvent(this.error);
}

/// Service exception
class RfidServiceException implements Exception {
  final String message;
  RfidServiceException(this.message);

  @override
  String toString() => 'RfidServiceException: $message';
}
