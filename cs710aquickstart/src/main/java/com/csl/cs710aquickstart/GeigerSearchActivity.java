package com.csl.cs710aquickstart;

import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;

import com.csl.cs710aquickstart.viewmodels.GeigerViewModel;
import com.csl.rfidsdk.RfidManager;
import com.csl.rfidsdk.callbacks.BatteryCallback;
import com.csl.rfidsdk.callbacks.TriggerCallback;
import com.csl.rfidsdk.models.BatteryInfo;
import com.ekn.gruzer.gaugelibrary.HalfGauge;
import com.ekn.gruzer.gaugelibrary.Range;

/**
 * Activity for Geiger search (tag locating)
 */
public class GeigerSearchActivity extends AppCompatActivity {
    private GeigerViewModel viewModel;
    private EditText editTargetEpc;
    private Button btnSearch;
    private HalfGauge halfGauge;
    private TextView textRssi;
    private TextView textStats;
    private TextView textBattery;
    private RfidManager rfidManager;

    // Timeout mechanism for RSSI reset
    private Handler timeoutHandler = new Handler(Looper.getMainLooper());
    private Runnable resetRssiRunnable;
    private static final long RSSI_TIMEOUT_MS = 2000; // 2 seconds

    private final BatteryCallback batteryCallback = new BatteryCallback() {
        @Override
        public void onBatteryUpdate(BatteryInfo batteryInfo) {
            if (textBattery != null && batteryInfo != null) {
                textBattery.setText(String.format("Battery: %d%%", batteryInfo.getPercentage()));
            }
        }
    };

    private final TriggerCallback triggerCallback = new TriggerCallback() {
        @Override
        public void onTriggerStateChanged(boolean pressed) {
            runOnUiThread(() -> {
                if (pressed) {
                    // Only click if button shows "Search" (not currently searching)
                    if (btnSearch.getText().toString().equals(getString(R.string.btn_search))) {
                        btnSearch.performClick();
                    }
                } else {
                    // Only click if button shows "Stop Search" (currently searching)
                    if (btnSearch.getText().toString().equals(getString(R.string.btn_stop_search))) {
                        btnSearch.performClick();
                    }
                }
            });
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_geiger);

        // Setup ViewModel
        viewModel = new ViewModelProvider(this).get(GeigerViewModel.class);

        // Get shared RfidManager
        rfidManager = QuickStartApplication.getRfidManager();

        // Setup views
        editTargetEpc = findViewById(R.id.editTargetEpc);
        btnSearch = findViewById(R.id.btnSearch);
        halfGauge = findViewById(R.id.halfGauge);
        textRssi = findViewById(R.id.textRssi);
        textStats = findViewById(R.id.textStats);
        textBattery = findViewById(R.id.textBattery);

        // Setup HalfGauge with RSSI range (-80 to -20 dBm)
        // Low to high: light grey -> yellow -> orange -> red
        Range greyRange = new Range();
        greyRange.setColor(Color.parseColor("#BDBDBD")); // Light grey for far
        greyRange.setFrom(0.0);
        greyRange.setTo(25.0);

        Range yellowRange = new Range();
        yellowRange.setColor(Color.parseColor("#FFEB3B")); // Yellow for medium
        yellowRange.setFrom(25.0);
        yellowRange.setTo(50.0);

        Range orangeRange = new Range();
        orangeRange.setColor(Color.parseColor("#FF9800")); // Orange for close
        orangeRange.setFrom(50.0);
        orangeRange.setTo(75.0);

        Range redRange = new Range();
        redRange.setColor(Color.parseColor("#F44336")); // Red for very close
        redRange.setFrom(75.0);
        redRange.setTo(100.0);

        halfGauge.addRange(greyRange);
        halfGauge.addRange(yellowRange);
        halfGauge.addRange(orangeRange);
        halfGauge.addRange(redRange);

        halfGauge.setMinValue(0.0);
        halfGauge.setMaxValue(100.0);
        halfGauge.setValue(0.0); // Start at minimum (far)

        // Get target EPC from intent (if launched from InventoryActivity)
        String targetEpc = getIntent().getStringExtra("TARGET_EPC");
        if (targetEpc != null) {
            editTargetEpc.setText(targetEpc);
        }

        // Setup RSSI reset runnable
        resetRssiRunnable = () -> {
            // Reset to minimum RSSI (far)
            halfGauge.setValue(0.0);
            textRssi.setText(String.format("%.1f", 0.0));
        };

        // Observe Geiger stats
        viewModel.getGeigerStats().observe(this, stats -> {
            if (stats != null) {
                // Cancel any pending reset
                timeoutHandler.removeCallbacks(resetRssiRunnable);

                // Update gauge with current RSSI (formatted to 2 decimal places)
                double currentRssi = stats.getCurrentRssi();
                halfGauge.setValue(Math.floor(stats.getProximityLevel() * 10) / 10.0);

                // Update RSSI text (also 2 decimal places)
                textRssi.setText(String.format("%.1f", currentRssi));

                // Update stats
                textStats.setText(String.format(
                        getString(R.string.geiger_stats_format),
                        stats.getReadCount(),
                        stats.getReadRate(),
                        stats.getPeakRssi()
                ));

                // Schedule RSSI reset after 2 seconds of no reads
                timeoutHandler.postDelayed(resetRssiRunnable, RSSI_TIMEOUT_MS);
            }
        });

        // Observe search state
        viewModel.isSearching().observe(this, searching -> {
            if (searching) {
                btnSearch.setText(R.string.btn_stop_search);
                editTargetEpc.setEnabled(false);
            } else {
                btnSearch.setText(R.string.btn_search);
                editTargetEpc.setEnabled(true);
                // Cancel timeout and reset when search stops
                timeoutHandler.removeCallbacks(resetRssiRunnable);
                resetRssiRunnable.run(); // Reset immediately
            }
        });

        // Observe errors
        viewModel.getErrors().observe(this, error -> {
            if (error != null) {
                Toast.makeText(this, error.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });

        // Search button
        btnSearch.setOnClickListener(v -> {
            Boolean searching = viewModel.isSearching().getValue();
            if (searching != null && searching) {
                viewModel.stopSearch();
            } else {
                String epc = editTargetEpc.getText().toString().trim();
                if (epc.isEmpty()) {
                    Toast.makeText(this, R.string.error_invalid_epc, Toast.LENGTH_SHORT).show();
                    return;
                }

                // Check if connected
                if (!viewModel.getRfidManager().isConnected()) {
                    Toast.makeText(this, R.string.error_not_connected, Toast.LENGTH_SHORT).show();
                    return;
                }

                viewModel.startSearch(epc, 1); // Memory bank 1 = EPC
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Start battery monitoring if connected
        if (rfidManager != null && rfidManager.isConnected()) {
            rfidManager.startBatteryMonitoring(batteryCallback);

            // Enable trigger key without auto-inventory (manual control for geiger search)
            // The callback will handle starting/stopping geiger search operations
            rfidManager.enableTrigger(triggerCallback, false);
        } else if (textBattery != null) {
            textBattery.setText("Not Connected");
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        // Stop battery monitoring when activity paused
        if (rfidManager != null) {
            rfidManager.stopBatteryMonitoring();
            // Disable trigger monitoring
            rfidManager.disableTrigger();
        }
    }

    @Override
    protected void onDestroy() {
        // Clean up timeout handler
        timeoutHandler.removeCallbacks(resetRssiRunnable);
        viewModel.stopSearch();
        super.onDestroy();
    }
}
