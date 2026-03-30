import Flutter
import UIKit
import CSL_CS710S_Library

class RfidPlatformChannel: NSObject {
    // MARK: - Constants
    private static let METHOD_CHANNEL = "com.csl.rfid/manager"
    private static let SCAN_EVENT_CHANNEL = "com.csl.rfid/scan_events"
    private static let CONNECTION_EVENT_CHANNEL = "com.csl.rfid/connection_events"
    private static let INVENTORY_EVENT_CHANNEL = "com.csl.rfid/inventory_events"
    private static let GEIGER_EVENT_CHANNEL = "com.csl.rfid/geiger_events"
    private static let BARCODE_EVENT_CHANNEL = "com.csl.rfid/barcode_events"
    private static let BATTERY_EVENT_CHANNEL = "com.csl.rfid/battery_events"
    private static let TRIGGER_EVENT_CHANNEL = "com.csl.rfid/trigger_events"
    private static let CONFIG_EVENT_CHANNEL = "com.csl.rfid/config_events"

    // MARK: - SDK Reference
    private let rfidManager = RfidManager.shared

    // MARK: - Channels
    private var methodChannel: FlutterMethodChannel?
    private var scanEventChannel: FlutterEventChannel?
    private var connectionEventChannel: FlutterEventChannel?
    private var inventoryEventChannel: FlutterEventChannel?
    private var geigerEventChannel: FlutterEventChannel?
    private var barcodeEventChannel: FlutterEventChannel?
    private var batteryEventChannel: FlutterEventChannel?
    private var triggerEventChannel: FlutterEventChannel?
    private var configEventChannel: FlutterEventChannel?

    // MARK: - Event Sinks
    private var scanEventSink: FlutterEventSink?
    private var connectionEventSink: FlutterEventSink?
    private var inventoryEventSink: FlutterEventSink?
    private var geigerEventSink: FlutterEventSink?
    private var barcodeEventSink: FlutterEventSink?
    private var batteryEventSink: FlutterEventSink?
    private var triggerEventSink: FlutterEventSink?
    private var configEventSink: FlutterEventSink?

    // MARK: - State
    private var discoveredReaders: [RfidReader] = []
    private var tags: [String: RfidTag] = [:]  // EPC -> Tag
    private var barcodes: [BarcodeData] = []

    // MARK: - Geiger State
    private var currentGeigerTargetEpc: String = ""

    // MARK: - Timers
    private var rssiTimeoutTimer: Timer?
    private var geigerRateTimer: Timer?
    private var lastGeigerReadCount = 0

    // MARK: - Configuration
    private var currentPowerLevel: Int = 300  // 30.0 dBm
    private var currentSession: Int = 1       // S1
    private var currentTarget: Int = 0        // A
    private var currentPopulation: Int = 100

