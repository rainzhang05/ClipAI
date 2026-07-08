import Foundation
import ClipAICore

enum RequestQueueTests: TestCase {
    static let name = "RequestQueueTests"

    static func run() throws {
        try runAsync { try await testProcessesRequestsInOrder() }
        try runAsync { try await testCancelAllStopsPendingWork() }
    }

    private static func testProcessesRequestsInOrder() async throws {
        let provider = MockProvider(responses: ["one", "two", "three"])
        let overlay = MockOverlayPresenter()
        let queue = RequestQueue(provider: provider, overlayManager: overlay)

        await queue.enqueue(.text("a"))
        await queue.enqueue(.text("b"))
        await queue.enqueue(.text("c"))

        try await waitUntil("Expected all queued requests to finish") {
            provider.sendCount == 3 && overlay.messages.count == 3
        }

        try assertEqual(provider.sendCount, 3)
        try assertEqual(overlay.messages, ["one", "two", "three"])
    }

    private static func testCancelAllStopsPendingWork() async throws {
        let provider = SlowMockProvider()
        let overlay = MockOverlayPresenter()
        let queue = RequestQueue(provider: provider, overlayManager: overlay)

        await queue.enqueue(.text("first"))
        await queue.enqueue(.text("second"))
        await queue.cancelAll()

        try await waitUntil("Expected in-flight request to be cancelled") {
            provider.didCancel
        }

        try assertTrue(provider.sendCount <= 1, "Expected at most one in-flight request")
    }
}

private final class MockProvider: AIProvider {
    let providerName = "Mock"
    let displayName = "mock"
    let modelIdentifier = "mock"

    private var responses: [String]
    private(set) var sendCount = 0

    init(responses: [String]) {
        self.responses = responses
    }

    func send(content: ClipboardContent) async throws -> String {
        sendCount += 1
        if responses.isEmpty {
            return "empty"
        }
        return responses.removeFirst()
    }
}

private final class SlowMockProvider: AIProvider {
    let providerName = "Mock"
    let displayName = "mock"
    let modelIdentifier = "mock"
    private(set) var sendCount = 0
    private(set) var didCancel = false

    func send(content: ClipboardContent) async throws -> String {
        sendCount += 1
        try await Task.sleep(nanoseconds: 500_000_000)
        return "slow"
    }

    func cancelInFlightRequest() {
        didCancel = true
    }
}

private final class MockOverlayPresenter: OverlayPresenting {
    private(set) var messages: [String] = []

    func show(text: String, isError: Bool) {
        messages.append(text)
    }
}
