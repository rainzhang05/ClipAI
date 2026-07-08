import AppKit
import Foundation
@testable import ClipAICore

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
        try testBasicMarkdownBlocks()
        try testAdditionalBlockTypes()
        try testMalformedMarkdownFallbacks()
        try testOverlayClipboardAndPlainTextMode()
        try testSelfCopyGuard()
    }

    private static func testBasicMarkdownBlocks() throws {
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
    }

    private static func testAdditionalBlockTypes() throws {
        let markdown = """
        1. First
        2. Second

        > quoted
        > text

        ---
        """

        let blocks = MarkdownDocumentParser.parse(markdown)
        try assertEqual(blocks.count, 3)

        if case .numberedList(let items) = blocks[0] {
            try assertEqual(items, ["First", "Second"])
        } else {
            throw TestFailure.message("Expected numbered list block")
        }

        if case .blockquote(let lines) = blocks[1] {
            try assertEqual(lines, ["quoted", "text"])
        } else {
            throw TestFailure.message("Expected blockquote block")
        }

        try assertEqual(blocks[2], .thematicBreak)
    }

    private static func testMalformedMarkdownFallbacks() throws {
        let headingWithoutSpace = MarkdownDocumentParser.parse("#Not a heading")
        try assertEqual(headingWithoutSpace, [.paragraph(text: "#Not a heading")])

        let unclosedFence = MarkdownDocumentParser.parse("""
        ```swift
        let value = 1
        """)
        try assertEqual(unclosedFence, [.codeBlock(language: "swift", code: "let value = 1")])

        let malformedNumber = MarkdownDocumentParser.parse("1.Not a list")
        try assertEqual(malformedNumber, [.paragraph(text: "1.Not a list")])
    }

    private static func testOverlayClipboardAndPlainTextMode() throws {
        try assertTrue(OverlayClipboard.copy("test copy"))
        let readBack = NSPasteboard.general.string(forType: .string)
        try assertEqual(readBack, "test copy")
        try assertTrue(
            NSPasteboard.general.types?.contains(ClipboardPasteboardTypes.clipAIIgnore) == true
        )

        let errorView = OverlayView(text: "Error message", isError: true)
        try assertTrue(errorView.usesPlainTextContent)

        let successView = OverlayView(text: "**Hello**", isError: false)
        try assertFalse(successView.usesPlainTextContent)
    }

    private static func testSelfCopyGuard() throws {
        let hash = ClipboardContent.text("guarded response").contentHash
        try assertFalse(ClipboardSelfCopyGuard.shouldIgnoreTextHash(hash))
        ClipboardSelfCopyGuard.markCopiedTextHash(hash)
        try assertTrue(ClipboardSelfCopyGuard.shouldIgnoreTextHash(hash))
    }
}
