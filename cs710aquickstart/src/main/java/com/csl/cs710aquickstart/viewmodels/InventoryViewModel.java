package com.csl.cs710aquickstart.viewmodels;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import com.csl.cs710aquickstart.QuickStartApplication;
import com.csl.rfidsdk.RfidManager;
import com.csl.rfidsdk.callbacks.RfidInventoryCallback;
import com.csl.rfidsdk.config.RfidStopReason;
import com.csl.rfidsdk.models.RfidError;
import com.csl.rfidsdk.models.RfidInventoryStats;
import com.csl.rfidsdk.models.RfidTag;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * ViewModel for RFID inventory operations
 */
public class InventoryViewModel extends AndroidViewModel {
    private final RfidManager rfidManager;
    private final MutableLiveData<List<RfidTag>> tagsLiveData = new MutableLiveData<>(new ArrayList<>());
    private final MutableLiveData<RfidInventoryStats> statsLiveData = new MutableLiveData<>();
    private final MutableLiveData<Boolean> inventoryingLiveData = new MutableLiveData<>(false);
    private final MutableLiveData<RfidError> errorLiveData = new MutableLiveData<>();
    private final Map<String, RfidTag> tagMap = new HashMap<>();

    public InventoryViewModel(@NonNull Application application) {
        super(application);
        // Use shared RfidManager instance from Application
        rfidManager = QuickStartApplication.getRfidManager();
    }

    public LiveData<List<RfidTag>> getTags() {
        return tagsLiveData;
    }

    public LiveData<RfidInventoryStats> getStats() {
        return statsLiveData;
    }

    public LiveData<Boolean> isInventorying() {
        return inventoryingLiveData;
    }

    public LiveData<RfidError> getErrors() {
        return errorLiveData;
    }

    public void startInventory() {
        rfidManager.startInventory(new RfidInventoryCallback() {
            @Override
            public void onTagRead(RfidTag tag) {
                RfidTag existing = tagMap.get(tag.getEpc());
                if (existing != null) {
                    tag = existing.withCount(existing.getCount() + 1)
                                 .withRssi(tag.getRssi());
                }
                tagMap.put(tag.getEpc(), tag);
                tagsLiveData.postValue(new ArrayList<>(tagMap.values()));
            }

            @Override
            public void onInventoryRound(RfidInventoryStats stats) {
                statsLiveData.postValue(stats);
            }

            @Override
            public void onInventoryStopped(RfidStopReason reason) {
                inventoryingLiveData.postValue(false);
            }

            @Override
            public void onInventoryError(RfidError error) {
                errorLiveData.postValue(error);
                inventoryingLiveData.postValue(false);
            }
        });

        inventoryingLiveData.postValue(true);
    }

    public void stopInventory() {
        rfidManager.stopInventory();
    }

    public void clearTags() {
        tagMap.clear();
        tagsLiveData.postValue(new ArrayList<>());
    }

    public RfidManager getRfidManager() {
        return rfidManager;
    }

    @Override
    protected void onCleared() {
        // Don't release the shared RfidManager - it's managed by the Application
        // Just stop any ongoing operations
        stopInventory();
        super.onCleared();
    }
}
