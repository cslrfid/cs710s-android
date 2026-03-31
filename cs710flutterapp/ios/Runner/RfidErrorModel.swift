import Foundation
import CSL_CS710S_Library

// MARK: - RfidError Extension for JSON Serialization
extension RfidError {
    /// Convert RfidError to Dictionary for Flutter platform channel
    func toDictionary() -> [String: Any] {
        return [
            "message": message,
            "type": errorType,
            "cause": underlyingError?.localizedDescription ?? ""
        ]
    }

    /// Error type categorization for Flutter
    var errorType: String {
        switch type {
        case .CONNECTION_FAILED, .CONNECTION_LOST, .DISCONNECTED, .NOT_CONNECTED:
            return "CONNECTION_ERROR"
        case .BLUETOOTH_DISABLED, .PERMISSION_DENIED:
            return "BLUETOOTH_ERROR"
        case .SCAN_FAILED:
            return "SCAN_ERROR"
        case .INVENTORY_FAILED:
            return "INVENTORY_ERROR"
        case .CONFIGURATION_FAILED:
            return "CONFIG_ERROR"
        case .TIMEOUT:
            return "TIMEOUT_ERROR"
        case .UNKNOWN:
            return "UNKNOWN_ERROR"
        }
    }
}

// MARK: - Error Helper Functions
class RfidErrorHelper {
    /// Create a connection error dictionary
    static func connectionError(message: String) -> [String: Any] {
        return [
            "message": message,
            "type": "CONNECTION_ERROR",
            "cause": ""
        ]
    }

    /// Create a scan error dictionary
    static func scanError(message: String) -> [String: Any] {
        return [
            "message": message,
            "type": "SCAN_ERROR",
            "cause": ""
        ]
    }

    /// Create an inventory error dictionary
    static func inventoryError(message: String) -> [String: Any] {
        return [
            "message": message,
            "type": "INVENTORY_ERROR",
            "cause": ""
        ]
    }

    /// Create a configuration error dictionary
    static func configError(message: String) -> [String: Any] {
        return [
            "message": message,
            "type": "CONFIG_ERROR",
            "cause": ""
        ]
    }

    /// Create a barcode error dictionary
    static func barcodeError(message: String) -> [String: Any] {
        return [
            "message": message,
            "type": "BARCODE_ERROR",
            "cause": ""
        ]
    }

    /// Create a Geiger search error dictionary
    static func geigerError(message: String) -> [String: Any] {
        return [
            "message": message,
            "type": "GEIGER_ERROR",
            "cause": ""
        ]
    }

    /// Create a general error dictionary
    static func generalError(message: String, type: String = "RFID_ERROR") -> [String: Any] {
        return [
            "message": message,
            "type": type,
            "cause": ""
        ]
    }
}
