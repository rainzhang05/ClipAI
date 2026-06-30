import Foundation

/// Capabilities discovered from a provider Models API response.
public struct ModelParameterProfile: Equatable, Sendable {
    public var reasoningEffortLevels: [String] = []
    public var supportsThinkingToggle: Bool = false
    public var thinkingTypes: [String] = []
    public var supportsTemperature: Bool = false
    public var supportsTopP: Bool = false
    public var supportsVerbosity: Bool = false

    public var hasInteractiveChoices: Bool {
        !reasoningEffortLevels.isEmpty || supportsThinkingToggle
    }

    public var hasAutoDefaults: Bool {
        supportsTemperature || supportsTopP || supportsVerbosity
    }

    public init(
        reasoningEffortLevels: [String] = [],
        supportsThinkingToggle: Bool = false,
        thinkingTypes: [String] = [],
        supportsTemperature: Bool = false,
        supportsTopP: Bool = false,
        supportsVerbosity: Bool = false
    ) {
        self.reasoningEffortLevels = reasoningEffortLevels
        self.supportsThinkingToggle = supportsThinkingToggle
        self.thinkingTypes = thinkingTypes
        self.supportsTemperature = supportsTemperature
        self.supportsTopP = supportsTopP
        self.supportsVerbosity = supportsVerbosity
    }

    public static let empty = ModelParameterProfile()
}
