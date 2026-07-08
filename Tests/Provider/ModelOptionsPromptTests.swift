import Foundation
import ClipAICore

enum ModelOptionsPromptTests: TestCase {
    static let name = "ModelOptionsPromptTests"

    static func run() throws {
        defer {
            ModelOptionsPrompt.setLineReader(nil)
            ModelOptionsPrompt.setOutputWriter(nil)
        }
        ModelOptionsPrompt.setOutputWriter { _ in }

        try testEmptyProfileReturnsNone()
        try testThinkingOffStillPromptsEffort()
        try testThinkingOnWithEffortAndAutoDefaults()
        try testEffortOnlyProfile()
    }

    private static func testEmptyProfileReturnsNone() throws {
        let options = ModelOptionsPrompt.prompt(for: .empty)
        try assertEqual(options, .none)
    }

    private static func testThinkingOffStillPromptsEffort() throws {
        var inputs = ["n", "2"]
        ModelOptionsPrompt.setLineReader {
            guard !inputs.isEmpty else { return nil }
            return inputs.removeFirst()
        }

        let profile = ModelParameterProfile(
            reasoningEffortLevels: ["low", "medium", "high"],
            supportsThinkingToggle: true,
            thinkingTypes: ["adaptive"]
        )

        let options = ModelOptionsPrompt.prompt(for: profile)
        try assertEqual(options.thinkingEnabled, false)
        try assertEqual(options.reasoningEffort, "medium")
        try assertEqual(options.thinkingType, nil)
    }

    private static func testThinkingOnWithEffortAndAutoDefaults() throws {
        var inputs = ["y", "1"]
        ModelOptionsPrompt.setLineReader {
            guard !inputs.isEmpty else { return nil }
            return inputs.removeFirst()
        }

        let profile = ModelParameterProfile(
            reasoningEffortLevels: ["low", "medium", "high"],
            supportsThinkingToggle: true,
            thinkingTypes: ["adaptive", "enabled"],
            supportsTemperature: true,
            supportsTopP: true,
            supportsVerbosity: true
        )

        let options = ModelOptionsPrompt.prompt(for: profile)
        try assertEqual(options.thinkingEnabled, true)
        try assertEqual(options.thinkingType, "adaptive")
        try assertEqual(options.reasoningEffort, "low")
    }

    private static func testEffortOnlyProfile() throws {
        var inputs = [""]
        ModelOptionsPrompt.setLineReader {
            guard !inputs.isEmpty else { return nil }
            return inputs.removeFirst()
        }

        let profile = ModelParameterProfile(
            reasoningEffortLevels: ["low", "medium", "high"]
        )

        let options = ModelOptionsPrompt.prompt(for: profile)
        try assertEqual(options.reasoningEffort, "medium")
        try assertEqual(options.thinkingEnabled, nil)
    }
}
