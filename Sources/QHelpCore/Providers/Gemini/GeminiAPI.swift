import Foundation

public enum GeminiAPI {

    public static let imagePrompt = "Describe this clipboard content."

    public static func buildRequestBody(
        content: ClipboardContent,
        supportsImages: Bool
    ) throws -> [String: Any] {
        var parts: [[String: Any]] = []

        switch content {
        case .text(let text):
            parts.append(["text": text])

        case .image(let imageData, let mediaType):
            guard supportsImages else {
                throw ProviderError.unsupportedContent
            }

            parts.append([
                "inline_data": [
                    "mime_type": mediaType,
                    "data": imageData.base64EncodedString()
                ] as [String: String]
            ])
            parts.append(["text": imagePrompt])
        }

        return [
            "contents": [
                [
                    "role": "user",
                    "parts": parts
                ] as [String: Any]
            ]
        ]
    }

    public static func parseResponse(data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw ProviderError.invalidResponse
        }

        let textParts = parts.compactMap { $0["text"] as? String }
        guard !textParts.isEmpty else {
            throw ProviderError.invalidResponse
        }

        return textParts.joined(separator: "\n")
    }

    public static func parseError(statusCode: Int, data: Data, retryAfterHeader: String?) -> ProviderError {
        if statusCode == 429 {
            return .rateLimited(retryAfter: AnthropicAPI.parseRetryAfter(retryAfterHeader))
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return .apiError(statusCode: statusCode, message: message)
        }

        return .apiError(statusCode: statusCode, message: "Unknown error (HTTP \(statusCode))")
    }
}
