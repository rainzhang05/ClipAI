import Foundation
import QHelpCore

enum RequestOptionsAPITests: TestCase {
    static let name = "RequestOptionsAPITests"

    static func run() throws {
        try testAnthropicRequestOptions()
        try testOpenAICompatibleRequestOptions()
        try testGeminiRequestOptions()
        try testFetcherParserRouting()
    }

    private static func testAnthropicRequestOptions() throws {
        let options = ModelRequestOptions(
            reasoningEffort: "medium",
            thinkingEnabled: true,
            thinkingType: "adaptive"
        )

        let body = AnthropicAPI.buildRequestBody(
            modelIdentifier: "claude-sonnet-4-6",
            content: .text("hello"),
            options: options
        )

        let thinking = body["thinking"] as? [String: Any]
        try assertEqual(thinking?["type"] as? String, "adaptive")

        let outputConfig = body["output_config"] as? [String: Any]
        try assertEqual(outputConfig?["effort"] as? String, "medium")

        let enabledOptions = ModelRequestOptions(
            thinkingEnabled: true,
            thinkingType: "enabled"
        )
        let enabledBody = AnthropicAPI.buildRequestBody(
            modelIdentifier: "claude-sonnet-4-6",
            content: .text("hello"),
            options: enabledOptions
        )
        let enabledThinking = enabledBody["thinking"] as? [String: Any]
        try assertEqual(enabledThinking?["type"] as? String, "enabled")
        try assertEqual(enabledThinking?["budget_tokens"] as? Int, AnthropicAPI.defaultThinkingBudgetTokens)
    }

    private static func testOpenAICompatibleRequestOptions() throws {
        let options = ModelRequestOptions(
            reasoningEffort: "low",
            temperature: 0.0,
            topP: 1.0,
            verbosity: "low"
        )

        let body = try OpenAICompatibleAPI.buildRequestBody(
            modelIdentifier: "gpt-5.5",
            content: .text("hello"),
            supportsImages: true,
            options: options
        )

        try assertEqual(body["reasoning_effort"] as? String, "low")
        try assertEqual(body["temperature"] as? Double, 0.0)
        try assertEqual(body["top_p"] as? Double, 1.0)
        try assertEqual(body["verbosity"] as? String, "low")
    }

    private static func testGeminiRequestOptions() throws {
        let enabled = ModelRequestOptions(
            thinkingEnabled: true,
            temperature: 0.0,
            topP: 1.0
        )

        let enabledBody = try GeminiAPI.buildRequestBody(
            content: .text("hello"),
            supportsImages: true,
            options: enabled
        )

        let enabledConfig = enabledBody["generationConfig"] as? [String: Any]
        try assertEqual(enabledConfig?["temperature"] as? Double, 0.0)
        try assertEqual(enabledConfig?["topP"] as? Double, 1.0)
        let enabledThinking = enabledConfig?["thinkingConfig"] as? [String: Any]
        try assertEqual(enabledThinking?["thinkingBudget"] as? Int, 8192)

        let disabled = ModelRequestOptions(thinkingEnabled: false)
        let disabledBody = try GeminiAPI.buildRequestBody(
            content: .text("hello"),
            supportsImages: true,
            options: disabled
        )
        let disabledConfig = disabledBody["generationConfig"] as? [String: Any]
        let disabledThinking = disabledConfig?["thinkingConfig"] as? [String: Any]
        try assertEqual(disabledThinking?["thinkingBudget"] as? Int, 0)
    }

    private static func testFetcherParserRouting() throws {
        let anthropicData = Data("""
        {"capabilities":{"effort":{"supported":true,"low":{"supported":true}}}}
        """.utf8)
        let anthropicProfile = ModelCapabilityFetcher.parseResponse(kind: .anthropic, data: anthropicData)
        try assertEqual(anthropicProfile.reasoningEffortLevels, ["low"])

        let geminiData = Data("""
        {"thinking":true,"temperature":1.0}
        """.utf8)
        let geminiProfile = ModelCapabilityFetcher.parseResponse(kind: .gemini, data: geminiData)
        try assertTrue(geminiProfile.supportsThinkingToggle)
        try assertTrue(geminiProfile.supportsTemperature)
    }
}
