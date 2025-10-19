package com.csl.cs710aquickstart.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.csl.cs710aquickstart.R;
import com.csl.rfidsdk.models.RfidTag;

import java.util.ArrayList;
import java.util.List;

/**
 * Adapter for displaying RFID tags in a RecyclerView
 */
public class TagListAdapter extends RecyclerView.Adapter<TagListAdapter.TagViewHolder> {
    private List<RfidTag> tags = new ArrayList<>();
    private final OnTagClickListener clickListener;

    public interface OnTagClickListener {
        void onTagClick(RfidTag tag);
    }

    public TagListAdapter(OnTagClickListener clickListener) {
        this.clickListener = clickListener;
    }

    public void submitList(List<RfidTag> newTags) {
        this.tags = newTags != null ? new ArrayList<>(newTags) : new ArrayList<>();
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public TagViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_tag, parent, false);
        return new TagViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull TagViewHolder holder, int position) {
        RfidTag tag = tags.get(position);
        holder.bind(tag, clickListener);
    }

    @Override
    public int getItemCount() {
        return tags.size();
    }

    static class TagViewHolder extends RecyclerView.ViewHolder {
        private final TextView textEpc;
        private final TextView textRssi;
        private final TextView textCount;

        public TagViewHolder(@NonNull View itemView) {
            super(itemView);
            textEpc = itemView.findViewById(R.id.textTagEpc);
            textRssi = itemView.findViewById(R.id.textTagRssi);
            textCount = itemView.findViewById(R.id.textTagCount);
        }

        public void bind(RfidTag tag, OnTagClickListener clickListener) {
            textEpc.setText(tag.getEpc());
            textRssi.setText(String.format("%.1f dBm", tag.getRssi()));
            textCount.setText(String.format("Count: %d", tag.getCount()));

            itemView.setOnClickListener(v -> {
                if (clickListener != null) {
                    clickListener.onTagClick(tag);
                }
            });
        }
    }
}
