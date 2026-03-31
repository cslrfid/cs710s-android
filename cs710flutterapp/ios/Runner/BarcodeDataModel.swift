import Foundation
import CSL_CS710S_Library

// MARK: - BarcodeData Extension for JSON Serialization
extension BarcodeData {
    /// Convert BarcodeData to Dictionary for Flutter platform channel
    func toDictionary() -> [String: Any] {
        return [
            "barcode": barcode,
            "timestamp": Int(timestamp * 1000)
        ]
    }
}

// MARK: - BarcodeStats Extension
extension BarcodeStats {
    /// Convert BarcodeStats to Dictionary for Flutter platform channel
    func toDictionary() -> [String: Any] {
        return [
            "totalScans": totalScans,
            "uniqueBarcodes": uniqueBarcodes,
            "elapsedTimeMs": elapsedTimeMs
        ]
    }
}

// MARK: - Barcode Storage (for accumulating barcodes)
class BarcodeStorage {
    private var barcodes: [BarcodeData] = []
    private var uniqueBarcodes: Set<String> = []

    /// Add a barcode
    func add(_ barcodeData: BarcodeData) {
        barcodes.append(barcodeData)
        uniqueBarcodes.insert(barcodeData.barcode)
    }

    /// Get all barcodes
    func getAllBarcodes() -> [BarcodeData] {
        return barcodes
    }

    /// Clear all barcodes
    func clear() {
        barcodes.removeAll()
        uniqueBarcodes.removeAll()
    }

    /// Get total scan count
    var totalScans: Int {
        return barcodes.count
    }

    /// Get unique barcode count
    var uniqueCount: Int {
        return uniqueBarcodes.count
    }
}
