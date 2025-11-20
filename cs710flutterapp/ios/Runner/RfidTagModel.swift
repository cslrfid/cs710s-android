import Foundation
import CSL_CS710S_Library

// MARK: - RfidTag Extension for JSON Serialization
extension RfidTag {
    /// Convert RfidTag to Dictionary for Flutter platform channel
    func toDictionary() -> [String: Any] {
        // Convert TimeInterval to ISO8601 string
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = ISO8601DateFormatter()

        return [
            "epc": epc,
            "rssi": rssi,
            "count": count,
            "timestamp": formatter.string(from: date),
            "phase": phase,
            "channel": channel
        ]
    }
}

// MARK: - Tag Storage (for accumulating tags)
class TagStorage {
    private var tags: [String: RfidTag] = [:]

    /// Add or update a tag
    func addOrUpdate(_ tag: RfidTag) {
        if let existing = tags[tag.epc] {
            // Create updated tag with incremented count and new RSSI
            let updatedTag = existing.withUpdatedRead(
                rssi: tag.rssi,
                count: existing.count + 1
            )
            tags[tag.epc] = updatedTag
        } else {
            tags[tag.epc] = tag
        }
    }

    /// Get all tags as array
    func getAllTags() -> [RfidTag] {
        return Array(tags.values)
    }

    /// Clear all tags
    func clear() {
        tags.removeAll()
    }

    /// Get unique tag count
    var uniqueCount: Int {
        return tags.count
    }

    /// Get total reads
    var totalReads: Int {
        return tags.values.reduce(0) { $0 + $1.count }
    }
}
