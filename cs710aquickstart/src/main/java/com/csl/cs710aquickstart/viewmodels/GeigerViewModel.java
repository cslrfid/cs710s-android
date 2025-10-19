package com.csl.cs710aquickstart.viewmodels;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import com.csl.cs710aquickstart.QuickStartApplication;
import com.csl.rfidsdk.RfidManager;
import com.csl.rfidsdk.callbacks.RfidGeigerCallback;
import com.csl.rfidsdk.config.RfidStopReason;
import com.csl.rfidsdk.models.RfidError;
import com.csl.rfidsdk.models.RfidGeigerStats;

/**
 * ViewModel for Geiger search (tag locating) operations
 */
public class GeigerViewModel extends AndroidViewModel {
    private final RfidManager rfidManager;
    private final MutableLiveData<RfidGeigerStats> geigerStatsLiveData = new MutableLiveData<>();
    private final MutableLiveData<Boolean> searchingLiveData = new MutableLiveData<>(false);
    private final MutableLiveData<RfidError> errorLiveData = new MutableLiveData<>();

    public GeigerViewModel(@NonNull Application application) {
        super(application);
        // Use shared RfidManager instance from Application
        rfidManager = QuickStartApplication.getRfidManager();
    }

    public LiveData<RfidGeigerStats> getGeigerStats() {
        return geigerStatsLiveData;
    }

    public LiveData<Boolean> isSearching() {
        return searchingLiveData;
    }

    public LiveData<RfidError> getErrors() {
        return errorLiveData;
    }

    public void startSearch(String targetEpc, int memoryBank) {
        rfidManager.startGeigerSearch(targetEpc, memoryBank, new RfidGeigerCallback() {
            @Override
            public void onRssiUpdate(double rssi, RfidGeigerStats stats) {
                geigerStatsLiveData.postValue(stats);
            }

            @Override
            public void onProximityUpdate(RfidGeigerStats stats) {
                geigerStatsLiveData.postValue(stats);
            }

            @Override
            public void onSearchStarted() {
                searchingLiveData.postValue(true);
            }

            @Override
            public void onSearchStopped(RfidStopReason reason) {
                searchingLiveData.postValue(false);
            }

            @Override
            public void onSearchError(RfidError error) {
                errorLiveData.postValue(error);
                searchingLiveData.postValue(false);
            }
        });
    }

    public void stopSearch() {
        rfidManager.stopGeigerSearch();
    }

    public RfidManager getRfidManager() {
        return rfidManager;
    }

    @Override
    protected void onCleared() {
        // Don't release the shared RfidManager - it's managed by the Application
        // Just stop any ongoing operations
        stopSearch();
        super.onCleared();
    }
}
