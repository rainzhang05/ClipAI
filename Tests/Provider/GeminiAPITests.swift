import Foundation
import QHelpCore

enum GeminiAPITests: TestCase {
    static let name = "GeminiAPITests"

    static func run() throws {
        let textMessage = try GeminiAPI.buildUserMessage(
            content: .text("hello"),
            supportsImages: true
        )
        let textBody = GeminiAPI.buildRequestBody(
            contents: [textMessage]
        )
        let contents = textBody["contents"] as? [[String: Any]]
        let parts = contents?.first?["parts"] as? [[String: Any]]
        try assertEqual(parts?.first?["text"] as? String, "hello")

        let imageMessage = try GeminiAPI.buildUserMessage(
            content: .image(Data([0x01, 0x02]), mediaType: "image/png"),
            supportsImages: true
        )
        let imageBody = GeminiAPI.buildRequestBody(
            contents: [imageMessage]
        )
        let imageParts = (imageBody["contents"] as? [[String: Any]])?.first?["parts"] as? [[String: Any]]
        try assertEqual(imageParts?.count, 2)

        let json = """
        {"candidates":[{"content":{"parts":[{"text":"Hi there"}]}}]}
        """
        let response = try GeminiAPI.parseResponse(data: Data(json.utf8))
        try assertEqual(response, "Hi there")
    }
}
