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

@main
enum TestRunner {
    static func main() {
        let testCases: [TestCase.Type] = [
            ClipboardContentTests.self,
            CLIParserTests.self,
            ProviderRegistryTests.self,
            ProviderCatalogTests.self,
            AnthropicAPITests.self,
            OpenAICompatibleAPITests.self,
            GeminiAPITests.self,
            OverlayInteractionTests.self,
            MarkdownRenderingTests.self,
            RequestQueueTests.self
        ]

        var failures = 0

        for testCase in testCases {
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
            exit(1)
        }

        print("\nAll tests passed.")
    }
}
