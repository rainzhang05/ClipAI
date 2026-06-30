import Foundation

/// Errors that can occur during AI provider operations.
public enum ProviderError: LocalizedError {

    /// No API key was found for the specified provider.
    case missingAPIKey(provider: String)

    /// The API returned a response that could not be parsed.
    case invalidResponse

    /// The API returned an error status code.
    case apiError(statusCode: Int, message: String)

    /// The API rate-limited the request.
    case rateLimited(retryAfter: Int?)

    /// The request timed out.
    case timeout

    /// The clipboard content type is not supported by this provider.
    case unsupportedContent

    /// No internet connection is available.
    case networkUnavailable

    /// The API server could not be reached.
    case serverUnreachable

    /// A generic network error occurred.
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "No API key found for \(provider). Set the appropriate environment variable."
        case .invalidResponse:
            return "Received an invalid response from the API."
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limited. Retry after \(seconds) seconds."
            }
            return "Rate limited. Please wait before retrying."
        case .timeout:
            return "Request timed out."
        case .unsupportedContent:
            return "Unsupported clipboard content type."
        case .networkUnavailable:
            return "No internet connection."
        case .serverUnreachable:
            return "Cannot reach the API server."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
