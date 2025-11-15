/// RFID error information
class RfidError {
  final String message;
  final RfidErrorType type;
  final String? cause;

  const RfidError({
    required this.message,
    required this.type,
    this.cause,
  });

  /// Create RfidError from platform channel map
  factory RfidError.fromMap(Map<String, dynamic> map) {
    return RfidError(
      message: map['message'] as String,
      type: RfidErrorType.fromString(map['type'] as String),
      cause: map['cause'] as String?,
    );
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'type': type.toString(),
      if (cause != null) 'cause': cause,
    };
  }

  @override
  String toString() => 'RfidError($type: $message)';
}

/// Types of RFID errors
enum RfidErrorType {
  connectionFailed,
  connectionLost,
  disconnected,
  notConnected,
  scanFailed,
  inventoryFailed,
  configurationFailed,
  permissionDenied,
  bluetoothDisabled,
  timeout,
  unknown;

  /// Create error type from string
  static RfidErrorType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CONNECTION_FAILED':
        return RfidErrorType.connectionFailed;
      case 'CONNECTION_LOST':
        return RfidErrorType.connectionLost;
      case 'DISCONNECTED':
        return RfidErrorType.disconnected;
      case 'NOT_CONNECTED':
        return RfidErrorType.notConnected;
      case 'SCAN_FAILED':
        return RfidErrorType.scanFailed;
      case 'INVENTORY_FAILED':
        return RfidErrorType.inventoryFailed;
      case 'CONFIGURATION_FAILED':
        return RfidErrorType.configurationFailed;
      case 'PERMISSION_DENIED':
        return RfidErrorType.permissionDenied;
      case 'BLUETOOTH_DISABLED':
        return RfidErrorType.bluetoothDisabled;
      case 'TIMEOUT':
        return RfidErrorType.timeout;
      default:
        return RfidErrorType.unknown;
    }
  }

  @override
  String toString() {
    switch (this) {
      case RfidErrorType.connectionFailed:
        return 'CONNECTION_FAILED';
      case RfidErrorType.connectionLost:
        return 'CONNECTION_LOST';
      case RfidErrorType.disconnected:
        return 'DISCONNECTED';
      case RfidErrorType.notConnected:
        return 'NOT_CONNECTED';
      case RfidErrorType.scanFailed:
        return 'SCAN_FAILED';
      case RfidErrorType.inventoryFailed:
        return 'INVENTORY_FAILED';
      case RfidErrorType.configurationFailed:
        return 'CONFIGURATION_FAILED';
      case RfidErrorType.permissionDenied:
        return 'PERMISSION_DENIED';
      case RfidErrorType.bluetoothDisabled:
        return 'BLUETOOTH_DISABLED';
      case RfidErrorType.timeout:
        return 'TIMEOUT';
      case RfidErrorType.unknown:
        return 'UNKNOWN';
    }
  }
}
