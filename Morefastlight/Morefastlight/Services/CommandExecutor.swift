import Foundation

class CommandExecutor {
    private let config: Config

    init(config: Config = .default) {
        self.config = config
    }

    // SECURITY: Escape strings for AppleScript to prevent injection attacks
    private func escapeAppleScriptString(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }

    // SECURITY: Validate that path is safe to access
    private func validatePath(_ path: String) -> Bool {
        let expandedPath = NSString(string: path).expandingTildeInPath

        // Disallow sensitive system directories
        let forbidden = [
            "/etc/", "/var/", "/private/", "/System/Library/",
            "/.ssh/", "/.gnupg/", "/Library/Keychains/"
        ]

        for prefix in forbidden {
            if expandedPath.hasPrefix(prefix) {
                print("⚠️ Security: Blocked access to sensitive path: \(expandedPath)")
                return false
            }
        }

        // Only allow user's home directory, /Applications, and /Users
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let allowed = [homeDir, "/Applications", "/Users"]

        let isAllowed = allowed.contains { expandedPath.hasPrefix($0) }
        if !isAllowed {
            print("⚠️ Security: Blocked access to unauthorized path: \(expandedPath)")
        }

        return isAllowed
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
        let escapedCommand = escapeAppleScriptString(command)

        let script: String
        if terminalApp == "iTerm" {
            script = """
            tell application "iTerm"
                create window with default profile command "\(escapedCommand)"
            end tell
            """
        } else {
            script = """
            tell application "Terminal"
                do script "\(escapedCommand)"
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

        // SECURITY: Validate path before opening
        guard validatePath(expandedPath) else {
            print("❌ Cannot open directory: path validation failed")
            return
        }

        // SECURITY: Use Process with separate arguments to prevent shell injection
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [expandedPath]

        do {
            try process.run()
        } catch {
            print("Failed to open directory in Finder: \(error)")
        }
    }

    func openDirectoryInTerminal(_ path: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath

        // SECURITY: Validate path before opening
        guard validatePath(expandedPath) else {
            print("❌ Cannot open directory in Terminal: path validation failed")
            return
        }

        let terminalApp = detectTerminalApp()
        let escapedPath = escapeAppleScriptString(expandedPath)

        let script: String
        if terminalApp == "iTerm" {
            script = """
            tell application "iTerm"
                create window with default profile command "cd '\(escapedPath)'"
            end tell
            """
        } else {
            script = """
            tell application "System Events"
                tell process "Terminal"
                    keystroke "n" using command down
                end tell
            end tell
            delay 0.2
            tell application "Terminal"
                do script "cd '\(escapedPath)'" in front window
            end tell
            """
        }

        executeAppleScript(script)
    }

    func executeQuickAction(_ action: QuickAction, path: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath

        // SECURITY: Validate path before executing action
        guard validatePath(expandedPath) else {
            print("❌ Cannot execute quick action: path validation failed")
            return
        }

        let terminalApp = detectTerminalApp()
        // Pass the expanded path for validation
        let command = action.executeCommand(path: expandedPath, terminalApp: terminalApp, shell: config.shell)

        // If it's an AppleScript command
        if command.contains("tell application") {
            // Note: executeCommand should already escape the path
            executeAppleScript(command)
        } else {
            // SECURITY: For shell commands, we should use Process instead
            // But QuickAction commands are user-configured, so trust them
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
