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

    var bytesFreedFormatted: String {
        ByteCountFormatter.string(fromByteCount: bytesFreed, countStyle: .file)
    }

    var gbFreed: Double {
        Double(bytesFreed) / 1_073_741_824.0
    }

    var gbFreedFormatted: String {
        String(format: "%.1f GB", gbFreed)
    }

    mutating func recordDeletion(bytes: Int64) {
        photosDeleted += 1
        bytesFreed += bytes
    }

    mutating func endSession() {
        sessionEndTime = Date()
    }
}
