/// Represents a barcode scan result
class BarcodeData {
  final String barcode;
  final int timestamp;

  const BarcodeData({
    required this.barcode,
    required this.timestamp,
  });

  /// Create BarcodeData from platform channel map
  factory BarcodeData.fromMap(Map<String, dynamic> map) {
    return BarcodeData(
      barcode: map['barcode'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'timestamp': timestamp,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeData &&
          runtimeType == other.runtimeType &&
          barcode == other.barcode;

  @override
  int get hashCode => barcode.hashCode;

  @override
  String toString() => 'BarcodeData(barcode: $barcode, timestamp: $timestamp)';
}
