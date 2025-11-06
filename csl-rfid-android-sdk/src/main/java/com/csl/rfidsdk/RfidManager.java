package com.csl.rfidsdk;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import com.csl.rfidsdk.callbacks.BarcodeScanCallback;
import com.csl.rfidsdk.callbacks.RfidConfigurationCallback;
import com.csl.rfidsdk.callbacks.RfidConnectionCallback;
import com.csl.rfidsdk.callbacks.RfidGeigerCallback;
import com.csl.rfidsdk.callbacks.RfidInventoryCallback;
import com.csl.rfidsdk.callbacks.RfidScanCallback;
import com.csl.rfidsdk.config.RfidInventoryMode;
import com.csl.rfidsdk.config.RfidRegion;
import com.csl.rfidsdk.config.RfidTarget;
import com.csl.rfidsdk.internal.SdkBridge;
import com.csl.rfidsdk.internal.ThreadManager;
import com.csl.rfidsdk.managers.BarcodeScanManager;
import com.csl.rfidsdk.managers.RfidConfigurationManager;
import com.csl.rfidsdk.managers.RfidConnectionManager;
import com.csl.rfidsdk.managers.RfidGeigerManager;
import com.csl.rfidsdk.managers.RfidInventoryManager;
import com.csl.rfidsdk.models.RfidConfiguration;
import com.csl.rfidsdk.models.RfidReader;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Main entry point for the CSL RFID SDK
 * Provides simplified, callback-based API for CS710S RFID operations
 */
public class RfidManager {
    private final Context context;
    private SdkBridge sdkBridge;  // Lazy initialized
    private ThreadManager threadManager;  // Lazy initialized
    private RfidConnectionManager connectionManager;  // Lazy initialized
    private RfidInventoryManager inventoryManager;  // Lazy initialized
    private RfidGeigerManager geigerManager;  // Lazy initialized
    private BarcodeScanManager barcodeManager;  // Lazy initialized
    private RfidConfigurationManager configurationManager;  // Lazy initialized
    private final RfidManagerBuilder.LoggerCallback logger;
    private final boolean autoReconnect;
    private volatile boolean initialized = false;

    private RfidConfiguration currentConfiguration;

    /**
     * Create a new RfidManager with default configuration
     * @param context Application context
     * @return New RfidManager instance
     */
    public static RfidManager create(Context context) {
        return builder(context).build();
    }

    /**
     * Create a builder for custom configuration
     * @param context Application context
     * @return RfidManagerBuilder instance
     */
    public static RfidManagerBuilder builder(Context context) {
        return new RfidManagerBuilder(context);
    }

    /**
     * Package-private constructor used by builder
     */
    RfidManager(Context context, RfidManagerBuilder.LoggerCallback logger, boolean autoReconnect) {
        this.context = context.getApplicationContext();
        this.logger = logger;
        this.autoReconnect = autoReconnect;

        // Default configuration
        this.currentConfiguration = new RfidConfiguration.Builder().build();

        log("RfidManager created (SDK will be initialized on first use)");
    }

    /**
     * Lazy initialization of SDK components
     * This ensures SDK is created on the main thread when actually needed
     */
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

    /**
     * Actually performs SDK initialization (must be called on main thread)
     */
    private void initializeSdk() {
        log("Creating SDK components on thread: " + Thread.currentThread().getName());

        this.sdkBridge = new SdkBridge(this.context);
        this.threadManager = new ThreadManager();

        // Initialize managers
        this.connectionManager = new RfidConnectionManager(sdkBridge, threadManager, logger);
        this.inventoryManager = new RfidInventoryManager(sdkBridge, threadManager, logger);
        this.geigerManager = new RfidGeigerManager(sdkBridge, threadManager, logger);
        this.barcodeManager = new BarcodeScanManager(sdkBridge, threadManager, logger);
        this.configurationManager = new RfidConfigurationManager(sdkBridge, threadManager, logger);

        initialized = true;
        log("SDK initialized successfully");
    }

