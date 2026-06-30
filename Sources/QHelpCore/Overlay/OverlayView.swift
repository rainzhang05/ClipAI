import SwiftUI

/// The SwiftUI view displayed inside the floating overlay panel.
struct OverlayView: View {
    let text: String
    let isError: Bool
    let onDismiss: () -> Void

    init(text: String, isError: Bool = false, onDismiss: @escaping () -> Void = {}) {
        self.text = text
        self.isError = isError
        self.onDismiss = onDismiss
    }

    /// Invokes the dismiss callback (used by unit tests).
    func triggerDismiss() {
        onDismiss()
    }

    /// Whether the overlay renders plain text instead of markdown.
    var usesPlainTextContent: Bool {
        isError
    }

    var body: some View {
        cardContent
            .modifier(LiquidGlassCard())
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            contentView
        }
        .padding(16)
        .frame(width: 480, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isError ? .orange : .secondary)

            Text("qhelp")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if !isError {
                Button(action: { OverlayClipboard.copy(text) }) {
                    Label("Copy all", systemImage: "doc.on.doc")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Text("Click to dismiss")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if isError {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            } else {
                ResponseMarkdownView(content: text)
            }
        }
        .frame(maxHeight: 300)
    }
}

// MARK: - Liquid Glass

private struct LiquidGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.modifier(LiquidGlassCardOS26())
        } else {
            content
                .background(
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
