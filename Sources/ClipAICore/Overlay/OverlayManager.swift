import AppKit
import SwiftUI

/// Manages the floating overlay panel that displays AI responses.
final class OverlayPanel: NSPanel {
    var onSpacePressed: (() -> Bool)?
    var onCPressed: (() -> Bool)?

    override var canBecomeKey: Bool {
        return true
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown,
           let action = OverlayKeyboardShortcut.action(
            forKeyCode: Int64(event.keyCode),
            flags: CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue)),
            isRepeat: event.isARepeat
           ),
           handle(action) {
            return
        }
        super.sendEvent(event)
    }

    private func handle(_ action: OverlayKeyboardAction) -> Bool {
        switch action {
        case .copy:
            return onCPressed?() == true
        case .dismiss:
            return onSpacePressed?() == true
        }
    }
}

/// Manages the floating overlay panel that displays AI responses.
///
/// The overlay appears in the bottom-right corner, fades in, and stays visible
/// until the user clicks the header to dismiss. Text can be scrolled and copied.
/// The panel never activates the application or steals keyboard focus.
final class OverlayManager {

    private var panel: OverlayPanel?
    private let keyboardMonitor = OverlayKeyboardMonitor()
    private let keyboardState = OverlayEntryKeyboardState()
    private var currentResponseText = ""
    private var displayState: OverlayDisplayState?

    // MARK: - Public Interface

    func show(text: String, isError: Bool = false) {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        currentResponseText = text
        keyboardState.beginEntry()

        let displayText = text.isEmpty ? "(empty response)" : text
        let state: OverlayDisplayState
        let needsHostingView = displayState == nil || panel.contentView == nil
        if let displayState {
            displayState.update(text: displayText, isError: isError)
            state = displayState
        } else {
            state = OverlayDisplayState(text: displayText, isError: isError)
            displayState = state
        }

        panel.onSpacePressed = { [weak self] in
            self?.dismiss(slideOut: true)
            return true
        }
        panel.onCPressed = { [weak self] in
            self?.copyCurrentEntryIfNeeded() ?? false
        }

        let wasVisible = panel.isVisible

        if needsHostingView {
            let overlayView = OverlayView(displayState: state) { [weak self] in
                self?.dismiss()
            }
            let hostingView = configureHostingView(rootView: overlayView)
            panel.contentView = hostingView
        }

        guard let contentView = panel.contentView else { return }
        contentView.layoutSubtreeIfNeeded()
        let contentSize = contentView.fittingSize
        contentView.setFrameSize(contentSize)
        positionPanel(panel, size: contentSize)

        if !wasVisible {
            panel.alphaValue = 0
            panel.makeKeyAndOrderFront(nil)
            keyboardMonitor.start { [weak self] action in
                self?.handleKeyboardAction(action) ?? false
            }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = OverlayMetrics.animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        } else {
            panel.alphaValue = 0.85
            panel.makeKey()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = OverlayMetrics.contentReplaceDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        }
    }

    // MARK: - Private

    private func dismiss(slideOut: Bool = false) {
        guard let panel = panel, panel.isVisible else { return }

        keyboardMonitor.stop()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = OverlayMetrics.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            if slideOut {
                var frame = panel.frame
                if let screen = panel.screen ?? NSScreen.main {
                    frame.origin.x = screen.visibleFrame.maxX + OverlayMetrics.screenMargin
                } else {
                    frame.origin.x += frame.width + OverlayMetrics.screenMargin
                }
                panel.animator().setFrame(frame, display: true)
            }
        }, completionHandler: { [weak self] in
            self?.panel?.orderOut(nil)
        })
    }

    private func handleKeyboardAction(_ action: OverlayKeyboardAction) -> Bool {
        switch action {
        case .copy:
            return copyCurrentEntryIfNeeded()
        case .dismiss:
            dismiss()
            return true
        }
    }

    private func copyCurrentEntryIfNeeded() -> Bool {
        guard keyboardState.consumeCopyIfNeeded() else {
            return false
        }

        OverlayClipboard.copy(currentResponseText)
        displayState?.showCopiedToast()
        return true
    }

    private func configureHostingView<Content: View>(rootView: Content) -> NSHostingView<Content> {
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false
        return hostingView
    }

    private func createPanel() {
        let panel = OverlayPanel(
            contentRect: NSRect(origin: .zero, size: OverlayMetrics.initialPanelSize),
            styleMask: OverlayInteractionPolicy.panelStyleMask,
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = OverlayInteractionPolicy.ignoresMouseEvents
        panel.becomesKeyOnlyIfNeeded = OverlayInteractionPolicy.becomesKeyOnlyIfNeeded
        panel.animationBehavior = .utilityWindow

        self.panel = panel
    }

    private func positionPanel(_ panel: OverlayPanel, size: CGSize) {
        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.maxX - size.width - OverlayMetrics.screenMargin
        let y = visibleFrame.minY + OverlayMetrics.screenMargin

        panel.setFrame(
            NSRect(x: x, y: y, width: size.width, height: size.height),
            display: true
        )
    }
}
