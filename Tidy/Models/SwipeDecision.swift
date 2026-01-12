import Foundation

enum SwipeDecision: String, Codable {
    case keep
    case delete
    case maybe
    case undecided
}

struct SwipeAction: Identifiable, Codable {
    let id: UUID
    let assetIdentifier: String
    let decision: SwipeDecision
    let timestamp: Date

    init(assetIdentifier: String, decision: SwipeDecision) {
        self.id = UUID()
        self.assetIdentifier = assetIdentifier
        self.decision = decision
        self.timestamp = Date()
    }
}
