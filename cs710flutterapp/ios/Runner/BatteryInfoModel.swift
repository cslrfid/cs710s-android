import Foundation
import CSL_CS710S_Library

// MARK: - BatteryInfo Extension for JSON Serialization
extension BatteryInfo {
    /// Convert BatteryInfo to Dictionary for Flutter platform channel
    func toDictionary() -> [String: Any] {
        let formatter = ISO8601DateFormatter()

        return [
            "level": level,              // 0-100%
            "voltage": 0.0,              // Not provided by iOS SDK
            "timestamp": formatter.string(from: Date()),
            "isCharging": isCharging     // If available
        ]
    }

    /// Create a minimal battery dictionary
    func toMinimalDictionary() -> [String: Any] {
        return [
            "level": level
        ]
    }
}

// MARK: - Battery State Manager
class BatteryState {
    private var lastBatteryInfo: BatteryInfo?
    private var isMonitoring: Bool = false

    /// Update battery info
    func update(_ info: BatteryInfo) {
        lastBatteryInfo = info
    }

    /// Get latest battery info
    func getLatest() -> BatteryInfo? {
        return lastBatteryInfo
    }

    /// Get battery level (0-100)
    var level: Int {
        return lastBatteryInfo?.level ?? 0
    }

    /// Check if charging
    var isCharging: Bool {
        return lastBatteryInfo?.isCharging ?? false
    }

    /// Start monitoring
    func startMonitoring() {
        isMonitoring = true
    }

    /// Stop monitoring
    func stopMonitoring() {
        isMonitoring = false
    }

    /// Check if monitoring is active
    var isActive: Bool {
        return isMonitoring
    }

    /// Create a battery dictionary from cached data
    func toDictionary() -> [String: Any]? {
        return lastBatteryInfo?.toDictionary()
    }
}
