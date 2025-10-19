package com.csl.cs710aquickstart;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.RecyclerView;

import com.csl.cs710aquickstart.adapters.TagListAdapter;
import com.csl.cs710aquickstart.viewmodels.InventoryViewModel;
import com.csl.rfidsdk.models.RfidTag;

/**
 * Activity for RFID tag inventory
 */
public class InventoryActivity extends AppCompatActivity {
    private InventoryViewModel viewModel;
    private TagListAdapter adapter;
    private Button btnInventory;
    private Button btnClear;
    private TextView textStats;
    private TextView textEmpty;
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
        recyclerViewTags = findViewById(R.id.recyclerViewTags);

        // Setup RecyclerView
        adapter = new TagListAdapter(this::onTagClick);
        recyclerViewTags.setAdapter(adapter);

        // Observe tags
        viewModel.getTags().observe(this, tags -> {
            adapter.submitList(tags);
            if (tags.isEmpty()) {
                textEmpty.setVisibility(View.VISIBLE);
                recyclerViewTags.setVisibility(View.GONE);
            } else {
                textEmpty.setVisibility(View.GONE);
                recyclerViewTags.setVisibility(View.VISIBLE);
            }
        });

        // Observe stats
        viewModel.getStats().observe(this, stats -> {
            if (stats != null) {
                textStats.setText(String.format(
                        getString(R.string.stats_format),
                        stats.getUniqueTagCount(),
                        stats.getTotalReads(),
                        stats.getReadRate()
                ));
            }
        });

        // Observe inventory state
        viewModel.isInventorying().observe(this, inventorying -> {
            if (inventorying) {
                btnInventory.setText(R.string.btn_stop_inventory);
            } else {
                btnInventory.setText(R.string.btn_start_inventory);
            }
        });

        // Observe errors
        viewModel.getErrors().observe(this, error -> {
            if (error != null) {
                Toast.makeText(this, error.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });

        // Inventory button
        btnInventory.setOnClickListener(v -> {
            Boolean inventorying = viewModel.isInventorying().getValue();
            if (inventorying != null && inventorying) {
                viewModel.stopInventory();
            } else {
                // Check if connected
                if (!viewModel.getRfidManager().isConnected()) {
                    Toast.makeText(this, R.string.error_not_connected, Toast.LENGTH_SHORT).show();
                    return;
                }
                viewModel.startInventory();
            }
        });

        // Clear button
        btnClear.setOnClickListener(v -> {
            viewModel.clearTags();
            textStats.setText(String.format(getString(R.string.stats_format), 0, 0, 0.0));
        });
    }

    private void onTagClick(RfidTag tag) {
        // Navigate to Geiger search with this tag
        Intent intent = new Intent(this, GeigerSearchActivity.class);
        intent.putExtra("TARGET_EPC", tag.getEpc());
        startActivity(intent);
    }

    @Override
    protected void onDestroy() {
        viewModel.stopInventory();
        super.onDestroy();
    }
}
