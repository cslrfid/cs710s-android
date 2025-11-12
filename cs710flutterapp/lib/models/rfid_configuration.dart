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

  /// Create a builder for fluent configuration
  static RfidConfigurationBuilder builder() {
    return RfidConfigurationBuilder();
  }

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

/// Builder for RfidConfiguration with fluent API
/// Usage: RfidConfiguration.builder()
///           .powerLevel(300)
///           .session(1)
///           .build()
class RfidConfigurationBuilder {
  int _powerLevel = 300; // Default 30.0 dBm
  int _session = 1;
  int _qValue = 7;
  String _target = 'A';
  String _inventoryMode = 'COMPACT';
  String _region = 'FCC';
  bool _enableBeep = true;
  bool _enableVibrate = true;

  RfidConfigurationBuilder();

  /// Set power level (0-320, representing 0.0-32.0 dBm)
  RfidConfigurationBuilder powerLevel(int value) {
    _powerLevel = value;
    return this;
  }

  /// Set session (0-3)
  RfidConfigurationBuilder session(int value) {
    _session = value;
    return this;
  }

  /// Set Q value (0-15)
  RfidConfigurationBuilder qValue(int value) {
    _qValue = value;
    return this;
  }

  /// Set target ("A", "B", "AB_FLIP")
  RfidConfigurationBuilder target(String value) {
    _target = value;
    return this;
  }

  /// Set inventory mode ("STANDARD", "COMPACT")
  RfidConfigurationBuilder inventoryMode(String value) {
    _inventoryMode = value;
    return this;
  }

  /// Set region ("FCC", "ETSI", "CN", etc.)
  RfidConfigurationBuilder region(String value) {
    _region = value;
    return this;
  }

  /// Enable or disable beep
  RfidConfigurationBuilder enableBeep(bool value) {
    _enableBeep = value;
    return this;
  }

  /// Enable or disable vibrate
  RfidConfigurationBuilder enableVibrate(bool value) {
    _enableVibrate = value;
    return this;
  }

  /// Build the configuration
  RfidConfiguration build() {
    return RfidConfiguration(
      powerLevel: _powerLevel,
      session: _session,
      qValue: _qValue,
      target: _target,
      inventoryMode: _inventoryMode,
      region: _region,
      enableBeep: _enableBeep,
      enableVibrate: _enableVibrate,
    );
  }
}
