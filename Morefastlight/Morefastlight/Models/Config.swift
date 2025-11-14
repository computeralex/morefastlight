import Foundation

struct Config: Codable {
    var version: String
    var hotkey: String
    var terminalApp: String
    var shell: String
    var appSearchPaths: [String]
    var commandPrefixes: [String]
    var terminalOpeningCommands: [String]
    var forceOutputPrefix: String
    var directoryQuickActions: [QuickAction]
    var customDirectoryActions: [QuickAction]
    var ui: UIConfig
    var cache: CacheConfig

    enum CodingKeys: String, CodingKey {
        case version
        case hotkey
        case terminalApp = "terminal_app"
        case shell
        case appSearchPaths = "app_search_paths"
        case commandPrefixes = "command_prefixes"
        case terminalOpeningCommands = "terminal_opening_commands"
        case forceOutputPrefix = "force_output_prefix"
        case directoryQuickActions = "directory_quick_actions"
        case customDirectoryActions = "custom_directory_actions"
        case ui
        case cache
    }

    static var `default`: Config {
        Config(
            version: "1.0",
            hotkey: "Cmd+Space",
            terminalApp: "Terminal",
            shell: "/bin/zsh",
            appSearchPaths: [
                "/Applications",
                "~/Applications"
            ],
            commandPrefixes: [
                "open", "cd", "ls", "git", "npm", "yarn", "pnpm", "brew",
                "python", "python3", "node", "curl", "wget", "docker",
                "kubectl", "ssh", "scp", "rsync", "make", "cargo", "go",
                "claude"
            ],
            terminalOpeningCommands: ["cd"],
            forceOutputPrefix: "!",
            directoryQuickActions: [
                QuickAction(
                    id: "claude_code",
                    name: "Open in Claude Code",
                    commandTemplate: "tell application \"{terminal_app}\" to do script \"cd {path} && claude\"",
                    shortcut: "Cmd+C",
                    icon: "terminal.fill",
                    enabled: true
                )
            ],
            customDirectoryActions: [],
            ui: UIConfig(
                maxResults: 8,
                resultHeight: 44,
                windowWidth: 600,
                darkMode: "auto"
            ),
            cache: CacheConfig(
                appIndexPath: "~/.morefastlight/app_index.cache",
                recentPathsLimit: 50
            )
        )
    }
}

struct UIConfig: Codable {
    var maxResults: Int
    var resultHeight: Int
    var windowWidth: Int
    var darkMode: String

    enum CodingKeys: String, CodingKey {
        case maxResults = "max_results"
        case resultHeight = "result_height"
        case windowWidth = "window_width"
        case darkMode = "dark_mode"
    }
}

struct CacheConfig: Codable {
    var appIndexPath: String
    var recentPathsLimit: Int

    enum CodingKeys: String, CodingKey {
        case appIndexPath = "app_index_path"
        case recentPathsLimit = "recent_paths_limit"
    }
}
