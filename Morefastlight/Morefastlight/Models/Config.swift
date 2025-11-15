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
    var reindexIntervalHours: Int

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
        case reindexIntervalHours = "reindex_interval_hours"
    }

    init(version: String, hotkey: String, terminalApp: String, shell: String, appSearchPaths: [String], commandPrefixes: [String], terminalOpeningCommands: [String], forceOutputPrefix: String, directoryQuickActions: [QuickAction], customDirectoryActions: [QuickAction], ui: UIConfig, cache: CacheConfig, reindexIntervalHours: Int) {
        self.version = version
        self.hotkey = hotkey
        self.terminalApp = terminalApp
        self.shell = shell
        self.appSearchPaths = appSearchPaths
        self.commandPrefixes = commandPrefixes
        self.terminalOpeningCommands = terminalOpeningCommands
        self.forceOutputPrefix = forceOutputPrefix
        self.directoryQuickActions = directoryQuickActions
        self.customDirectoryActions = customDirectoryActions
        self.ui = ui
        self.cache = cache
        self.reindexIntervalHours = reindexIntervalHours
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        hotkey = try container.decode(String.self, forKey: .hotkey)
        terminalApp = try container.decode(String.self, forKey: .terminalApp)
        shell = try container.decode(String.self, forKey: .shell)
        appSearchPaths = try container.decode([String].self, forKey: .appSearchPaths)
        commandPrefixes = try container.decode([String].self, forKey: .commandPrefixes)
        terminalOpeningCommands = try container.decode([String].self, forKey: .terminalOpeningCommands)
        forceOutputPrefix = try container.decode(String.self, forKey: .forceOutputPrefix)
        directoryQuickActions = try container.decode([QuickAction].self, forKey: .directoryQuickActions)
        customDirectoryActions = try container.decode([QuickAction].self, forKey: .customDirectoryActions)
        ui = try container.decode(UIConfig.self, forKey: .ui)
        cache = try container.decode(CacheConfig.self, forKey: .cache)
        reindexIntervalHours = try container.decodeIfPresent(Int.self, forKey: .reindexIntervalHours) ?? 24
    }

    static var `default`: Config {
        Config(
            version: "1.0",
            hotkey: "Cmd+Space",
            terminalApp: "Terminal",
            shell: "/bin/zsh",
            appSearchPaths: [
                "/Applications",
                "~/Applications",
                "/System/Applications",
                "/System/Applications/Utilities"
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
            ),
            reindexIntervalHours: 24
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
