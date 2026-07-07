import AppKit
import Foundation
@testable import ClipAICore

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

        // Test custom OverlayPanel key event handling
        let panel = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 200),
            styleMask: OverlayInteractionPolicy.panelStyleMask,
            backing: .buffered,
            defer: false
        )

        var spacePressed = false
        var cPressed = false
        panel.onSpacePressed = { spacePressed = true }
        panel.onCPressed = { cPressed = true }

        // Simulate Space press
        if let spaceEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: panel.windowNumber,
            context: nil,
            characters: " ",
            charactersIgnoringModifiers: " ",
            isARepeat: false,
            keyCode: 49
        ) {
            panel.sendEvent(spaceEvent)
        }

        // Simulate 'c' press
        if let cEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: panel.windowNumber,
            context: nil,
            characters: "c",
            charactersIgnoringModifiers: "c",
            isARepeat: false,
            keyCode: 8
        ) {
            panel.sendEvent(cEvent)
        }

        try assertTrue(spacePressed)
        try assertTrue(cPressed)

        // Simulate 'x' press (other key, should not trigger callbacks)
        var spacePressed2 = false
        var cPressed2 = false
        panel.onSpacePressed = { spacePressed2 = true }
        panel.onCPressed = { cPressed2 = true }

        if let xEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: panel.windowNumber,
            context: nil,
            characters: "x",
            charactersIgnoringModifiers: "x",
            isARepeat: false,
            keyCode: 7
        ) {
            panel.sendEvent(xEvent)
        }

        try assertFalse(spacePressed2)
        try assertFalse(cPressed2)

        try assertEqual(
            OverlayKeyboardShortcut.action(forKeyCode: 8, flags: [], isRepeat: false),
            .copy
        )
        try assertEqual(
            OverlayKeyboardShortcut.action(forKeyCode: 49, flags: [], isRepeat: false),
            .dismiss
        )
        try assertEqual(
            OverlayKeyboardShortcut.action(forKeyCode: 8, flags: [.maskCommand], isRepeat: false),
            nil
        )
        try assertEqual(
            OverlayKeyboardShortcut.action(forKeyCode: 49, flags: [.maskShift], isRepeat: false),
            nil
        )
        try assertEqual(
            OverlayKeyboardShortcut.action(forKeyCode: 8, flags: [], isRepeat: true),
            nil
        )
        try assertEqual(
            OverlayKeyboardShortcut.action(forKeyCode: 7, flags: [], isRepeat: false),
            nil
        )
    }
}
