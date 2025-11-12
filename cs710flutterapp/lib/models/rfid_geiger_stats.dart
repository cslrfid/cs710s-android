/// Statistics for Geiger search (tag locating) operations
class RfidGeigerStats {
  final String targetEpc;
  final double currentRssi;
  final double peakRssi;
  final int readCount;
  final int proximity; // 0-100%
  final int elapsedTimeMs;

  const RfidGeigerStats({
    required this.targetEpc,
    required this.currentRssi,
    required this.peakRssi,
    required this.readCount,
    required this.proximity,
    required this.elapsedTimeMs,
  });

  /// Create RfidGeigerStats from platform channel map
  factory RfidGeigerStats.fromMap(Map<String, dynamic> map) {
    return RfidGeigerStats(
      targetEpc: map['targetEpc'] as String,
      currentRssi: (map['currentRssi'] as num).toDouble(),
      peakRssi: (map['peakRssi'] as num).toDouble(),
      readCount: map['readCount'] as int,
      proximity: map['proximity'] as int,
      elapsedTimeMs: map['elapsedTimeMs'] as int,
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'targetEpc': targetEpc,
      'currentRssi': currentRssi,
      'peakRssi': peakRssi,
      'readCount': readCount,
      'proximity': proximity,
      'elapsedTimeMs': elapsedTimeMs,
    };
  }

  /// Get elapsed time in seconds
  int get elapsedSeconds => (elapsedTimeMs / 1000).floor();

  @override
  String toString() =>
      'RfidGeigerStats(epc: $targetEpc, rssi: $currentRssi, proximity: $proximity%)';
}
