import Foundation
import Flutter
import CoreBluetooth
import CoreLocation

/// Handles permission requests for Bluetooth and Location
class PermissionChannel: NSObject {
    private static let channelName = "com.csl.rfid/permissions"
    private var methodChannel: FlutterMethodChannel?
    private var locationManager: CLLocationManager?
    private var permissionResult: FlutterResult?

    /// Register the permission channel with Flutter
    func register(with messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(name: PermissionChannel.channelName, binaryMessenger: messenger)
        methodChannel?.setMethodCallHandler(handleMethodCall)

        // Initialize location manager
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }

    /// Handle method calls from Flutter
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkPermissions":
            result(hasRequiredPermissions())

        case "requestPermissions":
            if hasRequiredPermissions() {
                result(true)
            } else {
                permissionResult = result
                requestPermissions()
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Check if all required permissions are granted
    private func hasRequiredPermissions() -> Bool {
        // On iOS, Bluetooth permission is automatically handled by the system when BLE is accessed
        // We only need to check Location permission for BLE scanning (required on iOS 13+)

        let locationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            locationStatus = locationManager?.authorizationStatus ?? .notDetermined
        } else {
            locationStatus = CLLocationManager.authorizationStatus()
        }

        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    /// Request required permissions
    private func requestPermissions() {
        // Request location permission (required for BLE scanning on iOS 13+)
        // Bluetooth permission is requested automatically by the system when BLE is first accessed

        let locationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            locationStatus = locationManager?.authorizationStatus ?? .notDetermined
        } else {
            locationStatus = CLLocationManager.authorizationStatus()
        }

        switch locationStatus {
        case .notDetermined:
            // Request location permission
            locationManager?.requestWhenInUseAuthorization()

        case .denied, .restricted:
            // Permission previously denied
            permissionResult?(false)
            permissionResult = nil

        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized
            permissionResult?(true)
            permissionResult = nil

        @unknown default:
            permissionResult?(false)
            permissionResult = nil
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension PermissionChannel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Called when location authorization status changes
        if let result = permissionResult {
            result(hasRequiredPermissions())
            permissionResult = nil
        }
    }

    // For iOS 13 and earlier
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if let result = permissionResult {
            result(hasRequiredPermissions())
            permissionResult = nil
        }
    }
}
