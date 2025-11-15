package com.csl.cs710aquickstart.viewmodels;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import com.csl.cs710aquickstart.QuickStartApplication;
import com.csl.rfidsdk.RfidManager;
import com.csl.rfidsdk.callbacks.RfidConnectionCallback;
import com.csl.rfidsdk.callbacks.RfidScanCallback;
import com.csl.rfidsdk.models.RfidError;
import com.csl.rfidsdk.models.RfidReader;

import java.util.ArrayList;
import java.util.List;

/**
 * ViewModel for device scanning and connection
 */
public class ScanViewModel extends AndroidViewModel {
    private final RfidManager rfidManager;
    private final MutableLiveData<List<RfidReader>> readersLiveData = new MutableLiveData<>(new ArrayList<>());
    private final MutableLiveData<Boolean> scanningLiveData = new MutableLiveData<>(false);
    private final MutableLiveData<RfidError> errorLiveData = new MutableLiveData<>();
    private final MutableLiveData<ConnectionState> connectionStateLiveData = new MutableLiveData<>(ConnectionState.DISCONNECTED);

    public enum ConnectionState {
        DISCONNECTED,
        CONNECTING,
        CONNECTED,      // BLE connected
        INITIALIZING,   // Waiting for reader to be ready
        READY           // Fully initialized and ready
    }

    public ScanViewModel(@NonNull Application application) {
        super(application);
        // Use shared RfidManager instance from Application
        rfidManager = QuickStartApplication.getRfidManager();
    }

    public LiveData<List<RfidReader>> getReaders() {
        return readersLiveData;
    }

    public LiveData<Boolean> isScanning() {
        return scanningLiveData;
    }

    public LiveData<RfidError> getErrors() {
        return errorLiveData;
    }

    public LiveData<ConnectionState> getConnectionState() {
        return connectionStateLiveData;
    }

    public void startScan() {
        List<RfidReader> readers = new ArrayList<>();

        rfidManager.startScan(new RfidScanCallback() {
            @Override
            public void onReaderDiscovered(RfidReader reader) {
                readers.add(reader);
                readersLiveData.postValue(new ArrayList<>(readers));
            }

            @Override
            public void onReaderUpdated(RfidReader reader) {
                int index = -1;
                for (int i = 0; i < readers.size(); i++) {
                    if (readers.get(i).getAddress().equals(reader.getAddress())) {
                        index = i;
                        break;
                    }
                }
                if (index >= 0) {
                    readers.set(index, reader);
                    readersLiveData.postValue(new ArrayList<>(readers));
                }
            }

            @Override
            public void onScanError(RfidError error) {
                errorLiveData.postValue(error);
                scanningLiveData.postValue(false);
            }
        });

        scanningLiveData.postValue(true);
    }

    public void stopScan() {
        rfidManager.stopScan();
        scanningLiveData.postValue(false);
    }

    public void connect(RfidReader reader) {
        connectionStateLiveData.postValue(ConnectionState.CONNECTING);

        rfidManager.connect(reader, new RfidConnectionCallback() {
            @Override
            public void onConnecting() {
                connectionStateLiveData.postValue(ConnectionState.CONNECTING);
            }

            @Override
            public void onConnected(RfidReader connectedReader) {
                connectionStateLiveData.postValue(ConnectionState.INITIALIZING);
            }

            @Override
            public void onReaderReady(RfidReader reader) {
                connectionStateLiveData.postValue(ConnectionState.READY);
            }

            @Override
            public void onConnectionFailed(RfidError error) {
                errorLiveData.postValue(error);
                connectionStateLiveData.postValue(ConnectionState.DISCONNECTED);
            }

            @Override
            public void onDisconnected(RfidReader reader, RfidError error) {
                if (error != null) {
                    errorLiveData.postValue(error);
                }
                connectionStateLiveData.postValue(ConnectionState.DISCONNECTED);
            }
        });
    }

    public void disconnect() {
        rfidManager.disconnect();
        connectionStateLiveData.postValue(ConnectionState.DISCONNECTED);
    }

    public RfidReader getConnectedReader() {
        return rfidManager.getConnectedReader();
    }

    public RfidManager getRfidManager() {
        return rfidManager;
    }

    @Override
    protected void onCleared() {
        // Don't release the shared RfidManager - it's managed by the Application
        // Just stop any ongoing operations
        stopScan();
        super.onCleared();
    }
}
