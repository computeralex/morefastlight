import Foundation

class CommandExecutor {
    private let config: Config

    init(config: Config = .default) {
        self.config = config
    }

    func execute(_ command: String) async -> CommandResult {
        // Check if this is a terminal-opening command
        if isTerminalOpeningCommand(command) {
            openInTerminal(command)
            return CommandResult(exitCode: 0, output: "", error: "")
        }

        // Execute in background and capture output
        return await executeInBackground(command)
    }

    private func isTerminalOpeningCommand(_ command: String) -> Bool {
        for terminalCmd in config.terminalOpeningCommands {
            if command.hasPrefix(terminalCmd + " ") || command == terminalCmd {
                return true
            }
        }
        return false
    }

    func openInTerminal(_ command: String) {
        let terminalApp = detectTerminalApp()

        let script: String
        if terminalApp == "iTerm" {
            script = """
            tell application "iTerm"
                create window with default profile command "\(command)"
            end tell
            """
        } else {
            script = """
            tell application "Terminal"
                do script "\(command)"
                activate
            end tell
            """
        }

        executeAppleScript(script)
    }

    private func executeInBackground(_ command: String) async -> CommandResult {
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: config.shell)
            process.arguments = ["-c", command]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                let output = String(data: outputData, encoding: .utf8) ?? ""
                let error = String(data: errorData, encoding: .utf8) ?? ""

                let result = CommandResult(
                    exitCode: Int(process.terminationStatus),
                    output: output,
                    error: error
                )
                continuation.resume(returning: result)
            } catch {
                let result = CommandResult(
                    exitCode: 1,
                    output: "",
                    error: error.localizedDescription
                )
                continuation.resume(returning: result)
            }
        }
    }

    func openDirectoryInFinder(_ path: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        executeShellCommand("open \"\(expandedPath)\"")
    }

    func openDirectoryInTerminal(_ path: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let terminalApp = detectTerminalApp()

        let script: String
        if terminalApp == "iTerm" {
            script = """
            tell application "iTerm"
                create window with default profile command "cd '\(expandedPath)'"
            end tell
            """
        } else {
            script = """
            tell application "Terminal"
                do script "cd '\(expandedPath)'"
                activate
            end tell
            """
        }

        executeAppleScript(script)
    }

    func executeQuickAction(_ action: QuickAction, path: String) {
        let terminalApp = detectTerminalApp()
        let command = action.executeCommand(path: path, terminalApp: terminalApp, shell: config.shell)

        // If it's an AppleScript command
        if command.contains("tell application") {
            executeAppleScript(command)
        } else {
            executeShellCommand(command)
        }
    }

    private func detectTerminalApp() -> String {
        if FileManager.default.fileExists(atPath: "/Applications/iTerm.app") {
            return "iTerm"
        }
        return "Terminal"
    }

    private func executeAppleScript(_ script: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        do {
            try process.run()
        } catch {
            print("Failed to execute AppleScript: \(error)")
        }
    }

    private func executeShellCommand(_ command: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: config.shell)
        process.arguments = ["-c", command]

        do {
            try process.run()
        } catch {
            print("Failed to execute shell command: \(error)")
        }
    }
}