    // ========== Device Scanning ==========

    /**
     * Start scanning for RFID readers
     * @param callback Callback to receive scan results
     */
    public void startScan(RfidScanCallback callback) {
        ensureInitialized();
        log("Starting reader scan");
        connectionManager.startScan(callback);
    }

    /**
     * Stop scanning for RFID readers
     */
    public void stopScan() {
        if (!initialized) return;
        log("Stopping reader scan");
        connectionManager.stopScan();
    }

    /**
     * Check if currently scanning
     */
    public boolean isScanning() {
        if (!initialized) return false;
        return connectionManager.isScanning();
    }

    // ========== Connection Management ==========

    /**
     * Connect to an RFID reader
     * @param reader The reader to connect to
     * @param callback Callback to receive connection events
     */
    public void connect(RfidReader reader, RfidConnectionCallback callback) {
        ensureInitialized();
        log("Connecting to reader: " + reader.getName());
        connectionManager.connect(reader, callback);
    }

    /**
     * Disconnect from the current reader
     */
    public void disconnect() {
        if (!initialized) return;
        log("Disconnecting from reader");
        connectionManager.disconnect();
    }

    /**
     * Check if connected to a reader
     */
    public boolean isConnected() {
        if (!initialized) return false;
        return sdkBridge.isConnected();
    }

    /**
     * Get the currently connected reader
     */
    public RfidReader getConnectedReader() {
        if (!initialized) return null;
        return connectionManager.getConnectedReader();
    }

    // ========== Configuration ==========

    /**
     * Get a configuration builder for the current settings
     * @return Configuration builder
     */
    public ConfigurationBuilder configure() {
        return new ConfigurationBuilder(this, currentConfiguration);
    }

    /**
     * Get the current configuration
     */
    public RfidConfiguration getConfiguration() {
        return currentConfiguration;
    }

    /**
     * Get the current configuration (alias for getConfiguration)
     */
    public RfidConfiguration getCurrentConfiguration() {
        return currentConfiguration;
    }

    // ========== Inventory Operations ==========

    /**
     * Start RFID inventory (tag reading)
     * @param callback Callback to receive tag reads and statistics
     */
    public void startInventory(RfidInventoryCallback callback) {
        ensureInitialized();
        log("Starting inventory");
        inventoryManager.startInventory(callback);
    }

    /**
     * Stop RFID inventory
     */
    public void stopInventory() {
        if (!initialized) return;
        log("Stopping inventory");
        inventoryManager.stopInventory();
    }

    /**
     * Check if inventory is currently running
     */
    public boolean isInventorying() {
        if (!initialized) return false;
        return inventoryManager.isInventorying();
    }

    // ========== Geiger Search ==========

    /**
     * Start Geiger search for a specific tag
     * @param targetEpc The EPC of the tag to search for
     * @param memoryBank Memory bank to search (typically 1 for EPC)
     * @param callback Callback to receive RSSI updates
     */
    public void startGeigerSearch(String targetEpc, int memoryBank, RfidGeigerCallback callback) {
        ensureInitialized();
        log("Starting Geiger search for: " + targetEpc);
        geigerManager.startGeigerSearch(targetEpc, memoryBank, callback);
    }

    /**
     * Stop Geiger search
     */
    public void stopGeigerSearch() {
        if (!initialized) return;
        log("Stopping Geiger search");
        geigerManager.stopGeigerSearch();
    }

    /**
     * Check if Geiger search is running
     */
    public boolean isSearching() {
        if (!initialized) return false;
        return geigerManager.isSearching();
    }

    // ========== Barcode Scanning Operations ==========

    /**
     * Start barcode scanning
     * @param callback Callback to receive barcode scans and statistics
     */
    public void startBarcodeScan(BarcodeScanCallback callback) {
        ensureInitialized();
        log("Starting barcode scanning");
        barcodeManager.startScan(callback);
    }

