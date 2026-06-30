import Foundation
import QHelpCore

enum CLIParserTests: TestCase {
    static let name = "CLIParserTests"

    static func run() throws {
        let result = CLIParser.parseResult(["qhelp", "claude-sonnet-4-6"])
        guard case .config(let config) = result else {
            throw TestFailure.message("Expected config result")
        }
        try assertEqual(config.modelAlias, "claude-sonnet-4-6")

        try assertEqual(CLIParser.parseResult(["qhelp", "--help"]), CLIParseResult.help)
        try assertEqual(CLIParser.parseResult(["qhelp", "-h"]), CLIParseResult.help)
        try assertEqual(CLIParser.parseResult(["qhelp", "--version"]), CLIParseResult.version)
        try assertEqual(CLIParser.parseResult(["qhelp"]), CLIParseResult.invalidUsage)
        try assertEqual(CLIParser.parseResult(["qhelp", "--unknown"]), CLIParseResult.invalidUsage)

        let usage = CLIParser.usageText()
        try assertTrue(usage.contains("claude-sonnet-4-6"))
        try assertTrue(usage.contains("gpt-4o"))
        try assertTrue(usage.contains("gemini-2.5-flash"))
        try assertTrue(usage.contains("click the header"))
    }
}
