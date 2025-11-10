/// Represents an RFID reader device discovered via BLE scanning
class RfidReader {
  final String name;
  final String address;
  final int rssi;
  final int serviceUUID;

  const RfidReader({
    required this.name,
    required this.address,
    required this.rssi,
    required this.serviceUUID,
  });

  /// Create RfidReader from platform channel map
  factory RfidReader.fromMap(Map<String, dynamic> map) {
    return RfidReader(
      name: map['name'] as String,
      address: map['address'] as String,
      rssi: map['rssi'] as int,
      serviceUUID: map['serviceUUID'] as int,
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'rssi': rssi,
      'serviceUUID': serviceUUID,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RfidReader &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() =>
      'RfidReader(name: $name, address: $address, rssi: $rssi)';
}
