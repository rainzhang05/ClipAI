import AppKit

public enum ClipAIApplication {

    public static func run(with arguments: [String]) {
        let config = CLIParser.parse(arguments)

        guard let kind = ProviderCatalog.kind(for: config.modelName) else {
            exitWithRoutingError(modelName: config.modelName)
        }

        guard let apiKey = ProviderRegistry.resolveAPIKey(for: config.modelName, promptIfMissing: true),
              !apiKey.isEmpty else {
            exitWithMissingAPIKey(kind: kind)
        }

        print("ClipAI\n")
        print("Provider: \(kind.displayName)")
        print("Model: \(config.modelName)\n")

        let profile = fetchCapabilities(modelName: config.modelName, apiKey: apiKey)
        let options = ModelOptionsPrompt.prompt(for: profile)

        guard let provider = ProviderRegistry.makeProvider(
            modelName: config.modelName,
            apiKey: apiKey,
            options: options
        ) else {
            exitWithRoutingError(modelName: config.modelName)
        }

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let overlayManager = OverlayManager()
        let requestQueue = RequestQueue(provider: provider, overlayManager: overlayManager)
        let clipboardMonitor = ClipboardMonitor(queue: requestQueue)

        func shutdown() {
            print("\n\nShutting down...")
            clipboardMonitor.stop()
            Task {
                await requestQueue.cancelAll()
                await MainActor.run {
                    NSApp.terminate(nil)
                }
            }
        }

        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signal(SIGINT, SIG_IGN)
        sigintSource.setEventHandler { shutdown() }
        sigintSource.resume()

        let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        signal(SIGTERM, SIG_IGN)
        sigtermSource.setEventHandler { shutdown() }
        sigtermSource.resume()

        print("Watching clipboard...\n")
        print("Press Ctrl+C to quit.")

        clipboardMonitor.start()
        app.run()
    }

    private static func fetchCapabilities(modelName: String, apiKey: String) -> ModelParameterProfile {
        var profile = ModelParameterProfile.empty
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            profile = await ProviderRegistry.fetchCapabilities(
                modelName: modelName,
                apiKey: apiKey
            )
            semaphore.signal()
        }

        semaphore.wait()
        return profile
    }

    private static func exitWithRoutingError(modelName: String) -> Never {
        print("Error: Cannot route model '\(modelName)' to a provider.")
        print("\nUse an exact API model name with a recognized prefix:\n")
        print(ProviderCatalog.routingHelp)
        exit(1)
    }

    private static func exitWithMissingAPIKey(kind: ProviderKind) -> Never {
        print("Error: No \(kind.displayName) API key found.")
        print("Set \(kind.envVarName) or enter your key when prompted.")
        exit(1)
    }
}