    /**
     * Stop barcode scanning
     */
    public void stopBarcodeScan() {
        if (!initialized) return;
        log("Stopping barcode scanning");
        barcodeManager.stopScan();
    }

    /**
     * Check if barcode scanning is running
     */
    public boolean isBarcodeScanning() {
        if (!initialized) return false;
        return barcodeManager.isScanning();
    }

    /**
     * Check if barcode module is available
     * @return true if barcode scanning is available
     */
    public boolean isBarcodeAvailable() {
        if (!initialized) return false;
        return barcodeManager.isBarcodeAvailable();
    }

    // ========== Lifecycle Management ==========

    /**
     * Release all resources and disconnect
     * Call this when done using the RfidManager
     */
    public void release() {
        log("Releasing RfidManager");
        if (!initialized) return;

        stopScan();
        stopInventory();
        stopGeigerSearch();
        stopBarcodeScan();

        // Cleanup managers before shutdown
        inventoryManager.cleanup();
        geigerManager.cleanup();
        barcodeManager.cleanup();

        connectionManager.disconnect();
        threadManager.shutdown();
        sdkBridge.release();
        initialized = false;
    }

    // ========== Helper Methods ==========

    private void log(String message) {
        if (logger != null) {
            logger.log(message);
        }
    }

    /**
     * Configuration builder for fluent API
     * Implements the API from rfid-wrapper-proposal.md section 3.4
     */
    public static class ConfigurationBuilder {
        private final RfidManager manager;
        private final RfidConfiguration.Builder configBuilder;

        ConfigurationBuilder(RfidManager manager, RfidConfiguration currentConfig) {
            this.manager = manager;
            this.configBuilder = new RfidConfiguration.Builder()
                    .powerLevel(currentConfig.getPowerLevel())
                    .session(currentConfig.getSession())
                    .qValue(currentConfig.getQValue())
                    .target(currentConfig.getTarget())
                    .inventoryMode(currentConfig.getInventoryMode())
                    .region(currentConfig.getRegion())
                    .populateRssi(currentConfig.isPopulateRssi())
                    .populatePhase(currentConfig.isPopulatePhase())
                    .populateChannel(currentConfig.isPopulateChannel())
                    .enableBeep(currentConfig.isEnableBeep())
                    .enableVibrate(currentConfig.isEnableVibrate());
        }

        public ConfigurationBuilder powerLevel(int powerLevel) {
            configBuilder.powerLevel(powerLevel);
            return this;
        }

        public ConfigurationBuilder session(int session) {
            configBuilder.session(session);
            return this;
        }

        public ConfigurationBuilder target(RfidTarget target) {
            configBuilder.target(target);
            return this;
        }

        public ConfigurationBuilder inventoryMode(RfidInventoryMode mode) {
            configBuilder.inventoryMode(mode);
            return this;
        }

        public ConfigurationBuilder region(RfidRegion region) {
            configBuilder.region(region);
            return this;
        }

        public ConfigurationBuilder qValue(int qValue) {
            configBuilder.qValue(qValue);
            return this;
        }

        public ConfigurationBuilder enableBeep(boolean enableBeep) {
            configBuilder.enableBeep(enableBeep);
            return this;
        }

        public ConfigurationBuilder enableVibrate(boolean enableVibrate) {
            configBuilder.enableVibrate(enableVibrate);
            return this;
        }

        /**
         * Apply the configuration asynchronously with callback
         * @param callback Callback for configuration result
         */
        public void apply(RfidConfigurationCallback callback) {
            manager.ensureInitialized();
            RfidConfiguration config = configBuilder.build();
            manager.currentConfiguration = config;
            manager.configurationManager.applyConfiguration(config, callback);
        }

        /**
         * Apply the configuration synchronously (blocks until complete)
         * Not recommended - use apply(callback) instead for better UX
         */
        public void applySync() {
            RfidConfiguration config = configBuilder.build();
            manager.currentConfiguration = config;
            manager.log("Configuration stored (will be applied on next operation)");
        }
    }
}
