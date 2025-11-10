import 'package:flutter/services.dart';

/// Service for handling Android runtime permissions
/// Required permissions:
/// - Android 12+: BLUETOOTH_SCAN, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION
/// - Android 11-: ACCESS_FINE_LOCATION, BLUETOOTH, BLUETOOTH_ADMIN
class PermissionService {
  static const _channel = MethodChannel('com.csl.rfid/permissions');

  /// Check if all required permissions are granted
  Future<bool> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking permissions: ${e.message}');
      return false;
    }
  }

  /// Request required permissions
  /// Returns true if all permissions were granted
  Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error requesting permissions: ${e.message}');
      return false;
    }
  }

  /// Check and request permissions if not granted
  /// Returns true if permissions are granted (either already had them or user granted them)
  Future<bool> ensurePermissions() async {
    final hasPermissions = await checkPermissions();
    if (hasPermissions) {
      return true;
    }
    return await requestPermissions();
  }
}
