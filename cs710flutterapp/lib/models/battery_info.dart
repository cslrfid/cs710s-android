/// Battery status information from the RFID reader
class BatteryInfo {
  final int level; // 0-100%
  final double? voltage; // Voltage in volts (e.g., 3.750)
  final bool charging; // Always false for CS710S (no charging detection)
  final int timestamp;

  const BatteryInfo({
    required this.level,
    this.voltage,
    this.charging = false,
    required this.timestamp,
  });

  /// Create BatteryInfo from platform channel map
  factory BatteryInfo.fromMap(Map<String, dynamic> map) {
    return BatteryInfo(
      level: map['level'] as int,
      voltage: map['voltage'] as double?,
      charging: map['charging'] as bool? ?? false,
      timestamp: map['timestamp'] as int,
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'voltage': voltage,
      'charging': charging,
      'timestamp': timestamp,
    };
  }

  /// Check if battery level is valid (0-100%)
  bool get isValid => level >= 0 && level <= 100;

  /// Get display string (e.g., "85%" or "85% (Charging)")
  String get displayString {
    final base = '$level%';
    return charging ? '$base (Charging)' : base;
  }

  @override
  String toString() =>
      'BatteryInfo(level: $level%, charging: $charging, timestamp: $timestamp)';
}
