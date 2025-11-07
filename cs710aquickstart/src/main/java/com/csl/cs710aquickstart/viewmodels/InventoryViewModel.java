package com.csl.cs710aquickstart.viewmodels;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import com.csl.cs710aquickstart.QuickStartApplication;
import com.csl.cs710aquickstart.models.ScanItem;
import com.csl.rfidsdk.RfidManager;
import com.csl.rfidsdk.callbacks.BarcodeScanCallback;
import com.csl.rfidsdk.callbacks.RfidInventoryCallback;
import com.csl.rfidsdk.config.RfidStopReason;
import com.csl.rfidsdk.models.BarcodeData;
import com.csl.rfidsdk.models.BarcodeStats;
import com.csl.rfidsdk.models.BatteryInfo;
import com.csl.rfidsdk.models.RfidError;
import com.csl.rfidsdk.models.RfidInventoryStats;
import com.csl.rfidsdk.models.RfidTag;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * ViewModel for RFID inventory and barcode scanning operations
 */
public class InventoryViewModel extends AndroidViewModel {
    public enum ScanMode {
        RFID,
        BARCODE
    }

    private final RfidManager rfidManager;
    private final MutableLiveData<List<ScanItem>> itemsLiveData = new MutableLiveData<>(new ArrayList<>());
    private final MutableLiveData<String> statsTextLiveData = new MutableLiveData<>();
    private final MutableLiveData<Boolean> scanningLiveData = new MutableLiveData<>(false);
    private final MutableLiveData<ScanMode> scanModeLiveData = new MutableLiveData<>(ScanMode.RFID);
    private final MutableLiveData<RfidError> errorLiveData = new MutableLiveData<>();
    private final MutableLiveData<BatteryInfo> batteryLiveData = new MutableLiveData<>();
    private final Map<String, ScanItem> itemMap = new HashMap<>();

    public InventoryViewModel(@NonNull Application application) {
        super(application);
        // Use shared RfidManager instance from Application
        rfidManager = QuickStartApplication.getRfidManager();
    }

    public LiveData<List<ScanItem>> getItems() {
        return itemsLiveData;
    }

    public LiveData<String> getStatsText() {
        return statsTextLiveData;
    }

    public LiveData<Boolean> isScanning() {
        return scanningLiveData;
    }

    public LiveData<ScanMode> getScanMode() {
        return scanModeLiveData;
    }

    public LiveData<RfidError> getErrors() {
        return errorLiveData;
    }

    public LiveData<BatteryInfo> getBattery() {
        return batteryLiveData;
    }

    public void setScanMode(ScanMode mode) {
        // Stop current scanning before changing mode
        stopScanning();
        scanModeLiveData.postValue(mode);
    }

    public void startScanning() {
        ScanMode mode = scanModeLiveData.getValue();
        if (mode == ScanMode.BARCODE) {
            startBarcodeScanning();
        } else {
            startRfidInventory();
        }
    }

    public void stopScanning() {
        ScanMode mode = scanModeLiveData.getValue();
        if (mode == ScanMode.BARCODE) {
            rfidManager.stopBarcodeScan();
        } else {
            rfidManager.stopInventory();
        }
    }

    private void startRfidInventory() {
        rfidManager.startInventory(new RfidInventoryCallback() {
            @Override
            public void onTagRead(RfidTag tag) {
                ScanItem item = ScanItem.fromRfidTag(tag);
                ScanItem existing = itemMap.get(item.getIdentifier());
                if (existing != null) {
                    item = existing.withCount(existing.getCount() + 1)
                                   .withRssi(item.getRssi());
                }
                itemMap.put(item.getIdentifier(), item);
                itemsLiveData.postValue(new ArrayList<>(itemMap.values()));
            }

            @Override
            public void onInventoryRound(RfidInventoryStats stats) {
                String statsText = String.format("Tags: %d | Reads: %d | Rate: %.1f/sec",
                        stats.getUniqueTagCount(), stats.getTotalReads(), stats.getReadRate());
                statsTextLiveData.postValue(statsText);
            }

            @Override
            public void onInventoryStopped(RfidStopReason reason) {
                scanningLiveData.postValue(false);
            }

            @Override
            public void onInventoryError(RfidError error) {
                errorLiveData.postValue(error);
                scanningLiveData.postValue(false);
            }

            @Override
            public void onBatteryUpdate(BatteryInfo batteryInfo) {
                batteryLiveData.postValue(batteryInfo);
            }
        });

        scanningLiveData.postValue(true);
    }

    private void startBarcodeScanning() {
        rfidManager.startBarcodeScan(new BarcodeScanCallback() {
            @Override
            public void onBarcodeScanned(BarcodeData barcode) {
                ScanItem item = ScanItem.fromBarcodeData(barcode);
                ScanItem existing = itemMap.get(item.getIdentifier());
                if (existing != null) {
                    item = existing.withCount(existing.getCount() + 1);
                }
                itemMap.put(item.getIdentifier(), item);
                itemsLiveData.postValue(new ArrayList<>(itemMap.values()));
            }

            @Override
            public void onScanUpdate(BarcodeStats stats) {
                String statsText = String.format("Barcodes: %d | Scans: %d",
                        stats.getUniqueBarcodes(), stats.getTotalScans());
                statsTextLiveData.postValue(statsText);
            }

            @Override
            public void onScanStopped(RfidStopReason reason) {
                scanningLiveData.postValue(false);
            }

            @Override
            public void onScanError(RfidError error) {
                errorLiveData.postValue(error);
                scanningLiveData.postValue(false);
            }

            @Override
            public void onBatteryUpdate(BatteryInfo batteryInfo) {
                batteryLiveData.postValue(batteryInfo);
            }
        });

        scanningLiveData.postValue(true);
    }

    public void clearItems() {
        itemMap.clear();
        itemsLiveData.postValue(new ArrayList<>());
        statsTextLiveData.postValue("");
    }

    public RfidManager getRfidManager() {
        return rfidManager;
    }

    @Override
    protected void onCleared() {
        // Don't release the shared RfidManager - it's managed by the Application
        // Just stop any ongoing operations
        stopScanning();
        super.onCleared();
    }
}
