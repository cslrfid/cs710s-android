# CS710 Flutter App

Flutter application for CS710S/CS108 RFID reader operations using platform channels to access the `csl-rfid-android-sdk`.

## Project Status

✅ **Core Implementation Complete** - Functional RFID App

### Completed Features

#### Foundation & Architecture
- ✅ Project structure and dependencies
- ✅ Platform channel bridge (RfidPlatformChannel.kt - 732 lines)
- ✅ Riverpod state management with code generation
- ✅ Material Design 3 theme and utilities
- ✅ Permission handling system

#### Data Models (9 classes)
- ✅ RfidReader, RfidTag, RfidError
- ✅ RfidInventoryStats, RfidGeigerStats
- ✅ BarcodeData, BarcodeStats
- ✅ BatteryInfo, RfidConfiguration

#### Services Layer (6 services)
- ✅ RfidService - Core RFID operations
- ✅ ScanService - BLE device discovery
- ✅ InventoryService - Tag inventory management
- ✅ GeigerService - Tag locating with proximity
- ✅ BatteryService - Battery monitoring
- ✅ PermissionService - Runtime permissions

#### State Providers (6 providers)
- ✅ ScanStateProvider - Reader scanning state
- ✅ ConnectionStateProvider - Connection management
- ✅ InventoryStateProvider - RFID/Barcode inventory
- ✅ GeigerStateProvider - Geiger search state
- ✅ BatteryStateProvider - Battery monitoring
- ✅ PermissionProvider - Permission state

#### UI Screens (4 screens)
- ✅ ScanScreen - Reader discovery and connection
- ✅ MainScreen - Main navigation and status
- ✅ InventoryScreen - RFID and barcode scanning
- ✅ GeigerScreen - Tag location (Geiger mode)

#### Reusable Widgets (6 widgets)
- ✅ ReaderListItem - Reader display with RSSI
- ✅ TagListItem - Tag display with details
- ✅ ConnectionStatus - Connection indicator
- ✅ BatteryIndicator - Battery level display
- ✅ StatsCard - Statistics display card
- ✅ LoadingOverlay - Connection loading state

#### Advanced Features
- ✅ Hardware trigger key support (auto start/stop)
- ✅ Battery monitoring (5-second polling)
- ✅ Auto-configuration on connection (30.0 dBm, Session 1, Q=7)
- ✅ Real-time tag accumulation and statistics
- ✅ RSSI-based proximity calculation (Geiger mode)
- ✅ Beep and vibrate feedback
- ✅ Tag sorting (EPC, RSSI, Count, Timestamp)
- ✅ Comprehensive error handling
- ✅ Connection state monitoring
- ✅ Event stream-based architecture

### Known Limitations

- ⚠️ No tag filtering UI (SDK supports filtering)
- ⚠️ No advanced configuration UI (basic config implemented)
- ⚠️ No tag write operations (read-only)
- ⚠️ No barcode reader configuration UI
- ⚠️ No data export functionality
- ⚠️ Limited to Android platform

## Architecture

