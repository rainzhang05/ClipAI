import Foundation

/// Anthropic Claude API provider.
///
/// Supports text and image inputs via the Messages API.
/// Images are sent as base64-encoded data.
///
/// API reference: https://docs.anthropic.com/en/api/messages
public final class AnthropicProvider: AIProvider {

    public let providerName = "Anthropic"
    public let displayName: String
    public let modelIdentifier: String

    private let apiKey: String
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let session: URLSession
    private let timeoutInterval: TimeInterval = 120

    // MARK: - Initialization

    public init(modelIdentifier: String, displayName: String, apiKey: String, session: URLSession? = nil) {
        self.modelIdentifier = modelIdentifier
        self.displayName = displayName
        self.apiKey = apiKey

        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 120
            configuration.timeoutIntervalForResource = 120
            self.session = URLSession(configuration: configuration)
        }
    }

    // MARK: - AIProvider

    public func send(content: ClipboardContent) async throws -> String {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(AnthropicAPI.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = timeoutInterval

        let body = AnthropicAPI.buildRequestBody(modelIdentifier: modelIdentifier, content: content)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return try await performRequest(request)
    }

    public func cancelInFlightRequest() {
        session.invalidateAndCancel()
    }

    // MARK: - Networking

    private func performRequest(_ request: URLRequest) async throws -> String {
        var attempt = 0

        while true {
            try Task.checkCancellation()

            let data: Data
            let response: URLResponse

            do {
                (data, response) = try await session.data(for: request)
            } catch {
                throw AnthropicAPI.mapNetworkError(error)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProviderError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                return try AnthropicAPI.parseResponse(data: data)
            }

            if httpResponse.statusCode == 429, attempt < AnthropicAPI.maxRateLimitRetries {
                let retryAfter = AnthropicAPI.parseRetryAfter(
                    httpResponse.value(forHTTPHeaderField: "Retry-After")
                )
                let delay = AnthropicAPI.backoffDelay(for: attempt, retryAfter: retryAfter)
                attempt += 1
                try await Task.sleep(nanoseconds: delay)
                continue
            }

            throw AnthropicAPI.parseError(
                statusCode: httpResponse.statusCode,
                data: data,
                retryAfterHeader: httpResponse.value(forHTTPHeaderField: "Retry-After")
            )
        }
    }
}
