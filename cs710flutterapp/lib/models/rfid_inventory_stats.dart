/// Statistics for RFID inventory operations
class RfidInventoryStats {
  final int uniqueTagCount;
  final int totalReads;
  final double readRate; // tags per second
  final int elapsedTimeMs;

  const RfidInventoryStats({
    required this.uniqueTagCount,
    required this.totalReads,
    required this.readRate,
    required this.elapsedTimeMs,
  });

  /// Create RfidInventoryStats from platform channel map
  factory RfidInventoryStats.fromMap(Map<String, dynamic> map) {
    return RfidInventoryStats(
      uniqueTagCount: map['uniqueTagCount'] as int,
      totalReads: map['totalReads'] as int,
      readRate: (map['readRate'] as num).toDouble(),
      elapsedTimeMs: map['elapsedTimeMs'] as int,
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'uniqueTagCount': uniqueTagCount,
      'totalReads': totalReads,
      'readRate': readRate,
      'elapsedTimeMs': elapsedTimeMs,
    };
  }

  /// Get elapsed time in seconds
  int get elapsedSeconds => (elapsedTimeMs / 1000).floor();

  @override
  String toString() =>
      'RfidInventoryStats(unique: $uniqueTagCount, total: $totalReads, rate: $readRate tags/s)';
}
