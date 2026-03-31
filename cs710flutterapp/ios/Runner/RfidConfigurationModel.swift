import Foundation
import CSL_CS710S_Library

// MARK: - RfidConfiguration Extension for JSON Serialization
extension RfidConfiguration {
    /// Convert RfidConfiguration to Dictionary for Flutter platform channel
    func toDictionary() -> [String: Any] {
        return [
            "powerLevel": powerLevel,
            "session": session,
            "target": target.rawValue,
            "qValue": qValue
        ]
    }
}
