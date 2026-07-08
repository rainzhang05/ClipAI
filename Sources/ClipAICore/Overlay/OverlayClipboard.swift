import AppKit
import Foundation

enum OverlayClipboard {
    /// Copies plain text to the general pasteboard. Returns whether the write succeeded.
    @discardableResult
    static func copy(_ string: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        pasteboard.setString("true", forType: ClipboardPasteboardTypes.clipAIIgnore)
        let didSetString = pasteboard.setString(string, forType: .string)
        if didSetString {
            ClipboardSelfCopyGuard.markCopiedTextHash(ClipboardContent.text(string).contentHash)
        }
        return didSetString
    }
}
