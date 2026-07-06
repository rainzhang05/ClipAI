import Foundation
import QHelpCore

enum RequestOptionsAPITests: TestCase {
    static let name = "RequestOptionsAPITests"

    static func run() throws {
        try testAnthropicRequestOptions()
        try testAnthropicEffortWithoutThinking()
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

        let textMessage = AnthropicAPI.buildUserMessage(content: .text("hello"))
        let body = AnthropicAPI.buildRequestBody(
            modelIdentifier: "claude-sonnet-4-6",
            messages: [textMessage],
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
        let enabledMessage = AnthropicAPI.buildUserMessage(content: .text("hello"))
        let enabledBody = AnthropicAPI.buildRequestBody(
            modelIdentifier: "claude-sonnet-4-6",
            messages: [enabledMessage],
            options: enabledOptions
        )
        let enabledThinking = enabledBody["thinking"] as? [String: Any]
        try assertEqual(enabledThinking?["type"] as? String, "enabled")
        try assertEqual(enabledThinking?["budget_tokens"] as? Int, AnthropicAPI.defaultThinkingBudgetTokens)
    }

    private static func testAnthropicEffortWithoutThinking() throws {
        let options = ModelRequestOptions(
            reasoningEffort: "high",
            thinkingEnabled: false
        )

        let textMessage = AnthropicAPI.buildUserMessage(content: .text("hello"))
        let body = AnthropicAPI.buildRequestBody(
            modelIdentifier: "claude-opus-4-8",
            messages: [textMessage],
            options: options
        )

        try assertTrue(body["thinking"] == nil)

        let outputConfig = body["output_config"] as? [String: Any]
        try assertEqual(outputConfig?["effort"] as? String, "high")

        let adaptiveOnly = ModelRequestOptions(
            reasoningEffort: "medium",
            thinkingEnabled: true,
            thinkingType: "adaptive"
        )
        let textMessage2 = AnthropicAPI.buildUserMessage(content: .text("hello"))
        let adaptiveBody = AnthropicAPI.buildRequestBody(
            modelIdentifier: "claude-opus-4-8",
            messages: [textMessage2],
            options: adaptiveOnly
        )
        let thinking = adaptiveBody["thinking"] as? [String: Any]
        try assertEqual(thinking?["type"] as? String, "adaptive")
        try assertTrue(thinking?["budget_tokens"] == nil)
    }

    private static func testOpenAICompatibleRequestOptions() throws {
        let options = ModelRequestOptions(
            reasoningEffort: "low",
            temperature: 0.0,
            topP: 1.0,
            verbosity: "low"
        )

        let textMessage = try OpenAICompatibleAPI.buildUserMessage(
            content: .text("hello"),
            supportsImages: true
        )
        let body = OpenAICompatibleAPI.buildRequestBody(
            modelIdentifier: "gpt-5.5",
            messages: [textMessage],
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

        let textMessage = try GeminiAPI.buildUserMessage(
            content: .text("hello"),
            supportsImages: true
        )
        let enabledBody = GeminiAPI.buildRequestBody(
            contents: [textMessage],
            options: enabled
        )

        let enabledConfig = enabledBody["generationConfig"] as? [String: Any]
        try assertEqual(enabledConfig?["temperature"] as? Double, 0.0)
        try assertEqual(enabledConfig?["topP"] as? Double, 1.0)
        let enabledThinking = enabledConfig?["thinkingConfig"] as? [String: Any]
        try assertEqual(enabledThinking?["thinkingBudget"] as? Int, 8192)

        let disabled = ModelRequestOptions(thinkingEnabled: false)
        let textMessage2 = try GeminiAPI.buildUserMessage(
            content: .text("hello"),
            supportsImages: true
        )
        let disabledBody = GeminiAPI.buildRequestBody(
            contents: [textMessage2],
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
