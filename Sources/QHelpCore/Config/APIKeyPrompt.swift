import Darwin
import Foundation

enum APIKeyPrompt {

    static func readKey(for kind: ProviderKind) -> String? {
        print("")
        print("\(kind.displayName) API key required.")
        print("Your key will be saved securely in the macOS Keychain.")
        print("Environment override: \(kind.envVarName)")
        print("")

        guard let cString = getpass("API key: ") else { return nil }

        let key = String(cString: cString).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }

        print("API key saved.")
        print("")
        return key
    }

    static func readAnthropicKey() -> String? {
        readKey(for: .anthropic)
    }
}