```
cs710flutterapp/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # MaterialApp configuration
│   ├── platform_channels/
│   │   └── rfid_channel.dart        # Platform channel wrapper
│   ├── services/                    # Business logic layer
│   │   ├── rfid_service.dart        # Core RFID operations (16.7KB)
│   │   ├── scan_service.dart        # BLE scanning
│   │   ├── inventory_service.dart   # Inventory management
│   │   ├── geiger_service.dart      # Geiger search
│   │   ├── battery_service.dart     # Battery monitoring
│   │   └── permission_service.dart  # Permissions
│   ├── models/                      # Data models (9 classes)
│   │   ├── rfid_reader.dart
│   │   ├── rfid_tag.dart
│   │   ├── rfid_inventory_stats.dart
│   │   ├── rfid_geiger_stats.dart
│   │   ├── rfid_configuration.dart
│   │   ├── rfid_error.dart
│   │   ├── barcode_data.dart
│   │   ├── barcode_stats.dart
│   │   └── battery_info.dart
│   ├── providers/                   # Riverpod state (6 providers + generated)
│   │   ├── scan_state_provider.dart
│   │   ├── connection_state_provider.dart
│   │   ├── inventory_state_provider.dart
│   │   ├── geiger_state_provider.dart
│   │   ├── battery_state_provider.dart
│   │   └── permission_provider.dart
│   ├── screens/                     # UI screens (4 screens)
│   │   ├── scan_screen.dart         # Reader discovery (15.3KB)
│   │   ├── main_screen.dart         # Main navigation (9KB)
│   │   ├── inventory_screen.dart    # RFID/Barcode (14.7KB)
│   │   └── geiger_screen.dart       # Tag location (10KB)
│   ├── widgets/                     # Reusable widgets (6 widgets)
│   │   ├── reader_list_item.dart
│   │   ├── tag_list_item.dart
│   │   ├── connection_status.dart
│   │   ├── battery_indicator.dart
│   │   ├── stats_card.dart
│   │   └── loading_overlay.dart
│   └── utils/                       # Utilities
│       ├── constants.dart
│       ├── formatters.dart
│       └── theme.dart
├── android/
│   └── app/src/main/kotlin/com/csl/cs710flutterapp/
│       └── RfidPlatformChannel.kt   # Platform bridge (732 lines)
├── pubspec.yaml                     # Dependencies
└── README.md                        # This file
```

**Total Lines**: 43 Dart files implementing full RFID functionality

## Dependencies

### Production
- **flutter_riverpod** (^2.4.0): State management with code generation
- **riverpod_annotation** (^2.3.0): Annotations for Riverpod
- **material_design_icons_flutter** (^7.0.0): Icon library
- **intl** (^0.18.0): Internationalization and formatting
- **collection** (^1.18.0): Collection utilities

### Development
- **build_runner** (^2.4.0): Code generation
- **riverpod_generator** (^2.3.0): Riverpod code generation
- **flutter_lints** (^3.0.0): Linting rules

## Setup

### Prerequisites
- Flutter SDK 3.0.0+
- Android Studio with Flutter plugin
- CS710S/CS108 RFID reader hardware
- Android device with Bluetooth (API 26+)

### Installation

