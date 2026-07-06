import AppKit
import SwiftUI

/// Manages the floating overlay panel that displays AI responses.
///
/// The overlay appears in the bottom-right corner, fades in, and stays visible
/// until the user clicks the header to dismiss. Text can be scrolled and copied.
/// The panel never activates the application or steals keyboard focus.
final class OverlayPanel: NSPanel {
    var onSpacePressed: (() -> Void)?
    var onCPressed: (() -> Void)?

    override var canBecomeKey: Bool {
        return true
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            let chars = event.charactersIgnoringModifiers ?? ""
            if chars == " " {
                onSpacePressed?()
                return
            } else if chars == "c" || chars == "C" {
                onCPressed?()
                return
            }
        }
        super.sendEvent(event)
    }
}

/// Manages the floating overlay panel that displays AI responses.
///
/// The overlay appears in the bottom-right corner, fades in, and stays visible
/// until the user clicks the header to dismiss. Text can be scrolled and copied.
/// The panel never activates the application or steals keyboard focus.
final class OverlayManager {

    private var panel: OverlayPanel?

    private let animationDuration: TimeInterval = 0.3
    private let contentReplaceDuration: TimeInterval = 0.15
    private let screenMargin: CGFloat = 16.0

    // MARK: - Public Interface

    func show(text: String, isError: Bool = false) {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        let displayText = text.isEmpty ? "(empty response)" : text
        let overlayView = OverlayView(text: displayText, isError: isError) { [weak self] in
            self?.dismiss()
        }

        panel.onSpacePressed = { [weak self] in
            self?.dismiss()
        }
        panel.onCPressed = {
            OverlayClipboard.copy(text)
        }

        let hostingView = configureHostingView(rootView: overlayView)
        let contentSize = hostingView.fittingSize
        hostingView.setFrameSize(contentSize)

        let wasVisible = panel.isVisible
        panel.contentView = hostingView
        positionPanel(panel, size: contentSize)

        if !wasVisible {
            panel.alphaValue = 0
            panel.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        } else {
            panel.alphaValue = 0.85
            panel.makeKey()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = contentReplaceDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        }
    }

    // MARK: - Private

    private func dismiss() {
        guard let panel = panel, panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel?.orderOut(nil)
        })
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
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 200),
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
        let x = visibleFrame.maxX - size.width - screenMargin
        let y = visibleFrame.minY + screenMargin

        panel.setFrame(
            NSRect(x: x, y: y, width: size.width, height: size.height),
            display: true
        )
    }
}
