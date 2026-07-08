import Foundation
import ClipAICore

enum ModelCapabilityFetcherTests: TestCase {
    static let name = "ModelCapabilityFetcherTests"

    static func run() throws {
        defer { MockURLProtocol.requestHandler = nil }

        try runAsync(testRetrieveSuccess)
        try runAsync(testRetrieve404UsesListFallback)
        try runAsync(testBothFailReturnsEmpty)
        try runAsync(testOpenAICompatibleFetchUsesBearerModelURL)
        try runAsync(testGeminiFetchUsesAPIKeyQueryAndNormalizedModel)
    }

    private static func testRetrieveSuccess() async throws {
        let opusJSON = """
        {
          "id": "claude-opus-4-8",
          "capabilities": {
            "effort": {
              "supported": true,
              "low": { "supported": true },
              "medium": { "supported": true },
              "high": { "supported": true }
            },
            "thinking": {
              "supported": true,
              "types": {
                "enabled": { "supported": false },
                "adaptive": { "supported": true }
              }
            }
          }
        }
        """

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(opusJSON.utf8))
        }

        let session = makeMockSession()
        let profile = await ModelCapabilityFetcher.fetch(
            kind: .anthropic,
            modelIdentifier: "claude-opus-4-8",
            apiKey: "test-key",
            session: session,
            logger: { _ in }
        )

        try assertEqual(profile.reasoningEffortLevels, ["low", "medium", "high"])
        try assertTrue(profile.supportsThinkingToggle)
        try assertEqual(profile.thinkingTypes, ["adaptive"])
    }

    private static func testRetrieve404UsesListFallback() async throws {
        let listJSON = """
        {
          "data": [
            {
              "id": "claude-opus-4-8",
              "capabilities": {
                "effort": {
                  "supported": true,
                  "medium": { "supported": true }
                },
                "thinking": {
                  "supported": true,
                  "types": {
                    "adaptive": { "supported": true }
                  }
                }
              }
            }
          ],
          "has_more": false
        }
        """

        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            let statusCode = path.hasSuffix("/claude-opus-4-8") ? 404 : 200
            let body = statusCode == 404 ? Data("{}".utf8) : Data(listJSON.utf8)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, body)
        }

        let session = makeMockSession()
        let profile = await ModelCapabilityFetcher.fetch(
            kind: .anthropic,
            modelIdentifier: "claude-opus-4-8",
            apiKey: "test-key",
            session: session,
            logger: { _ in }
        )

        try assertEqual(profile.reasoningEffortLevels, ["medium"])
        try assertTrue(profile.supportsThinkingToggle)
        try assertEqual(profile.thinkingTypes, ["adaptive"])
    }

    private static func testBothFailReturnsEmpty() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{}".utf8))
        }

        let session = makeMockSession()
        let profile = await ModelCapabilityFetcher.fetch(
            kind: .anthropic,
            modelIdentifier: "claude-missing",
            apiKey: "test-key",
            session: session,
            logger: { _ in }
        )

        try assertEqual(profile, ModelParameterProfile.empty)
    }

    private static func testOpenAICompatibleFetchUsesBearerModelURL() async throws {
        let json = """
        {
          "id": "gpt-5.5",
          "supported_parameters": [
            "reasoning_effort",
            "reasoning_effort_low",
            "reasoning_effort_medium",
            "temperature",
            "top_p"
          ]
        }
        """
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(json.utf8))
        }

        let session = makeMockSession()
        let profile = await ModelCapabilityFetcher.fetch(
            kind: .openai,
            modelIdentifier: "gpt-5.5",
            apiKey: "openai-key",
            session: session,
            logger: { _ in }
        )

        try assertEqual(
            capturedRequest?.url?.absoluteString,
            "https://api.openai.com/v1/models/gpt-5.5"
        )
        try assertEqual(
            capturedRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer openai-key"
        )
        try assertEqual(profile.reasoningEffortLevels, ["low", "medium"])
        try assertTrue(profile.supportsTemperature)
        try assertTrue(profile.supportsTopP)
    }

    private static func testGeminiFetchUsesAPIKeyQueryAndNormalizedModel() async throws {
        let json = """
        {
          "name": "models/gemini-2.5-flash",
          "thinking": true,
          "temperature": 1.0,
          "topP": 0.95
        }
        """
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(json.utf8))
        }

        let session = makeMockSession()
        let profile = await ModelCapabilityFetcher.fetch(
            kind: .gemini,
            modelIdentifier: "models/gemini-2.5-flash",
            apiKey: "gemini-key",
            session: session,
            logger: { _ in }
        )

        try assertEqual(capturedRequest?.url?.path, "/v1beta/models/gemini-2.5-flash")
        try assertEqual(
            URLComponents(url: capturedRequest!.url!, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "key" })?
                .value,
            "gemini-key"
        )
        try assertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), nil)
        try assertTrue(profile.supportsThinkingToggle)
        try assertTrue(profile.supportsTemperature)
        try assertTrue(profile.supportsTopP)
    }

    private static func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private static func runAsync(_ operation: @escaping () async throws -> Void) throws {
        let semaphore = DispatchSemaphore(value: 0)
        var thrown: Error?

        Task {
            do {
                try await operation()
            } catch {
                thrown = error
            }
            semaphore.signal()
        }

        semaphore.wait()

        if let thrown {
            throw thrown
        }
    }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
