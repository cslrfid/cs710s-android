# iOS Platform Models - JSON Serialization Helpers

This folder contains Swift model extensions and helper classes that convert CSL-CS710S-Library SDK types to Dictionary format for Flutter platform channel communication.

## Overview

Flutter platform channels require data to be serialized as primitive types (String, Int, Double, Bool, Array, Dictionary). These models provide conversion methods for all SDK data types used in the RFID platform implementation.

## Model Files

### 1. RfidReaderModel.swift

**Purpose**: Convert discovered RFID readers to Dictionary format

**SDK Type**: `RfidReader`

**Methods**:
- `toDictionary()` → `[String: Any]`
- `toDetailedDictionary(firmwareVersion:model:)` → `[String: Any]`

**Output Format**:
```swift
[
    "name": "CS710S-12AB",
    "address": "00:11:22:33:44:55",
    "rssi": -65,
    "serviceUUID": 0,
    "firmwareVersion": "1.0.0",  // Optional
    "model": "CS710S"             // Optional
]
```

**Helper Classes**:
- `ReaderConnectionState` - Connection state enumeration

---

### 2. RfidTagModel.swift

**Purpose**: Convert RFID tag reads to Dictionary format

**SDK Type**: `RfidTag`

**Methods**:
- `toDictionary()` → `[String: Any]`
- `toMinimalDictionary()` → `[String: Any]`

**Output Format**:
```swift
[
    "epc": "E28011700000020123456789",
    "rssi": -45,
    "count": 5,
    "timestamp": "2024-11-18T12:34:56Z",
    "phase": 0,     // Not available
    "channel": 0,   // Not available
    "pc": "",
    "crc": ""
]
```

**Helper Classes**:
- `TagStorage` - Tag accumulation and deduplication
  - `addOrUpdate(_ tag:)` - Add or update tag count
  - `getAllTags()` - Get all stored tags
  - `clear()` - Clear all tags
  - `uniqueCount` - Get unique tag count
  - `totalReads` - Get total read count

---

### 3. RfidGeigerStatsModel.swift

**Purpose**: Convert Geiger search statistics to Dictionary format

**SDK Type**: `RfidGeigerStats`

**Methods**:
- `toDictionary(targetEpc:elapsedTimeMs:)` → `[String: Any]`
- `toMinimalDictionary()` → `[String: Any]`

**Output Format**:
```swift
[
    "targetEpc": "E28011700000020123456789",
    "currentRssi": -50,
    "peakRssi": -30,
    "proximity": 75,        // 0-100% (SDK-calculated)
    "readCount": 42,
    "readRate": 12,         // Reads/second
    "elapsedTimeMs": 5420
]
```

**Helper Classes**:
- `GeigerSearchState` - Search state tracking
  - `reset(targetEpc:)` - Start new search
  - `stop()` - End search
  - `elapsedTimeMs` - Calculate elapsed time
  - `createZeroProximityStats()` - Create timeout event

---

### 4. BatteryInfoModel.swift

**Purpose**: Convert battery status to Dictionary format

**SDK Type**: `BatteryInfo`

**Methods**:
- `toDictionary()` → `[String: Any]`
- `toMinimalDictionary()` → `[String: Any]`

**Output Format**:
```swift
[
    "level": 85,                    // 0-100%
    "voltage": 0.0,                 // Not available
    "timestamp": "2024-11-18T12:34:56Z",
    "isCharging": false
]
```

**Helper Classes**:
- `BatteryState` - Battery state caching
  - `update(_ info:)` - Update cached battery info
  - `getLatest()` - Get last known battery info
  - `startMonitoring()` / `stopMonitoring()` - Control monitoring
  - `isActive` - Check if monitoring

---

### 5. BarcodeDataModel.swift

**Purpose**: Convert barcode scans to Dictionary format

**SDK Type**: `BarcodeData`, `BarcodeStats`

**Methods**:
- `BarcodeData.toDictionary()` → `[String: Any]`
- `BarcodeStats.toDictionary(elapsedTimeMs:)` → `[String: Any]`

**Output Formats**:
```swift
// Barcode Data
[
    "barcode": "1234567890123",
    "timestamp": "2024-11-18T12:34:56Z",
    "type": ""
]

// Barcode Stats
[
    "totalScans": 15,
    "uniqueBarcodes": 12,
    "elapsedTimeMs": 45000
]
```

**Helper Classes**:
- `BarcodeStorage` - Barcode accumulation and deduplication
  - `add(_ data:)` - Add barcode (returns true if new)
  - `getAllBarcodes()` - Get all scans
  - `clear()` - Clear all barcodes
  - `totalScans` - Total scan count
  - `uniqueCount` - Unique barcode count
  - `statsToDict()` - Create stats dictionary

---

### 6. RfidErrorModel.swift

**Purpose**: Convert RFID errors to Dictionary format

**SDK Type**: `RfidError`

**Methods**:
- `toDictionary()` → `[String: Any]`
- `errorType` - Categorize error type

**Output Format**:
```swift
[
    "message": "Connection failed: timeout",
    "type": "CONNECTION_ERROR",
    "cause": ""
]
```

**Error Types**:
- `CONNECTION_ERROR`
- `BLUETOOTH_ERROR`
- `SCAN_ERROR`
- `INVENTORY_ERROR`
- `CONFIG_ERROR`
- `TIMEOUT_ERROR`
- `UNKNOWN_ERROR`

**Helper Class**:
- `RfidErrorHelper` - Static error dictionary creators
  - `connectionError(message:)`
  - `scanError(message:)`
  - `inventoryError(message:)`
  - `configError(message:)`
  - `barcodeError(message:)`
  - `geigerError(message:)`
  - `generalError(message:type:)`

