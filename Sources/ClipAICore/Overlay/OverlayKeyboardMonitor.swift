import ApplicationServices
import Foundation

enum OverlayKeyboardAction: Equatable {
    case copy
    case dismiss
}

enum OverlayKeyboardShortcut {
    private static let cKeyCode: Int64 = 8
    private static let spaceKeyCode: Int64 = 49
    private static let ignoredModifiers: CGEventFlags = [
        .maskCommand,
        .maskControl,
        .maskAlternate,
        .maskShift,
        .maskSecondaryFn
    ]

    static func action(forKeyCode keyCode: Int64, flags: CGEventFlags, isRepeat: Bool) -> OverlayKeyboardAction? {
        guard !isRepeat else { return nil }
        guard flags.intersection(ignoredModifiers).isEmpty else { return nil }

        switch keyCode {
        case cKeyCode:
            return .copy
        case spaceKeyCode:
            return .dismiss
        default:
            return nil
        }
    }
}

final class OverlayEntryKeyboardState {
    private var hasCopiedCurrentEntry = false

    func beginEntry() {
        hasCopiedCurrentEntry = false
    }

    func consumeCopyIfNeeded() -> Bool {
        guard !hasCopiedCurrentEntry else {
            return false
        }

        hasCopiedCurrentEntry = true
        return true
    }
}

final class OverlayKeyboardMonitor {
    typealias Handler = (OverlayKeyboardAction) -> Bool

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var handler: Handler?
    private var didRequestPermission = false
    private var didWarnUnavailable = false

    var isActive: Bool {
        eventTap != nil
    }

    func start(handler: @escaping Handler) {
        self.handler = handler

        guard eventTap == nil else {
            return
        }

        if !AXIsProcessTrusted() {
            requestAccessibilityPermission()
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: OverlayKeyboardMonitor.handleEvent,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            if !didWarnUnavailable {
                didWarnUnavailable = true
                print("""
                Warning: ClipAI could not enable global overlay keyboard controls.
                Grant ClipAI Accessibility/Input Monitoring permission in System Settings > Privacy & Security, then restart ClipAI.
                Until then, click the overlay before pressing c or Space.
                """)
            }
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.eventTap = eventTap
        self.runLoopSource = source
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        handler = nil
    }

    private func requestAccessibilityPermission() {
        guard !didRequestPermission else { return }
        didRequestPermission = true

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private static let handleEvent: CGEventTapCallBack = { _, type, event, userInfo in
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let monitor = Unmanaged<OverlayKeyboardMonitor>.fromOpaque(userInfo).takeUnretainedValue()
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

        guard let action = OverlayKeyboardShortcut.action(
            forKeyCode: keyCode,
            flags: event.flags,
            isRepeat: isRepeat
        ) else {
            return Unmanaged.passUnretained(event)
        }

        if monitor.handler?(action) == true {
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    deinit {
        stop()
    }
}
