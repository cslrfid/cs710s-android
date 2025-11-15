# CS710S SDK (cslibrary4a) Usage Guide

This document provides detailed workflow and API documentation for the cslibrary4a SDK layer for performing reader discovery, connectivity, configuration, and RFID tag inventory operations.

## Table of Contents

1. [Reader Discovery and Connectivity](#1-reader-discovery-and-connectivity)
2. [Post-Connection Configuration](#2-post-connection-configuration)
3. [Start Inventory and Receive RFID Tag Data Asynchronously](#3-start-inventory-and-receive-rfid-tag-data-asynchronously)
4. [Complete Workflow Example](#complete-workflow-example)
5. [Important Notes](#important-notes)

---

## 1. Reader Discovery and Connectivity

### Step 1: Initialize the SDK

Create an SDK instance based on your device type (CS710 or CS108):

```java
// Create SDK instance (choose CS710 or CS108 based on your device)
Context context = getApplicationContext();
TextView logView = findViewById(R.id.log_view); // Optional for logging
Cs710Library4A csLibrary4A = new Cs710Library4A(context, logView);
```

**SDK Files**:
- `Cs710Library4A.java` - Main SDK entry point for CS710S readers
- `Cs108Library4A.java` - Main SDK entry point for CS108 readers
- `CsLibrary4A.java` - Unified interface that wraps both

### Step 2: Start BLE Scanning

```java
// Start scanning for nearby CS710S readers
boolean success = csLibrary4A.scanLeDevice(true);
```

**Location**: `Cs710Library4A.java:308` → `BluetoothGatt.java:574`

**What happens internally**:
- Uses Android BLE scanner (`BluetoothLeScanner`) for SDK 21+
- Filters devices with service UUID `0x9802` (CS710) or `0x9800` (CS108)
- Scan callbacks are handled in `CsReaderConnector.onScanResult()`
- Discovered devices are added to an internal queue

### Step 3: Poll for Discovered Devices

Continuously poll for newly scanned devices in your UI thread or with a Handler:

```java
// Poll for newly scanned devices
BluetoothGatt.CsScanData csScanData = csLibrary4A.getNewDeviceScanned();
if (csScanData != null) {
    String deviceName = csScanData.getName();
    String deviceAddress = csScanData.device.getAddress();
    int rssi = csScanData.rssi;

    // Add to your device list
    ReaderDevice readerDevice = new ReaderDevice(
        deviceName,
        deviceAddress,
        false,  // not connected yet
        "",     // details
        rssi,
        csScanData.serviceUUID2p2
    );

    // Add to your UI list
    deviceList.add(readerDevice);
}
```

**Location**: `Cs710Library4A.java:319` → `CsReaderConnector.java:536`

**CsScanData Structure**:
```java
public class CsScanData {
    public BluetoothDevice device;      // Android BLE device
    public int rssi;                    // Signal strength
    public byte[] scanRecord;           // Raw scan record
    public int serviceUUID2p2;          // Service UUID identifier
    public String getName();            // Device name
}
```

### Step 4: Stop Scanning

```java
csLibrary4A.scanLeDevice(false);
```

### Step 5: Connect to Reader

```java
// Connect to a specific reader device
boolean connected = csLibrary4A.connect(readerDevice);

// Wait for connection to establish (poll in a background thread)
int waitTime = 40; // 20 seconds maximum wait
while (!csLibrary4A.isBleConnected() && waitTime > 0) {
    Thread.sleep(500);
    waitTime--;
}

if (csLibrary4A.isBleConnected()) {
    // Connection successful
    Log.i(TAG, "Connected to " + readerDevice.getName());
} else {
    // Connection failed
    Log.e(TAG, "Failed to connect to " + readerDevice.getName());
}
```

**Location**: `Cs710Library4A.java:318` → `CsReaderConnector.java:33` → `BluetoothGatt.java:754`

**Connection Flow**:
1. `BluetoothGatt.connect()` - Initiates GATT connection to the BLE device
2. `onConnectionStateChange()` callback - Notified when connection state changes
3. `discoverServices()` - Discovers available BLE services and characteristics
4. `onServicesDiscovered()` callback - Services and characteristics discovered
5. `setCharacteristicNotification()` - Enables notifications for the data stream characteristic
6. Connection is ready when `isConnected()` returns `true`

**BLE Characteristics**:
- Stream Out: `00009900-0000-1000-8000-00805f9b34fb` (write commands to reader)
- Stream In: `00009901-0000-1000-8000-00805f9b34fb` (receive data from reader)

**Example from demo app**: `ConnectionFragment.java:321-350`

### Step 6: Disconnect from Reader

```java
// Disconnect and cleanup
csLibrary4A.disconnect(false);
```

**Parameters**:
- `false` - Normal disconnect
- `true` - Force disconnect (if reader is unresponsive)

---

## 2. Post-Connection Configuration

After connection is established, configure the reader settings before starting inventory operations.

### 2.1 Power Level

Set the antenna transmit power:

```java
// Set antenna power (0-320, representing 0.0-32.0 dBm)
csLibrary4A.setSelectedPowerLevel(300); // 30.0 dBm

// Get current power level
long powerLevel = csLibrary4A.getSelectedPowerLevel();
```

**Valid Range**: 0-320 (each unit = 0.1 dBm)
- Typical range: 180-320 (18.0-32.0 dBm)
- Default maximum: 320 (32.0 dBm)

### 2.2 Antenna Port Selection

For multi-port readers:

```java
// Set active antenna port (0-based index)
csLibrary4A.setSelectedLinkProfile(0); // Port 0

// Get current port
long currentPort = csLibrary4A.getSelectedLinkProfile();
```

### 2.3 Inventory Algorithm Settings

```java
// Set inventory algorithm
// 0 = Fixed Q, 1 = Dynamic Q
csLibrary4A.setInvAlgo(0);

// Set Q value (0-15) for Fixed Q algorithm
// Higher Q = better for many tags, Lower Q = better for few tags
csLibrary4A.setQValue(7);

// Get current settings
long invAlgo = csLibrary4A.getInvAlgo();
long qValue = csLibrary4A.getQValue();
```

**Q Value Guidelines**:
- Q=4-6: Few tags (1-10)
- Q=7-10: Medium density (10-100 tags)
- Q=11-15: High density (100+ tags)

### 2.4 Session and Target Settings

```java
// Set session (0-3)
csLibrary4A.setSessionTarget(1); // Session 1

// Set target flag (0 = A, 1 = B, 2 = Toggle A/B)
csLibrary4A.setTarget(0); // Target A

// Get current settings
long session = csLibrary4A.getSessionTarget();
long target = csLibrary4A.getTarget();
```

**Session Guidelines**:
- Session 0: No persistence (fastest, may read duplicates)
- Session 1: Short persistence (~500ms)
- Session 2: Medium persistence (~2s)
- Session 3: Long persistence (until power off)

### 2.5 Tag Select/Filter Configuration

Filter tags based on memory bank content:

```java
// Enable tag filtering
csLibrary4A.setSelectEnable(true);

// Set memory bank to filter
// 0=Reserved, 1=EPC, 2=TID, 3=User, 4=EPC+TID
csLibrary4A.setSelectTarget(1); // EPC bank

// Set bit offset in the memory bank
csLibrary4A.setSelectOffset(32); // Start at bit 32 (after PC and CRC)

// Set mask data to match (hexadecimal string)
csLibrary4A.setSelectMaskData("E200"); // Match tags starting with E200

// Set mask length in bits (optional, calculated from mask data if not set)
csLibrary4A.setSelectMaskLength(16); // 16 bits = 4 hex chars

// Disable filtering
csLibrary4A.setSelectEnable(false);
```

**Example Use Cases**:
- Filter by manufacturer: Match TID bank (bank 2)
- Filter by product type: Match EPC prefix
- Filter by user data: Match User bank (bank 3)

### 2.6 Region and Frequency Settings

```java
// Set regulatory region
csLibrary4A.setCurrentRegionCode(RfidReader.RegionCodes.FCC); // North America
// Other options: ETSI (Europe), CHN (China), JPN (Japan), etc.

// Get available channels for current region
int channelCount = csLibrary4A.getChannelCount();

// Set specific channel (0 to channelCount-1)
csLibrary4A.setChannel(0); // Use channel 0

// Enable frequency hopping (use all channels)
csLibrary4A.setChannel(-1); // -1 = frequency hopping enabled
```

**Common Regions**:
- `RegionCodes.FCC` - North America (902-928 MHz)
- `RegionCodes.ETSI` - Europe (865-868 MHz)
- `RegionCodes.CHN` - China (920-925 MHz)
- `RegionCodes.JPN` - Japan (916-921 MHz)

### 2.7 Inventory Mode

```java
// Set inventory mode to compact for higher performance (E710 chip only)
csLibrary4A.setInvModeCompact(true); // Compact mode (recommended for CS710S)

// Standard mode (compatible with both chips)
csLibrary4A.setInvModeCompact(false);
```

**Compact Mode Benefits**:
- Higher tag read rates
- Lower bandwidth usage
- Optimized for E710 RFID chip (CS710S)

### 2.8 Extra Data Bank Reading

Read additional memory banks along with EPC:

```java
// Read TID bank along with EPC
csLibrary4A.setExtraDataBank(
    2,     // bank1: TID bank
    0,     // offset1: start at word 0
    2,     // count1: read 2 words (4 bytes)
    -1,    // bank2: disabled
    0,     // offset2: N/A
    0      // count2: N/A
);

// Read both TID and User bank
csLibrary4A.setExtraDataBank(
    2,     // bank1: TID bank
    0,     // offset1: start at word 0
    2,     // count1: read 2 words
    3,     // bank2: User bank
    0,     // offset2: start at word 0
    4      // count2: read 4 words
);

// Disable extra data reading
csLibrary4A.setExtraDataBank(-1, 0, 0, -1, 0, 0);
```

**Memory Banks**:
- Bank 0: Reserved (kill/access passwords)
- Bank 1: EPC (automatically read)
- Bank 2: TID (tag identifier, manufacturer info)
- Bank 3: User (application-specific data)

### 2.9 Sound and Vibration Settings

```java
// Enable beep on tag read
csLibrary4A.setInventoryBeep(true);

// Enable vibration on tag read
csLibrary4A.setInventoryVibrate(true);

// Set vibration mode
// 0 = vibrate on each new tag
// 1 = continuous vibration during inventory
csLibrary4A.setVibrateModeSetting(1);

// Set vibration duration (milliseconds)
csLibrary4A.setVibrateWindow(100);

// Get current settings
boolean beepEnabled = csLibrary4A.getInventoryBeep();
boolean vibrateEnabled = csLibrary4A.getInventoryVibrate();
```

### 2.10 Other Useful Settings

```java
// Set tag focus (for searching specific tag)
csLibrary4A.setTagFocus(true);

// Set inventory duration (milliseconds, 0 = continuous)
csLibrary4A.setInventoryDuration(0); // Continuous until stopped

// Set duplicate elimination time window (milliseconds)
csLibrary4A.setDuplicateEliminationTime(1000); // 1 second

// Enable tag delay (for better tag reads)
csLibrary4A.setTagDelay(30); // 30ms delay

// Enable fast ID mode (EPC only, no CRC)
csLibrary4A.setFastId(false); // Disable for complete data
```

### Configuration Best Practices

1. **Set power level first** - Affects tag read range
2. **Configure region** - Must comply with local regulations
3. **Set session and target** - Based on your use case (static vs. moving tags)
4. **Enable compact mode** - For CS710S readers (better performance)
5. **Configure filters** - Only if you need to filter specific tags
6. **Set extra banks** - Only if you need TID or User data (reduces read rate)

**Note**: All configuration commands are queued in `mRfidToWrite` and sent asynchronously to the reader. Changes take effect before the next inventory operation starts.

---

## 3. Start Inventory and Receive RFID Tag Data Asynchronously

### Step 1: Start Inventory Operation

```java
// Start continuous inventory (compact mode - recommended for CS710S)
boolean success = csLibrary4A.startOperation(
    RfidReaderChipData.OperationTypes.TAG_INVENTORY_COMPACT
);

// Alternative: Standard inventory mode (compatible with CS108 and CS710S)
boolean success = csLibrary4A.startOperation(
    RfidReaderChipData.OperationTypes.TAG_INVENTORY
);
```

**Location**: `Cs710Library4A.java:849` → `RfidReader.java:3489`

**What happens internally**:
1. Inventory start command is queued to `mRx000ToWrite`
2. Command flows through: `mRx000ToWrite` → `mRfidToWrite` → BLE characteristic write
3. Reader receives command and begins scanning for RFID tags
4. Tag data streams back via BLE notifications
5. Data is parsed and added to `mRx000ToRead` queue

**Operation Types**:
```java
public enum OperationTypes {
    TAG_INVENTORY,              // Standard inventory
    TAG_INVENTORY_COMPACT,      // Compact inventory (E710 only, faster)
    TAG_SEARCHING,              // Search for specific tag
    TAG_RANGING,                // Tag ranging/location
    TAG_READ,                   // Read tag memory
    TAG_WRITE,                  // Write tag memory
    TAG_LOCK,                   // Lock tag memory
    TAG_KILL,                   // Kill (disable) tag
    // ... other operations
}
```

### Step 2: Receive Tag Data Asynchronously (Polling Method)

Tag data must be retrieved in a background thread to avoid blocking the UI thread. Use AsyncTask, Thread, Handler, or Kotlin Coroutines.

**Example using background thread**:

```java
// Run in AsyncTask, Thread, or similar background mechanism
while (csLibrary4A.isBleConnected() && !cancelled) {
    // Poll for RFID event data from the queue
    RfidReaderChipData.Rx000pkgData tagData = csLibrary4A.onRFIDEvent();

    if (tagData != null && csLibrary4A.mrfidToWriteSize() == 0) {
        // Process based on response type
        switch (tagData.responseType) {
            case TYPE_18K6C_INVENTORY:
            case TYPE_18K6C_INVENTORY_COMPACT:
                // New tag data received
                if (tagData.decodedError == null) {
                    // Successfully read tag
                    String epc = csLibrary4A.byteArrayToString(tagData.decodedEpc);
                    String pc = csLibrary4A.byteArrayToString(tagData.decodedPc);
                    String crc = csLibrary4A.byteArrayToString(tagData.decodedCrc);
                    double rssi = tagData.decodedRssi;
                    int phase = tagData.decodedPhase;
                    int channel = tagData.decodedChidx;
                    int port = tagData.decodedPort;
                    long timestamp = tagData.decodedTime;

                    // Optional extra data (if configured via setExtraDataBank)
                    byte[] tidData = tagData.decodedData1;  // TID or bank 1 data
                    byte[] userData = tagData.decodedData2; // User or bank 2 data

                    // Process tag (add to list, update UI, etc.)
                    processTag(epc, rssi, timestamp, tidData, userData);

                } else {
                    // Tag read error occurred
                    Log.e(TAG, "Tag read error: " + tagData.decodedError);
                }
                break;

            case TYPE_ANTENNA_CYCLE_END:
                // Antenna cycle completed (for multi-port readers)
                // Useful for tracking when all antennas have been scanned
                Log.d(TAG, "Antenna cycle completed");
                break;

            case TYPE_COMMAND_END:
                // Inventory operation ended (normal or error)
                if (tagData.decodedError != null) {
                    Log.w(TAG, "Inventory ended with error: " + tagData.decodedError);
                } else {
                    Log.i(TAG, "Inventory completed successfully");
                }
                break;

            case TYPE_COMMAND_ABORT_RETURN:
                // Operation was aborted (user requested stop)
                Log.i(TAG, "Inventory operation aborted");
                break;

            default:
                // Other response types (access, write, etc.)
                Log.d(TAG, "Received response type: " + tagData.responseType);
                break;
        }
    }

    // Small sleep to avoid busy-waiting and reduce CPU usage
    Thread.sleep(50);
}
```

**Location**: Example implementation in `InventoryRfidTask.java:124-227`

### Understanding the Data Flow

The tag data goes through multiple processing layers before reaching your application:

```
RFID Reader (CS710S)
    ↓
BLE Notification (raw bytes)
    ↓
BluetoothGatt.onCharacteristicChanged()
    ↓
streamInBuffer (circular buffer)
    ↓
CsReaderConnector.processStreamInData() (packet parsing)
    ↓
RfidConnector (RFID protocol layer)
    ↓
RfidReaderChipE710.decode710Data() (decode tag data)
    ↓
mRx000ToRead queue (parsed tag data)
    ↓
csLibrary4A.onRFIDEvent() (your application)
```

**Key Classes**:
- `BluetoothGatt.java:271-450` - BLE characteristic change handler
- `CsReaderConnector.java:132-500` - Stream data processing
- `RfidConnector.java:44-46` - RFID data queues
- `RfidReaderChipE710.java:2805-3100` - E710 chip data decoding
- `Cs710Library4A.java:539-547` - Public API for retrieving events

### Step 3: Stop Inventory

Stop the inventory operation gracefully:

```java
// Request abort
csLibrary4A.abortOperation();

// Wait for acknowledgment (optional but recommended)
boolean aborted = false;
int timeout = 20; // 10 seconds timeout
while (!aborted && timeout > 0) {
    RfidReaderChipData.Rx000pkgData data = csLibrary4A.onRFIDEvent();
    if (data != null) {
        if (data.responseType == RfidReaderChipData.HostCmdResponseTypes.TYPE_COMMAND_END ||
            data.responseType == RfidReaderChipData.HostCmdResponseTypes.TYPE_COMMAND_ABORT_RETURN) {
            aborted = true;
            Log.i(TAG, "Inventory stopped successfully");
            break;
        }
    }
    Thread.sleep(500);
    timeout--;
}

if (!aborted) {
    Log.w(TAG, "Inventory stop timeout - reader may still be scanning");
}
```

### Key Data Structure - Rx000pkgData

Complete structure of tag data returned by `onRFIDEvent()`:

```java
public class Rx000pkgData {
    // Response type identifier
    public HostCmdResponseTypes responseType;

    // Tag data (for inventory responses)
    public byte[] decodedEpc;           // EPC data (tag ID)
    public byte[] decodedPc;            // Protocol Control word
    public byte[] decodedCrc;           // CRC checksum
    public byte[] decodedData1;         // Extra bank 1 data (e.g., TID)
    public byte[] decodedData2;         // Extra bank 2 data (e.g., User)

    // Tag metadata
    public double decodedRssi;          // Signal strength (dBm)
    public int decodedPhase;            // Phase value
    public int decodedChidx;            // Channel index/frequency
    public int decodedPort;             // Antenna port number
    public long decodedTime;            // Timestamp (milliseconds)

    // Error handling
    public String decodedError;         // Error message if read failed

    // Additional metadata
    public int decodedPcEpcLength;      // EPC length from PC word
    public boolean decodedPcToggle;     // Toggle bit from PC word

    // Access operation results (for read/write operations)
    public byte[] decodedAccessData;    // Data from access operations
    public int decodedAccessError;      // Access error code
}
```

**Common Response Types**:
```java
public enum HostCmdResponseTypes {
    TYPE_18K6C_INVENTORY,              // Standard inventory response
    TYPE_18K6C_INVENTORY_COMPACT,      // Compact inventory response
    TYPE_ANTENNA_CYCLE_END,            // Antenna cycle completed
    TYPE_COMMAND_END,                  // Operation completed
    TYPE_COMMAND_ABORT_RETURN,         // Operation aborted
    TYPE_18K6C_READ,                   // Tag read response
    TYPE_18K6C_WRITE,                  // Tag write response
    TYPE_18K6C_LOCK,                   // Tag lock response
    TYPE_18K6C_KILL,                   // Tag kill response
    // ... additional types
}
```

### Processing Tag Data - Complete Example

```java
private void processTag(String epc, double rssi, long timestamp,
                       byte[] tidData, byte[] userData) {
    // Check if tag already exists in list
    ReaderDevice existingTag = findTagByEpc(epc);

    if (existingTag != null) {
        // Tag already seen - update count and RSSI
        existingTag.setCount(existingTag.getCount() + 1);
        existingTag.setRssi((int) rssi);
        existingTag.setTimestamp(timestamp);
    } else {
        // New tag - add to list
        ReaderDevice newTag = new ReaderDevice(
            epc,                                    // Name/EPC
            epc,                                    // Address/EPC
            false,                                  // Not connected
            formatTagDetails(rssi, tidData),        // Details
            (int) rssi,                             // RSSI
            0                                       // Service UUID
        );
        newTag.setCount(1);
        newTag.setTimestamp(timestamp);

        // Add TID if available
        if (tidData != null && tidData.length > 0) {
            String tid = csLibrary4A.byteArrayToString(tidData);
            newTag.setTid(tid);
        }

        // Add User data if available
        if (userData != null && userData.length > 0) {
            String user = csLibrary4A.byteArrayToString(userData);
            newTag.setUserData(user);
        }

        tagsList.add(newTag);

        // Trigger sound/vibration for new tag
        if (beepEnabled) {
            playBeep();
        }
        if (vibrateEnabled) {
            vibrate(100);
        }
    }

    // Update UI on main thread
    publishProgress("TAG_FOUND");
}

private String formatTagDetails(double rssi, byte[] tidData) {
    StringBuilder details = new StringBuilder();
    details.append(String.format("RSSI: %.1f dBm", rssi));

    if (tidData != null && tidData.length >= 4) {
        // Extract manufacturer info from TID
        String tid = csLibrary4A.byteArrayToString(tidData);
        String mdid = tid.substring(0, Math.min(4, tid.length()));
        details.append("\nMfg: ").append(getManufacturerName(mdid));
    }

    return details.toString();
}

private ReaderDevice findTagByEpc(String epc) {
    for (ReaderDevice tag : tagsList) {
        if (tag.getAddress().equals(epc)) {
            return tag;
        }
    }
    return null;
}
```

### Complete AsyncTask Example

Full implementation based on `InventoryRfidTask.java`:

```java
public class InventoryRfidTask extends AsyncTask<Void, String, String> {
    private Context context;
    private ArrayList<ReaderDevice> tagsList;
    private boolean cancelled = false;

    public InventoryRfidTask(Context context, ArrayList<ReaderDevice> tagsList) {
        this.context = context;
        this.tagsList = tagsList;
    }

    @Override
    protected void onPreExecute() {
        // Setup before starting
        tagsList.clear();

        // Start inventory operation
        MainActivity.csLibrary4A.startOperation(
            RfidReaderChipData.OperationTypes.TAG_INVENTORY_COMPACT
        );
    }

    @Override
    protected String doInBackground(Void... params) {
        // Clear any pending events
        while (MainActivity.csLibrary4A.onRFIDEvent() != null) { }

        boolean inventoryRunning = true;

        while (MainActivity.csLibrary4A.isBleConnected() &&
               !isCancelled() &&
               inventoryRunning) {

            // Poll for tag data
            RfidReaderChipData.Rx000pkgData tagData =
                MainActivity.csLibrary4A.onRFIDEvent();

            if (tagData != null &&
                MainActivity.csLibrary4A.mrfidToWriteSize() == 0) {

                switch (tagData.responseType) {
                    case TYPE_18K6C_INVENTORY_COMPACT:
                        if (tagData.decodedError == null) {
                            String epc = MainActivity.csLibrary4A
                                .byteArrayToString(tagData.decodedEpc);
                            publishProgress("TAG", epc,
                                String.valueOf(tagData.decodedRssi));
                        } else {
                            publishProgress("ERROR", tagData.decodedError);
                        }
                        break;

                    case TYPE_COMMAND_END:
                    case TYPE_COMMAND_ABORT_RETURN:
                        inventoryRunning = false;
                        break;
                }
            }

            try {
                Thread.sleep(50);
            } catch (InterruptedException e) {
                break;
            }
        }

        return "Inventory completed. Tags found: " + tagsList.size();
    }

    @Override
    protected void onProgressUpdate(String... values) {
        if (values[0].equals("TAG")) {
            String epc = values[1];
            double rssi = Double.parseDouble(values[2]);

            // Update tag list
            ReaderDevice tag = findOrCreateTag(epc);
            tag.setRssi((int) rssi);
            tag.setCount(tag.getCount() + 1);

            // Update UI
            notifyDataSetChanged();
        } else if (values[0].equals("ERROR")) {
            Toast.makeText(context, values[1], Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    protected void onPostExecute(String result) {
        // Cleanup
        Log.i(TAG, result);
    }

    @Override
    protected void onCancelled() {
        // Stop inventory
        MainActivity.csLibrary4A.abortOperation();
    }

    private ReaderDevice findOrCreateTag(String epc) {
        for (ReaderDevice tag : tagsList) {
            if (tag.getAddress().equals(epc)) {
                return tag;
            }
        }

        ReaderDevice newTag = new ReaderDevice(epc, epc, false, "", 0, 0);
        newTag.setCount(0);
        tagsList.add(newTag);
        return newTag;
    }
}
```

**Usage**:
```java
// Start inventory
InventoryRfidTask task = new InventoryRfidTask(context, tagsList);
task.execute();

// Stop inventory
task.cancel(true);
```

---

## Complete Workflow Example

This example demonstrates the complete workflow from initialization to tag reading:

```java
public class RfidManager {
    private Cs710Library4A csLibrary4A;
    private Context context;
    private ArrayList<ReaderDevice> discoveredDevices = new ArrayList<>();
    private ArrayList<ReaderDevice> tagsList = new ArrayList<>();
    private Handler handler = new Handler();

    // Initialize SDK
    public void initialize(Context context) {
        this.context = context;
        csLibrary4A = new Cs710Library4A(context, null);
    }

    // Step 1: Scan for readers
    public void startScan() {
        discoveredDevices.clear();
        csLibrary4A.scanLeDevice(true);

        // Poll for devices
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                BluetoothGatt.CsScanData device = csLibrary4A.getNewDeviceScanned();
                if (device != null) {
                    ReaderDevice readerDevice = new ReaderDevice(
                        device.getName(),
                        device.device.getAddress(),
                        false,
                        "RSSI: " + device.rssi,
                        device.rssi,
                        device.serviceUUID2p2
                    );
                    discoveredDevices.add(readerDevice);
                    onDeviceDiscovered(readerDevice);
                }

                // Continue polling if scanning
                if (csLibrary4A.isScanning()) {
                    handler.postDelayed(this, 100);
                }
            }
        }, 100);
    }

    public void stopScan() {
        csLibrary4A.scanLeDevice(false);
        handler.removeCallbacksAndMessages(null);
    }

    // Step 2: Connect to reader
    public boolean connect(ReaderDevice device) {
        boolean result = csLibrary4A.connect(device);

        if (result) {
            // Wait for connection
            new Thread(() -> {
                int timeout = 40; // 20 seconds
                while (!csLibrary4A.isBleConnected() && timeout > 0) {
                    try {
                        Thread.sleep(500);
                        timeout--;
                    } catch (InterruptedException e) {
                        break;
                    }
                }

                if (csLibrary4A.isBleConnected()) {
                    onConnected();
                } else {
                    onConnectionFailed();
                }
            }).start();
        }

        return result;
    }

    // Step 3: Configure reader
    private void configureReader() {
        // Power settings
        csLibrary4A.setSelectedPowerLevel(300); // 30.0 dBm

        // Inventory settings
        csLibrary4A.setInvModeCompact(true);    // Use compact mode
        csLibrary4A.setSessionTarget(1);         // Session 1
        csLibrary4A.setTarget(0);                // Target A
        csLibrary4A.setInvAlgo(0);               // Fixed Q
        csLibrary4A.setQValue(7);                // Q = 7

        // Region
        csLibrary4A.setCurrentRegionCode(RfidReader.RegionCodes.FCC);

        // Extra data (read TID)
        csLibrary4A.setExtraDataBank(2, 0, 2, -1, 0, 0);

        // Sound/vibration
        csLibrary4A.setInventoryBeep(true);
        csLibrary4A.setInventoryVibrate(true);

        Log.i("RfidManager", "Reader configured");
    }

    // Step 4: Start inventory
    public void startInventory() {
        tagsList.clear();

        boolean success = csLibrary4A.startOperation(
            RfidReaderChipData.OperationTypes.TAG_INVENTORY_COMPACT
        );

        if (success) {
            // Start background thread to receive tags
            new Thread(() -> {
                while (csLibrary4A.isBleConnected() && isInventoryRunning) {
                    RfidReaderChipData.Rx000pkgData tagData =
                        csLibrary4A.onRFIDEvent();

                    if (tagData != null) {
                        handleTagData(tagData);
                    }

                    try {
                        Thread.sleep(50);
                    } catch (InterruptedException e) {
                        break;
                    }
                }
            }).start();
        }
    }

    // Step 5: Process tag data
    private void handleTagData(RfidReaderChipData.Rx000pkgData tagData) {
        switch (tagData.responseType) {
            case TYPE_18K6C_INVENTORY_COMPACT:
                if (tagData.decodedError == null) {
                    String epc = csLibrary4A.byteArrayToString(tagData.decodedEpc);
                    double rssi = tagData.decodedRssi;
                    String tid = csLibrary4A.byteArrayToString(tagData.decodedData1);

                    onTagFound(epc, rssi, tid);
                }
                break;

            case TYPE_COMMAND_END:
            case TYPE_COMMAND_ABORT_RETURN:
                onInventoryEnded();
                break;
        }
    }

    // Step 6: Stop inventory
    public void stopInventory() {
        isInventoryRunning = false;
        csLibrary4A.abortOperation();
    }

    // Step 7: Disconnect
    public void disconnect() {
        stopInventory();
        csLibrary4A.disconnect(false);
    }

    // Callbacks (implement these in your UI)
    protected void onDeviceDiscovered(ReaderDevice device) { }
    protected void onConnected() { configureReader(); }
    protected void onConnectionFailed() { }
    protected void onTagFound(String epc, double rssi, String tid) { }
    protected void onInventoryEnded() { }

    private volatile boolean isInventoryRunning = false;
}
```

**Usage in Activity/Fragment**:

```java
public class MainActivity extends AppCompatActivity {
    private RfidManager rfidManager;
    private ReaderListAdapter deviceAdapter;
    private TagListAdapter tagAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Initialize
        rfidManager = new RfidManager() {
            @Override
            protected void onDeviceDiscovered(ReaderDevice device) {
                runOnUiThread(() -> {
                    deviceAdapter.add(device);
                    deviceAdapter.notifyDataSetChanged();
                });
            }

            @Override
            protected void onConnected() {
                super.onConnected();
                runOnUiThread(() -> {
                    Toast.makeText(MainActivity.this,
                        "Connected!", Toast.LENGTH_SHORT).show();
                });
            }

            @Override
            protected void onTagFound(String epc, double rssi, String tid) {
                runOnUiThread(() -> {
                    updateTagList(epc, rssi, tid);
                });
            }
        };

        rfidManager.initialize(this);

        // Setup UI
        setupButtons();
    }

    private void setupButtons() {
        findViewById(R.id.btnScan).setOnClickListener(v ->
            rfidManager.startScan());

        findViewById(R.id.btnStopScan).setOnClickListener(v ->
            rfidManager.stopScan());

        findViewById(R.id.btnInventory).setOnClickListener(v ->
            rfidManager.startInventory());

        findViewById(R.id.btnStop).setOnClickListener(v ->
            rfidManager.stopInventory());
    }

    private void updateTagList(String epc, double rssi, String tid) {
        // Update your tag list UI
        tagAdapter.addOrUpdate(epc, rssi, tid);
        tagAdapter.notifyDataSetChanged();
    }

    @Override
    protected void onDestroy() {
        rfidManager.disconnect();
        super.onDestroy();
    }
}
```

---

## Important Notes

### 1. Threading
- All tag data retrieval (`onRFIDEvent()`) **must** be done in a background thread to avoid blocking the UI thread
- Use `AsyncTask`, `Thread`, `Handler`, or Kotlin Coroutines
- Update UI using `runOnUiThread()`, `publishProgress()`, or similar mechanisms

### 2. Queue Management
The SDK uses internal queues for asynchronous command/response handling:

**Write Queues** (commands to reader):
- `mRfidToWrite` - RFID protocol layer commands
- `mRx000ToWrite` - RFID chip-specific commands
- `bluetoothIcToWrite` - Bluetooth IC commands

**Read Queues** (responses from reader):
- `mRfidToRead` - RFID protocol layer responses
- `mRx000ToRead` - Decoded tag data and responses

**Key Points**:
- Commands are processed asynchronously (queued and sent in background)
- Always check `mrfidToWriteSize() == 0` before processing tag data to ensure commands have been sent
- Clear event queues before starting new operations using `while (onRFIDEvent() != null) { }`

### 3. Event-Driven Architecture

Tag data flows through multiple processing layers:

```
Hardware → BLE → Buffer → Parser → Decoder → Queue → Application
```

**Processing Layers**:
1. **BluetoothGatt** - BLE characteristic notifications
2. **CsReaderConnector** - Stream buffer and packet parsing
3. **RfidConnector** - RFID protocol processing
4. **RfidReaderChipE710** - Tag data decoding
5. **Application** - `onRFIDEvent()` retrieval

### 4. Error Handling

Always implement comprehensive error handling:

```java
// Check connection status
if (!csLibrary4A.isBleConnected()) {
    Log.e(TAG, "Reader disconnected");
    return;
}

// Check for RFID failures
if (csLibrary4A.isRfidFailure()) {
    Log.e(TAG, "RFID module failure");
    csLibrary4A.disconnect(false);
    return;
}

// Check tag data for errors
if (tagData.decodedError != null) {
    Log.e(TAG, "Tag read error: " + tagData.decodedError);
}

// Monitor write queue for timeout issues
if (csLibrary4A.mrfidToWriteSize() > 0) {
    // Commands still pending - may indicate communication issue
}
```

### 5. Performance Optimization

**For Best Performance**:
- Use `TAG_INVENTORY_COMPACT` mode with CS710S (E710 chip)
- Set appropriate Q value based on tag density
- Disable extra bank reading unless needed (TID/User data)
- Use Session 0 or 1 for fast-moving tags
- Adjust power level based on read range requirements
- Enable duplicate elimination to reduce redundant reads

**Typical Read Rates**:
- Compact mode: 200-400 tags/second (depending on configuration)
- Standard mode: 100-200 tags/second
- With TID reading: 50-150 tags/second

### 6. Multi-Bank Reading

Reading extra memory banks (TID, User) reduces read rate:

```java
// EPC only (fastest)
csLibrary4A.setExtraDataBank(-1, 0, 0, -1, 0, 0);

// EPC + TID (moderate speed)
csLibrary4A.setExtraDataBank(2, 0, 2, -1, 0, 0);

// EPC + TID + User (slowest)
csLibrary4A.setExtraDataBank(2, 0, 2, 3, 0, 4);
```

**When to use**:
- TID: Verify tag authenticity, identify manufacturer
- User bank: Read application-specific data stored on tag

### 7. Connection Management

**Best Practices**:
- Always call `disconnect()` when done
- Implement reconnection logic for connection drops
- Monitor battery level during inventory: `getBatteryCount()`
- Check `isBleConnected()` before each operation

**Connection States**:
- `STATE_DISCONNECTED` (0) - Not connected
- `STATE_CONNECTING` (1) - Connection in progress
- `STATE_CONNECTED` (2) - Connected and ready
- `STATE_DISCONNECTING` (3) - Disconnection in progress

### 8. Memory Considerations

Tag lists can grow large during extended inventory:

```java
// Periodically clear old tags or implement LRU cache
if (tagsList.size() > MAX_TAGS) {
    tagsList.clear();
}

// Or filter by time
long currentTime = System.currentTimeMillis();
tagsList.removeIf(tag ->
    currentTime - tag.getTimestamp() > TAG_TIMEOUT);
```

### 9. Regulatory Compliance

**Always configure region code** to comply with local regulations:

```java
// North America
csLibrary4A.setCurrentRegionCode(RfidReader.RegionCodes.FCC);

// Europe
csLibrary4A.setCurrentRegionCode(RfidReader.RegionCodes.ETSI);

// China
csLibrary4A.setCurrentRegionCode(RfidReader.RegionCodes.CHN);
```

Using incorrect region settings may violate local RF regulations.

### 10. Debugging

Enable debug logging:

```java
// View logs via TextView (if provided during initialization)
TextView logView = findViewById(R.id.log_view);
Cs710Library4A csLibrary4A = new Cs710Library4A(context, logView);

// Programmatically append to log
csLibrary4A.appendToLog("Custom debug message");

// Check internal debug flags in Utility class
// Modify DEBUG flags in source code for verbose logging
```

**Common Debug Flags** (in SDK source):
- `DEBUG_PKDATA` - Packet data flow
- `DEBUG_CONNECT` - Connection events
- `DEBUG_SCAN` - BLE scanning
- `DEBUG_COMPACT` - Compact mode operations

---

## Additional Resources

### Demo App Reference

The `app` module provides complete working examples:

**Key Files**:
- `ConnectionFragment.java` - Reader discovery and connection
- `InventoryFragment.java` - Basic inventory UI
- `InventoryRfidTask.java` - Complete inventory implementation
- `SettingFragment.java` - Configuration UI
- `MainActivity.java` - Application structure

### SDK Architecture

**Core Components**:
- `Cs710Library4A.java` - Main API for CS710S
- `CsReaderConnector.java` - Connection management
- `BluetoothGatt.java` - BLE communication
- `RfidConnector.java` - RFID protocol layer
- `RfidReader.java` - High-level RFID operations
- `RfidReaderChipE710.java` - E710 chip-specific implementation
- `SettingData.java` - Configuration persistence

### Common Issues and Solutions

**Issue**: Tags not reading
- Check power level (increase if too low)
- Verify region/frequency settings
- Check antenna connection
- Ensure tags are in read range

**Issue**: Slow read rates
- Disable extra bank reading if not needed
- Use compact mode
- Adjust Q value for tag density
- Check for interference

**Issue**: Connection drops
- Check Bluetooth permissions
- Verify Android location services enabled (required for BLE)
- Monitor battery level
- Reduce distance between phone and reader

**Issue**: Duplicate tags
- Enable duplicate elimination
- Increase duplicate elimination time window
- Use appropriate session/target settings

---

## Version Information

This documentation is based on:
- SDK Version: 15.0
- App Version: 4.18.0
- Android SDK: 26-36
- Supported Devices: CS710S, CS108

For the latest updates, refer to the source code repository.
