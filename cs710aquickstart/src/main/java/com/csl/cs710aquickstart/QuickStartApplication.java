package com.csl.cs710aquickstart;

import android.app.Application;

import com.csl.rfidsdk.RfidManager;

/**
 * Application class that holds a single shared RfidManager instance
 * This ensures the SDK connection persists across activity transitions
 */
public class QuickStartApplication extends Application {
    private static RfidManager rfidManager;

    @Override
    public void onCreate() {
        super.onCreate();
        // Create single shared RfidManager instance
        rfidManager = RfidManager.create(this);
    }

    /**
     * Get the shared RfidManager instance
     * This allows all activities/viewmodels to use the same SDK connection
     */
    public static RfidManager getRfidManager() {
        return rfidManager;
    }

    @Override
    public void onTerminate() {
        // Release RFID resources when app terminates
        if (rfidManager != null) {
            rfidManager.release();
            rfidManager = null;
        }
        super.onTerminate();
    }
}
