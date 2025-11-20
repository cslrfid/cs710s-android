import Foundation
import CSL_CS710S_Library

// MARK: - RfidInventoryStats Extension for JSON Serialization
extension RfidInventoryStats {
    /// Convert RfidInventoryStats to Dictionary for Flutter platform channel
    func toDictionary() -> [String: Any] {
        return [
            "uniqueCount": uniqueTagCount,
            "totalReads": totalReads,
            "readRate": readRate,
            "elapsedTimeMs": elapsedTimeMs
        ]
    }
}

// MARK: - RfidStopReason Extension
extension RfidStopReason {
    /// Convert stop reason to string for Flutter
    var description: String {
        switch self {
        case .USER_STOPPED:
            return "USER_STOPPED"
        case .COMPLETED:
            return "COMPLETED"
        case .ERROR:
            return "ERROR"
        case .CONNECTION_LOST:
            return "CONNECTION_LOST"
        case .TIMEOUT:
            return "TIMEOUT"
        }
    }
}
