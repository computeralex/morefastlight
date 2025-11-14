import Foundation

struct CommandResult {
    let exitCode: Int
    let output: String
    let error: String

    var isSuccess: Bool {
        return exitCode == 0
    }

    var combinedOutput: String {
        var result = ""
        if !output.isEmpty {
            result += output
        }
        if !error.isEmpty {
            if !result.isEmpty {
                result += "\n"
            }
            result += error
        }
        return result
    }
}
