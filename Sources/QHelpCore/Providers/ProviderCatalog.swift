import Foundation

/// Provider metadata: routing, model aliases, and endpoints.
public enum ProviderCatalog {

    // MARK: - Model Maps

    private static let anthropicModels: [String: String] = [
        "claude-sonnet-4-6": "claude-sonnet-4-6",
        "claude-opus-4-1": "claude-opus-4-1",
        "claude-sonnet-4": "claude-sonnet-4-5-20250929",
        "claude-haiku-4-5": "claude-haiku-4-5-20251001",
        "claude-haiku-3-5": "claude-3-5-haiku-20241022",
    ]

    private static let openaiModels: [String: String] = [
        "gpt-4o": "gpt-4o",
        "gpt-4.1": "gpt-4.1",
        "gpt-4.1-mini": "gpt-4.1-mini",
        "o3-mini": "o3-mini",
        "o4-mini": "o4-mini",
    ]

    private static let geminiModels: [String: String] = [
        "gemini-2.5-flash": "gemini-2.5-flash",
        "gemini-2.5-pro": "gemini-2.5-pro",
        "gemini-2.0-flash": "gemini-2.0-flash",
    ]

    private static let grokModels: [String: String] = [
        "grok-3": "grok-3",
        "grok-3-mini": "grok-3-mini",
        "grok-2-vision-1212": "grok-2-vision-1212",
    ]

    private static let kimiModels: [String: String] = [
        "kimi-k2": "kimi-k2-0711-preview",
        "kimi-k2-turbo": "kimi-k2-turbo-preview",
        "moonshot-v1-128k": "moonshot-v1-128k",
        "moonshot-v1-32k": "moonshot-v1-32k",
    ]

    private static let deepseekModels: [String: String] = [
        "deepseek-chat": "deepseek-chat",
        "deepseek-reasoner": "deepseek-reasoner",
    ]

    private static let qwenModels: [String: String] = [
        "qwen-plus": "qwen-plus",
        "qwen-max": "qwen-max",
        "qwen-turbo": "qwen-turbo",
        "qwen-vl-plus": "qwen-vl-plus",
    ]

    private static let glmModels: [String: String] = [
        "glm-4-plus": "glm-4-plus",
        "glm-4-flash": "glm-4-flash",
        "glm-4v-plus": "glm-4v-plus",
    ]

    // MARK: - Public

    public static var allModelAliases: [String] {
        var models: [String] = []
        models.append(contentsOf: anthropicModels.keys)
        models.append(contentsOf: openaiModels.keys)
        models.append(contentsOf: geminiModels.keys)
        models.append(contentsOf: grokModels.keys)
        models.append(contentsOf: kimiModels.keys)
        models.append(contentsOf: deepseekModels.keys)
        models.append(contentsOf: qwenModels.keys)
        models.append(contentsOf: glmModels.keys)
        return models.sorted()
    }

    public static func kind(for modelAlias: String) -> ProviderKind? {
        if modelAlias.hasPrefix("claude") { return .anthropic }
        if modelAlias.hasPrefix("gpt")
            || modelAlias.hasPrefix("o1")
            || modelAlias.hasPrefix("o3")
            || modelAlias.hasPrefix("o4") { return .openai }
        if modelAlias.hasPrefix("gemini") { return .gemini }
        if modelAlias.hasPrefix("grok") { return .grok }
        if modelAlias.hasPrefix("kimi") || modelAlias.hasPrefix("moonshot") { return .kimi }
        if modelAlias.hasPrefix("deepseek") { return .deepseek }
        if modelAlias.hasPrefix("qwen") { return .qwen }
        if modelAlias.hasPrefix("glm") { return .glm }
        return nil
    }

    public static func modelIdentifier(for alias: String, kind: ProviderKind) -> String {
        let map = modelMap(for: kind)
        return map[alias] ?? alias
    }

    public static func supportsImages(modelIdentifier: String, kind: ProviderKind) -> Bool {
        if !kind.defaultSupportsImages { return false }

        switch kind {
        case .deepseek:
            return false
        case .qwen:
            return modelIdentifier.contains("vl") || modelIdentifier.contains("vision")
        case .glm:
            return modelIdentifier.contains("v") || modelIdentifier.contains("vision")
        case .kimi:
            return modelIdentifier.contains("vision") || modelIdentifier.contains("k2")
        default:
            return true
        }
    }

    public static func openAICompatibleBaseURL(for kind: ProviderKind) -> URL? {
        let urlString: String
        switch kind {
        case .openai:
            urlString = "https://api.openai.com/v1"
        case .grok:
            urlString = "https://api.x.ai/v1"
        case .kimi:
            urlString = "https://api.moonshot.cn/v1"
        case .deepseek:
            urlString = "https://api.deepseek.com"
        case .qwen:
            if let override = ProcessInfo.processInfo.environment["QWEN_BASE_URL"],
               !override.isEmpty {
                urlString = override
            } else {
                urlString = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1"
            }
        case .glm:
            urlString = "https://open.bigmodel.cn/api/paas/v4"
        case .anthropic, .gemini:
            return nil
        }

        return URL(string: urlString)
    }

    public static func chatCompletionsURL(for kind: ProviderKind) -> URL? {
        guard let base = openAICompatibleBaseURL(for: kind) else { return nil }
        return base.appendingPathComponent("chat/completions")
    }

    public static func geminiGenerateContentURL(modelIdentifier: String, apiKey: String) -> URL? {
        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelIdentifier):generateContent")
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        return components?.url
    }

    // MARK: - Private

    private static func modelMap(for kind: ProviderKind) -> [String: String] {
        switch kind {
        case .anthropic: return anthropicModels
        case .openai: return openaiModels
        case .gemini: return geminiModels
        case .grok: return grokModels
        case .kimi: return kimiModels
        case .deepseek: return deepseekModels
        case .qwen: return qwenModels
        case .glm: return glmModels
        }
    }
}
