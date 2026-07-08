import Foundation

/// Interactive terminal prompts for model options supported by provider metadata.
public enum ModelOptionsPrompt {

    public typealias LineReader = () -> String?
    public typealias OutputWriter = (String) -> Void

    private static var lineReader: LineReader = { readLine() }
    private static var outputWriter: OutputWriter = { print($0) }

    /// Overrides stdin for tests. Pass `nil` to restore default `readLine()`.
    public static func setLineReader(_ reader: LineReader?) {
        lineReader = reader ?? { readLine() }
    }

    /// Overrides stdout for tests. Pass `nil` to restore default `print`.
    public static func setOutputWriter(_ writer: OutputWriter?) {
        outputWriter = writer ?? { print($0) }
    }

    public static func prompt(for profile: ModelParameterProfile) -> ModelRequestOptions {
        guard profile.hasInteractiveChoices || profile.hasAutoDefaults else {
            return .none
        }

        var options = ModelRequestOptions()

        if profile.supportsThinkingToggle {
            let thinkingEnabled = promptThinkingToggle(thinkingTypes: profile.thinkingTypes)
            options.thinkingEnabled = thinkingEnabled
            if thinkingEnabled, !profile.thinkingTypes.isEmpty {
                options.thinkingType = preferredThinkingType(from: profile.thinkingTypes)
            }
        }

        if !profile.reasoningEffortLevels.isEmpty,
           let effort = promptReasoningEffort(levels: profile.reasoningEffortLevels) {
            options.reasoningEffort = effort
        }

        return options
    }

    static func preferredThinkingType(from types: [String]) -> String? {
        if types.contains("adaptive") { return "adaptive" }
        if types.contains("enabled") { return "enabled" }
        return types.first
    }

    private static func promptThinkingToggle(thinkingTypes: [String]) -> Bool {
        writeLine()
        if thinkingTypes == ["adaptive"] {
            writeLine("Enable adaptive thinking? [y/N]")
        } else {
            writeLine("Enable extended thinking? [y/N]")
        }
        let input = lineReader()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return input == "y" || input == "yes"
    }

    private static func promptReasoningEffort(levels: [String]) -> String? {
        guard !levels.isEmpty else { return nil }

        writeLine()
        writeLine("Reasoning effort:")
        for (index, level) in levels.enumerated() {
            writeLine("  \(index + 1)) \(level)")
        }

        let defaultIndex = defaultEffortIndex(in: levels)
        writeLine("Choice [\(defaultIndex + 1)]:")
        let input = lineReader()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if input.isEmpty {
            return levels[defaultIndex]
        }

        if let number = Int(input), number >= 1, number <= levels.count {
            return levels[number - 1]
        }

        if levels.contains(input) {
            return input
        }

        return levels[defaultIndex]
    }

    private static func defaultEffortIndex(in levels: [String]) -> Int {
        if let mediumIndex = levels.firstIndex(of: "medium") {
            return mediumIndex
        }
        return min(1, levels.count - 1)
    }

    private static func writeLine(_ text: String = "") {
        outputWriter(text)
    }
}
