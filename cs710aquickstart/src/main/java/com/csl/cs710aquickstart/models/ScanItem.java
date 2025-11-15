package com.csl.cs710aquickstart.models;

import com.csl.rfidsdk.models.BarcodeData;
import com.csl.rfidsdk.models.RfidTag;

/**
 * Unified model representing either an RFID tag or a barcode scan
 * Allows displaying both types in the same RecyclerView
 */
public class ScanItem {
    public enum Type {
        RFID,
        BARCODE
    }

    private final Type type;
    private final String identifier;  // EPC for RFID, barcode string for Barcode
    private final double rssi;        // Signal for RFID, 0.0 for Barcode
    private final int count;
    private final long timestamp;

    private ScanItem(Type type, String identifier, double rssi, int count, long timestamp) {
        this.type = type;
        this.identifier = identifier;
        this.rssi = rssi;
        this.count = count;
        this.timestamp = timestamp;
    }

    /**
     * Create a ScanItem from an RFID tag
     */
    public static ScanItem fromRfidTag(RfidTag tag) {
        return new ScanItem(
                Type.RFID,
                tag.getEpc(),
                tag.getRssi(),
                tag.getCount(),
                tag.getTimestamp()
        );
    }

    /**
     * Create a ScanItem from barcode data
     */
    public static ScanItem fromBarcodeData(BarcodeData barcode) {
        return new ScanItem(
                Type.BARCODE,
                barcode.getBarcode(),
                0.0,  // No RSSI for barcodes
                barcode.getCount(),
                barcode.getTimestamp()
        );
    }

    public Type getType() {
        return type;
    }

    public String getIdentifier() {
        return identifier;
    }

    public double getRssi() {
        return rssi;
    }

    public int getCount() {
        return count;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public boolean isRfid() {
        return type == Type.RFID;
    }

    public boolean isBarcode() {
        return type == Type.BARCODE;
    }

    /**
     * Create a new ScanItem with updated count
     */
    public ScanItem withCount(int newCount) {
        return new ScanItem(type, identifier, rssi, newCount, timestamp);
    }

    /**
     * Create a new ScanItem with updated RSSI (for RFID only)
     */
    public ScanItem withRssi(double newRssi) {
        return new ScanItem(type, identifier, newRssi, count, timestamp);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ScanItem scanItem = (ScanItem) o;
        return identifier != null ? identifier.equals(scanItem.identifier) : scanItem.identifier == null;
    }

    @Override
    public int hashCode() {
        return identifier != null ? identifier.hashCode() : 0;
    }

    @Override
    public String toString() {
        return "ScanItem{" +
                "type=" + type +
                ", identifier='" + identifier + '\'' +
                ", rssi=" + rssi +
                ", count=" + count +
                '}';
    }
}
