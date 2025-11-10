/// RFID reader configuration settings
class RfidConfiguration {
  final int powerLevel; // 0-320 (0.0-32.0 dBm)
  final int session; // 0-3
  final int qValue; // 0-15
  final String target; // "A", "B", "AB_FLIP"
  final String inventoryMode; // "STANDARD", "COMPACT"
  final String region; // "FCC", "ETSI", "CN", etc.
  final bool enableBeep;
  final bool enableVibrate;

  const RfidConfiguration({
    required this.powerLevel,
    required this.session,
    required this.qValue,
    required this.target,
    required this.inventoryMode,
    required this.region,
    required this.enableBeep,
    required this.enableVibrate,
  });

  /// Create default configuration (matches cs710aquickstart defaults)
  factory RfidConfiguration.defaultConfig() {
    return const RfidConfiguration(
      powerLevel: 300, // 30.0 dBm
      session: 1,
      qValue: 7,
      target: 'A',
      inventoryMode: 'COMPACT',
      region: 'FCC',
      enableBeep: true,
      enableVibrate: true,
    );
  }

  /// Create RfidConfiguration from platform channel map
  factory RfidConfiguration.fromMap(Map<String, dynamic> map) {
    return RfidConfiguration(
      powerLevel: map['powerLevel'] as int,
      session: map['session'] as int,
      qValue: map['qValue'] as int,
      target: map['target'] as String,
      inventoryMode: map['inventoryMode'] as String,
      region: map['region'] as String,
      enableBeep: map['enableBeep'] as bool,
      enableVibrate: map['enableVibrate'] as bool,
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'powerLevel': powerLevel,
      'session': session,
      'qValue': qValue,
      'target': target,
      'inventoryMode': inventoryMode,
      'region': region,
      'enableBeep': enableBeep,
      'enableVibrate': enableVibrate,
    };
  }

  /// Get power level in dBm (e.g., 300 -> 30.0)
  double get powerDbm => powerLevel / 10.0;

  @override
  String toString() =>
      'RfidConfiguration(power: ${powerDbm}dBm, session: $session, target: $target)';
}
