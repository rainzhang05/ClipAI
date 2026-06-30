import Foundation

/// Registry for resolving model names to AI provider instances.
public enum ProviderRegistry {

    // MARK: - Public Interface

    public static func resolve(modelName: String) -> AIProvider? {
        guard let kind = ProviderCatalog.kind(for: modelName) else {
            return nil
        }

        guard let apiKey = APIKeyStore.resolveKey(for: kind, promptIfMissing: true),
              !apiKey.isEmpty else {
            print("Error: No \(kind.displayName) API key found.")
            print("Set \(kind.envVarName) or enter your key when prompted.")
            exit(1)
        }

        let modelIdentifier = ProviderCatalog.modelIdentifier(for: modelName)
        let supportsImages = ProviderCatalog.supportsImages(
            modelIdentifier: modelIdentifier,
            kind: kind
        )

        switch kind {
        case .anthropic:
            return AnthropicProvider(
                modelIdentifier: modelIdentifier,
                displayName: modelName,
                apiKey: apiKey
            )

        case .openai, .grok, .kimi, .deepseek, .qwen, .glm:
            return OpenAICompatibleProvider(
                kind: kind,
                modelIdentifier: modelIdentifier,
                displayName: modelName,
                apiKey: apiKey,
                supportsImages: supportsImages
            )

        case .gemini:
            return GeminiProvider(
                modelIdentifier: modelIdentifier,
                displayName: modelName,
                apiKey: apiKey,
                supportsImages: supportsImages
            )
        }
    }

    // MARK: - Testing Helpers

    public static func makeAnthropicProvider(modelName: String, apiKey: String) -> AIProvider {
        AnthropicProvider(
            modelIdentifier: ProviderCatalog.modelIdentifier(for: modelName),
            displayName: modelName,
            apiKey: apiKey
        )
    }

    public static func anthropicAPIKey(promptIfMissing: Bool = false) -> String? {
        APIKeyStore.resolveKey(for: .anthropic, promptIfMissing: promptIfMissing)
    }

    public static func providerKind(for modelName: String) -> ProviderKind? {
        ProviderCatalog.kind(for: modelName)
    }
}
