import Foundation

/// Tracks recently copied ClipAI response text hashes to prevent immediate self-reprocessing.
enum ClipboardSelfCopyGuard {
    private static let lock = NSLock()
    private static let ignoreWindow: TimeInterval = 8
    private static var ignoredTextHashes: [String: Date] = [:]

    static func markCopiedTextHash(_ hash: String) {
        lock.lock()
        defer { lock.unlock() }
        ignoredTextHashes[hash] = Date().addingTimeInterval(ignoreWindow)
    }

    static func shouldIgnoreTextHash(_ hash: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        ignoredTextHashes = ignoredTextHashes.filter { $0.value > now }
        guard let expiry = ignoredTextHashes[hash] else {
            return false
        }

        return expiry > now
    }
}
