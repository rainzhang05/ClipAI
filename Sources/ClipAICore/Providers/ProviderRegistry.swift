import Foundation

/// Registry for resolving model names to AI provider instances.
public enum ProviderRegistry {

    // MARK: - Public Interface

    public static func resolve(
        modelName: String,
        options: ModelRequestOptions = .none,
        promptIfMissing: Bool = true
    ) -> AIProvider? {
        guard let kind = ProviderCatalog.kind(for: modelName) else {
            return nil
        }

        guard let apiKey = APIKeyStore.resolveKey(for: kind, promptIfMissing: promptIfMissing),
              !apiKey.isEmpty else {
            return nil
        }

        return makeProvider(
            modelName: modelName,
            kind: kind,
            apiKey: apiKey,
            options: options
        )
    }

    public static func makeProvider(
        modelName: String,
        apiKey: String,
        options: ModelRequestOptions = .none
    ) -> AIProvider? {
        guard let kind = ProviderCatalog.kind(for: modelName),
              !apiKey.isEmpty else {
            return nil
        }

        return makeProvider(
            modelName: modelName,
            kind: kind,
            apiKey: apiKey,
            options: options
        )
    }

    public static func fetchCapabilities(
        modelName: String,
        apiKey: String
    ) async -> ModelParameterProfile {
        guard let kind = ProviderCatalog.kind(for: modelName) else {
            return .empty
        }

        let modelIdentifier = ProviderCatalog.modelIdentifier(for: modelName)
        return await ModelCapabilityFetcher.fetch(
            kind: kind,
            modelIdentifier: modelIdentifier,
            apiKey: apiKey
        )
    }

    public static func resolveAPIKey(for modelName: String, promptIfMissing: Bool = true) -> String? {
        guard let kind = ProviderCatalog.kind(for: modelName) else {
            return nil
        }

        return APIKeyStore.resolveKey(for: kind, promptIfMissing: promptIfMissing)
    }

    public static func providerKind(for modelName: String) -> ProviderKind? {
        ProviderCatalog.kind(for: modelName)
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

    // MARK: - Private

    private static func makeProvider(
        modelName: String,
        kind: ProviderKind,
        apiKey: String,
        options: ModelRequestOptions
    ) -> AIProvider {
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
                apiKey: apiKey,
                requestOptions: options
            )

        case .openai, .grok, .kimi, .deepseek, .qwen, .glm:
            return OpenAICompatibleProvider(
                kind: kind,
                modelIdentifier: modelIdentifier,
                displayName: modelName,
                apiKey: apiKey,
                supportsImages: supportsImages,
                requestOptions: options
            )

        case .gemini:
            return GeminiProvider(
                modelIdentifier: modelIdentifier,
                displayName: modelName,
                apiKey: apiKey,
                supportsImages: supportsImages,
                requestOptions: options
            )
        }
    }
}
