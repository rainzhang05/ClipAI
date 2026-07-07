import Foundation

/// Parsed command-line configuration.
public struct CLIConfig: Equatable {
    public let modelName: String
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

        guard let modelName = args.first, !modelName.hasPrefix("-") else {
            return .invalidUsage
        }

        return .config(CLIConfig(modelName: modelName))
    }

    public static func parse(_ arguments: [String]) -> CLIConfig {
        switch parseResult(arguments) {
        case .config(let config):
            return config
        case .help:
            printUsage()
            exit(0)
        case .version:
            print("clip \(version)")
            exit(0)
        case .invalidUsage:
            printUsage()
            exit(1)
        }
    }

    public static func usageText() -> String {
        """
        ClipAI — Clipboard-to-AI utility for macOS

        USAGE:
          clip <model>

        DESCRIPTION:
          Monitors the macOS system clipboard. When new content appears
          (text or image), sends it to the specified AI model and displays
          the response in a floating overlay.

          Pass the exact model name from your provider's API documentation.
          ClipAI routes by name prefix and sends the model string verbatim.
          Invalid or unavailable models return an API error from the provider.

        OVERLAY:
          Stays visible until you click the header to dismiss.
          Press c while the overlay is visible to copy the full response once.
          Press Space while the overlay is visible to dismiss it.
          If macOS has not granted keyboard monitoring permission, click the
          overlay before pressing c or Space.

        PROVIDER ROUTING (model name prefix):
        \(ProviderCatalog.routingHelp)
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
