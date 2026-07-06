import Foundation

/// Pure Anthropic Messages API helpers (request building and response parsing).
public enum AnthropicAPI {

    public static let apiVersion = "2023-06-01"
    public static let maxTokens = 4096
    public static let imagePrompt = "Describe this clipboard content."
    public static let maxRateLimitRetries = 2
    public static let defaultThinkingBudgetTokens = 4096

    public static func buildRequestBody(
        modelIdentifier: String,
        content: ClipboardContent,
        options: ModelRequestOptions = .none
    ) -> [String: Any] {
        let messageContent: Any

        switch content {
        case .text(let text):
            messageContent = text

        case .image(let imageData, let mediaType):
            messageContent = [
                [
                    "type": "image",
                    "source": [
                        "type": "base64",
                        "media_type": mediaType,
                        "data": imageData.base64EncodedString()
                    ] as [String: String]
                ] as [String: Any],
                [
                    "type": "text",
                    "text": imagePrompt
                ] as [String: Any]
            ]
        }

        var body: [String: Any] = [
            "model": modelIdentifier,
            "max_tokens": maxTokens,
            "messages": [
                [
                    "role": "user",
                    "content": messageContent
                ] as [String: Any]
            ]
        ]

        applyOptions(options, to: &body)
        return body
    }

    static func applyOptions(_ options: ModelRequestOptions, to body: inout [String: Any]) {
        if options.thinkingEnabled == true, let type = options.thinkingType {
            switch type {
            case "enabled":
                body["thinking"] = [
                    "type": "enabled",
                    "budget_tokens": defaultThinkingBudgetTokens
                ] as [String: Any]
                body["max_tokens"] = maxTokens + defaultThinkingBudgetTokens
            case "adaptive":
                body["thinking"] = ["type": "adaptive"]
            default:
                body["thinking"] = ["type": type]
            }
        }

        if let effort = options.reasoningEffort {
            body["output_config"] = ["effort": effort]
        }

        if let temperature = options.temperature {
            body["temperature"] = temperature
        }

        if let topP = options.topP {
            body["top_p"] = topP
        }
    }

    public static func parseResponse(data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]] else {
            throw ProviderError.invalidResponse
        }

        let textBlocks = contentArray.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }

        guard !textBlocks.isEmpty else {
            throw ProviderError.invalidResponse
        }

        return textBlocks.joined(separator: "\n")
    }

    public static func parseError(statusCode: Int, data: Data, retryAfterHeader: String?) -> ProviderError {
        if statusCode == 429 {
            let retryAfter = parseRetryAfter(retryAfterHeader)
            return .rateLimited(retryAfter: retryAfter)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return .apiError(statusCode: statusCode, message: message)
        }

        return .apiError(statusCode: statusCode, message: "Unknown error (HTTP \(statusCode))")
    }

    public static func parseRetryAfter(_ header: String?) -> Int? {
        guard let header, let seconds = Int(header), seconds > 0 else {
            return nil
        }
        return seconds
    }

    public static func backoffDelay(for attempt: Int, retryAfter: Int?) -> UInt64 {
        if let retryAfter {
            return UInt64(retryAfter) * 1_000_000_000
        }
        let baseDelay = UInt64(pow(2.0, Double(attempt + 1))) * 1_000_000_000
        return baseDelay
    }

    public static func mapNetworkError(_ error: Error) -> Error {
        if error is ProviderError || error is CancellationError {
            return error
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return ProviderError.timeout
            case .notConnectedToInternet, .networkConnectionLost:
                return ProviderError.networkUnavailable
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return ProviderError.serverUnreachable
            default:
                return ProviderError.networkError(urlError.localizedDescription)
            }
        }

        return error
    }

    public static func userFacingMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}
