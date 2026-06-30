import AppKit
import SwiftUI

/// Renders parsed markdown blocks inside the overlay scroll area.
struct ResponseMarkdownView: View {
    let content: String

    private var blocks: [MarkdownBlock] {
        MarkdownDocumentParser.parse(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if blocks.isEmpty {
                InlineMarkdownText(text: content)
            } else {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    blockView(for: block)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
        .environment(\.openURL, OpenURLAction { url in
            NSWorkspace.shared.open(url)
            return .handled
        })
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            InlineMarkdownText(text: text)
                .font(headingFont(for: level))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

        case .paragraph(let text):
            InlineMarkdownText(text: text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)

        case .codeBlock(_, let code):
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        InlineMarkdownText(text: item)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }

        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 20, alignment: .trailing)
                        InlineMarkdownText(text: item)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }

        case .blockquote(let lines):
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        InlineMarkdownText(text: line)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 10)
            }

        case .thematicBreak:
            Divider()
                .overlay(Color.secondary.opacity(0.3))
        }
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .title3
        case 2: return .headline
        case 3: return .subheadline
        default: return .body
        }
    }
}
