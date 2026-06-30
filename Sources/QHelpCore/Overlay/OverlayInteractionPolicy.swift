import AppKit

/// Non-activating overlay interaction settings shared with tests.
enum OverlayInteractionPolicy {
    static let panelStyleMask: NSWindow.StyleMask = [.nonactivatingPanel]
    static let ignoresMouseEvents = false
    static let becomesKeyOnlyIfNeeded = false
    static let hasAutoDismiss = false
}
