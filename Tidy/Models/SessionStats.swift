import Foundation

struct SessionStats: Codable {
    var photosReviewed: Int
    var photosDeleted: Int
    var bytesFreed: Int64
    var sessionStartTime: Date
    var sessionEndTime: Date?

    init() {
        self.photosReviewed = 0
        self.photosDeleted = 0
        self.bytesFreed = 0
        self.sessionStartTime = Date()
        self.sessionEndTime = nil
    }

    /// Smart file size formatting - shows most appropriate unit
    var smartSizeFormatted: String {
        formatFileSize(bytesFreed)
    }

    /// Just the number part (e.g., "2.50" from "2.50 GB")
    var smartSizeValue: String {
        let kb = Double(bytesFreed) / 1_000
        let mb = kb / 1_000
        let gb = mb / 1_000

        if gb >= 1.0 {
            return String(format: "%.2f", gb)
        } else if mb >= 1.0 {
            return String(format: "%.1f", mb)
        } else if kb >= 1.0 {
            return String(format: "%.0f", kb)
        } else {
            return "\(bytesFreed)"
        }
    }

    /// Just the unit part (e.g., "GB" from "2.50 GB")
    var smartSizeUnit: String {
        let kb = Double(bytesFreed) / 1_000
        let mb = kb / 1_000
        let gb = mb / 1_000

        if gb >= 1.0 {
            return "GB"
        } else if mb >= 1.0 {
            return "MB"
        } else if kb >= 1.0 {
            return "KB"
        } else {
            return "bytes"
        }
    }

    mutating func recordDeletion(bytes: Int64) {
        photosDeleted += 1
        bytesFreed += bytes
    }

    mutating func endSession() {
        sessionEndTime = Date()
    }
}

/// Smart file size formatting - shows most appropriate unit
func formatFileSize(_ bytes: Int64) -> String {
    let kb = Double(bytes) / 1_000
    let mb = kb / 1_000
    let gb = mb / 1_000

    if gb >= 1.0 {
        return String(format: "%.2f GB", gb)
    } else if mb >= 1.0 {
        return String(format: "%.1f MB", mb)
    } else if kb >= 1.0 {
        return String(format: "%.0f KB", kb)
    } else {
        return "\(bytes) bytes"
    }
}
