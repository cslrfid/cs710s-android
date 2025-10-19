package com.csl.cs710aquickstart;

import android.media.MediaPlayer;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;

import com.csl.cs710aquickstart.viewmodels.GeigerViewModel;

/**
 * Activity for Geiger search (tag locating)
 */
public class GeigerSearchActivity extends AppCompatActivity {
    private GeigerViewModel viewModel;
    private EditText editTargetEpc;
    private Button btnSearch;
    private ProgressBar progressProximity;
    private TextView textRssi;
    private TextView textStats;
    private CheckBox checkBoxBeep;
    private SeekBar seekbarThreshold;
    private TextView textThreshold;

    private MediaPlayer beepPlayer;
    private Handler beepHandler = new Handler(Looper.getMainLooper());
    private Runnable beepRunnable;
    private int currentBeepInterval = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_geiger);

        // Setup ViewModel
        viewModel = new ViewModelProvider(this).get(GeigerViewModel.class);

        // Setup views
        editTargetEpc = findViewById(R.id.editTargetEpc);
        btnSearch = findViewById(R.id.btnSearch);
        progressProximity = findViewById(R.id.progressProximity);
        textRssi = findViewById(R.id.textRssi);
        textStats = findViewById(R.id.textStats);
        checkBoxBeep = findViewById(R.id.checkBoxBeep);
        seekbarThreshold = findViewById(R.id.seekbarThreshold);
        textThreshold = findViewById(R.id.textThreshold);

        // Get target EPC from intent (if launched from InventoryActivity)
        String targetEpc = getIntent().getStringExtra("TARGET_EPC");
        if (targetEpc != null) {
            editTargetEpc.setText(targetEpc);
        }

        // Setup beep player (use a simple tone generator since we don't have audio file)
        // In a real implementation, add beep_tone.wav to res/raw/
        // beepPlayer = MediaPlayer.create(this, R.raw.beep_tone);

        // Observe Geiger stats
        viewModel.getGeigerStats().observe(this, stats -> {
            if (stats != null) {
                // Update progress
                double proximity = stats.getProximityLevel();
                progressProximity.setProgress((int) (proximity * 100));

                // Update RSSI
                textRssi.setText(String.format("%.1f dBm", stats.getCurrentRssi()));

                // Update stats
                textStats.setText(String.format(
                        getString(R.string.geiger_stats_format),
                        stats.getReadCount(),
                        stats.getReadRate(),
                        stats.getPeakRssi()
                ));

                // Handle beeping
                if (checkBoxBeep.isChecked()) {
                    updateBeeping(stats.getCurrentRssi(), seekbarThreshold.getProgress());
                }
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
                stopBeeping();
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

        // Threshold seekbar
        seekbarThreshold.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                textThreshold.setText(String.format("%d dBm", progress - 90));
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
            }
        });

        // Initialize threshold display
        textThreshold.setText(String.format("%d dBm", seekbarThreshold.getProgress() - 90));
    }

    private void updateBeeping(double rssi, int thresholdProgress) {
        int threshold = thresholdProgress - 90; // Convert to dBm

        if (rssi < threshold) {
            stopBeeping();
            return;
        }

        // Calculate beep interval based on RSSI
        // Higher RSSI = faster beeping
        int interval;
        if (rssi >= -20) {
            interval = 50;       // Very close - continuous
        } else if (rssi >= -30) {
            interval = 250;      // Close - fast
        } else if (rssi >= -40) {
            interval = 500;      // Medium - moderate
        } else if (rssi >= -50) {
            interval = 1000;     // Far - slow
        } else {
            interval = 2000;     // Very far - very slow
        }

        // Only update if interval changed
        if (interval != currentBeepInterval) {
            currentBeepInterval = interval;
            stopBeeping();
            startBeeping(interval);
        }
    }

    private void startBeeping(int interval) {
        beepRunnable = new Runnable() {
            @Override
            public void run() {
                // Play beep sound
                if (beepPlayer != null) {
                    beepPlayer.seekTo(0);
                    beepPlayer.start();
                } else {
                    // Fallback: use system sound if MediaPlayer not available
                    // You could use ToneGenerator here
                }

                beepHandler.postDelayed(this, interval);
            }
        };
        beepHandler.post(beepRunnable);
    }

    private void stopBeeping() {
        currentBeepInterval = 0;
        if (beepRunnable != null) {
            beepHandler.removeCallbacks(beepRunnable);
            beepRunnable = null;
        }
        if (beepPlayer != null && beepPlayer.isPlaying()) {
            beepPlayer.pause();
        }
    }

    @Override
    protected void onDestroy() {
        stopBeeping();
        if (beepPlayer != null) {
            beepPlayer.release();
            beepPlayer = null;
        }
        viewModel.stopSearch();
        super.onDestroy();
    }
}
