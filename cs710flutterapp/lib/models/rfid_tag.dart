/// Represents an RFID tag read during inventory operations
class RfidTag {
  final String epc;
  final double rssi;
  final int count;
  final int timestamp;
  final int phase;
  final int channel;

  const RfidTag({
    required this.epc,
    required this.rssi,
    required this.count,
    required this.timestamp,
    required this.phase,
    required this.channel,
  });

  /// Create RfidTag from platform channel map
  factory RfidTag.fromMap(Map<String, dynamic> map) {
    return RfidTag(
      epc: map['epc'] as String,
      rssi: (map['rssi'] as num).toDouble(),
      count: map['count'] as int,
      timestamp: map['timestamp'] as int,
      phase: map['phase'] as int,
      channel: map['channel'] as int,
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'epc': epc,
      'rssi': rssi,
      'count': count,
      'timestamp': timestamp,
      'phase': phase,
      'channel': channel,
    };
  }

  /// Create a copy with updated count
  RfidTag copyWith({
    String? epc,
    double? rssi,
    int? count,
    int? timestamp,
    int? phase,
    int? channel,
  }) {
    return RfidTag(
      epc: epc ?? this.epc,
      rssi: rssi ?? this.rssi,
      count: count ?? this.count,
      timestamp: timestamp ?? this.timestamp,
      phase: phase ?? this.phase,
      channel: channel ?? this.channel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RfidTag && runtimeType == other.runtimeType && epc == other.epc;

  @override
  int get hashCode => epc.hashCode;

  @override
  String toString() => 'RfidTag(epc: $epc, rssi: $rssi, count: $count)';
}
