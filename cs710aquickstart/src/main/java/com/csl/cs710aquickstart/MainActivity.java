package com.csl.cs710aquickstart;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.csl.rfidsdk.RfidManager;
import com.csl.rfidsdk.callbacks.BatteryCallback;
import com.csl.rfidsdk.models.BatteryInfo;

/**
 * Main activity with navigation to three core features
 */
public class MainActivity extends AppCompatActivity {
    private static final int PERMISSION_REQUEST_CODE = 100;
    private TextView textBattery;
    private RfidManager rfidManager;

    private final BatteryCallback batteryCallback = new BatteryCallback() {
        @Override
        public void onBatteryUpdate(BatteryInfo batteryInfo) {
            if (textBattery != null && batteryInfo != null) {
                textBattery.setText(String.format("Battery: %d%%", batteryInfo.getPercentage()));
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Get shared RfidManager
        rfidManager = QuickStartApplication.getRfidManager();

        // Setup battery display
        textBattery = findViewById(R.id.textBattery);

        // Check and request permissions
        if (!hasRequiredPermissions()) {
            requestPermissions();
        }

        // Setup navigation buttons
        findViewById(R.id.btnScanReaders).setOnClickListener(v -> {
            if (hasRequiredPermissions()) {
                startActivity(new Intent(this, ScanActivity.class));
            } else {
                Toast.makeText(this, R.string.error_no_permission, Toast.LENGTH_SHORT).show();
            }
        });

        findViewById(R.id.btnInventory).setOnClickListener(v -> {
            if (hasRequiredPermissions()) {
                startActivity(new Intent(this, InventoryActivity.class));
            } else {
                Toast.makeText(this, R.string.error_no_permission, Toast.LENGTH_SHORT).show();
            }
        });

        findViewById(R.id.btnGeigerSearch).setOnClickListener(v -> {
            if (hasRequiredPermissions()) {
                startActivity(new Intent(this, GeigerSearchActivity.class));
            } else {
                Toast.makeText(this, R.string.error_no_permission, Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateBatteryDisplay();
    }

    @Override
    protected void onPause() {
        super.onPause();
        // Stop battery monitoring when MainActivity is not visible
        if (rfidManager != null) {
            rfidManager.stopBatteryMonitoring();
        }
    }

    private void updateBatteryDisplay() {
        if (rfidManager != null && rfidManager.isConnected()) {
            // Start battery monitoring when connected
            rfidManager.startBatteryMonitoring(batteryCallback);
            textBattery.setText("Battery: --");  // Will update on first poll
        } else {
            textBattery.setText("Not Connected");
        }
    }

    private boolean hasRequiredPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+
            return ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        } else {
            // Android 11 and below
            return ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        }
    }

    private void requestPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(this,
                    new String[]{
                            Manifest.permission.BLUETOOTH_SCAN,
                            Manifest.permission.BLUETOOTH_CONNECT,
                            Manifest.permission.ACCESS_FINE_LOCATION
                    },
                    PERMISSION_REQUEST_CODE);
        } else {
            ActivityCompat.requestPermissions(this,
                    new String[]{
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.BLUETOOTH,
                            Manifest.permission.BLUETOOTH_ADMIN
                    },
                    PERMISSION_REQUEST_CODE);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_REQUEST_CODE) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (!allGranted) {
                Toast.makeText(this, R.string.error_no_permission, Toast.LENGTH_LONG).show();
            }
        }
    }
}
