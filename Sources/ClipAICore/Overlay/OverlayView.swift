import SwiftUI

/// The SwiftUI view displayed inside the floating overlay panel.
struct OverlayView: View {
    @ObservedObject private var displayState: OverlayDisplayState
    let onDismiss: () -> Void

    init(text: String, isError: Bool = false, onDismiss: @escaping () -> Void = {}) {
        self.init(
            displayState: OverlayDisplayState(text: text, isError: isError),
            onDismiss: onDismiss
        )
    }

    init(displayState: OverlayDisplayState, onDismiss: @escaping () -> Void = {}) {
        self.displayState = displayState
        self.onDismiss = onDismiss
    }

    /// Invokes the dismiss callback (used by unit tests).
    func triggerDismiss() {
        onDismiss()
    }

    /// Whether the overlay renders plain text instead of markdown.
    var usesPlainTextContent: Bool {
        displayState.isError
    }

    var text: String {
        displayState.text
    }

    var isError: Bool {
        displayState.isError
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            copiedToastSlot
            cardContent
                .modifier(LiquidGlassCard())
        }
        .animation(.easeOut(duration: 0.18), value: displayState.showsCopiedToast)
    }

    private var cardContent: some View {
        contentView
            .padding(16)
            .frame(width: OverlayMetrics.panelWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Content

    private var copiedToastSlot: some View {
        ZStack(alignment: .trailing) {
            if displayState.showsCopiedToast {
                Text("Copied!")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .modifier(LiquidGlassCard())
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(
            width: OverlayMetrics.panelWidth,
            height: OverlayMetrics.toastHeight,
            alignment: .trailing
        )
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if displayState.isError {
                Text(displayState.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            } else {
                ResponseMarkdownView(content: displayState.text)
            }
        }
        .frame(maxHeight: OverlayMetrics.maxContentHeight)
    }
}

// MARK: - Liquid Glass

private struct LiquidGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.modifier(LiquidGlassCardOS26())
        } else {
            content.background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
    }
}

@available(macOS 26.0, *)
private struct LiquidGlassCardOS26: ViewModifier {
    func body(content: Content) -> some View {
        GlassEffectContainer {
            content
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
