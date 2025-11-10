/// Statistics for barcode scanning operations
class BarcodeStats {
  final int totalScans;
  final int uniqueBarcodes;
  final int elapsedTimeMs;

  const BarcodeStats({
    required this.totalScans,
    required this.uniqueBarcodes,
    required this.elapsedTimeMs,
  });

  /// Create BarcodeStats from platform channel map
  factory BarcodeStats.fromMap(Map<String, dynamic> map) {
    return BarcodeStats(
      totalScans: map['totalScans'] as int,
      uniqueBarcodes: map['uniqueBarcodes'] as int,
      elapsedTimeMs: map['elapsedTimeMs'] as int,
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'totalScans': totalScans,
      'uniqueBarcodes': uniqueBarcodes,
      'elapsedTimeMs': elapsedTimeMs,
    };
  }

  /// Get elapsed time in seconds
  int get elapsedSeconds => (elapsedTimeMs / 1000).floor();

  @override
  String toString() =>
      'BarcodeStats(total: $totalScans, unique: $uniqueBarcodes)';
}