1. **Navigate to the project**:
   ```bash
   cd cs710flutterapp
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Riverpod code**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Platform Channel API

The app communicates with native Android code via platform channels:

### MethodChannel: `com.csl.rfid/manager`

#### Device Management
- `startScan()` - Start BLE scanning for readers
- `stopScan()` - Stop BLE scanning
- `isScanning()` - Check if scanning
- `connect(String address)` - Connect to reader
- `disconnect()` - Disconnect from reader
- `isConnected()` - Check connection status

#### RFID Operations
- `startInventory()` - Start RFID tag inventory
- `stopInventory()` - Stop RFID tag inventory
- `startGeigerSearch(String epc, int memoryBank)` - Start Geiger search
- `stopGeigerSearch()` - Stop Geiger search

#### Barcode Operations
- `startBarcodeScan()` - Start barcode scanning
- `stopBarcodeScan()` - Stop barcode scanning

#### Battery & Trigger
- `getBatteryInfo()` - Get current battery level
- `startBatteryMonitoring()` - Start 5-second polling
- `stopBatteryMonitoring()` - Stop battery monitoring
- `enableTrigger(bool autoInventory)` - Enable trigger key
- `disableTrigger()` - Disable trigger key

#### Configuration
- `getConfiguration()` - Get current reader config
- `applyConfiguration(Map config)` - Apply reader settings

### EventChannels (8 streams)

- **`com.csl.rfid/scan_events`** - Reader discovery events
  - `scanStarted`, `scanStopped`, `readerFound`, `scanError`

- **`com.csl.rfid/connection_events`** - Connection status
  - `connecting`, `connected`, `disconnected`, `connectionError`

- **`com.csl.rfid/inventory_events`** - Tag read events
  - `inventoryStarted`, `inventoryStopped`, `tagRead`, `inventoryStats`, `inventoryError`

- **`com.csl.rfid/geiger_events`** - Proximity updates
  - `geigerStarted`, `geigerStopped`, `geigerUpdate`, `geigerError`

- **`com.csl.rfid/barcode_events`** - Barcode scan events
  - `barcodeStarted`, `barcodeStopped`, `barcodeRead`, `barcodeError`

- **`com.csl.rfid/battery_events`** - Battery level updates
  - `batteryUpdate` (every 5 seconds)

- **`com.csl.rfid/trigger_events`** - Trigger button events
  - `triggerPressed`, `triggerReleased`

- **`com.csl.rfid/config_events`** - Configuration results
  - `configApplied`, `configError`

## Features

### 1. Reader Scanning & Connection
- BLE discovery of CS710S/CS108 readers
- Reader list with RSSI signal strength
- Real-time RSSI updates during scanning
- Connection with loading overlay
- Connection state monitoring
- Auto-disconnect on app exit

### 2. RFID Inventory
- Real-time tag reading with accumulation
- Tag list display (EPC, RSSI, read count, timestamp)
- Live statistics:
  - Unique tag count
  - Total read count
  - Read rate (tags/second)
- Sort by: EPC, RSSI, Count, Timestamp (ascending)
- Clear tag list
- Tap tag to navigate to Geiger search
- Hardware trigger support (press to start, release to stop)
- Battery indicator in statistics card

### 3. Geiger Search (Tag Location)
- Tag locating by EPC
- Real-time proximity gauge (0-100%)
- Visual indicators:
  - Percentage display
  - 5-bar proximity meter
  - Linear progress bar
  - Color coding (Grey → Yellow → Orange → Green)
  - "Tag Found" indicator
- Proximity descriptions:
  - No Signal (0%)
  - Very Far (0-20%)
  - Far (20-40%)
  - Medium (40-60%)
  - Close (60-80%)
  - Very Close (80-100%)
- Hardware trigger support
- Battery indicator above search controls
- Auto-reset proximity to zero on search start

### 4. Barcode Scanning
- 1D/2D barcode support
- Barcode list with timestamps
- Statistics:
  - Unique barcode count
  - Total scan count
  - Elapsed time
- Clear barcode list

### 5. Advanced Features

#### Hardware Trigger Key
- Automatic start/stop on trigger press/release
- Works for both RFID inventory and Geiger search
- No manual button press required

#### Battery Monitoring
- Automatic monitoring when connected
- 5-second polling interval
- Display format: "Battery: 80%"
- Visual indicator with color coding:
  - Green: 60-100%
  - Orange: 30-59%
  - Red: 0-29%
- Battery icon with charging indicator
- Displayed on all screens after connection

#### Auto-Configuration
- Applied automatically on page load
- Default settings:
  - Power Level: 30.0 dBm (300)
  - Session: 1
  - Target: A
  - Inventory Mode: COMPACT
  - Q Value: 7
  - Beep: Enabled
  - Vibrate: Enabled

#### Error Handling
- Connection errors with retry
- Scan errors with user feedback
- Inventory/Geiger errors displayed
- Platform channel error handling
- Graceful disconnect handling

## Usage

### Scanning for Readers

1. Open the app
2. Grant Bluetooth and location permissions
3. Tap "Start Scan" on the scan screen
4. Wait for readers to appear in the list
5. Tap a reader to connect

### RFID Inventory

1. Connect to a reader
2. Navigate to "Inventory" from main screen
3. Select "RFID" tab
4. Tap "Start" or press hardware trigger
5. Tags appear in real-time with statistics
6. Tap any tag to locate it in Geiger mode
7. Use sort menu to organize tags
8. Tap "Stop" or release trigger when done
9. Tap "Clear" to reset tag list

### Locating a Tag (Geiger Mode)

1. From inventory, tap a tag, or
2. Navigate to "Locate Tag" and enter EPC manually
3. Tap "Start Search" or press hardware trigger
4. Move reader closer/farther from tag
5. Watch proximity gauge increase as you get closer
6. "Very Close" (80-100%) indicates tag is nearby
7. Tap "Stop Search" or release trigger when done

### Barcode Scanning

1. Connect to a reader
2. Navigate to "Inventory" from main screen
3. Select "Barcode" tab
4. Tap "Start"
5. Point reader at barcode
6. Barcode appears in list with timestamp
7. Tap "Stop" when done

## Development

### Code Generation

When modifying Riverpod providers:

```bash
# Watch mode (auto-generates on save)
flutter pub run build_runner watch --delete-conflicting-outputs

