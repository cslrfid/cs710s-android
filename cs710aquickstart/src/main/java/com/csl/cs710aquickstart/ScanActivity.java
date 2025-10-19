package com.csl.cs710aquickstart;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.RecyclerView;

import com.csl.cs710aquickstart.adapters.ReaderListAdapter;
import com.csl.cs710aquickstart.viewmodels.ScanViewModel;
import com.csl.rfidsdk.models.RfidReader;

/**
 * Activity for scanning and connecting to RFID readers
 */
public class ScanActivity extends AppCompatActivity {
    private ScanViewModel viewModel;
    private ReaderListAdapter adapter;
    private Button btnScan;
    private ProgressBar progressBar;
    private TextView textEmpty;
    private RecyclerView recyclerView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_scan);

        // Setup ViewModel
        viewModel = new ViewModelProvider(this).get(ScanViewModel.class);

        // Setup views
        btnScan = findViewById(R.id.btnScan);
        progressBar = findViewById(R.id.progressBar);
        textEmpty = findViewById(R.id.textEmpty);
        recyclerView = findViewById(R.id.recyclerView);

        // Setup RecyclerView
        adapter = new ReaderListAdapter(this::onReaderClick);
        recyclerView.setAdapter(adapter);

        // Observe readers
        viewModel.getReaders().observe(this, readers -> {
            adapter.submitList(readers);
            if (readers.isEmpty()) {
                textEmpty.setVisibility(View.VISIBLE);
                recyclerView.setVisibility(View.GONE);
            } else {
                textEmpty.setVisibility(View.GONE);
                recyclerView.setVisibility(View.VISIBLE);
            }
        });

        // Observe scanning state
        viewModel.isScanning().observe(this, scanning -> {
            if (scanning) {
                btnScan.setText(R.string.btn_stop_scan);
                progressBar.setVisibility(View.VISIBLE);
            } else {
                btnScan.setText(R.string.btn_start_scan);
                progressBar.setVisibility(View.GONE);
            }
        });

        // Observe errors
        viewModel.getErrors().observe(this, error -> {
            if (error != null) {
                Toast.makeText(this, error.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });

        // Observe connection state
        viewModel.getConnectionState().observe(this, state -> {
            if (state == ScanViewModel.ConnectionState.CONNECTING) {
                Toast.makeText(this, R.string.connecting, Toast.LENGTH_SHORT).show();
            } else if (state == ScanViewModel.ConnectionState.CONNECTED) {
                Toast.makeText(this, R.string.connected, Toast.LENGTH_SHORT).show();
                // Navigate to inventory
                startActivity(new Intent(this, InventoryActivity.class));
                finish();
            }
        });

        // Scan button
        btnScan.setOnClickListener(v -> {
            Boolean scanning = viewModel.isScanning().getValue();
            if (scanning != null && scanning) {
                viewModel.stopScan();
            } else {
                viewModel.startScan();
            }
        });
    }

    private void onReaderClick(RfidReader reader) {
        viewModel.stopScan();
        viewModel.connect(reader);
    }

    @Override
    protected void onDestroy() {
        viewModel.stopScan();
        super.onDestroy();
    }
}
