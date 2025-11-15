# CSL RFID Android SDK - Technical Documentation

**Module**: csl-rfid-android-sdk
**Status**: ✅ **Production Ready**
**Last Updated**: January 2025
**Version**: 1.0.0

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Module Architecture](#module-architecture)
3. [Package Structure](#package-structure)
4. [Core Components](#core-components)
5. [Manager Classes](#manager-classes)
6. [Data Models](#data-models)
7. [Configuration System](#configuration-system)
8. [Thread Management](#thread-management)
9. [API Reference](#api-reference)
10. [Implementation Patterns](#implementation-patterns)
11. [Integration Guide](#integration-guide)

---

## Executive Summary

The **csl-rfid-android-sdk** module provides a clean, modern Android wrapper around the `cslibrary4a` vendor SDK for CSL CS710S RFID readers. It simplifies RFID operations with:

- **Clean API**: Intuitive, callback-based interface
- **Thread Safety**: Automatic background/main thread management
- **MVVM Ready**: LiveData-compatible callbacks
- **Comprehensive**: All core RFID operations supported
- **Production Quality**: Error handling, resource management, documentation

### Module Status

| Component | Status | Lines |
|-----------|--------|-------|
| RfidManager | ✅ Complete | 778 |
| RfidConnectionManager | ✅ Complete | 443 |
| RfidInventoryManager | ✅ Complete | 345 |
| RfidGeigerManager | ✅ Complete | 330 |
| RfidConfigurationManager | ✅ Complete | 165 |
| BarcodeScanManager | ✅ Complete | 210 |
| Data Models | ✅ Complete | ~650 |
| Callbacks | ✅ Complete | ~230 |
| Internal Utilities | ✅ Complete | ~164 |
| **Total** | **✅ Production Ready** | **~3,300** |

---

## Module Architecture

### Layer Diagram

```
┌─────────────────────────────────────────┐
│   Public API (RfidManager)              │
│   Fluent Configuration, Lifecycle       │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│   Manager Layer                         │
│   Connection, Inventory, Geiger, Config │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│   Internal Layer                        │
│   SdkBridge, ThreadManager              │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│   Vendor SDK (cslibrary4a)              │
│   CsLibrary4A - Native RFID operations  │
└─────────────────────────────────────────┘
```

### Design Principles

1. **Separation of Concerns**: Each manager handles one domain
2. **Encapsulation**: Vendor SDK complexity hidden behind clean API
3. **Thread Safety**: All SDK calls on background thread, callbacks on main
4. **Resource Management**: Proper lifecycle handling and cleanup
5. **Error Handling**: Comprehensive error reporting via callbacks

---

## Package Structure

```
com.csl.rfidsdk/
├── RfidManager.java                    # Main API entry point (778 lines)
├── RfidManagerBuilder.java             # Builder pattern for setup (58 lines)
│
├── callbacks/                          # Callback Interfaces (8 files)
│   ├── RfidScanCallback.java           # Reader scan events
│   ├── RfidConnectionCallback.java     # Connection events (with onReaderReady)
│   ├── RfidInventoryCallback.java      # Tag inventory events
│   ├── RfidGeigerCallback.java         # Geiger search events
│   ├── RfidConfigurationCallback.java  # Configuration events
│   ├── BatteryCallback.java            # Battery monitoring events
│   ├── BarcodeScanCallback.java        # Barcode scan events
│   └── TriggerCallback.java            # Trigger key events
│
├── config/                             # Configuration Enums (4 files)
│   ├── RfidRegion.java                 # FCC, ETSI, Japan, etc.
│   ├── RfidTarget.java                 # A, B, AB_FLIP
│   ├── RfidInventoryMode.java          # COMPACT, STANDARD
│   └── RfidStopReason.java             # Stop reasons
│
├── internal/                           # Internal Utilities (2 files)
│   ├── SdkBridge.java                  # SDK wrapper (70 lines)
│   └── ThreadManager.java              # Thread management (94 lines)
│
├── managers/                           # Core Managers (5 files)
│   ├── RfidConnectionManager.java      # BLE scan/connect (443 lines)
│   ├── RfidInventoryManager.java       # Tag inventory (345 lines)
│   ├── RfidGeigerManager.java          # Tag locating (330 lines)
│   ├── RfidConfigurationManager.java   # Reader config (165 lines)
│   └── BarcodeScanManager.java         # Barcode scanning (210 lines)
│
└── models/                             # Data Models (10 files)
    ├── RfidReader.java                 # Reader device info
    ├── RfidTag.java                    # Tag data (EPC, RSSI, etc.)
    ├── RfidError.java                  # Error information
    ├── RfidConfiguration.java          # Reader settings
    ├── RfidInventoryStats.java         # Inventory statistics
    ├── RfidGeigerStats.java            # Geiger search statistics
    ├── BatteryInfo.java                # Battery status data
    ├── BarcodeData.java                # Barcode scan result
    └── BarcodeStats.java               # Barcode statistics
```

---

## Core Components

### 1. RfidManager (Main API)

**Purpose**: Primary entry point for all RFID operations

**Responsibilities**:
- Lazy SDK initialization (created on first use, main thread safe)
- Lifecycle management (create, release)
- Public API for all RFID operations
- Fluent configuration builder

**Key Methods**:

```java
// Factory methods
public static RfidManager create(Context context)
public static RfidManagerBuilder builder(Context context)

// Scanning
public void startScan(RfidScanCallback callback)
public void stopScan()
public boolean isScanning()

// Connection
public void connect(RfidReader reader, RfidConnectionCallback callback)
public void disconnect()
public boolean isConnected()
public RfidReader getConnectedReader()

// Configuration
public ConfigurationBuilder configure()
public RfidConfiguration getConfiguration()

// Inventory
public void startInventory(RfidInventoryCallback callback)
public void stopInventory()
public boolean isInventorying()

// Geiger Search
public void startGeigerSearch(String epc, int bank, RfidGeigerCallback callback)
public void stopGeigerSearch()
public boolean isSearching()

// Battery Monitoring
public void startBatteryMonitoring(BatteryCallback callback)
public void stopBatteryMonitoring()

// Barcode Scanning
public void startBarcodeScan(BarcodeScanCallback callback)
public void stopBarcodeScan()
public boolean isBarcodeScanActive()

// Trigger Key Support
public void enableTrigger(TriggerCallback callback, boolean autoInventory)
public void disableTrigger()

// Lifecycle
public void release()
```

**Lazy Initialization Pattern**:

```java
private synchronized void ensureInitialized() {
    if (initialized) return;

    // If not on main thread, post to main thread and wait
    if (Looper.myLooper() != Looper.getMainLooper()) {
        CountDownLatch latch = new CountDownLatch(1);
        new Handler(Looper.getMainLooper()).post(() -> {
            initializeSdk();
            latch.countDown();
        });
        latch.await(5, TimeUnit.SECONDS);
    } else {
        initializeSdk();
    }
}
```

**Why Lazy Initialization?**
- CsLibrary4A SDK must be created on main thread
- Delays initialization until first use
- Allows RfidManager to be created from any thread
- Prevents crashes from background thread creation

### 2. RfidManagerBuilder

**Purpose**: Builder pattern for RfidManager configuration

**Supported Options**:
- Custom logger callback
- Auto-reconnect enable/disable

**Usage**:

```java
RfidManager rfidManager = RfidManager.builder(context)
    .setLogger(message -> Log.d("RFID", message))
    .setAutoReconnect(true)
    .build();
```

---

## Manager Classes

### 1. RfidConnectionManager

**File**: `managers/RfidConnectionManager.java` (329 lines)

**Purpose**: Manages BLE scanning and connection to RFID readers

**Key Features**:
- BLE device scanning
- Reader discovery
- Connection establishment
- Connection monitoring
- Auto-reconnect (optional)
- 20-second connection timeout

**SDK Integration**:

| Operation | SDK Method | Notes |
|-----------|------------|-------|
| Start scanning | `scanLeDevice(true)` | Initiates BLE scan |
| Get discovered reader | `getNewDeviceScanned()` | Polls for new devices |
| Connect | `connect(ReaderDevice)` | Establishes connection |
| Check connection | `isBleConnected()` | Monitors status |
| Disconnect | `disconnect(false)` | Closes connection |

**Implementation Highlights**:

```java
// Start scanning - polls for discovered devices
public void startScan(RfidScanCallback callback) {
    this.callback = callback;
    this.scanning = true;

    threadManager.executeOnBackground(() -> {
        CsLibrary4A sdk = sdkBridge.getSdk();
        sdk.scanLeDevice(true);

        // Poll for discovered readers
        Runnable pollRunnable = new Runnable() {
            public void run() {
                if (!scanning) return;

                ReaderDevice device = sdk.getNewDeviceScanned();
                if (device != null) {
                    RfidReader reader = convertToRfidReader(device);
                    threadManager.executeOnMain(() ->
                        callback.onReaderDiscovered(reader)
                    );
                }

                if (scanning) {
                    threadManager.executeOnBackground(this);
                }
                Thread.sleep(100);
            }
        };
        threadManager.executeOnBackground(pollRunnable);
    });
}
```

**Connection Flow**:

```java
// Connect to reader with timeout
public void connect(RfidReader reader, RfidConnectionCallback callback) {
    threadManager.executeOnBackground(() -> {
        CsLibrary4A sdk = sdkBridge.getSdk();

        // Start connection
        boolean started = sdk.connect(reader.getDevice());

        // Poll connection status (20 second timeout)
        long startTime = System.currentTimeMillis();
        while (!sdk.isBleConnected()) {
            if (System.currentTimeMillis() - startTime > 20000) {
                // Timeout
                threadManager.executeOnMain(() ->
                    callback.onConnectionFailed(new RfidError("Connection timeout"))
                );
                return;
            }
            Thread.sleep(100);
        }

        // Connected
        threadManager.executeOnMain(() -> callback.onConnected(reader));
    });
}
```

### 2. RfidInventoryManager

**File**: `managers/RfidInventoryManager.java` (345 lines)

**Purpose**: Manages RFID tag inventory (reading) operations

**Key Features**:
- Tag inventory with compact mode
- Tag data extraction (EPC, RSSI, phase, channel, timestamp)
- Tag deduplication and counting
- Real-time statistics (unique count, total reads, read rate)
- RSSI display in dBm (negative values)
- Configuration application (power, session, target)

**SDK Integration**:

| Operation | SDK Method | Notes |
|-----------|------------|-------|
| Start inventory | `startOperation(TAG_INVENTORY_COMPACT)` | Begins tag reading |
| Poll for tags | `onRFIDEvent()` | Returns tag data packets |
| Stop inventory | `abortOperation()` | Stops operation |
| Convert EPC | `byteArrayToString()` | Converts bytes to hex |
| Set power | `setPowerLevel(long)` | Sets antenna power |
| Set session/target | `setTagGroup(int, int, int)` | Configures inventory |

**Polling Loop Pattern**:

```java
// Start inventory and poll for tag data
public void startInventory(RfidInventoryCallback callback) {
    threadManager.executeOnBackground(() -> {
        CsLibrary4A sdk = sdkBridge.getSdk();

        // Apply configuration if available
        if (configuration != null) {
            applyConfigurationInternal(sdk);
        }

        // Start inventory
        boolean started = sdk.startOperation(
            RfidReaderChipData.OperationTypes.TAG_INVENTORY_COMPACT
        );

        // Create polling runnable
        inventoryPollRunnable = new Runnable() {
            public void run() {
                if (!inventorying) return;

                // Check connection
                if (!sdk.isBleConnected()) {
                    // Handle connection lost
                    return;
                }

                // Poll for tag data
                RfidReaderChipData.Rx000pkgData tagData = sdk.onRFIDEvent();

                if (tagData != null && sdk.mrfidToWriteSize() == 0) {
                    processTagData(tagData);
                }

                // Continue polling
                if (inventorying) {
                    threadManager.executeOnBackground(this);
                }

                Thread.sleep(10);
            }
        };

        threadManager.executeOnBackground(inventoryPollRunnable);
    });
}
```

**Tag Data Processing**:

```java
private void processTagData(RfidReaderChipData.Rx000pkgData tagData) {
    switch (tagData.responseType) {
        case TYPE_18K6C_INVENTORY:
        case TYPE_18K6C_INVENTORY_COMPACT:
            if (tagData.decodedError == null) {
                // Extract tag data
                String epc = sdk.byteArrayToString(tagData.decodedEpc);

                // RSSI: SDK returns positive values when rssiDisplaySetting=1
                // True dBm values are negative, so we negate
                double rssi = -Math.abs(tagData.decodedRssi);

                int phase = tagData.decodedPhase;
                int channel = tagData.decodedChidx;
                long timestamp = tagData.decodedTime;

                // Track tag count
                int count = tagCounts.getOrDefault(epc, 0) + 1;
                tagCounts.put(epc, count);
                totalReads++;

                // Build RfidTag and callback
                RfidTag tag = new RfidTag.Builder(epc)
                    .rssi(rssi)
                    .count(count)
                    .phase(phase)
                    .channel(channel)
                    .timestamp(timestamp)
                    .build();

                threadManager.executeOnMain(() -> callback.onTagRead(tag));
            }
            break;

        case TYPE_COMMAND_END:
            inventorying = false;
            threadManager.executeOnMain(() ->
                callback.onInventoryStopped(RfidStopReason.COMPLETED)
            );
            break;

        case TYPE_COMMAND_ABORT_RETURN:
            inventorying = false;
            threadManager.executeOnMain(() ->
                callback.onInventoryStopped(RfidStopReason.USER_STOPPED)
            );
            break;
    }
}
```

**RSSI Correction**:

The SDK returns positive RSSI values when `rssiDisplaySetting=1` (dBm mode), but true dBm values should be negative. The fix:

```java
// RSSI: SDK returns positive values when rssiDisplaySetting=1 (dBm mode)
// True dBm values are negative, so we negate to get proper dBm format
double rssi = -Math.abs(tagData.decodedRssi);
```

This ensures RSSI displays correctly as negative values (e.g., -50 dBm instead of +50).

### 3. RfidGeigerManager

**File**: `managers/RfidGeigerManager.java` (330 lines)

**Purpose**: Manages Geiger search (tag locating) operations

**Key Features**:
- Search for specific tag by EPC
- RSSI tracking (current and peak)
- Proximity calculation (0-100%)
- Read count tracking
- Settings restoration after search

**SDK Integration**:

| Operation | SDK Method | Notes |
|-----------|------------|-------|
| Select target tag | `setSelectedTag(String, int, int)` | Filters for target |
| Start search | `startOperation(TAG_SEARCHING)` | Begins search |
| Poll for target | `onRFIDEvent()` | Returns target reads |
| Restore settings | `restoreAfterTagSelect()` | Cleans up |
| Stop search | `abortOperation()` | Stops operation |

**Search Implementation**:

```java
public void startGeigerSearch(String targetEpc, int memoryBank,
                               RfidGeigerCallback callback) {
    this.targetEpc = targetEpc;
    this.memoryBank = memoryBank;
    this.searching = true;
    this.startTime = System.currentTimeMillis();
    this.readCount = 0;
    this.peakRssi = -90.0;
    this.currentRssi = -90.0;

    threadManager.executeOnBackground(() -> {
        CsLibrary4A sdk = sdkBridge.getSdk();

        // Get power level from configuration
        int powerLevel = 300;
        if (configuration != null && configuration.getPowerLevel() >= 0) {
            powerLevel = configuration.getPowerLevel();
        }

        // Set selected tag for search
        boolean selectSuccess = sdk.setSelectedTag(targetEpc, memoryBank, powerLevel);

        // Start search operation
        boolean started = sdk.startOperation(
            RfidReaderChipData.OperationTypes.TAG_SEARCHING
        );

        // Poll for tag reads (similar to inventory)
        searchPollRunnable = new Runnable() {
            public void run() {
                if (!searching) return;

                RfidReaderChipData.Rx000pkgData tagData = sdk.onRFIDEvent();

                if (tagData != null && sdk.mrfidToWriteSize() == 0) {
                    processSearchData(tagData);
                }

                if (searching) {
                    threadManager.executeOnBackground(this);
                }

                Thread.sleep(10);
            }
        };

        threadManager.executeOnBackground(searchPollRunnable);
    });
}
```

**Proximity Calculation**:

```java
private void processSearchData(RfidReaderChipData.Rx000pkgData tagData) {
    if (tagData.responseType == TYPE_18K6C_INVENTORY ||
        tagData.responseType == TYPE_18K6C_INVENTORY_COMPACT) {

        if (tagData.decodedError == null) {
            readCount++;

            // RSSI: SDK returns positive values, negate for proper dBm
            currentRssi = -Math.abs(tagData.decodedRssi);

            // Update peak RSSI (highest = least negative = closest)
            if (currentRssi > peakRssi) {
                peakRssi = currentRssi;
            }

            // Calculate proximity percentage (0-100)
            // RSSI typically ranges from -90 dBm (far) to -10 dBm (very close)
            double normalizedRssi = (currentRssi + 90.0) / 80.0; // Normalize to 0-1
            int proximity = (int) Math.max(0, Math.min(100, normalizedRssi * 100));

            // Build stats
            RfidGeigerStats stats = new RfidGeigerStats.Builder()
                .targetEpc(targetEpc)
                .currentRssi(currentRssi)
                .peakRssi(peakRssi)
                .readCount(readCount)
                .proximity(proximity)
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .build();

            // Callback with stats
            threadManager.executeOnMain(() -> callback.onProximityUpdate(stats));
        }
    }
}
```

**Cleanup**:

```java
public void stopGeigerSearch() {
    if (!searching) return;
    searching = false;

    threadManager.executeOnBackground(() -> {
        CsLibrary4A sdk = sdkBridge.getSdk();
        sdk.abortOperation();
        sdk.restoreAfterTagSelect(); // Restore settings

        threadManager.executeOnMain(() ->
            callback.onSearchStopped(RfidStopReason.USER_STOPPED)
        );
    });
}
```

### 4. RfidConfigurationManager

**File**: `managers/RfidConfigurationManager.java` (165 lines)

**Purpose**: Manages reader configuration settings

**Key Features**:
- Power level configuration (0-320 = 0.0-32.0 dBm)
- Session and target configuration
- Inventory mode (compact/standard)
- Q value configuration
- Beep and vibrate settings
- RSSI display mode (dBm)

**SDK Integration**:

| Configuration | SDK Method | Parameters |
|--------------|------------|------------|
| Power level | `setPowerLevel(long)` | 0-320 (0.0-32.0 dBm) |
| Session/Target | `setTagGroup(int, int, int)` | sL, session (0-3), target (0/1/2) |
| Inventory mode | `setInvModeCompact(boolean)` | true=compact, false=standard |
| Q value | `setQValue(byte)` | 0-15 |
| Beep | `setInventoryBeep(boolean)` | true/false |
| Vibrate | `setInventoryVibrate(boolean)` | true/false |
| RSSI display | `setRssiDisplaySetting(int)` | 1=dBm, 0=dBuV |

**Configuration Application**:

```java
public void applyConfigurationInternal(CsLibrary4A sdk, RfidConfiguration config) {
    // 1. Set power level (0-320, representing 0.0-32.0 dBm)
    sdk.setPowerLevel(config.getPowerLevel());
    log("Power level: " + config.getPowerLevel() + " (" +
        (config.getPowerLevel() / 10.0) + " dBm)");

    // 2. Set session and target together using setTagGroup(sL, session, target)
    // Parameters: sL=0 (select), session (0-3), target (0=A, 1=B, 2=AB_FLIP)
    int targetValue = convertTargetToSdkValue(config.getTarget());
    sdk.setTagGroup(0, config.getSession(), targetValue);
    log("Session: " + config.getSession() + ", Target: " + config.getTarget());

    // 3. Set inventory mode (compact for CS710S)
    boolean compactMode = config.getInventoryMode() == RfidInventoryMode.COMPACT;
    sdk.setInvModeCompact(compactMode);
    log("Inventory mode: " + config.getInventoryMode());

    // 4. Skip region setting - region is hardware-specific
    // The reader's default region should be used
    log("Region: " + config.getRegion() + " (using reader default)");

    // 5. Set Q value (0-15) - method takes byte parameter
    sdk.setQValue((byte) config.getQValue());
    log("Q value: " + config.getQValue());

    // 6. Enable/disable beep on tag read
    sdk.setInventoryBeep(config.isEnableBeep());
    log("Beep: " + config.isEnableBeep());

    // 7. Enable/disable vibration on tag read
    sdk.setInventoryVibrate(config.isEnableVibrate());
    log("Vibrate: " + config.isEnableVibrate());

    // 8. Set RSSI display setting to dBm (1) instead of dBuV (0)
    sdk.setRssiDisplaySetting(1);
    log("RSSI display: dBm (value=1)");
}
```

**Target Conversion**:

```java
private int convertTargetToSdkValue(RfidTarget target) {
    switch (target) {
        case A:
            return 0;
        case B:
            return 1;
        case AB_FLIP:
            return 2;
        default:
            return 0; // Default to A
    }
}
```

**Region Note**:

Region configuration is intentionally skipped because:
- `setCountryInList()` expects an index into a dynamic region list
- The region list varies by reader hardware
- Passing enum ordinal causes ArrayIndexOutOfBoundsException
- Reader uses its factory default region, which is correct for the hardware

### 5. BarcodeScanManager

**File**: `managers/BarcodeScanManager.java` (210 lines)

**Purpose**: Manages barcode scanning operations

**Key Features**:
- 1D and 2D barcode scanning
- Real-time scan results
- Scan statistics (total scans, unique barcodes)
- Automatic duplicate tracking
- Error handling

**SDK Integration**:

| Operation | SDK Method | Notes |
|-----------|------------|-------|
| Start scan | `sendCommandSetContinuousModeAlertSound(true)` | Enable barcode scanner |
| Poll for scans | `getBarcodeOnePending()` | Check for new barcodes |
| Get barcode | `getBarcodeOne()` | Retrieve barcode data |
| Stop scan | `sendCommandSetContinuousModeAlertSound(false)` | Disable barcode scanner |

**Barcode Scanning Implementation**:

```java
public void startBarcodeScan(BarcodeScanCallback callback) {
    this.callback = callback;
    this.scanning = true;
    this.scannedBarcodes.clear();
    this.totalScans = 0;
    this.startTime = System.currentTimeMillis();

    threadManager.executeOnBackground(() -> {
        CsLibrary4A sdk = sdkBridge.getSdk();

        // Enable barcode scanner
        sdk.sendCommandSetContinuousModeAlertSound(true);

        // Poll for barcode data
        barcodePollRunnable = new Runnable() {
            @Override
            public void run() {
                if (!scanning) return;

                // Check if barcode data is pending
                if (sdk.getBarcodeOnePending()) {
                    String barcode = sdk.getBarcodeOne();

                    if (barcode != null && !barcode.isEmpty()) {
                        processBarcodeData(barcode);
                    }
                }

                // Continue polling
                if (scanning) {
                    threadManager.executeOnMainDelayed(() -> {
                        if (scanning) {
                            threadManager.executeOnBackground(this);
                        }
                    }, 100);
                }
            }
        };

        threadManager.executeOnBackground(barcodePollRunnable);
    });
}

private void processBarcodeData(String barcode) {
    totalScans++;

    // Track unique barcodes
    if (!scannedBarcodes.contains(barcode)) {
        scannedBarcodes.add(barcode);
    }

    // Build BarcodeData
    BarcodeData barcodeData = new BarcodeData(
        barcode,
        System.currentTimeMillis()
    );

    // Build statistics
    BarcodeStats stats = new BarcodeStats.Builder()
        .totalScans(totalScans)
        .uniqueBarcodes(scannedBarcodes.size())
        .elapsedTimeMs(System.currentTimeMillis() - startTime)
        .build();

    // Fire callbacks
    threadManager.executeOnMain(() -> {
        callback.onBarcodeScanned(barcodeData);
        callback.onStatisticsUpdate(stats);
    });
}
```

---

## Data Models

### RfidReader

**File**: `models/RfidReader.java`

**Purpose**: Represents an RFID reader device

```java
public class RfidReader {
    private final String name;          // Reader name (e.g., "CS710-21190")
    private final String address;       // BLE MAC address
    private final double rssi;          // Signal strength (dBm)
    private final ReaderDevice device;  // Internal device reference

    // Getters
    public String getName()
    public String getAddress()
    public double getRssi()
    public ReaderDevice getDevice()
}
```

### RfidTag

**File**: `models/RfidTag.java`

**Purpose**: Represents an RFID tag read

```java
public class RfidTag {
    private final String epc;           // Tag EPC (hex string)
    private final double rssi;          // Signal strength (dBm, negative)
    private final int count;            // Read count
    private final int phase;            // Phase angle (0-4095)
    private final int channel;          // Frequency channel
    private final long timestamp;       // Read timestamp (ms)

    // Builder pattern for construction
    public static class Builder {
        public Builder(String epc)
        public Builder rssi(double rssi)
        public Builder count(int count)
        public Builder phase(int phase)
        public Builder channel(int channel)
        public Builder timestamp(long timestamp)
        public RfidTag build()
    }

    // Getters
    public String getEpc()
    public double getRssi()
    public int getCount()
    public int getPhase()
    public int getChannel()
    public long getTimestamp()
}
```

### RfidConfiguration

**File**: `models/RfidConfiguration.java`

**Purpose**: Reader configuration settings

```java
public class RfidConfiguration {
    private final int powerLevel;               // 0-320 (0.0-32.0 dBm)
    private final int session;                  // 0-3
    private final RfidTarget target;            // A, B, AB_FLIP
    private final RfidInventoryMode inventoryMode;  // COMPACT, STANDARD
    private final RfidRegion region;            // FCC, ETSI, etc.
    private final int qValue;                   // 0-15
    private final boolean populateRssi;         // Include RSSI
    private final boolean populatePhase;        // Include phase
    private final boolean populateChannel;      // Include channel
    private final boolean enableBeep;           // Beep on tag read
    private final boolean enableVibrate;        // Vibrate on tag read

    // Builder pattern
    public static class Builder {
        public Builder powerLevel(int powerLevel)
        public Builder session(int session)
        public Builder target(RfidTarget target)
        public Builder inventoryMode(RfidInventoryMode mode)
        public Builder region(RfidRegion region)
        public Builder qValue(int qValue)
        public Builder populateRssi(boolean populate)
        public Builder populatePhase(boolean populate)
        public Builder populateChannel(boolean populate)
        public Builder enableBeep(boolean enable)
        public Builder enableVibrate(boolean enable)
        public RfidConfiguration build()
    }

    // Getters for all fields
}
```

**Default Values**:

```java
powerLevel: 300 (30.0 dBm)
session: 0
target: RfidTarget.A
inventoryMode: RfidInventoryMode.COMPACT
region: RfidRegion.FCC
qValue: 7
populateRssi: true
populatePhase: true
populateChannel: true
enableBeep: true
enableVibrate: true
```

### RfidInventoryStats

**File**: `models/RfidInventoryStats.java`

**Purpose**: Inventory operation statistics

```java
public class RfidInventoryStats {
    private final int uniqueTagCount;   // Number of unique tags read
    private final int totalReads;       // Total read count
    private final double readRate;      // Reads per second
    private final long elapsedTimeMs;   // Elapsed time

    // Builder pattern
    public static class Builder {
        public Builder uniqueTagCount(int count)
        public Builder totalReads(int reads)
        public Builder readsPerSecond(double rate)
        public Builder elapsedTimeMs(long elapsed)
        public RfidInventoryStats build()
    }

    // Getters
    public int getUniqueTagCount()
    public int getTotalReads()
    public double getReadRate()
    public long getElapsedTimeMs()
}
```

### RfidGeigerStats

**File**: `models/RfidGeigerStats.java`

**Purpose**: Geiger search statistics

```java
public class RfidGeigerStats {
    private final String targetEpc;     // Target tag EPC
    private final double currentRssi;   // Current RSSI (dBm, negative)
    private final double peakRssi;      // Peak RSSI (dBm, negative)
    private final int readCount;        // Read count
    private final int proximity;        // Proximity percentage (0-100)
    private final long elapsedTimeMs;   // Elapsed time

    // Builder pattern
    public static class Builder {
        public Builder targetEpc(String epc)
        public Builder currentRssi(double rssi)
        public Builder peakRssi(double rssi)
        public Builder readCount(int count)
        public Builder proximity(int proximity)
        public Builder elapsedTimeMs(long elapsed)
        public RfidGeigerStats build()
    }

    // Getters
    public String getTargetEpc()
    public double getCurrentRssi()
    public double getPeakRssi()
    public int getReadCount()
    public int getProximity()
    public long getElapsedTimeMs()
}
```

### RfidError

**File**: `models/RfidError.java`

**Purpose**: Error information

```java
public class RfidError {
    private final String message;       // Error message
    private final ErrorType type;       // Error type enum
    private final Throwable cause;      // Optional exception

    // Error types
    public enum ErrorType {
        CONNECTION_FAILED,
        CONNECTION_LOST,
        DISCONNECTED,
        NOT_CONNECTED,
        SCAN_FAILED,
        INVENTORY_FAILED,
        CONFIGURATION_FAILED,
        PERMISSION_DENIED,
        BLUETOOTH_DISABLED,
        TIMEOUT,
        UNKNOWN
    }

    // Constructors
    public RfidError(String message, ErrorType type)
    public RfidError(String message, ErrorType type, Throwable cause)

    // Getters
    public String getMessage()
    public ErrorType getType()
    public Throwable getCause()
}
```

### BatteryInfo

**File**: `models/BatteryInfo.java`

**Purpose**: Battery status information

```java
public class BatteryInfo {
    private final int level;           // Battery level (0-100%)
    private final boolean charging;    // Is device charging
    private final long timestamp;      // Reading timestamp

    // Static factory method
    public static BatteryInfo fromSdk(CsLibrary4A sdk)

    // Getters
    public int getLevel()
    public boolean isCharging()
    public long getTimestamp()
    public boolean isValid()           // Checks if level is valid (0-100)
}
```

### BarcodeData

**File**: `models/BarcodeData.java`

**Purpose**: Barcode scan result

```java
public class BarcodeData {
    private final String barcode;      // Barcode value
    private final long timestamp;      // Scan timestamp

    // Constructor
    public BarcodeData(String barcode, long timestamp)

    // Getters
    public String getBarcode()
    public long getTimestamp()
}
```

### BarcodeStats

**File**: `models/BarcodeStats.java`

**Purpose**: Barcode scanning statistics

```java
public class BarcodeStats {
    private final int totalScans;       // Total barcode scans
    private final int uniqueBarcodes;   // Number of unique barcodes
    private final long elapsedTimeMs;   // Elapsed time

    // Builder pattern
    public static class Builder {
        public Builder totalScans(int count)
        public Builder uniqueBarcodes(int count)
        public Builder elapsedTimeMs(long elapsed)
        public BarcodeStats build()
    }

    // Getters
    public int getTotalScans()
    public int getUniqueBarcodes()
    public long getElapsedTimeMs()
}
```

---

## Configuration System

### Fluent API

**RfidManager.ConfigurationBuilder** provides a fluent API for configuration:

```java
rfidManager.configure()
    .powerLevel(300)                          // 30.0 dBm
    .session(1)                               // Session 1
    .target(RfidTarget.A)                     // Target A
    .inventoryMode(RfidInventoryMode.COMPACT) // Compact mode
    .qValue(7)                                // Q = 7
    .enableBeep(true)                         // Enable beep
    .enableVibrate(true)                      // Enable vibrate
    .apply(new RfidConfigurationCallback() {
        @Override
        public void onConfigured() {
            // Configuration applied successfully
        }

        @Override
        public void onConfigurationFailed(RfidError error) {
            // Configuration failed
        }
    });
```

### Configuration Options

| Parameter | Type | Range/Values | Description | SDK Method |
|-----------|------|--------------|-------------|------------|
| powerLevel | int | 0-320 | Antenna power (0.0-32.0 dBm) | `setPowerLevel()` |
| session | int | 0-3 | Inventory session | `setTagGroup()` |
| target | RfidTarget | A, B, AB_FLIP | Target flag | `setTagGroup()` |
| inventoryMode | RfidInventoryMode | COMPACT, STANDARD | Inventory mode | `setInvModeCompact()` |
| qValue | int | 0-15 | Q algorithm value | `setQValue()` |
| enableBeep | boolean | true/false | Beep on tag read | `setInventoryBeep()` |
| enableVibrate | boolean | true/false | Vibrate on tag read | `setInventoryVibrate()` |

**Note**: Region configuration is not exposed in the fluent API because it uses the reader's hardware default.

---

## Thread Management

### ThreadManager

**File**: `internal/ThreadManager.java` (94 lines)

**Purpose**: Manages background and main thread execution

**Components**:
- ExecutorService for background thread pool
- Handler for main thread posting
- Shutdown handling

**Key Methods**:

```java
public void executeOnBackground(Runnable task)
public void executeOnMain(Runnable task)
public void shutdown()
public boolean isShutdown()
```

**Usage Pattern**:

```java
// Execute SDK operation on background thread
threadManager.executeOnBackground(() -> {
    CsLibrary4A sdk = sdkBridge.getSdk();
    // SDK operations here
});

// Execute callback on main thread
threadManager.executeOnMain(() -> {
    callback.onUpdate(result);
});

// Check before submitting
if (!threadManager.isShutdown()) {
    threadManager.executeOnBackground(task);
}
```

**Implementation**:

```java
public class ThreadManager {
    private final ExecutorService executorService;
    private final Handler mainHandler;
    private volatile boolean shutdown = false;

    public ThreadManager() {
        this.executorService = Executors.newCachedThreadPool();
        this.mainHandler = new Handler(Looper.getMainLooper());
    }

    public void executeOnBackground(Runnable task) {
        if (!shutdown) {
            executorService.execute(task);
        }
    }

    public void executeOnMain(Runnable task) {
        mainHandler.post(task);
    }

    public void shutdown() {
        shutdown = true;
        executorService.shutdown();
    }

    public boolean isShutdown() {
        return shutdown;
    }
}
```

### SdkBridge

**File**: `internal/SdkBridge.java` (70 lines)

**Purpose**: Wraps CsLibrary4A SDK instance

**Responsibilities**:
- SDK instance management
- Connection state tracking
- Resource cleanup

**Key Methods**:

```java
public CsLibrary4A getSdk()
public boolean isConnected()
public void release()
```

**Implementation**:

```java
public class SdkBridge {
    private final CsLibrary4A sdk;

    public SdkBridge(Context context) {
        this.sdk = new CsLibrary4A(context, CsLibrary4A.ServiceType.BLUETOOTH_LE);
    }

    public CsLibrary4A getSdk() {
        return sdk;
    }

    public boolean isConnected() {
        return sdk != null && sdk.isBleConnected();
    }

    public void release() {
        if (sdk != null) {
            sdk.disconnect(false);
        }
    }
}
```

---

## API Reference

### Quick Start Example

```java
// 1. Create RfidManager
RfidManager rfidManager = RfidManager.create(context);

// 2. Scan for readers
rfidManager.startScan(new RfidScanCallback() {
    @Override
    public void onReaderDiscovered(RfidReader reader) {
        // New reader found
        Log.d("RFID", "Found: " + reader.getName());
    }

    @Override
    public void onScanError(RfidError error) {
        // Handle error
    }
});

// 3. Connect to reader
rfidManager.connect(selectedReader, new RfidConnectionCallback() {
    @Override
    public void onConnected(RfidReader reader) {
        // Connected successfully
    }

    @Override
    public void onConnectionFailed(RfidError error) {
        // Handle error
    }

    @Override
    public void onDisconnected() {
        // Reader disconnected
    }
});

// 4. Configure reader
rfidManager.configure()
    .powerLevel(300)
    .session(1)
    .target(RfidTarget.A)
    .apply(new RfidConfigurationCallback() {
        @Override
        public void onConfigured() {
            // Ready to inventory
        }

        @Override
        public void onConfigurationFailed(RfidError error) {
            // Handle error
        }
    });

// 5. Start inventory
rfidManager.startInventory(new RfidInventoryCallback() {
    @Override
    public void onTagRead(RfidTag tag) {
        // New tag read
        Log.d("RFID", "EPC: " + tag.getEpc() +
              ", RSSI: " + tag.getRssi() + " dBm");
    }

    @Override
    public void onInventoryRound(RfidInventoryStats stats) {
        // Statistics updated
        Log.d("RFID", "Unique: " + stats.getUniqueTagCount() +
              ", Total: " + stats.getTotalReads() +
              ", Rate: " + stats.getReadRate() + " tags/sec");
    }

    @Override
    public void onInventoryStopped(RfidStopReason reason) {
        // Inventory stopped
    }

    @Override
    public void onInventoryError(RfidError error) {
        // Handle error
    }
});

// 6. Stop inventory
rfidManager.stopInventory();

// 7. Start Geiger search
String targetEpc = "E28011700000020EA9E44444";
rfidManager.startGeigerSearch(targetEpc, 1, new RfidGeigerCallback() {
    @Override
    public void onSearchStarted() {
        // Search started
    }

    @Override
    public void onProximityUpdate(RfidGeigerStats stats) {
        // Proximity updated
        Log.d("RFID", "Proximity: " + stats.getProximity() + "%, " +
              "RSSI: " + stats.getCurrentRssi() + " dBm");
    }

    @Override
    public void onSearchStopped(RfidStopReason reason) {
        // Search stopped
    }

    @Override
    public void onSearchError(RfidError error) {
        // Handle error
    }
});

// 8. Release resources
rfidManager.release();
```

### Callback Interfaces

#### RfidScanCallback

```java
public interface RfidScanCallback {
    void onReaderDiscovered(RfidReader reader);
    void onScanError(RfidError error);
}
```

#### RfidConnectionCallback

```java
public interface RfidConnectionCallback {
    void onConnecting();                      // Connection initiated
    void onConnected(RfidReader reader);      // BLE connected
    void onReaderReady(RfidReader reader);    // Fully initialized (battery data available)
    void onConnectionFailed(RfidError error); // Connection failed
    void onDisconnected(RfidReader reader, RfidError error); // Disconnected (error may be null)
}
```

**Connection Flow**:
1. `onConnecting()` - Connection initiated
2. `onConnected()` - BLE connection established
3. `onReaderReady()` - Reader fully initialized (15s max wait for battery data)
4. (operations can begin)
5. `onDisconnected()` - Connection lost or user-initiated disconnect

#### RfidInventoryCallback

```java
public interface RfidInventoryCallback {
    void onTagRead(RfidTag tag);
    void onInventoryRound(RfidInventoryStats stats);
    void onInventoryStopped(RfidStopReason reason);
    void onInventoryError(RfidError error);
}
```

#### RfidGeigerCallback

```java
public interface RfidGeigerCallback {
    void onSearchStarted();
    void onProximityUpdate(RfidGeigerStats stats);
    void onSearchStopped(RfidStopReason reason);
    void onSearchError(RfidError error);
}
```

#### RfidConfigurationCallback

```java
public interface RfidConfigurationCallback {
    void onConfigured();
    void onConfigurationFailed(RfidError error);
}
```

#### BatteryCallback

```java
public interface BatteryCallback {
    void onBatteryUpdate(BatteryInfo batteryInfo);
    void onBatteryError(RfidError error);
}
```

**Usage**: Start monitoring with `startBatteryMonitoring()`, polls every 5 seconds

#### BarcodeScanCallback

```java
public interface BarcodeScanCallback {
    void onBarcodeScanned(BarcodeData data);
    void onStatisticsUpdate(BarcodeStats stats);
    void onScanError(RfidError error);
}
```

#### TriggerCallback

```java
public interface TriggerCallback {
    void onTriggerStateChanged(boolean pressed);
}
```

**Usage**: Enable with `enableTrigger(callback, autoInventory)` where:
- `pressed = true`: Trigger key pressed down
- `pressed = false`: Trigger key released
- `autoInventory = false`: Manual mode (app handles events)
- `autoInventory = true`: Auto mode (SDK starts/stops inventory automatically)

---

## Implementation Patterns

### Pattern 1: Polling Loop

**Used in**: RfidInventoryManager, RfidGeigerManager

**Purpose**: Continuously poll SDK for data

```java
Runnable pollRunnable = new Runnable() {
    @Override
    public void run() {
        if (!active) return;

        // Poll for data
        Rx000pkgData data = sdk.onRFIDEvent();

        // Process if available
        if (data != null && sdk.mrfidToWriteSize() == 0) {
            processData(data);
        }

        // Continue polling
        if (active) {
            threadManager.executeOnBackground(this);
        }

        // Small delay to reduce CPU usage
        Thread.sleep(10);
    }
};

threadManager.executeOnBackground(pollRunnable);
```

### Pattern 2: Response Type Handling

**Used in**: RfidInventoryManager, RfidGeigerManager

**Purpose**: Handle different SDK response types

```java
private void processData(Rx000pkgData tagData) {
    switch (tagData.responseType) {
        case TYPE_18K6C_INVENTORY:
        case TYPE_18K6C_INVENTORY_COMPACT:
            // Tag data received
            if (tagData.decodedError == null) {
                processTagData(tagData);
            }
            break;

        case TYPE_ANTENNA_CYCLE_END:
            // Antenna cycle completed
            log("Antenna cycle completed");
            break;

        case TYPE_COMMAND_END:
            // Operation ended
            active = false;
            if (tagData.decodedError != null) {
                handleError(tagData.decodedError);
            } else {
                handleCompletion();
            }
            break;

        case TYPE_COMMAND_ABORT_RETURN:
            // Operation was aborted
            active = false;
            handleAbort();
            break;

        default:
            log("Unknown response type: " + tagData.responseType);
            break;
    }
}
```

### Pattern 3: Lazy Initialization

**Used in**: RfidManager

**Purpose**: Ensure SDK is created on main thread

```java
private synchronized void ensureInitialized() {
    if (initialized) {
        return;
    }

    log("Initializing SDK on thread: " + Thread.currentThread().getName());

    // If we're not on the main thread, post to main thread and wait
    if (Looper.myLooper() != Looper.getMainLooper()) {
        log("Not on main thread, posting initialization to main thread");

        final CountDownLatch latch = new CountDownLatch(1);
        final AtomicReference<Exception> error = new AtomicReference<>();

        new Handler(Looper.getMainLooper()).post(() -> {
            try {
                initializeSdk();
            } catch (Exception e) {
                error.set(e);
            } finally {
                latch.countDown();
            }
        });

        try {
            // Wait for main thread initialization to complete (max 5 seconds)
            if (!latch.await(5, TimeUnit.SECONDS)) {
                throw new RuntimeException("SDK initialization timed out");
            }

            if (error.get() != null) {
                throw new RuntimeException("SDK initialization failed", error.get());
            }
        } catch (InterruptedException e) {
            throw new RuntimeException("SDK initialization interrupted", e);
        }
    } else {
        // Already on main thread, initialize directly
        initializeSdk();
    }
}
```

### Pattern 4: Builder Pattern

**Used in**: RfidTag, RfidConfiguration, RfidInventoryStats, RfidGeigerStats

**Purpose**: Flexible object construction

```java
public class RfidTag {
    private final String epc;
    private final double rssi;
    private final int count;

    private RfidTag(Builder builder) {
        this.epc = builder.epc;
        this.rssi = builder.rssi;
        this.count = builder.count;
    }

    public static class Builder {
        private final String epc;
        private double rssi = 0.0;
        private int count = 0;

        public Builder(String epc) {
            this.epc = epc;
        }

        public Builder rssi(double rssi) {
            this.rssi = rssi;
            return this;
        }

        public Builder count(int count) {
            this.count = count;
            return this;
        }

        public RfidTag build() {
            return new RfidTag(this);
        }
    }
}

// Usage
RfidTag tag = new RfidTag.Builder("E28011700000020EA9E44444")
    .rssi(-50.0)
    .count(5)
    .build();
```

---

## Integration Guide

### Step 1: Add Dependency

Add the SDK module to your `build.gradle`:

```gradle
dependencies {
    implementation project(':csl-rfid-android-sdk')
}
```

### Step 2: Add Permissions

Add required permissions to your `AndroidManifest.xml`:

```xml
<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Location (required for BLE scanning) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Step 3: Create RfidManager

Create a singleton instance in your Application class:

```java
public class MyApplication extends Application {
    private RfidManager rfidManager;

    @Override
    public void onCreate() {
        super.onCreate();
        rfidManager = RfidManager.create(this);
    }

    public RfidManager getRfidManager() {
        return rfidManager;
    }
}
```

### Step 4: Use in ViewModel

Access RfidManager in your ViewModel:

```java
public class InventoryViewModel extends AndroidViewModel {
    private final RfidManager rfidManager;
    private final MutableLiveData<List<RfidTag>> tags = new MutableLiveData<>();

    public InventoryViewModel(Application app) {
        super(app);
        this.rfidManager = ((MyApplication) app).getRfidManager();
    }

    public void startInventory() {
        rfidManager.startInventory(new RfidInventoryCallback() {
            @Override
            public void onTagRead(RfidTag tag) {
                // Update LiveData
                List<RfidTag> currentTags = tags.getValue();
                currentTags.add(tag);
                tags.setValue(currentTags);
            }

            @Override
            public void onInventoryRound(RfidInventoryStats stats) {
                // Update stats
            }

            @Override
            public void onInventoryStopped(RfidStopReason reason) {
                // Handle stop
            }

            @Override
            public void onInventoryError(RfidError error) {
                // Handle error
            }
        });
    }

    @Override
    protected void onCleared() {
        rfidManager.stopInventory();
    }
}
```

### Step 5: Observe in Activity

Observe LiveData in your Activity:

```java
public class InventoryActivity extends AppCompatActivity {
    private InventoryViewModel viewModel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_inventory);

        viewModel = new ViewModelProvider(this).get(InventoryViewModel.class);

        viewModel.getTags().observe(this, tags -> {
            // Update UI with tags
        });
    }
}
```

---

## Build Requirements

- **Java 17 or higher**
- **Android Studio Giraffe or newer**
- **Android SDK API 26+** (Android 8.0+)
- **Gradle 8.13.0**

### Build Commands

```bash
# Build SDK wrapper
./gradlew :csl-rfid-android-sdk:build

# Build AAR
./gradlew :csl-rfid-android-sdk:assembleRelease

# Run tests
./gradlew :csl-rfid-android-sdk:test
```

---

## Key Implementation Decisions

### 1. Lazy SDK Initialization

**Why**: CsLibrary4A must be created on main thread

**How**: `ensureInitialized()` creates SDK on first use with main thread guarantee

**Benefit**: No crash from background thread creation, RfidManager can be created anywhere

### 2. RSSI Negation

**Why**: SDK returns positive RSSI when dBm mode is enabled

**How**: `double rssi = -Math.abs(tagData.decodedRssi)`

**Benefit**: Proper dBm display (negative values like -50 dBm)

### 3. Region Skipping

**Why**: `setCountryInList()` expects dynamic index, not enum ordinal

**How**: Skip region setting, use reader hardware default

**Benefit**: No ArrayIndexOutOfBoundsException, uses correct hardware region

### 4. Thread Manager Shutdown Check

**Why**: Prevent RejectedExecutionException after release

**How**: Check `isShutdown()` before submitting tasks

**Benefit**: Clean shutdown, no crashes

### 5. Polling with Small Delay

**Why**: Reduce CPU usage while maintaining responsiveness

**How**: `Thread.sleep(10)` in polling loops

**Benefit**: Efficient polling without busy-waiting

### 6. Reader Initialization Wait

**Why**: Reader needs time to initialize after BLE connection (battery data availability)

**How**: `waitForReaderReady()` polls battery every 200ms for up to 15s

**Benefit**: Ensures reader is fully operational before allowing operations

---

## Advanced Features

### Battery Monitoring

Monitor reader battery level with automatic 5-second polling:

```java
rfidManager.startBatteryMonitoring(new BatteryCallback() {
    @Override
    public void onBatteryUpdate(BatteryInfo batteryInfo) {
        // Battery info updated every 5 seconds
        int level = batteryInfo.getLevel();  // 0-100%
        boolean charging = batteryInfo.isCharging();

        Log.d("Battery", "Level: " + level + "%, Charging: " + charging);
    }

    @Override
    public void onBatteryError(RfidError error) {
        Log.e("Battery", "Error: " + error.getMessage());
    }
});

// Stop monitoring when done
rfidManager.stopBatteryMonitoring();
```

**Note**: Battery monitoring is independent and does not interfere with RFID operations.

### Barcode Scanning

Scan 1D/2D barcodes using the reader's built-in barcode scanner:

```java
rfidManager.startBarcodeScan(new BarcodeScanCallback() {
    @Override
    public void onBarcodeScanned(BarcodeData data) {
        // New barcode scanned
        String barcode = data.getBarcode();
        Log.d("Barcode", "Scanned: " + barcode);
    }

    @Override
    public void onStatisticsUpdate(BarcodeStats stats) {
        // Statistics updated
        Log.d("Barcode", "Total: " + stats.getTotalScans() +
              ", Unique: " + stats.getUniqueBarcodes());
    }

    @Override
    public void onScanError(RfidError error) {
        Log.e("Barcode", "Error: " + error.getMessage());
    }
});

// Stop scanning when done
rfidManager.stopBarcodeScan();
```

### Trigger Key Support

Use the hardware trigger button to control operations:

**Manual Mode** (recommended - app handles button clicks):

```java
rfidManager.enableTrigger(new TriggerCallback() {
    @Override
    public void onTriggerStateChanged(boolean pressed) {
        runOnUiThread(() -> {
            if (pressed) {
                // Trigger pressed - simulate "Start" button click
                if (btnInventory.getText().equals("Start Inventory")) {
                    btnInventory.performClick();
                }
            } else {
                // Trigger released - simulate "Stop" button click
                if (btnInventory.getText().equals("Stop Inventory")) {
                    btnInventory.performClick();
                }
            }
        });
    }
}, false); // false = manual mode

// Disable when done
rfidManager.disableTrigger();
```

**Auto Mode** (SDK controls inventory directly):

```java
// In auto mode, SDK starts/stops inventory automatically
rfidManager.enableTrigger(new TriggerCallback() {
    @Override
    public void onTriggerStateChanged(boolean pressed) {
        // Optional: Update UI to reflect trigger state
        if (pressed) {
            btnInventory.setText("Stop Inventory");
        } else {
            btnInventory.setText("Start Inventory");
        }
    }
}, true); // true = auto mode
```

**Key Points**:
- Manual mode: App controls what happens on trigger press/release
- Auto mode: SDK automatically starts/stops inventory
- Trigger callback must be registered on main thread (SDK requirement)
- State-based logic prevents spurious actions (check button text before clicking)

### Enhanced Connection Flow

The enhanced connection flow includes reader initialization:

```java
rfidManager.connect(reader, new RfidConnectionCallback() {
    @Override
    public void onConnecting() {
        // Show "Connecting..." UI
        showLoadingOverlay("Connecting to reader...");
    }

    @Override
    public void onConnected(RfidReader reader) {
        // BLE connected, waiting for reader initialization
        updateLoadingMessage("Initializing reader...");
    }

    @Override
    public void onReaderReady(RfidReader reader) {
        // Reader fully initialized (battery data available)
        hideLoadingOverlay();
        Toast.makeText(this, "Reader ready!", Toast.LENGTH_SHORT).show();

        // Safe to start operations now
        navigateToInventoryScreen();
    }

    @Override
    public void onConnectionFailed(RfidError error) {
        hideLoadingOverlay();
        Toast.makeText(this, "Connection failed: " + error.getMessage(),
                      Toast.LENGTH_LONG).show();
    }

    @Override
    public void onDisconnected(RfidReader reader, RfidError error) {
        if (error != null) {
            Toast.makeText(this, "Connection lost: " + error.getMessage(),
                          Toast.LENGTH_LONG).show();
        }
    }
});
```

**Connection States**:
1. **DISCONNECTED** - No connection
2. **CONNECTING** - BLE connection in progress (onConnecting)
3. **CONNECTED** - BLE connected (onConnected)
4. **INITIALIZING** - Waiting for battery data (up to 15s)
5. **READY** - Fully operational (onReaderReady)

**Timeouts**:
- BLE connection: 20 seconds
- Reader initialization: 15 seconds
- Total connection time: Up to 35 seconds

---

## Conclusion

The **csl-rfid-android-sdk** module provides a production-ready, clean API for CSL CS710S RFID operations on Android. Key features:

✅ **Clean Architecture**: Well-organized packages and clear responsibilities
✅ **Thread Safety**: Proper background/main thread management
✅ **Error Handling**: Comprehensive error reporting via callbacks
✅ **Modern Android**: MVVM-compatible, LiveData-friendly
✅ **Complete Features**: RFID inventory, Geiger search, barcode scanning, battery monitoring, trigger support
✅ **Advanced Operations**: Reader initialization, hardware trigger integration
✅ **Production Quality**: Tested, documented, and ready for integration

**Status**: ✅ **PRODUCTION READY**

---

**Document Version**: 2.0.0
**Last Updated**: January 2025
**Total Lines of Code**: ~3,300 lines
**Total Files**: 28 files (8 callbacks, 5 managers, 10 models, 5 other)
