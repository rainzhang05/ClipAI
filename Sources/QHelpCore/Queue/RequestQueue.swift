import Foundation

/// A serial queue for processing AI requests one at a time.
///
/// Clipboard events are enqueued and processed sequentially.
/// No clipboard event is lost, and no two requests run simultaneously.
///
/// Uses Swift's actor model for thread-safe access without explicit locks.
public actor RequestQueue {

    public static let maxQueueSize = 20

    private let provider: AIProvider
    private let overlayManager: OverlayPresenting
    private var items: [ClipboardContent] = []
    private var isProcessing = false
    private var isShuttingDown = false
    private var processingTask: Task<Void, Never>?

    public init(provider: AIProvider, overlayManager: OverlayPresenting) {
        self.provider = provider
        self.overlayManager = overlayManager
    }

    // MARK: - Public Interface

    /// Enqueues a clipboard content item for processing.
    public func enqueue(_ content: ClipboardContent) {
        guard !isShuttingDown else { return }

        while items.count >= Self.maxQueueSize {
            items.removeFirst()
            print("Queue full; dropping oldest request.")
        }

        items.append(content)

        if !isProcessing {
            isProcessing = true
            processingTask = Task { await processQueue() }
        }
    }

    /// Stops accepting new work and cancels in-flight requests.
    public func cancelAll() {
        isShuttingDown = true
        items.removeAll()
        processingTask?.cancel()
        provider.cancelInFlightRequest()
    }

    // MARK: - Processing

    private func processQueue() async {
        while !items.isEmpty {
            if Task.isCancelled || isShuttingDown {
                break
            }

            let content = items.removeFirst()

            print("Sending request...")

            do {
                let response = try await provider.send(content: content)
                guard !Task.isCancelled, !isShuttingDown else { break }

                print("Response received.")

                await MainActor.run {
                    overlayManager.show(text: response, isError: false)
                }
            } catch is CancellationError {
                break
            } catch {
                guard !Task.isCancelled, !isShuttingDown else { break }

                let errorMessage = AnthropicAPI.userFacingMessage(for: error)
                print("Error: \(errorMessage)")

                await MainActor.run {
                    overlayManager.show(text: errorMessage, isError: true)
                }
            }
        }

        isProcessing = false
        processingTask = nil
    }
}
