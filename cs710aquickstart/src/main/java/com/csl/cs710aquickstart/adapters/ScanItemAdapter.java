package com.csl.cs710aquickstart.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.csl.cs710aquickstart.R;
import com.csl.cs710aquickstart.models.ScanItem;

import java.util.ArrayList;
import java.util.List;

/**
 * Adapter for displaying both RFID tags and barcodes in a RecyclerView
 */
public class ScanItemAdapter extends RecyclerView.Adapter<ScanItemAdapter.ScanItemViewHolder> {
    private List<ScanItem> items = new ArrayList<>();
    private final OnItemClickListener clickListener;

    public interface OnItemClickListener {
        void onItemClick(ScanItem item);
    }

    public ScanItemAdapter(OnItemClickListener clickListener) {
        this.clickListener = clickListener;
    }

    public void submitList(List<ScanItem> newItems) {
        this.items = newItems != null ? new ArrayList<>(newItems) : new ArrayList<>();
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public ScanItemViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_scan, parent, false);
        return new ScanItemViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ScanItemViewHolder holder, int position) {
        ScanItem item = items.get(position);
        holder.bind(item, clickListener);
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    static class ScanItemViewHolder extends RecyclerView.ViewHolder {
        private final TextView textType;
        private final TextView textIdentifier;
        private final TextView textSignal;
        private final TextView textCount;

        public ScanItemViewHolder(@NonNull View itemView) {
            super(itemView);
            textType = itemView.findViewById(R.id.textScanType);
            textIdentifier = itemView.findViewById(R.id.textScanIdentifier);
            textSignal = itemView.findViewById(R.id.textScanSignal);
            textCount = itemView.findViewById(R.id.textScanCount);
        }

        public void bind(ScanItem item, OnItemClickListener clickListener) {
            // Set type indicator
            textType.setText(item.isRfid() ? "RFID" : "BARCODE");
            textType.setTextColor(item.isRfid()
                ? itemView.getContext().getColor(android.R.color.holo_blue_dark)
                : itemView.getContext().getColor(android.R.color.holo_orange_dark));

            // Set identifier (EPC or barcode)
            textIdentifier.setText(item.getIdentifier());

            // Set signal (RSSI for RFID, hidden for barcode)
            if (item.isRfid()) {
                textSignal.setVisibility(View.VISIBLE);
                textSignal.setText(String.format("Signal: %.1f", item.getRssi()));
            } else {
                textSignal.setVisibility(View.GONE);
            }

            // Set count
            textCount.setText(String.format("Count: %d", item.getCount()));

            // Set click listener
            itemView.setOnClickListener(v -> {
                if (clickListener != null) {
                    clickListener.onItemClick(item);
                }
            });
        }
    }
}
