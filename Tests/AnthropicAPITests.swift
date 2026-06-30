import Foundation
import QHelpCore

enum AnthropicAPITests: TestCase {
    static let name = "AnthropicAPITests"

    static func run() throws {
        let textBody = AnthropicAPI.buildRequestBody(
            modelIdentifier: "claude-sonnet-4-6",
            content: .text("hello")
        )
        try assertEqual(textBody["model"] as? String, "claude-sonnet-4-6")
        let messages = textBody["messages"] as? [[String: Any]]
        let textContent = messages?.first?["content"] as? String
        try assertEqual(textContent, "hello")

        let imageBody = AnthropicAPI.buildRequestBody(
            modelIdentifier: "claude-sonnet-4-6",
            content: .image(Data([0x01, 0x02]), mediaType: "image/png")
        )
        let imageMessages = imageBody["messages"] as? [[String: Any]]
        let blocks = imageMessages?.first?["content"] as? [[String: Any]]
        try assertEqual(blocks?.count, 2)
        try assertEqual(blocks?.first?["type"] as? String, "image")
        try assertEqual(blocks?.last?["type"] as? String, "text")
        try assertEqual(blocks?.last?["text"] as? String, AnthropicAPI.imagePrompt)

        let json = """
        {"content":[{"type":"text","text":"Hello"},{"type":"text","text":"World"}]}
        """
        let response = try AnthropicAPI.parseResponse(data: Data(json.utf8))
        try assertEqual(response, "Hello\nWorld")

        let rateLimit = AnthropicAPI.parseError(statusCode: 429, data: Data(), retryAfterHeader: "30")
        guard case .rateLimited(let retryAfter) = rateLimit else {
            throw TestFailure.message("Expected rateLimited")
        }
        try assertEqual(retryAfter, 30)

        let authJSON = """
        {"error":{"type":"authentication_error","message":"invalid x-api-key"}}
        """
        let authError = AnthropicAPI.parseError(
            statusCode: 401,
            data: Data(authJSON.utf8),
            retryAfterHeader: nil
        )
        guard case .apiError(let statusCode, let message) = authError else {
            throw TestFailure.message("Expected apiError")
        }
        try assertEqual(statusCode, 401)
        try assertEqual(message, "invalid x-api-key")

        let networkError = AnthropicAPI.mapNetworkError(URLError(.notConnectedToInternet))
        guard case .networkUnavailable = networkError as? ProviderError else {
            throw TestFailure.message("Expected networkUnavailable")
        }
    }
}
