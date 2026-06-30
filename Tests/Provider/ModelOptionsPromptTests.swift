import Foundation
import QHelpCore

enum ModelOptionsPromptTests: TestCase {
    static let name = "ModelOptionsPromptTests"

    static func run() throws {
        defer { ModelOptionsPrompt.setLineReader(nil) }

        try testEmptyProfileReturnsNone()
        try testThinkingOffSkipsEffort()
        try testThinkingOnWithEffortAndAutoDefaults()
        try testEffortOnlyProfile()
    }

    private static func testEmptyProfileReturnsNone() throws {
        let options = ModelOptionsPrompt.prompt(for: .empty)
        try assertEqual(options, .none)
    }

    private static func testThinkingOffSkipsEffort() throws {
        var inputs = ["n"]
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
        try assertEqual(options.reasoningEffort, nil)
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
        try assertEqual(options.temperature, 0.0)
        try assertEqual(options.topP, 1.0)
        try assertEqual(options.verbosity, "low")
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
