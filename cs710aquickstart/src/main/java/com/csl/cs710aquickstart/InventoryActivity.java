package com.csl.cs710aquickstart;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.RecyclerView;

import com.csl.cs710aquickstart.adapters.ScanItemAdapter;
import com.csl.cs710aquickstart.models.ScanItem;
import com.csl.cs710aquickstart.viewmodels.InventoryViewModel;
import com.csl.rfidsdk.callbacks.RfidConfigurationCallback;
import com.csl.rfidsdk.config.RfidInventoryMode;
import com.csl.rfidsdk.config.RfidTarget;
import com.csl.rfidsdk.models.RfidError;

/**
 * Activity for RFID tag inventory and barcode scanning
 */
public class InventoryActivity extends AppCompatActivity {
    private InventoryViewModel viewModel;
    private ScanItemAdapter adapter;
    private Button btnInventory;
    private Button btnClear;
    private TextView textStats;
    private TextView textEmpty;
    private TextView textModeLabel;
    private SwitchCompat switchScanMode;
    private RecyclerView recyclerViewTags;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_inventory);

        // Setup ViewModel
        viewModel = new ViewModelProvider(this).get(InventoryViewModel.class);

        // Setup views
        btnInventory = findViewById(R.id.btnInventory);
        btnClear = findViewById(R.id.btnClear);
        textStats = findViewById(R.id.textStats);
        textEmpty = findViewById(R.id.textEmpty);
        textModeLabel = findViewById(R.id.textModeLabel);
        switchScanMode = findViewById(R.id.switchScanMode);
        recyclerViewTags = findViewById(R.id.recyclerViewTags);

        // Setup RecyclerView
        adapter = new ScanItemAdapter(this::onItemClick);
        recyclerViewTags.setAdapter(adapter);

        // Apply configuration if connected
        if (viewModel.getRfidManager().isConnected()) {
            applyReaderConfiguration();
        }

        // Observe items (both RFID and Barcode)
        viewModel.getItems().observe(this, items -> {
            adapter.submitList(items);
            if (items.isEmpty()) {
                textEmpty.setVisibility(View.VISIBLE);
                recyclerViewTags.setVisibility(View.GONE);
            } else {
                textEmpty.setVisibility(View.GONE);
                recyclerViewTags.setVisibility(View.VISIBLE);
            }
        });

        // Observe stats (now formatted as string)
        viewModel.getStatsText().observe(this, statsText -> {
            if (statsText != null && !statsText.isEmpty()) {
                textStats.setText(statsText);
            } else {
                textStats.setText("");
            }
        });

        // Observe scanning state
        viewModel.isScanning().observe(this, scanning -> {
            if (scanning) {
                btnInventory.setText(R.string.btn_stop_inventory);
                switchScanMode.setEnabled(false);  // Disable mode switch while scanning
            } else {
                btnInventory.setText(R.string.btn_start_inventory);
                switchScanMode.setEnabled(true);   // Enable mode switch when not scanning
            }
        });

        // Observe scan mode
        viewModel.getScanMode().observe(this, mode -> {
            boolean isBarcodeMode = (mode == InventoryViewModel.ScanMode.BARCODE);
            switchScanMode.setChecked(isBarcodeMode);
            textModeLabel.setText(isBarcodeMode ? R.string.mode_barcode : R.string.mode_rfid);
        });

        // Observe errors
        viewModel.getErrors().observe(this, error -> {
            if (error != null) {
                Toast.makeText(this, error.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });

        // Mode switch listener
        switchScanMode.setOnCheckedChangeListener((buttonView, isChecked) -> {
            InventoryViewModel.ScanMode newMode = isChecked
                    ? InventoryViewModel.ScanMode.BARCODE
                    : InventoryViewModel.ScanMode.RFID;
            viewModel.setScanMode(newMode);
        });

        // Inventory/Scan button
        btnInventory.setOnClickListener(v -> {
            Boolean scanning = viewModel.isScanning().getValue();
            if (scanning != null && scanning) {
                viewModel.stopScanning();
            } else {
                // Check if connected
                if (!viewModel.getRfidManager().isConnected()) {
                    Toast.makeText(this, R.string.error_not_connected, Toast.LENGTH_SHORT).show();
                    return;
                }
                viewModel.startScanning();
            }
        });

        // Clear button
        btnClear.setOnClickListener(v -> {
            viewModel.clearItems();
            textStats.setText("");
        });
    }

    private void onItemClick(ScanItem item) {
        // Navigate to Geiger search only for RFID tags
        if (item.isRfid()) {
            Intent intent = new Intent(this, GeigerSearchActivity.class);
            intent.putExtra("TARGET_EPC", item.getIdentifier());
            startActivity(intent);
        } else {
            // For barcodes, just show a toast with the barcode value
            Toast.makeText(this, "Barcode: " + item.getIdentifier(), Toast.LENGTH_SHORT).show();
        }
    }

    /**
     * Apply reader configuration when inventory page loads
     * Configuration as specified in rfid-wrapper-proposal.md section 3.4
     * Note: Region is not set - reader uses its hardware default region
     */
    private void applyReaderConfiguration() {
        viewModel.getRfidManager().configure()
                .powerLevel(300)                          // 30.0 dBm
                .session(1)                               // Session 1
                .target(RfidTarget.A)                     // Target A
                .inventoryMode(RfidInventoryMode.COMPACT) // Compact mode
                .qValue(7)                                // Q = 7
                .enableBeep(true)                         // Enable beep
                .enableVibrate(true)                      // Enable vibrate
                .apply(new RfidConfigurationCallback() {
                    @Override
                    public void onConfigured() {
                        Toast.makeText(InventoryActivity.this,
                                "Reader configured successfully",
                                Toast.LENGTH_SHORT).show();
                    }

                    @Override
                    public void onConfigurationFailed(RfidError error) {
                        Toast.makeText(InventoryActivity.this,
                                "Configuration failed: " + error.getMessage(),
                                Toast.LENGTH_LONG).show();
                    }
                });
    }

    @Override
    protected void onDestroy() {
        viewModel.stopScanning();
        super.onDestroy();
    }
}
