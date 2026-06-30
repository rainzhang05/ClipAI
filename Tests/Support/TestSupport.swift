import Foundation

enum TestFailure: Error {
    case message(String)
}

func assertTrue(_ condition: Bool, _ message: String = "Expected true") throws {
    if !condition {
        throw TestFailure.message(message)
    }
}

func assertEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String = "Values not equal") throws {
    if lhs != rhs {
        throw TestFailure.message("\(message): \(lhs) != \(rhs)")
    }
}

func assertFalse(_ condition: Bool, _ message: String = "Expected false") throws {
    if condition {
        throw TestFailure.message(message)
    }
}

func assertNotEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String = "Values should differ") throws {
    if lhs == rhs {
        throw TestFailure.message(message)
    }
}

protocol TestCase {
    static var name: String { get }
    static func run() throws
}

enum TestSuites {
    static let all: [TestCase.Type] = [
        ClipboardContentTests.self,
        CLIParserTests.self,
        ProviderCatalogTests.self,
        ProviderRegistryTests.self,
        AnthropicAPITests.self,
        OpenAICompatibleAPITests.self,
        GeminiAPITests.self,
        ModelCapabilityParserTests.self,
        ModelOptionsPromptTests.self,
        RequestOptionsAPITests.self,
        OverlayInteractionTests.self,
        MarkdownRenderingTests.self,
        RequestQueueTests.self
    ]

    static func matching(_ names: [String]) -> [TestCase.Type] {
        let requested = Set(names)
        let matched = all.filter { requested.contains($0.name) }
        if matched.isEmpty {
            let available = all.map { $0.name }.joined(separator: ", ")
            fputs("Unknown test suite. Available: \(available)\n", stderr)
            exit(1)
        }
        return matched
    }
}

func runTestSuites(_ suites: [TestCase.Type]) -> Int {
    var failures = 0

    for testCase in suites {
        do {
            try testCase.run()
            print("PASS \(testCase.name)")
        } catch {
            failures += 1
            print("FAIL \(testCase.name): \(error)")
        }
    }

    if failures > 0 {
        print("\n\(failures) test suite(s) failed.")
    } else {
        print("\nAll tests passed.")
    }

    return failures
}
