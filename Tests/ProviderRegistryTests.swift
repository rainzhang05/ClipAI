import Foundation
import QHelpCore

enum ProviderRegistryTests: TestCase {
    static let name = "ProviderRegistryTests"

    static func run() throws {
        try assertEqual(
            ProviderRegistry.anthropicModelIdentifier(for: "claude-sonnet-4-6"),
            "claude-sonnet-4-6"
        )
        try assertEqual(
            ProviderRegistry.providerKind(for: "gpt-4o"),
            .openai
        )
        try assertEqual(
            ProviderRegistry.providerKind(for: "gemini-2.5-flash"),
            .gemini
        )

        let provider = ProviderRegistry.makeAnthropicProvider(
            modelAlias: "claude-sonnet-4-6",
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
