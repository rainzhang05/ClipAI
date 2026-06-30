import Foundation

public enum ProviderKind: String, CaseIterable, Sendable {
    case anthropic
    case openai
    case gemini
    case grok
    case kimi
    case deepseek
    case qwen
    case glm

    public var displayName: String {
        switch self {
        case .anthropic: return "Anthropic"
        case .openai: return "OpenAI"
        case .gemini: return "Google Gemini"
        case .grok: return "xAI Grok"
        case .kimi: return "Moonshot Kimi"
        case .deepseek: return "DeepSeek"
        case .qwen: return "Qwen"
        case .glm: return "Zhipu GLM"
        }
    }

    public var envVarName: String {
        switch self {
        case .anthropic: return "ANTHROPIC_API_KEY"
        case .openai: return "OPENAI_API_KEY"
        case .gemini: return "GEMINI_API_KEY"
        case .grok: return "XAI_API_KEY"
        case .kimi: return "MOONSHOT_API_KEY"
        case .deepseek: return "DEEPSEEK_API_KEY"
        case .qwen: return "DASHSCOPE_API_KEY"
        case .glm: return "ZHIPU_API_KEY"
        }
    }

    public var keychainService: String {
        "qhelp.\(rawValue)"
    }

    public var defaultSupportsImages: Bool {
        switch self {
        case .anthropic, .openai, .gemini, .grok, .kimi, .qwen, .glm:
            return true
        case .deepseek:
            return false
        }
    }
}
