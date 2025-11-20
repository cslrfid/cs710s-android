import Foundation
import CSL_CS710S_Library

// MARK: - RfidGeigerStats Extension for JSON Serialization
extension RfidGeigerStats {
    /// Convert RfidGeigerStats to Dictionary for Flutter platform channel
    /// readRate must be calculated externally by tracking previous readCount
    func toDictionary(readRate: Int = 0) -> [String: Any] {
        return [
            "targetEpc": targetEpc,
            "currentRssi": currentRssi,
            "peakRssi": peakRssi,
            "proximity": proximity,         // 0-100% (calculated by SDK)
            "readCount": readCount,
            "readRate": readRate,           // Reads per second (calculated externally)
            "elapsedTimeMs": elapsedTimeMs
        ]
    }

    /// Create a minimal stats dictionary
    func toMinimalDictionary() -> [String: Any] {
        return [
            "currentRssi": currentRssi,
            "peakRssi": peakRssi,
            "proximity": proximity,
            "readCount": readCount
        ]
    }
}

// MARK: - Geiger Search State Manager
class GeigerSearchState {
    var targetEpc: String = ""
    var isSearching: Bool = false
    var startTime: Date = Date()

    /// Calculate elapsed time in milliseconds
    var elapsedTimeMs: Int {
        return Int(Date().timeIntervalSince(startTime) * 1000)
    }

    /// Reset state for new search
    func reset(targetEpc: String) {
        self.targetEpc = targetEpc
        self.isSearching = true
        self.startTime = Date()
    }

    /// Stop search
    func stop() {
        self.isSearching = false
    }

    /// Create a zero-proximity stats dictionary (for timeout)
    func createZeroProximityStats(peakRssi: Double, readCount: Int) -> [String: Any] {
        return [
            "targetEpc": targetEpc,
            "currentRssi": 0.0,
            "peakRssi": peakRssi,
            "proximity": 0,
            "readCount": readCount,
            "readRate": 0,
            "elapsedTimeMs": elapsedTimeMs
        ]
    }
}
