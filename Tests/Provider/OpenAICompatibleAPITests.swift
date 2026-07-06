import Foundation
import QHelpCore

enum OpenAICompatibleAPITests: TestCase {
    static let name = "OpenAICompatibleAPITests"

    static func run() throws {
        let textMessage = try OpenAICompatibleAPI.buildUserMessage(
            content: .text("hello"),
            supportsImages: true
        )
        let textBody = OpenAICompatibleAPI.buildRequestBody(
            modelIdentifier: "gpt-4o",
            messages: [textMessage]
        )
        try assertEqual(textBody["model"] as? String, "gpt-4o")

        let imageMessage = try OpenAICompatibleAPI.buildUserMessage(
            content: .image(Data([0x01]), mediaType: "image/png"),
            supportsImages: true
        )
        let imageBody = OpenAICompatibleAPI.buildRequestBody(
            modelIdentifier: "gpt-4o",
            messages: [imageMessage]
        )
        let messages = imageBody["messages"] as? [[String: Any]]
        let blocks = messages?.first?["content"] as? [[String: Any]]
        try assertEqual(blocks?.count, 2)
        try assertEqual(blocks?.last?["type"] as? String, "image_url")

        let json = """
        {"choices":[{"message":{"content":"Hello"}}]}
        """
        let response = try OpenAICompatibleAPI.parseResponse(data: Data(json.utf8))
        try assertEqual(response, "Hello")

        do {
            _ = try OpenAICompatibleAPI.buildUserMessage(
                content: .image(Data([0x01]), mediaType: "image/png"),
                supportsImages: false
            )
            throw TestFailure.message("Expected unsupportedContent")
        } catch let error as ProviderError {
            guard case .unsupportedContent = error else {
                throw TestFailure.message("Expected unsupportedContent")
            }
        }
    }
}