    // MARK: - Registration
    func register(with messenger: FlutterBinaryMessenger) {
        // Method channel
        methodChannel = FlutterMethodChannel(
            name: Self.METHOD_CHANNEL,
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler(handleMethodCall)

        // Event channels with stream handlers
        setupEventChannel(
            name: Self.SCAN_EVENT_CHANNEL,
            messenger: messenger,
            onListen: { [weak self] sink in
                self?.scanEventSink = sink
                return nil
            },
            onCancel: { [weak self] in
                self?.scanEventSink = nil
                return nil
            }
        )

        setupEventChannel(
            name: Self.CONNECTION_EVENT_CHANNEL,
            messenger: messenger,
            onListen: { [weak self] sink in
                self?.connectionEventSink = sink
                return nil
            },
            onCancel: { [weak self] in
                self?.connectionEventSink = nil
                return nil
            }
        )

        setupEventChannel(
            name: Self.INVENTORY_EVENT_CHANNEL,
            messenger: messenger,
            onListen: { [weak self] sink in
                self?.inventoryEventSink = sink
                return nil
            },
            onCancel: { [weak self] in
                self?.inventoryEventSink = nil
                return nil
            }
        )

        setupEventChannel(
            name: Self.GEIGER_EVENT_CHANNEL,
            messenger: messenger,
            onListen: { [weak self] sink in
                self?.geigerEventSink = sink
                return nil
            },
            onCancel: { [weak self] in
                self?.geigerEventSink = nil
                return nil
            }
        )

        setupEventChannel(
            name: Self.BARCODE_EVENT_CHANNEL,
            messenger: messenger,
            onListen: { [weak self] sink in
                self?.barcodeEventSink = sink
                return nil
            },
            onCancel: { [weak self] in
                self?.barcodeEventSink = nil
                return nil
            }
        )

        setupEventChannel(
            name: Self.BATTERY_EVENT_CHANNEL,
            messenger: messenger,
            onListen: { [weak self] sink in
                self?.batteryEventSink = sink
                return nil
            },
            onCancel: { [weak self] in
                self?.batteryEventSink = nil
                return nil
            }
        )

        setupEventChannel(
            name: Self.TRIGGER_EVENT_CHANNEL,
            messenger: messenger,
            onListen: { [weak self] sink in
                self?.triggerEventSink = sink
                return nil
            },
            onCancel: { [weak self] in
                self?.triggerEventSink = nil
                return nil
            }
        )

        setupEventChannel(
            name: Self.CONFIG_EVENT_CHANNEL,
            messenger: messenger,
            onListen: { [weak self] sink in
                self?.configEventSink = sink
                return nil
            },
            onCancel: { [weak self] in
                self?.configEventSink = nil
                return nil
            }
        )
    }

    // MARK: - Event Channel Setup Helper
    private func setupEventChannel(
        name: String,
        messenger: FlutterBinaryMessenger,
        onListen: @escaping (FlutterEventSink?) -> FlutterError?,
        onCancel: @escaping () -> FlutterError?
    ) {
        let channel = FlutterEventChannel(name: name, binaryMessenger: messenger)
        let handler = EventStreamHandler(onListen: onListen, onCancel: onCancel)
        channel.setStreamHandler(handler)
    }

    // MARK: - Method Call Handler
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        // Scanner
        case "startScan":
            startScan(result: result)
        case "stopScan":
            stopScan(result: result)
        case "isScanning":
            result(false)  // TODO: Track scanning state

        // Connection
        case "connect":
            connect(call: call, result: result)
        case "disconnect":
            disconnect(result: result)
        case "isConnected":
            result(rfidManager.isConnected)
        case "getConnectedReader":
            getConnectedReader(result: result)

        // Configuration
        case "setPowerLevel":
            setPowerLevel(call: call, result: result)
        case "setSession":
            setSession(call: call, result: result)
        case "setTarget":
            setTarget(call: call, result: result)
        case "setPopulation":
            setPopulation(call: call, result: result)
        case "applyConfiguration":
            applyConfigurationFromMap(call: call, result: result)
        case "getConfiguration":
            getConfiguration(result: result)

        // Inventory
        case "startInventory":
            startInventory(result: result)
        case "stopInventory":
            stopInventory(result: result)
        case "isInventorying":
            result(false)  // TODO: Track inventory state

        // Geiger Search
        case "startGeigerSearch":
            startGeigerSearch(call: call, result: result)
        case "stopGeigerSearch":
            stopGeigerSearch(result: result)
        case "isSearching":
            result(false)  // TODO: Track search state

        // Barcode
        case "startBarcodeScan":
            startBarcodeScan(result: result)
        case "stopBarcodeScan":
            stopBarcodeScan(result: result)
        case "isBarcodeScanning":
            result(false)  // TODO: Track barcode state

        // Battery
        case "getBatteryInfo":
            getBatteryInfo(result: result)
        case "startBatteryMonitoring":
            startBatteryMonitoring(result: result)
        case "stopBatteryMonitoring":
            stopBatteryMonitoring(result: result)
        case "isBatteryMonitoringActive":
            result(false)  // TODO: Track battery monitoring state

        // Trigger
        case "enableTrigger":
            enableTrigger(call: call, result: result)
        case "disableTrigger":
            disableTrigger(result: result)
        case "getTriggerState":
            getTriggerState(result: result)
        case "isTriggerMonitoringActive":
            result(false)  // TODO: Track trigger monitoring state

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Helper: Send Event to Sink
    private func sendEvent(to sink: FlutterEventSink?, data: [String: Any]) {
        DispatchQueue.main.async {
            sink?(data)
        }
    }
}

// MARK: - Scanner Implementation
extension RfidPlatformChannel: RfidScanDelegate {
    private func startScan(result: @escaping FlutterResult) {
        discoveredReaders.removeAll()
        rfidManager.startScan(delegate: self)
        result(nil)
    }

