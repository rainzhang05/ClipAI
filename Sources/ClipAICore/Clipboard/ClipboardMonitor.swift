import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Monitors the macOS system clipboard for new content.
///
/// Uses `NSPasteboard.changeCount` polling to detect clipboard changes.
/// This is the standard macOS approach — there is no notification-based
/// clipboard monitoring API on macOS.
///
/// **Important**: This class monitors the clipboard itself, not keyboard
/// events. Any application that writes to the clipboard triggers detection.
final class ClipboardMonitor {

    private let queue: RequestQueue
    private var lastChangeCount: Int
    private var lastContentHash: String?
    private var timer: Timer?

    /// Polling interval in seconds.
    /// 0.5s provides near-instant detection with negligible CPU cost.
    private let pollInterval: TimeInterval = 0.5

    // MARK: - Initialization

    init(queue: RequestQueue) {
        self.queue = queue
        // Record current clipboard state so we ignore existing content
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    // MARK: - Lifecycle

    /// Starts clipboard monitoring on the main run loop.
    func start() {
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// Stops clipboard monitoring and releases the timer.
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Clipboard Checking

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        // No change since last check
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // Ignore copies triggered by ClipAI itself
        if pasteboard.types?.contains(ClipboardPasteboardTypes.clipAIIgnore) == true {
            return
        }

        // Read content from clipboard
        guard let content = readContent(from: pasteboard) else {
            print("Unsupported clipboard format (ignored).")
            return
        }

        // Some clipboard managers may rewrite copied text and strip custom pasteboard
        // types. Keep a short-lived hash guard to avoid re-sending our own response.
        if case .text = content, ClipboardSelfCopyGuard.shouldIgnoreTextHash(content.contentHash) {
            return
        }

        // Duplicate detection via SHA-256 hash
        let hash = content.contentHash
        guard hash != lastContentHash else { return }
        lastContentHash = hash

        print("\nClipboard updated: \(content.typeDescription)")

        // Enqueue for processing
        Task {
            await queue.enqueue(content)
        }
    }

    // MARK: - Content Reading

    /// Reads the current clipboard content.
    ///
    /// Priority order:
    /// 1. PNG (native, no conversion)
    /// 2. HEIC/HEIF (modern macOS screenshots — converted to PNG)
    /// 3. JPEG (native, no conversion)
    /// 4. TIFF without text (screenshots/images — converted to PNG)
    /// 5. Plain text
    /// 6. Rich text → plain text
    /// 7. TIFF with text fallback
    ///
    /// Returns `nil` for unsupported clipboard formats.
    private func readContent(from pasteboard: NSPasteboard) -> ClipboardContent? {
        let types = pasteboard.types ?? []

        let hasPNG    = types.contains(.png)
        let hasHEIC   = types.contains(ClipboardPasteboardTypes.heic)
            || types.contains(ClipboardPasteboardTypes.heif)
        let hasJPEG   = types.contains(ClipboardPasteboardTypes.jpeg)
        let hasTIFF   = types.contains(.tiff)
        let hasString = types.contains(.string)

        // --- Image types (highest priority) ---

        // PNG: native format, send directly
        if hasPNG, let data = pasteboard.data(forType: .png), !data.isEmpty {
            return .image(data, mediaType: "image/png")
        }

        // HEIC/HEIF: common on modern Macs — convert to PNG for API
        if hasHEIC {
            let heifData = pasteboard.data(forType: ClipboardPasteboardTypes.heic)
                        ?? pasteboard.data(forType: ClipboardPasteboardTypes.heif)
            if let data = heifData, let pngData = convertToPNG(data) {
                return .image(pngData, mediaType: "image/png")
            }
        }

        // JPEG: Anthropic supports natively
        if hasJPEG,
           let data = pasteboard.data(forType: ClipboardPasteboardTypes.jpeg),
           !data.isEmpty {
            return .image(data, mediaType: "image/jpeg")
        }

        // TIFF without accompanying text → likely a pure image/screenshot
        if hasTIFF && !hasString {
            if let data = pasteboard.data(forType: .tiff), let pngData = convertToPNG(data) {
                return .image(pngData, mediaType: "image/png")
            }
        }

        // --- Text types ---

        // Plain text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return .text(text)
        }

        // Rich text → plain text fallback
        if let rtfData = pasteboard.data(forType: .rtf) {
            if let attrStr = try? NSAttributedString(
                data: rtfData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            ) {
                let text = attrStr.string
                if !text.isEmpty {
                    return .text(text)
                }
            }
        }

        // TIFF with text present → last resort image fallback
        if hasTIFF {
            if let data = pasteboard.data(forType: .tiff), let pngData = convertToPNG(data) {
                return .image(pngData, mediaType: "image/png")
            }
        }

        return nil
    }

    // MARK: - Image Conversion

    /// Converts any ImageIO-supported format (TIFF, HEIF, HEIC, WebP, etc.) to PNG.
    ///
    /// Uses `CGImageSource`/`CGImageDestination` from the ImageIO framework,
    /// which handles all Apple-supported image formats natively including HEIF.
    private func convertToPNG(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return mutableData as Data
    }
}
