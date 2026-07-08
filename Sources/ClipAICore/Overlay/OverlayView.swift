import SwiftUI

/// The SwiftUI view displayed inside the floating overlay panel.
struct OverlayView: View {
    @ObservedObject private var displayState: OverlayDisplayState
    let onDismiss: () -> Void
    let onCopy: () -> Void

    init(
        text: String,
        isError: Bool = false,
        onDismiss: @escaping () -> Void = {},
        onCopy: @escaping () -> Void = {}
    ) {
        self.init(
            displayState: OverlayDisplayState(text: text, isError: isError),
            onDismiss: onDismiss,
            onCopy: onCopy
        )
    }

    init(
        displayState: OverlayDisplayState,
        onDismiss: @escaping () -> Void = {},
        onCopy: @escaping () -> Void = {}
    ) {
        self.displayState = displayState
        self.onDismiss = onDismiss
        self.onCopy = onCopy
    }

    /// Invokes the dismiss callback (used by unit tests).
    func triggerDismiss() {
        onDismiss()
    }

    /// Invokes the copy callback (used by unit tests).
    func triggerCopy() {
        onCopy()
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
            copyButtonSlot
            cardContent
        }
        .animation(.easeOut(duration: 0.18), value: displayState.hasCopied)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            closeButtonRow
            contentView
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(width: OverlayMetrics.panelWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .modifier(LiquidGlassCard())
        .clipShape(cardShape)
    }

    // MARK: - Controls

    private var closeButtonRow: some View {
        HStack {
            closeButton
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Circle()
                .fill(Color(red: 1.0, green: 0.373, blue: 0.341))
                .frame(width: 12, height: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }

    private var copyButtonSlot: some View {
        HStack {
            Spacer()
            Button(action: onCopy) {
                Text(displayState.hasCopied ? "Copied" : "Copy")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .modifier(LiquidGlassCard())
            }
            .buttonStyle(.plain)
            .disabled(displayState.hasCopied)
            .accessibilityLabel(displayState.hasCopied ? "Copied" : "Copy")
        }
        .frame(
            width: OverlayMetrics.panelWidth,
            height: OverlayMetrics.copyButtonHeight,
            alignment: .trailing
        )
    }

    // MARK: - Content

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

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: OverlayMetrics.cardCornerRadius, style: .continuous)
    }
}

// MARK: - Liquid Glass

private struct LiquidGlassCard: ViewModifier {
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: OverlayMetrics.cardCornerRadius, style: .continuous)
    }

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.modifier(LiquidGlassCardOS26(shape: shape))
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }
}

@available(macOS 26.0, *)
private struct LiquidGlassCardOS26: ViewModifier {
    let shape: RoundedRectangle

    func body(content: Content) -> some View {
        GlassEffectContainer {
            content
        }
        .glassEffect(.regular, in: shape)
    }
}
