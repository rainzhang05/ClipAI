import Foundation

/// User-selected and auto-applied model parameters for API requests.
public struct ModelRequestOptions: Equatable, Sendable {
    public var reasoningEffort: String?
    public var thinkingEnabled: Bool?
    public var thinkingType: String?
    public var temperature: Double?
    public var topP: Double?
    public var verbosity: String?

    public init(
        reasoningEffort: String? = nil,
        thinkingEnabled: Bool? = nil,
        thinkingType: String? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        verbosity: String? = nil
    ) {
        self.reasoningEffort = reasoningEffort
        self.thinkingEnabled = thinkingEnabled
        self.thinkingType = thinkingType
        self.temperature = temperature
        self.topP = topP
        self.verbosity = verbosity
    }

    public static let none = ModelRequestOptions()
}