    func onReaderDiscovered(_ reader: RfidReader) {
        if !discoveredReaders.contains(where: { $0.address == reader.address }) {
            discoveredReaders.append(reader)

            sendEvent(to: scanEventSink, data: [
                "type": "readerDiscovered",
                "reader": reader.toDictionary()
            ])
        } else {
            // Update existing reader RSSI
            sendEvent(to: scanEventSink, data: [
                "type": "readerUpdated",
                "reader": reader.toDictionary()
            ])
        }
    }

    func onScanError(_ error: RfidError) {
        sendEvent(to: scanEventSink, data: [
            "type": "scanError",
            "error": [
                "message": error.description,
                "type": "SCAN_ERROR",
                "cause": ""
            ]
        ])
    }

    private func stopScan(result: @escaping FlutterResult) {
        rfidManager.stopScan()
        result(nil)
    }
}

// MARK: - Connection Implementation
extension RfidPlatformChannel: RfidConnectionDelegate {
    private func connect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let address = args["address"] as? String,
              let reader = discoveredReaders.first(where: { $0.address == address }) else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Reader not found or invalid arguments",
                details: nil
            ))
            return
        }

        sendEvent(to: connectionEventSink, data: ["type": "connecting"])
        rfidManager.connect(to: reader, delegate: self)
        result(nil)
    }

    func onConnected(_ reader: RfidReader) {
        sendEvent(to: connectionEventSink, data: [
            "type": "connected",
            "reader": reader.toDictionary()
        ])
    }

    func onReaderReady(_ reader: RfidReader) {
        sendEvent(to: connectionEventSink, data: [
            "type": "readerReady",
            "reader": reader.toDetailedDictionary()
        ])

        // Auto-start battery monitoring (match Android behavior)
        rfidManager.startBatteryMonitoring(delegate: self)
    }

    func onDisconnected(_ reader: RfidReader?, error: RfidError?) {
        sendEvent(to: connectionEventSink, data: [
            "type": "disconnected",
            "reason": error?.description ?? "Unknown"
        ])
    }

    func onConnectionFailed(_ error: RfidError) {
        sendEvent(to: connectionEventSink, data: [
            "type": "connectionFailed",
            "error": [
                "message": error.description,
                "type": "CONNECTION_ERROR",
                "cause": ""
            ]
        ])
    }

    private func disconnect(result: @escaping FlutterResult) {
        rfidManager.disconnect()
        result(nil)
    }

    private func getConnectedReader(result: @escaping FlutterResult) {
        if let reader = rfidManager.currentReader {
            result([
                "name": reader.name,
                "address": reader.address,
                "rssi": 0  // Not available when connected
            ])
        } else {
            result(nil)
        }
    }
}

// MARK: - Configuration Implementation
extension RfidPlatformChannel: RfidConfigurationDelegate {
    private func setPowerLevel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let powerLevel = args["powerLevel"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing powerLevel", details: nil))
            return
        }

        currentPowerLevel = powerLevel
        applyConfiguration()
        result(nil)
    }

    private func setSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let session = args["session"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing session", details: nil))
            return
        }

        currentSession = session
        applyConfiguration()
        result(nil)
    }

    private func setTarget(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let target = args["target"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing target", details: nil))
            return
        }

        currentTarget = target
        applyConfiguration()
        result(nil)
    }

    private func setPopulation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let population = args["population"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing population", details: nil))
            return
        }

        currentPopulation = population
        applyConfiguration()
        result(nil)
    }

    private func applyConfigurationFromMap(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let configMap = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Configuration map is required", details: nil))
            return
        }

        // Parse configuration from map
        let powerLevel = configMap["powerLevel"] as? Int ?? currentPowerLevel
        let session = configMap["session"] as? Int ?? currentSession
        let qValue = configMap["qValue"] as? Int ?? 4
        // Note: iOS SDK doesn't support enableBeep/enableVibrate in configure()

        // Update current values
        currentPowerLevel = powerLevel
        currentSession = session

        // Apply configuration
        rfidManager.configure()
            .powerLevel(powerLevel)
            .session(session)
            .target(RfidTarget(rawValue: currentTarget) ?? .A)
            .qValue(qValue)
            .apply(delegate: self)

        result(nil)
    }

    private func applyConfiguration() {
        rfidManager.configure()
            .powerLevel(currentPowerLevel)
            .session(currentSession)
            .target(RfidTarget(rawValue: currentTarget) ?? .A)
            .apply(delegate: self)
    }

    func onConfigured() {
        sendEvent(to: configEventSink, data: [
            "type": "configured"
        ])
    }

    func onConfigurationFailed(_ error: RfidError) {
        sendEvent(to: configEventSink, data: [
            "type": "configurationFailed",
            "error": [
                "message": error.description,
                "type": "CONFIG_ERROR",
                "cause": ""
            ]
        ])
    }

    private func getConfiguration(result: @escaping FlutterResult) {
        result([
            "powerLevel": currentPowerLevel,
            "session": currentSession,
            "target": currentTarget,
            "population": currentPopulation
        ])
    }
}

