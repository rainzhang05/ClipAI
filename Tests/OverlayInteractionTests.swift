import Foundation
@testable import QHelpCore

enum OverlayInteractionTests: TestCase {
    static let name = "OverlayInteractionTests"

    static func run() throws {
        try assertFalse(OverlayInteractionPolicy.hasAutoDismiss)
        try assertFalse(OverlayInteractionPolicy.ignoresMouseEvents)
        try assertFalse(OverlayInteractionPolicy.becomesKeyOnlyIfNeeded)
        try assertTrue(OverlayInteractionPolicy.panelStyleMask.contains(.nonactivatingPanel))

        var dismissed = false
        let view = OverlayView(text: "hello", isError: false) {
            dismissed = true
        }
        view.triggerDismiss()
        try assertTrue(dismissed)
    }
}
