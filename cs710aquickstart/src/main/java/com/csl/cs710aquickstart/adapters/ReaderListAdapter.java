package com.csl.cs710aquickstart.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.csl.cs710aquickstart.R;
import com.csl.rfidsdk.models.RfidReader;

import java.util.ArrayList;
import java.util.List;

/**
 * Adapter for displaying RFID readers in a RecyclerView
 */
public class ReaderListAdapter extends RecyclerView.Adapter<ReaderListAdapter.ReaderViewHolder> {
    private List<RfidReader> readers = new ArrayList<>();
    private final OnReaderClickListener clickListener;

    public interface OnReaderClickListener {
        void onReaderClick(RfidReader reader);
    }

    public ReaderListAdapter(OnReaderClickListener clickListener) {
        this.clickListener = clickListener;
    }

    public void submitList(List<RfidReader> newReaders) {
        this.readers = newReaders != null ? new ArrayList<>(newReaders) : new ArrayList<>();
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public ReaderViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_reader, parent, false);
        return new ReaderViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ReaderViewHolder holder, int position) {
        RfidReader reader = readers.get(position);
        holder.bind(reader, clickListener);
    }

    @Override
    public int getItemCount() {
        return readers.size();
    }

    static class ReaderViewHolder extends RecyclerView.ViewHolder {
        private final TextView textName;
        private final TextView textAddress;
        private final TextView textRssi;

        public ReaderViewHolder(@NonNull View itemView) {
            super(itemView);
            textName = itemView.findViewById(R.id.textReaderName);
            textAddress = itemView.findViewById(R.id.textReaderAddress);
            textRssi = itemView.findViewById(R.id.textReaderRssi);
        }

        public void bind(RfidReader reader, OnReaderClickListener clickListener) {
            textName.setText(reader.getName());
            textAddress.setText(reader.getAddress());
            textRssi.setText(String.format("Signal: %d", reader.getRssi()));

            itemView.setOnClickListener(v -> {
                if (clickListener != null) {
                    clickListener.onReaderClick(reader);
                }
            });
        }
    }
}