// MARK: - Inventory Implementation
extension RfidPlatformChannel: RfidInventoryDelegate {
    private func startInventory(result: @escaping FlutterResult) {
        // Tags accumulate - not cleared (match Android behavior)
        rfidManager.startInventory(delegate: self)
        result(nil)
    }

    func onTagRead(_ tag: RfidTag) {
        tags[tag.epc] = tag

        sendEvent(to: inventoryEventSink, data: [
            "type": "tagRead",
            "tag": tag.toDictionary()
        ])
    }

    func onInventoryRound(_ stats: RfidInventoryStats) {
        sendEvent(to: inventoryEventSink, data: [
            "type": "inventoryRound",
            "stats": stats.toDictionary()
        ])
    }

    func onInventoryStopped(_ reason: RfidStopReason) {
        let totalReads = tags.values.reduce(0) { $0 + $1.count }
        sendEvent(to: inventoryEventSink, data: [
            "type": "inventoryStopped",
            "reason": reason.description,
            "stats": [
                "uniqueTagCount": tags.count,
                "totalReads": totalReads,
                "readRate": 0.0,
                "elapsedTimeMs": 0
            ]
        ])
    }

    func onInventoryError(_ error: RfidError) {
        sendEvent(to: inventoryEventSink, data: [
            "type": "inventoryError",
            "error": error.toDictionary()
        ])
    }

    private func stopInventory(result: @escaping FlutterResult) {
        rfidManager.stopInventory()
        result(nil)
    }
}

// MARK: - Geiger Search Implementation
extension RfidPlatformChannel: RfidGeigerDelegate {
    private func startGeigerSearch(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let targetEpc = args["epc"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing epc", details: nil))
            return
        }

        currentGeigerTargetEpc = targetEpc

        // Reset timers
        stopGeigerTimers()
        lastGeigerReadCount = 0

        // Start rate calculation timer (1 second)
        geigerRateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Rate calculation happens in onProximityUpdate
        }

        // Start SDK Geiger search
        rfidManager.startGeigerSearch(targetEpc: targetEpc, delegate: self)
        result(nil)
    }

    func onSearchStarted() {
        sendEvent(to: geigerEventSink, data: [
            "type": "geigerStarted",
            "epc": currentGeigerTargetEpc
        ])
    }

    func onProximityUpdate(_ stats: RfidGeigerStats) {
        lastGeigerReadCount = stats.readCount

        sendEvent(to: geigerEventSink, data: [
            "type": "proximityUpdate",
            "stats": [
                "targetEpc": currentGeigerTargetEpc,
                "currentRssi": stats.currentRssi,
                "peakRssi": stats.peakRssi,
                "readCount": stats.readCount,
                "proximity": stats.proximity,
                "elapsedTimeMs": stats.elapsedTimeMs
            ]
        ])

        // RSSI timeout: reset proximity after 2 seconds of no reads
        resetRssiTimeout()
    }

    func onSearchStopped(_ reason: RfidStopReason) {
        sendEvent(to: geigerEventSink, data: [
            "type": "geigerStopped",
            "reason": reason.description,
            "stats": [
                "targetEpc": currentGeigerTargetEpc,
                "currentRssi": 0.0,
                "peakRssi": 0.0,
                "readCount": lastGeigerReadCount,
                "proximity": 0,
                "elapsedTimeMs": 0
            ]
        ])

        stopGeigerTimers()
    }

    func onSearchError(_ error: RfidError) {
        sendEvent(to: geigerEventSink, data: [
            "type": "geigerError",
            "error": error.toDictionary()
        ])
    }

    private func stopGeigerSearch(result: @escaping FlutterResult) {
        rfidManager.stopGeigerSearch()
        stopGeigerTimers()
        result(nil)
    }

    // Helpers
    private func resetRssiTimeout() {
        rssiTimeoutTimer?.invalidate()
        rssiTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // Send proximity reset event
            self.sendEvent(to: self.geigerEventSink, data: [
                "type": "proximityUpdate",
                "stats": [
                    "targetEpc": self.currentGeigerTargetEpc,
                    "currentRssi": 0,
                    "peakRssi": 0,
                    "readCount": self.lastGeigerReadCount,
                    "proximity": 0,
                    "elapsedTimeMs": 0
                ]
            ])
        }
    }

    private func stopGeigerTimers() {
        geigerRateTimer?.invalidate()
        geigerRateTimer = nil
        rssiTimeoutTimer?.invalidate()
        rssiTimeoutTimer = nil
    }
}

