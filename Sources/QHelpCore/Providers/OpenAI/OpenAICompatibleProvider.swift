import Foundation

/// OpenAI Chat Completions API client used by OpenAI and compatible providers.
public final class OpenAICompatibleProvider: AIProvider {

    public let providerName: String
    public let displayName: String
    public let modelIdentifier: String

    private let kind: ProviderKind
    private let apiKey: String
    private let apiURL: URL
    private let supportsImages: Bool
    private let session: URLSession

    public init(
        kind: ProviderKind,
        modelIdentifier: String,
        displayName: String,
        apiKey: String,
        supportsImages: Bool,
        session: URLSession? = nil
    ) {
        self.kind = kind
        self.providerName = kind.displayName
        self.displayName = displayName
        self.modelIdentifier = modelIdentifier
        self.apiKey = apiKey
        self.supportsImages = supportsImages
        self.apiURL = ProviderCatalog.chatCompletionsURL(for: kind)!
        self.session = session ?? ProviderHTTP.makeSession()
    }

    public func send(content: ClipboardContent) async throws -> String {
        let body = try OpenAICompatibleAPI.buildRequestBody(
            modelIdentifier: modelIdentifier,
            content: content,
            supportsImages: supportsImages
        )

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = ProviderHTTP.timeoutInterval
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return try await ProviderHTTP.performRequest(
            request,
            session: session,
            parseResponse: OpenAICompatibleAPI.parseResponse,
            parseError: ProviderHTTP.parseOpenAIError
        )
    }

    public func cancelInFlightRequest() {
        session.invalidateAndCancel()
    }
}
