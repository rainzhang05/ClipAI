import Foundation

/// Parsed command-line configuration.
public struct CLIConfig: Equatable {
    public let modelAlias: String
}

public enum CLIParseResult: Equatable {
    case config(CLIConfig)
    case help
    case version
    case invalidUsage
}

public enum CLIParser {

    public static let version = "1.1.0"

    public static func parseResult(_ arguments: [String]) -> CLIParseResult {
        let args = Array(arguments.dropFirst())

        if args.contains("--help") || args.contains("-h") {
            return .help
        }

        if args.contains("--version") || args.contains("-v") {
            return .version
        }

        guard let modelAlias = args.first, !modelAlias.hasPrefix("-") else {
            return .invalidUsage
        }

        return .config(CLIConfig(modelAlias: modelAlias))
    }

    public static func parse(_ arguments: [String]) -> CLIConfig {
        switch parseResult(arguments) {
        case .config(let config):
            return config
        case .help:
            printUsage()
            exit(0)
        case .version:
            print("qhelp \(version)")
            exit(0)
        case .invalidUsage:
            printUsage()
            exit(1)
        }
    }

    public static func usageText() -> String {
        """
        qhelp — Clipboard-to-AI utility for macOS

        USAGE:
          qhelp <model>

        DESCRIPTION:
          Monitors the macOS system clipboard. When new content appears
          (text or image), sends it to the specified AI model and displays
          the response in a floating overlay.

        OVERLAY:
          Stays visible until you click the header to dismiss.
          Scroll and copy response text without changing your active app.

        MODELS (Anthropic):
          claude-sonnet-4-6, claude-opus-4-1, claude-sonnet-4
          claude-haiku-4-5, claude-haiku-3-5

        MODELS (OpenAI):
          gpt-4o, gpt-4.1, gpt-4.1-mini, o3-mini, o4-mini

        MODELS (Gemini):
          gemini-2.5-flash, gemini-2.5-pro, gemini-2.0-flash

        MODELS (Grok):
          grok-3, grok-3-mini, grok-2-vision-1212

        MODELS (Kimi):
          kimi-k2, kimi-k2-turbo, moonshot-v1-128k, moonshot-v1-32k

        MODELS (DeepSeek):
          deepseek-chat, deepseek-reasoner

        MODELS (Qwen):
          qwen-plus, qwen-max, qwen-turbo, qwen-vl-plus

        MODELS (GLM):
          glm-4-plus, glm-4-flash, glm-4v-plus

        Unknown aliases within a provider family are passed through to the API.

        API KEYS:
          Keys are saved in the macOS Keychain on first use per provider.
          Environment variables override Keychain when set:

          ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY, XAI_API_KEY
          MOONSHOT_API_KEY, DEEPSEEK_API_KEY, DASHSCOPE_API_KEY, ZHIPU_API_KEY

          QWEN_BASE_URL — optional override for Qwen/DashScope endpoint

        OPTIONS:
          -h, --help       Show this help message
          -v, --version    Show version number
        """
    }

    private static func printUsage() {
        print(usageText())
    }
}