---

### 7. RfidConfigurationModel.swift

**Purpose**: Convert reader configuration to Dictionary format

**SDK Type**: `RfidConfiguration`

**Methods**:
- `toDictionary()` → `[String: Any]`

**Output Format**:
```swift
[
    "powerLevel": 300,          // 0-320 (0.0-32.0 dBm)
    "session": 1,               // 0-3 (S0-S3)
    "target": 0,                // 0=A, 1=B
    "population": 100,          // Tag population
    "linkProfile": 0,
    "qValue": 0,
    "beepEnabled": false,       // Not supported
    "vibrateEnabled": false     // Not supported
]
```

**Helper Classes**:
- `RfidConfigurationBuilder` - Fluent builder for configuration
  - `setPowerLevel(_ level:)` → Builder
  - `setSession(_ session:)` → Builder
  - `setTarget(_ target:)` → Builder
  - `setPopulation(_ population:)` → Builder
  - `build()` → Dictionary

- `ConfigurationState` - Configuration state tracking
  - `updatePowerLevel(_ level:)`
  - `updateSession(_ session:)`
  - `updateTarget(_ target:)`
  - `updatePopulation(_ population:)`
  - `toDictionary()` - Get current config

---

### 8. RfidInventoryStatsModel.swift

**Purpose**: Convert inventory statistics to Dictionary format

**SDK Type**: `RfidInventoryStats`, `RfidStopReason`

**Methods**:
- `RfidInventoryStats.toDictionary(elapsedTimeMs:)` → `[String: Any]`
- `RfidStopReason.description` → String

**Output Format**:
```swift
[
    "uniqueCount": 45,
    "totalReads": 234,
    "readRate": 12,         // Tags/second
    "elapsedTimeMs": 15420
]
```

**Helper Classes**:
- `InventoryState` - Inventory session state
  - `start()` / `stop()` - Control inventory
  - `active` - Check if running
  - `elapsedTimeMs` - Calculate elapsed time
  - `calculateReadRate(currentReadCount:)` - Compute rate
  - `resetRateCalculation()` - Reset timer

---

## Usage Patterns

### Basic Conversion

```swift
// Convert SDK type to Flutter Dictionary
let reader: RfidReader = ...
let dict = reader.toDictionary()

// Send to Flutter via EventSink
eventSink?([
    "type": "readerDiscovered",
    "reader": dict
])
```

### Using Helper Classes

```swift
// Tag storage
let tagStorage = TagStorage()
tagStorage.addOrUpdate(tag)
print("Unique tags: \(tagStorage.uniqueCount)")
print("Total reads: \(tagStorage.totalReads)")

// Battery state
let batteryState = BatteryState()
batteryState.update(batteryInfo)
if let dict = batteryState.toDictionary() {
    eventSink?(["type": "batteryUpdate", "battery": dict])
}

// Geiger search state
let geigerState = GeigerSearchState()
geigerState.reset(targetEpc: "E28011...")
let zeroStats = geigerState.createZeroProximityStats(peakRssi: -30, readCount: 10)
```

### Error Handling

```swift
// Convert SDK error
let error: RfidError = ...
let errorDict = error.toDictionary()
eventSink?(["type": "scanError", "error": errorDict])

// Create custom error
let customError = RfidErrorHelper.connectionError(message: "Timeout")
eventSink?(["type": "connectionFailed", "error": customError])
```

---

## Integration with RfidPlatformChannel

These models are used throughout `RfidPlatformChannel.swift` to convert SDK events to Flutter-compatible dictionaries:

```swift
// In RfidScanDelegate
func onReaderDiscovered(_ reader: RfidReader) {
    sendEvent(to: scanEventSink, data: [
        "type": "readerDiscovered",
        "reader": reader.toDictionary()  // ← Using model extension
    ])
}

// In RfidInventoryDelegate
func onTagRead(_ tag: RfidTag) {
    sendEvent(to: inventoryEventSink, data: [
        "type": "tagRead",
        "tag": tag.toDictionary()  // ← Using model extension
    ])
}

// In RfidGeigerDelegate
func onProximityUpdate(_ stats: RfidGeigerStats) {
    sendEvent(to: geigerEventSink, data: [
        "type": "proximityUpdate",
        "stats": stats.toDictionary(  // ← Using model extension
            targetEpc: targetEpc,
            elapsedTimeMs: elapsedMs
        )
    ])
}
```

---

## Design Principles

1. **Extensions over Wrappers**: Extend SDK types directly for seamless integration
2. **Consistent Naming**: All `toDictionary()` methods follow the same pattern
3. **Optional Data**: Handle missing SDK data gracefully (e.g., `phase`, `channel`)
4. **Helper Classes**: Provide state management utilities for complex workflows
5. **Type Safety**: Maintain Swift type safety while producing Dictionary output
6. **Minimal Dictionary**: Offer `toMinimalDictionary()` for bandwidth optimization

---

## Testing

To test these models:

```swift
// Test tag conversion
let tag = RfidTag(epc: "E280...", rssi: -45, count: 1, timestamp: Date())
let dict = tag.toDictionary()
assert(dict["epc"] as? String == "E280...")

// Test tag storage
let storage = TagStorage()
storage.addOrUpdate(tag)
assert(storage.uniqueCount == 1)
assert(storage.totalReads == 1)

// Test Geiger state
let geigerState = GeigerSearchState()
geigerState.reset(targetEpc: "E280...")
assert(geigerState.targetEpc == "E280...")
assert(geigerState.isSearching == true)
```

---

**Last Updated**: November 2024
**Version**: Phase 1 - Foundation
**Compatibility**: CSL-CS710S-Library 1.0+