# One-time build
flutter pub run build_runner build --delete-conflicting-outputs

# Clean and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Adding New Features

1. **Add data model** in `lib/models/`
2. **Create service** in `lib/services/`
3. **Create provider** in `lib/providers/` with `@riverpod` annotation
4. **Add UI screen** in `lib/screens/` as `ConsumerWidget`
5. **Run code generation** with build_runner
6. **Update navigation** in `main_screen.dart`

### Platform Channel Development

When adding new native functionality:

1. Add method in `RfidPlatformChannel.kt`
2. Add wrapper in `rfid_channel.dart`
3. Add service method in appropriate service class
4. Update provider to use new service method
5. Update UI to call provider method

## Build

### Debug APK
```bash
flutter build apk --debug
```

### Release APK
```bash
flutter build apk --release
```

### Install on Device
```bash
flutter install
```

### Build App Bundle (Play Store)
```bash
flutter build appbundle --release
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/rfid_service_test.dart
```

## Troubleshooting

### Common Issues

**1. Platform channel not found**
- Ensure `RfidPlatformChannel` is registered in `MainActivity.kt`
- Check channel names match between Dart and Kotlin
- Verify `csl-rfid-android-sdk` is in dependencies

**2. Reader not connecting**
- Grant all Bluetooth and location permissions
- Ensure reader is powered on and in range
- Check reader battery level
- Try disconnecting and reconnecting
- Restart the app

**3. Tags not appearing**
- Verify reader is connected (check status)
- Ensure inventory is started
- Check if tags are in range (~1-3 meters)
- Verify reader configuration (power level)
- Try stopping and restarting inventory

**4. Geiger search not working**
- Enter correct EPC (from inventory screen)
- Ensure target tag is in range
- Start search before moving reader
- Check if proximity resets to 0 on start
- Verify tag EPC matches exactly

**5. Trigger key not working**
- Ensure reader supports trigger key
- Check if trigger is enabled (auto-enabled)
- Try manual start/stop buttons instead
- Check logcat for trigger events

**6. Battery not showing**
- Wait 5 seconds after connection
- Check if reader supports battery reporting
- Verify battery monitoring is started
- Check logcat for battery events

**7. Riverpod code generation errors**
- Run `flutter pub run build_runner clean`
- Run `flutter pub run build_runner build --delete-conflicting-outputs`
- Check for syntax errors in provider files
- Ensure `part` directive matches filename

**8. Build errors**
- Run `flutter clean`
- Run `flutter pub get`
- Check Gradle sync in Android Studio
- Verify Kotlin version compatibility
- Update Android Gradle Plugin if needed

## Performance

### Optimization Tips

- Tags accumulate during inventory (no duplicates)
- Event streams use broadcast controllers
- Battery polling uses 5-second intervals
- RSSI updates throttled during scanning
- Dispose subscriptions in widget lifecycle
- Use `const` constructors where possible

### Memory Management

- Services properly disposed in providers
- Subscriptions cancelled in `dispose()`
- Platform channels cleaned up on disconnect
- Event streams closed when not needed

## Project History

### Recent Commits
- **58b87c6**: Improves Geiger counter and inventory screens
- **69c8838**: Enables trigger key for inventory and geiger
- **76a3fbb**: Improves battery monitoring and display
- **ba68100**: Enhances connection flow and UI/UX
- **4459e2d**: Improves RFID scanning and event handling
- **61041b8**: Flutter implementation of CS710S Quick Start Demo

See full history with `git log --oneline`

## Contributing

When contributing to this project:

1. Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
2. Use Riverpod for all state management
3. Write tests for new features
4. Update documentation (README, code comments)
5. Ensure platform channel contracts match Dart/Kotlin
6. Run `flutter analyze` before committing
7. Generate Riverpod code after provider changes

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Platform Channels Guide](https://docs.flutter.dev/platform-integration/platform-channels)
- [Material Design 3](https://m3.material.io/)
- [CSL RFID Android SDK](../csl-rfid-android-sdk/)


