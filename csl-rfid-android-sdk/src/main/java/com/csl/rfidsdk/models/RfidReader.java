package com.csl.rfidsdk.models;

import android.bluetooth.BluetoothDevice;

/**
 * Represents an RFID reader device
 */
public class RfidReader {
    private final String name;
    private final String address;
    private final int rssi;
    private final BluetoothDevice bluetoothDevice;

    public RfidReader(String name, String address, int rssi, BluetoothDevice bluetoothDevice) {
        this.name = name;
        this.address = address;
        this.rssi = rssi;
        this.bluetoothDevice = bluetoothDevice;
    }

    public String getName() {
        return name;
    }

    public String getAddress() {
        return address;
    }

    public int getRssi() {
        return rssi;
    }

    public BluetoothDevice getBluetoothDevice() {
        return bluetoothDevice;
    }

    /**
     * Create a new RfidReader with updated RSSI
     */
    public RfidReader withRssi(int newRssi) {
        return new RfidReader(name, address, newRssi, bluetoothDevice);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        RfidReader that = (RfidReader) o;
        return address != null ? address.equals(that.address) : that.address == null;
    }

    @Override
    public int hashCode() {
        return address != null ? address.hashCode() : 0;
    }

    @Override
    public String toString() {
        return "RfidReader{" +
                "name='" + name + '\'' +
                ", address='" + address + '\'' +
                ", rssi=" + rssi +
                '}';
    }
}
