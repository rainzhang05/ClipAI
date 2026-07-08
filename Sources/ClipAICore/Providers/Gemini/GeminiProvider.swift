import Foundation

public final class GeminiProvider: AIProvider {

    public let providerName = "Google Gemini"
    public let displayName: String
    public let modelIdentifier: String

    private let apiKey: String
    private let supportsImages: Bool
    private let requestOptions: ModelRequestOptions
    private let session: URLSession
    private var history: [[String: Any]] = []

    public init(
        modelIdentifier: String,
        displayName: String,
        apiKey: String,
        supportsImages: Bool,
        requestOptions: ModelRequestOptions = .none,
        session: URLSession? = nil
    ) {
        self.displayName = displayName
        self.modelIdentifier = modelIdentifier
        self.apiKey = apiKey
        self.supportsImages = supportsImages
        self.requestOptions = requestOptions
        self.session = session ?? ProviderHTTP.makeSession()
    }

    public func send(content: ClipboardContent) async throws -> String {
        guard let url = ProviderCatalog.geminiGenerateContentURL(
            modelIdentifier: modelIdentifier,
            apiKey: apiKey
        ) else {
            throw ProviderError.invalidResponse
        }

        let userMessage = try GeminiAPI.buildUserMessage(
            content: content,
            supportsImages: supportsImages
        )
        let currentMessages = history + [userMessage]

        let body = GeminiAPI.buildRequestBody(
            contents: currentMessages,
            options: requestOptions
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = ProviderHTTP.timeoutInterval
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let responseText = try await ProviderHTTP.performRequest(
            request,
            session: session,
            parseResponse: GeminiAPI.parseResponse,
            parseError: GeminiAPI.parseError
        )

        history = currentMessages + [
            [
                "role": "model",
                "parts": [["text": responseText]]
            ]
        ]
        return responseText
    }

    public func cancelInFlightRequest() {
        session.invalidateAndCancel()
    }
}
