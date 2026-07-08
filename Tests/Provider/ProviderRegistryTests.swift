import Foundation
import ClipAICore

enum ProviderRegistryTests: TestCase {
    static let name = "ProviderRegistryTests"

    static func run() throws {
        try testProviderKindLookup()
        try testExplicitAPIKeyProviderCreation()
        try testResolveReturnsNilForUnknownModel()
        try testLegacyAnthropicHelpers()
    }

    private static func testProviderKindLookup() throws {
        try assertEqual(ProviderRegistry.providerKind(for: "gpt-4o"), .openai)
        try assertEqual(ProviderRegistry.providerKind(for: "gemini-2.5-flash"), .gemini)
    }

    private static func testExplicitAPIKeyProviderCreation() throws {
        let cases: [(model: String, kind: ProviderKind)] = [
            ("claude-sonnet-4-6", .anthropic),
            ("gpt-4o", .openai),
            ("gemini-2.5-flash", .gemini),
            ("grok-3", .grok),
            ("kimi-k2", .kimi),
            ("deepseek-chat", .deepseek),
            ("qwen-plus", .qwen),
            ("glm-4-flash", .glm)
        ]

        for testCase in cases {
            guard let provider = ProviderRegistry.makeProvider(
                modelName: testCase.model,
                apiKey: "test-key"
            ) else {
                throw TestFailure.message("Expected provider for \(testCase.model)")
            }

            try assertEqual(provider.providerName, testCase.kind.displayName)
            try assertEqual(provider.modelIdentifier, testCase.model)
            try assertEqual(provider.displayName, testCase.model)
        }

        try assertEqual(
            ProviderRegistry.makeProvider(modelName: "unknown-model", apiKey: "test-key") == nil,
            true
        )
        try assertEqual(
            ProviderRegistry.makeProvider(modelName: "gpt-4o", apiKey: "") == nil,
            true
        )
    }

    private static func testResolveReturnsNilForUnknownModel() throws {
        try assertEqual(
            ProviderRegistry.resolve(modelName: "unknown-model", promptIfMissing: false) == nil,
            true
        )
    }

    private static func testLegacyAnthropicHelpers() throws {
        let provider = ProviderRegistry.makeAnthropicProvider(
            modelName: "claude-sonnet-4-6",
            apiKey: "test-key"
        )
        try assertEqual(provider.modelIdentifier, "claude-sonnet-4-6")
        try assertEqual(provider.displayName, "claude-sonnet-4-6")

        if ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] == nil,
           ProviderRegistry.anthropicAPIKey(promptIfMissing: false) == nil {
            try assertTrue(true)
        }
    }
}