// MARK: - Barcode Implementation
extension RfidPlatformChannel: BarcodeScanDelegate {
    private func startBarcodeScan(result: @escaping FlutterResult) {
        rfidManager.startBarcodeScan(delegate: self)
        result(nil)
    }

    func onBarcodeScanned(_ data: BarcodeData) {
        if !barcodes.contains(where: { $0.barcode == data.barcode }) {
            barcodes.append(data)
        }

        sendEvent(to: barcodeEventSink, data: [
            "type": "barcodeScanned",
            "barcode": data.toDictionary()
        ])
    }

    func onStatisticsUpdate(_ stats: BarcodeStats) {
        sendEvent(to: barcodeEventSink, data: [
            "type": "barcodeStats",
            "stats": stats.toDictionary()
        ])
    }

    private func stopBarcodeScan(result: @escaping FlutterResult) {
        rfidManager.stopBarcodeScan()

        sendEvent(to: barcodeEventSink, data: [
            "type": "scanStopped",
            "reason": "manual"
        ])

        result(nil)
    }
}

// MARK: - Battery Implementation
extension RfidPlatformChannel: BatteryDelegate {
    private func getBatteryInfo(result: @escaping FlutterResult) {
        result([
            "level": 0,
            "voltage": 0.0,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ])
    }

    private func startBatteryMonitoring(result: @escaping FlutterResult) {
        rfidManager.startBatteryMonitoring(delegate: self)
        result(nil)
    }

    func onBatteryUpdate(_ info: BatteryInfo) {
        sendEvent(to: batteryEventSink, data: [
            "type": "batteryUpdate",
            "battery": info.toDictionary()
        ])
    }

    func onBatteryError(_ error: RfidError) {
        sendEvent(to: batteryEventSink, data: [
            "type": "error",
            "error": error.toDictionary()
        ])
    }

    private func stopBatteryMonitoring(result: @escaping FlutterResult) {
        rfidManager.stopBatteryMonitoring()
        result(nil)
    }
}

// MARK: - Trigger Implementation
extension RfidPlatformChannel: TriggerDelegate {
    private func enableTrigger(call: FlutterMethodCall, result: @escaping FlutterResult) {
        rfidManager.enableTrigger(delegate: self)
        result(nil)
    }

    func onTriggerStateChanged(_ pressed: Bool) {
        sendEvent(to: triggerEventSink, data: [
            "type": "triggerStateChanged",
            "pressed": pressed
        ])

        // TODO: Implement autoInventory logic if enabled
    }

    private func disableTrigger(result: @escaping FlutterResult) {
        rfidManager.disableTrigger()
        result(nil)
    }

    private func getTriggerState(result: @escaping FlutterResult) {
        // TODO: Get current trigger state from SDK
        result(false)
    }
}

// MARK: - Event Stream Handler
private class EventStreamHandler: NSObject, FlutterStreamHandler {
    private let onListenCallback: (FlutterEventSink?) -> FlutterError?
    private let onCancelCallback: () -> FlutterError?

    init(
        onListen: @escaping (FlutterEventSink?) -> FlutterError?,
        onCancel: @escaping () -> FlutterError?
    ) {
        self.onListenCallback = onListen
        self.onCancelCallback = onCancel
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        return onListenCallback(events)
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return onCancelCallback()
    }
}
