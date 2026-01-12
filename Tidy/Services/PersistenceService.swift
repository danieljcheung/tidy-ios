import Foundation
import SwiftUI

@Observable
final class PersistenceService {
    static let shared = PersistenceService()

    private let defaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let currentSessionIndex = "currentSessionIndex"
        static let currentFilter = "currentFilter"
        static let markedForDeletion = "markedForDeletion"
        static let maybePile = "maybePile"
        static let reviewedPhotos = "reviewedPhotos"
        static let sessionStats = "sessionStats"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let undoStack = "undoStack"
    }

    // MARK: - Session Index

    var currentSessionIndex: Int {
        get { defaults.integer(forKey: Keys.currentSessionIndex) }
        set { defaults.set(newValue, forKey: Keys.currentSessionIndex) }
    }

    // MARK: - Current Filter

    var currentFilter: String {
        get { defaults.string(forKey: Keys.currentFilter) ?? "all" }
        set { defaults.set(newValue, forKey: Keys.currentFilter) }
    }

    // MARK: - Marked for Deletion

    var markedForDeletion: Set<String> {
        get {
            guard let data = defaults.data(forKey: Keys.markedForDeletion),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return Set(array)
        }
        set {
            let array = Array(newValue)
            if let data = try? JSONEncoder().encode(array) {
                defaults.set(data, forKey: Keys.markedForDeletion)
            }
        }
    }

    func markForDeletion(_ identifier: String) {
        var current = markedForDeletion
        current.insert(identifier)
        markedForDeletion = current
    }

    func unmarkForDeletion(_ identifier: String) {
        var current = markedForDeletion
        current.remove(identifier)
        markedForDeletion = current
    }

    func clearMarkedForDeletion() {
        markedForDeletion = []
    }

    // MARK: - Maybe Pile

    var maybePile: Set<String> {
        get {
            guard let data = defaults.data(forKey: Keys.maybePile),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return Set(array)
        }
        set {
            let array = Array(newValue)
            if let data = try? JSONEncoder().encode(array) {
                defaults.set(data, forKey: Keys.maybePile)
            }
        }
    }

    func addToMaybePile(_ identifier: String) {
        var current = maybePile
        current.insert(identifier)
        maybePile = current
    }

    func removeFromMaybePile(_ identifier: String) {
        var current = maybePile
        current.remove(identifier)
        maybePile = current
    }

    // MARK: - Reviewed Photos

    var reviewedPhotos: Set<String> {
        get {
            guard let data = defaults.data(forKey: Keys.reviewedPhotos),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return Set(array)
        }
        set {
            let array = Array(newValue)
            if let data = try? JSONEncoder().encode(array) {
                defaults.set(data, forKey: Keys.reviewedPhotos)
            }
        }
    }

    func markAsReviewed(_ identifier: String) {
        var current = reviewedPhotos
        current.insert(identifier)
        reviewedPhotos = current
    }

    func unmarkAsReviewed(_ identifier: String) {
        var current = reviewedPhotos
        current.remove(identifier)
        reviewedPhotos = current
    }

    // MARK: - Session Stats

    var sessionStats: SessionStats {
        get {
            guard let data = defaults.data(forKey: Keys.sessionStats),
                  let stats = try? JSONDecoder().decode(SessionStats.self, from: data) else {
                return SessionStats()
            }
            return stats
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.sessionStats)
            }
        }
    }

    func resetSessionStats() {
        sessionStats = SessionStats()
    }

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // MARK: - Undo Stack

    var undoStack: [SwipeAction] {
        get {
            guard let data = defaults.data(forKey: Keys.undoStack),
                  let actions = try? JSONDecoder().decode([SwipeAction].self, from: data) else {
                return []
            }
            return actions
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.undoStack)
            }
        }
    }

    func pushUndo(_ action: SwipeAction) {
        var stack = undoStack
        stack.append(action)
        // Keep only last 50 actions to prevent unbounded growth
        if stack.count > 50 {
            stack.removeFirst(stack.count - 50)
        }
        undoStack = stack
    }

    func popUndo() -> SwipeAction? {
        var stack = undoStack
        guard !stack.isEmpty else { return nil }
        let action = stack.removeLast()
        undoStack = stack
        return action
    }

    func clearUndoStack() {
        undoStack = []
    }

    // MARK: - Reset All

    func resetAll() {
        currentSessionIndex = 0
        currentFilter = "all"
        markedForDeletion = []
        maybePile = []
        reviewedPhotos = []
        resetSessionStats()
        clearUndoStack()
    }

    private init() {}
}
