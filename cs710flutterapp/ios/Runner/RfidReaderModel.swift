import Foundation
import CSL_CS710S_Library

// MARK: - RfidReader Extension for JSON Serialization
extension RfidReader {
    /// Convert RfidReader to Dictionary for Flutter platform channel
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "address": address,
            "rssi": rssi,
            "serviceUUID": 0  // Not available in iOS SDK
        ]
    }

    /// Create a detailed reader info dictionary with connection metadata
    func toDetailedDictionary(firmwareVersion: String? = nil, model: String? = nil) -> [String: Any] {
        var dict = toDictionary()

        if let firmware = firmwareVersion {
            dict["firmwareVersion"] = firmware
        }

        if let modelName = model {
            dict["model"] = modelName
        } else {
            dict["model"] = "CS710S"  // Default model
        }

        return dict
    }
}

// MARK: - Reader Connection State
enum ReaderConnectionState {
    case disconnected
    case connecting
    case connected
    case ready
    case error(String)

    var description: String {
        switch self {
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .ready: return "ready"
        case .error(let message): return "error: \(message)"
        }
    }
}
