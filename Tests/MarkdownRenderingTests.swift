import AppKit
import Foundation
@testable import QHelpCore

enum MarkdownRenderingTests: TestCase {
    static let name = "MarkdownRenderingTests"

    static let sampleMarkdown = """
    ## Summary

    This is **bold** and _italic_ with a [link](https://example.com).

    - First item
    - Second item

    ```swift
    let x = 1
    ```
    """

    static func run() throws {
        let blocks = MarkdownDocumentParser.parse(sampleMarkdown)
        try assertTrue(blocks.count >= 4)

        try assertEqual(blocks[0], .heading(level: 2, text: "Summary"))

        if case .paragraph(let text) = blocks[1] {
            try assertTrue(text.contains("**bold**"))
        } else {
            throw TestFailure.message("Expected paragraph block")
        }

        if case .bulletList(let items) = blocks[2] {
            try assertEqual(items.count, 2)
            try assertEqual(items[0], "First item")
        } else {
            throw TestFailure.message("Expected bullet list block")
        }

        if case .codeBlock(let language, let code) = blocks[3] {
            try assertEqual(language, "swift")
            try assertTrue(code.contains("let x = 1"))
        } else {
            throw TestFailure.message("Expected code block")
        }

        try assertTrue(OverlayClipboard.copy("test copy"))
        let readBack = NSPasteboard.general.string(forType: .string)
        try assertEqual(readBack, "test copy")

        let errorView = OverlayView(text: "Error message", isError: true, onDismiss: {})
        try assertTrue(errorView.usesPlainTextContent)

        let successView = OverlayView(text: "**Hello**", isError: false, onDismiss: {})
        try assertFalse(successView.usesPlainTextContent)
    }
}
