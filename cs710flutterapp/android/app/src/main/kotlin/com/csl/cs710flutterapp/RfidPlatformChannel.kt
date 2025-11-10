package com.csl.cs710flutterapp

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.csl.rfidsdk.*
import com.csl.rfidsdk.callbacks.*
import com.csl.rfidsdk.config.*
import com.csl.rfidsdk.models.*
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channel bridge between Flutter and csl-rfid-android-sdk
 * Handles 25+ method calls and 8 event streams
 */
class RfidPlatformChannel(
    private val context: Context,
    private val rfidManager: RfidManager,
    binaryMessenger: io.flutter.plugin.common.BinaryMessenger
) {
    companion object {
        private const val METHOD_CHANNEL = "com.csl.rfid/manager"
        private const val SCAN_EVENTS = "com.csl.rfid/scan_events"
        private const val CONNECTION_EVENTS = "com.csl.rfid/connection_events"
        private const val INVENTORY_EVENTS = "com.csl.rfid/inventory_events"
        private const val GEIGER_EVENTS = "com.csl.rfid/geiger_events"
        private const val BARCODE_EVENTS = "com.csl.rfid/barcode_events"
        private const val BATTERY_EVENTS = "com.csl.rfid/battery_events"
        private const val TRIGGER_EVENTS = "com.csl.rfid/trigger_events"
        private const val CONFIG_EVENTS = "com.csl.rfid/config_events"
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    // Store discovered readers by address
    private val discoveredReaders = mutableMapOf<String, RfidReader>()

    // Method channel
    private val methodChannel = MethodChannel(binaryMessenger, METHOD_CHANNEL)

    // Event channels
    private val scanEventChannel = EventChannel(binaryMessenger, SCAN_EVENTS)
    private val connectionEventChannel = EventChannel(binaryMessenger, CONNECTION_EVENTS)
    private val inventoryEventChannel = EventChannel(binaryMessenger, INVENTORY_EVENTS)
    private val geigerEventChannel = EventChannel(binaryMessenger, GEIGER_EVENTS)
    private val barcodeEventChannel = EventChannel(binaryMessenger, BARCODE_EVENTS)
    private val batteryEventChannel = EventChannel(binaryMessenger, BATTERY_EVENTS)
    private val triggerEventChannel = EventChannel(binaryMessenger, TRIGGER_EVENTS)
    private val configEventChannel = EventChannel(binaryMessenger, CONFIG_EVENTS)

    // Event sinks
    private var scanEventSink: EventChannel.EventSink? = null
    private var connectionEventSink: EventChannel.EventSink? = null
    private var inventoryEventSink: EventChannel.EventSink? = null
    private var geigerEventSink: EventChannel.EventSink? = null
    private var barcodeEventSink: EventChannel.EventSink? = null
    private var batteryEventSink: EventChannel.EventSink? = null
    private var triggerEventSink: EventChannel.EventSink? = null
    private var configEventSink: EventChannel.EventSink? = null

    /**
     * Initialize platform channel and set up handlers
     */
    fun initialize() {
        methodChannel.setMethodCallHandler(::handleMethodCall)
        scanEventChannel.setStreamHandler(scanStreamHandler)
        connectionEventChannel.setStreamHandler(connectionStreamHandler)
        inventoryEventChannel.setStreamHandler(inventoryStreamHandler)
        geigerEventChannel.setStreamHandler(geigerStreamHandler)
        barcodeEventChannel.setStreamHandler(barcodeStreamHandler)
        batteryEventChannel.setStreamHandler(batteryStreamHandler)
        triggerEventChannel.setStreamHandler(triggerStreamHandler)
        configEventChannel.setStreamHandler(configStreamHandler)
    }

    /**
     * Handle method calls from Flutter
     */
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                // Scanning
                "startScan" -> startScan(result)
                "stopScan" -> stopScan(result)
                "isScanning" -> isScanning(result)

                // Connection
                "connect" -> connect(call, result)
                "disconnect" -> disconnect(result)
                "isConnected" -> isConnected(result)
                "getConnectedReader" -> getConnectedReader(result)

                // Inventory
                "startInventory" -> startInventory(result)
                "stopInventory" -> stopInventory(result)
                "isInventorying" -> isInventorying(result)

                // Geiger Search
                "startGeigerSearch" -> startGeigerSearch(call, result)
                "stopGeigerSearch" -> stopGeigerSearch(result)
                "isSearching" -> isSearching(result)

                // Barcode
                "startBarcodeScan" -> startBarcodeScan(result)
                "stopBarcodeScan" -> stopBarcodeScan(result)
                "isBarcodeScanning" -> isBarcodeScanning(result)

                // Battery
                "getBatteryInfo" -> getBatteryInfo(result)
                "startBatteryMonitoring" -> startBatteryMonitoring(result)
                "stopBatteryMonitoring" -> stopBatteryMonitoring(result)
                "isBatteryMonitoringActive" -> isBatteryMonitoringActive(result)

                // Trigger
                "enableTrigger" -> enableTrigger(call, result)
                "disableTrigger" -> disableTrigger(result)
                "getTriggerState" -> getTriggerState(result)
                "isTriggerMonitoringActive" -> isTriggerMonitoringActive(result)

                // Configuration
                "getConfiguration" -> getConfiguration(result)
                "applyConfiguration" -> applyConfiguration(call, result)

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("PLATFORM_ERROR", e.message, e.stackTraceToString())
        }
    }

    // ========== SCANNING METHODS ==========

    private fun startScan(result: MethodChannel.Result) {
        rfidManager.startScan(object : RfidScanCallback {
            override fun onReaderDiscovered(reader: RfidReader) {
                // Store discovered reader
                discoveredReaders[reader.address] = reader
                sendEvent(scanEventSink, mapOf(
                    "type" to "readerDiscovered",
                    "reader" to reader.toMap()
                ))
            }

            override fun onReaderUpdated(reader: RfidReader) {
                // Update stored reader
                discoveredReaders[reader.address] = reader
                sendEvent(scanEventSink, mapOf(
                    "type" to "readerUpdated",
                    "reader" to reader.toMap()
                ))
            }

            override fun onScanError(error: RfidError) {
                sendEvent(scanEventSink, mapOf(
                    "type" to "scanError",
                    "error" to error.toMap()
                ))
            }
        })
        result.success(null)
    }

    private fun stopScan(result: MethodChannel.Result) {
        rfidManager.stopScan()
        result.success(null)
    }

    private fun isScanning(result: MethodChannel.Result) {
        result.success(rfidManager.isScanning())
    }

    // ========== CONNECTION METHODS ==========

    private fun connect(call: MethodCall, result: MethodChannel.Result) {
        val address = call.argument<String>("address")
        if (address == null) {
            result.error("INVALID_ARGUMENT", "Address is required", null)
            return
        }

        // Find reader by address from discovered readers
        val reader = discoveredReaders[address]
        if (reader == null) {
            result.error("READER_NOT_FOUND", "Reader not found. Please scan first.", null)
            return
        }

        rfidManager.connect(reader, object : RfidConnectionCallback {
            override fun onConnecting() {
                sendEvent(connectionEventSink, mapOf("type" to "connecting"))
            }

            override fun onConnected(reader: RfidReader) {
                sendEvent(connectionEventSink, mapOf(
                    "type" to "connected",
                    "reader" to reader.toMap()
                ))
            }

            override fun onReaderReady(reader: RfidReader) {
                sendEvent(connectionEventSink, mapOf(
                    "type" to "readerReady",
                    "reader" to reader.toMap()
                ))
            }

            override fun onConnectionFailed(error: RfidError) {
                sendEvent(connectionEventSink, mapOf(
                    "type" to "connectionFailed",
                    "error" to error.toMap()
                ))
            }

            override fun onDisconnected(reader: RfidReader?, error: RfidError?) {
                sendEvent(connectionEventSink, mapOf(
                    "type" to "disconnected",
                    "reader" to reader?.toMap(),
                    "error" to error?.toMap()
                ))
            }
        })
        result.success(null)
    }

    private fun disconnect(result: MethodChannel.Result) {
        rfidManager.disconnect()
        result.success(null)
    }

    private fun isConnected(result: MethodChannel.Result) {
        result.success(rfidManager.isConnected())
    }

    private fun getConnectedReader(result: MethodChannel.Result) {
        val reader = rfidManager.getConnectedReader()
        result.success(reader?.toMap())
    }

    // ========== INVENTORY METHODS ==========

    private fun startInventory(result: MethodChannel.Result) {
        if (!rfidManager.isConnected()) {
            result.error("NOT_CONNECTED", "Reader not connected", null)
            return
        }

        rfidManager.startInventory(object : RfidInventoryCallback {
            override fun onTagRead(tag: RfidTag) {
                sendEvent(inventoryEventSink, mapOf(
                    "type" to "tagRead",
                    "tag" to tag.toMap()
                ))
            }

            override fun onInventoryRound(stats: RfidInventoryStats) {
                sendEvent(inventoryEventSink, mapOf(
                    "type" to "inventoryRound",
                    "stats" to stats.toMap()
                ))
            }

            override fun onInventoryStopped(reason: RfidStopReason) {
                sendEvent(inventoryEventSink, mapOf(
                    "type" to "inventoryStopped",
                    "reason" to reason.name
                ))
            }

            override fun onInventoryError(error: RfidError) {
                sendEvent(inventoryEventSink, mapOf(
                    "type" to "inventoryError",
                    "error" to error.toMap()
                ))
            }
        })
        result.success(null)
    }

    private fun stopInventory(result: MethodChannel.Result) {
        rfidManager.stopInventory()
        result.success(null)
    }

    private fun isInventorying(result: MethodChannel.Result) {
        result.success(rfidManager.isInventorying())
    }

    // ========== GEIGER SEARCH METHODS ==========

    private fun startGeigerSearch(call: MethodCall, result: MethodChannel.Result) {
        val epc = call.argument<String>("epc")
        val memoryBank = call.argument<Int>("memoryBank") ?: 1

        if (epc == null) {
            result.error("INVALID_ARGUMENT", "EPC is required", null)
            return
        }

        if (!rfidManager.isConnected()) {
            result.error("NOT_CONNECTED", "Reader not connected", null)
            return
        }

        rfidManager.startGeigerSearch(epc, memoryBank, object : RfidGeigerCallback {
            override fun onSearchStarted() {
                sendEvent(geigerEventSink, mapOf("type" to "searchStarted"))
            }

            override fun onRssiUpdate(rssi: Double, stats: RfidGeigerStats) {
                sendEvent(geigerEventSink, mapOf(
                    "type" to "rssiUpdate",
                    "rssi" to rssi,
                    "stats" to stats.toMap()
                ))
            }

            override fun onProximityUpdate(stats: RfidGeigerStats) {
                sendEvent(geigerEventSink, mapOf(
                    "type" to "proximityUpdate",
                    "stats" to stats.toMap()
                ))
            }

            override fun onSearchStopped(reason: RfidStopReason) {
                sendEvent(geigerEventSink, mapOf(
                    "type" to "searchStopped",
                    "reason" to reason.name
                ))
            }

            override fun onSearchError(error: RfidError) {
                sendEvent(geigerEventSink, mapOf(
                    "type" to "searchError",
                    "error" to error.toMap()
                ))
            }
        })
        result.success(null)
    }

    private fun stopGeigerSearch(result: MethodChannel.Result) {
        rfidManager.stopGeigerSearch()
        result.success(null)
    }

    private fun isSearching(result: MethodChannel.Result) {
        result.success(rfidManager.isSearching())
    }

    // ========== BARCODE METHODS ==========

    private fun startBarcodeScan(result: MethodChannel.Result) {
        if (!rfidManager.isConnected()) {
            result.error("NOT_CONNECTED", "Reader not connected", null)
            return
        }

        rfidManager.startBarcodeScan(object : BarcodeScanCallback {
            override fun onBarcodeScanned(data: BarcodeData) {
                sendEvent(barcodeEventSink, mapOf(
                    "type" to "barcodeScanned",
                    "barcode" to data.toMap()
                ))
            }

            override fun onScanUpdate(stats: BarcodeStats) {
                sendEvent(barcodeEventSink, mapOf(
                    "type" to "scanUpdate",
                    "stats" to stats.toMap()
                ))
            }

            override fun onScanStopped(reason: RfidStopReason) {
                sendEvent(barcodeEventSink, mapOf(
                    "type" to "scanStopped",
                    "reason" to reason.name
                ))
            }

            override fun onScanError(error: RfidError) {
                sendEvent(barcodeEventSink, mapOf(
                    "type" to "scanError",
                    "error" to error.toMap()
                ))
            }
        })
        result.success(null)
    }

    private fun stopBarcodeScan(result: MethodChannel.Result) {
        rfidManager.stopBarcodeScan()
        result.success(null)
    }

    private fun isBarcodeScanning(result: MethodChannel.Result) {
        // Note: RfidManager doesn't have isBarcodeScanActive() method
        // We'll need to track this state manually or return false for now
        result.success(false)
    }

    // ========== BATTERY METHODS ==========

    private fun getBatteryInfo(result: MethodChannel.Result) {
        // This would need to be implemented in RfidManager if not already available
        // For now, return null
        result.success(null)
    }

    private fun startBatteryMonitoring(result: MethodChannel.Result) {
        rfidManager.startBatteryMonitoring(object : BatteryCallback {
            override fun onBatteryUpdate(batteryInfo: BatteryInfo) {
                sendEvent(batteryEventSink, mapOf(
                    "type" to "batteryUpdate",
                    "battery" to batteryInfo.toMap()
                ))
            }
        })
        result.success(null)
    }

    private fun stopBatteryMonitoring(result: MethodChannel.Result) {
        rfidManager.stopBatteryMonitoring()
        result.success(null)
    }

    private fun isBatteryMonitoringActive(result: MethodChannel.Result) {
        // Would need to track this state in RfidManager
        result.success(false)
    }

    // ========== TRIGGER METHODS ==========

    private fun enableTrigger(call: MethodCall, result: MethodChannel.Result) {
        val autoInventory = call.argument<Boolean>("autoInventory") ?: false

        rfidManager.enableTrigger(object : TriggerCallback {
            override fun onTriggerStateChanged(pressed: Boolean) {
                sendEvent(triggerEventSink, mapOf(
                    "type" to "triggerStateChanged",
                    "pressed" to pressed
                ))
            }
        }, autoInventory)
        result.success(null)
    }

    private fun disableTrigger(result: MethodChannel.Result) {
        rfidManager.disableTrigger()
        result.success(null)
    }

    private fun getTriggerState(result: MethodChannel.Result) {
        // Would need to be implemented in RfidManager
        result.success(false)
    }

    private fun isTriggerMonitoringActive(result: MethodChannel.Result) {
        // Would need to track this state in RfidManager
        result.success(false)
    }

    // ========== CONFIGURATION METHODS ==========

    private fun getConfiguration(result: MethodChannel.Result) {
        val config = rfidManager.getConfiguration()
        result.success(config.toMap())
    }

    private fun applyConfiguration(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val configMap = call.arguments as? Map<String, Any>

        if (configMap == null) {
            result.error("INVALID_ARGUMENT", "Configuration map is required", null)
            return
        }

        // Parse configuration from map
        val powerLevel = configMap["powerLevel"] as? Int ?: 300
        val session = configMap["session"] as? Int ?: 1
        val qValue = configMap["qValue"] as? Int ?: 4
        val enableBeep = configMap["enableBeep"] as? Boolean ?: true
        val enableVibrate = configMap["enableVibrate"] as? Boolean ?: true

        rfidManager.configure()
            .powerLevel(powerLevel)
            .session(session)
            .qValue(qValue)
            .enableBeep(enableBeep)
            .enableVibrate(enableVibrate)
            .apply(object : RfidConfigurationCallback {
                override fun onConfigured() {
                    sendEvent(configEventSink, mapOf("type" to "configured"))
                }

                override fun onConfigurationFailed(error: RfidError) {
                    sendEvent(configEventSink, mapOf(
                        "type" to "configurationFailed",
                        "error" to error.toMap()
                    ))
                }
            })

        result.success(null)
    }

    // ========== MODEL SERIALIZATION ==========

    private fun RfidReader.toMap(): Map<String, Any> {
        return mapOf(
            "name" to name,
            "address" to address,
            "rssi" to rssi,
            "serviceUUID" to serviceUUID
        )
    }

    private fun RfidTag.toMap(): Map<String, Any> {
        return mapOf(
            "epc" to epc,
            "rssi" to rssi,
            "count" to count,
            "timestamp" to timestamp,
            "phase" to phase,
            "channel" to channel
        )
    }

    private fun BatteryInfo.toMap(): Map<String, Any> {
        return mapOf(
            "level" to percentage,
            "voltage" to voltage,
            "timestamp" to timestamp
        )
    }

    private fun RfidConfiguration.toMap(): Map<String, Any> {
        return mapOf(
            "powerLevel" to powerLevel,
            "session" to session,
            "qValue" to qValue,
            "target" to target.name,
            "inventoryMode" to inventoryMode.name,
            "region" to region.name,
            "enableBeep" to isEnableBeep,
            "enableVibrate" to isEnableVibrate
        )
    }

    private fun RfidInventoryStats.toMap(): Map<String, Any> {
        return mapOf(
            "uniqueTagCount" to uniqueTagCount,
            "totalReads" to totalReads,
            "readRate" to readRate,
            "elapsedTimeMs" to duration
        )
    }

    private fun RfidGeigerStats.toMap(): Map<String, Any> {
        return mapOf(
            "currentRssi" to currentRssi,
            "peakRssi" to peakRssi,
            "readCount" to readCount,
            "proximity" to proximityLevel,
            "elapsedTimeMs" to duration,
            "readRate" to readRate
        )
    }

    private fun BarcodeData.toMap(): Map<String, Any> {
        return mapOf(
            "barcode" to barcode,
            "timestamp" to timestamp
        )
    }

    private fun BarcodeStats.toMap(): Map<String, Any> {
        return mapOf(
            "totalScans" to totalScans,
            "uniqueBarcodes" to uniqueBarcodes,
            "elapsedTimeMs" to elapsedTimeMs
        )
    }

    private fun RfidError.toMap(): Map<String, Any> {
        return mapOf(
            "message" to message,
            "type" to type.name,
            "cause" to (cause ?: "")
        )
    }

    // ========== UTILITY METHODS ==========

    /**
     * Send event to Flutter on main thread
     */
    private fun sendEvent(sink: EventChannel.EventSink?, data: Map<String, Any?>) {
        mainHandler.post {
            sink?.success(data)
        }
    }

    // ========== STREAM HANDLERS ==========

    private val scanStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            scanEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            scanEventSink = null
        }
    }

    private val connectionStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            connectionEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            connectionEventSink = null
        }
    }

    private val inventoryStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            inventoryEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            inventoryEventSink = null
        }
    }

    private val geigerStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            geigerEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            geigerEventSink = null
        }
    }

    private val barcodeStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            barcodeEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            barcodeEventSink = null
        }
    }

    private val batteryStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            batteryEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            batteryEventSink = null
        }
    }

    private val triggerStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            triggerEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            triggerEventSink = null
        }
    }

    private val configStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            configEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            configEventSink = null
        }
    }
}
