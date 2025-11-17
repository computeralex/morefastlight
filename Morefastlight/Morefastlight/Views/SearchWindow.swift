import SwiftUI

struct SearchWindow: View {
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var selectedIndex = 0
    @State private var showErrorPopup = false
    @State private var errorMessage = ""
    @State private var pathCompletions: [String] = []
    @State private var completionIndex = 0

    private let appCache = AppCache.shared
    private let classifier = InputClassifier()
    private let executor = CommandExecutor()
    private let autocompleter = PathAutocompleter()

    var body: some View {
        print("DEBUG: Body rendering with \(results.count) results, isEmpty=\(!results.isEmpty)")
        return VStack(spacing: 0) {
            // Search field
            SearchField(query: $query, onSubmit: executeSelected, onEscape: closeWindow, onTab: handleTab, onShiftTab: handleShiftTab, onArrowUp: selectPrevious, onArrowDown: selectNext)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .onChange(of: query) { newValue in
                    Task {
                        await updateResults()
                    }
                }

            if !results.isEmpty {
                Divider()

                // Results list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                            SearchResultRow(result: result, isSelected: index == selectedIndex)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedIndex = index
                                    executeSelected()
                                }
                        }
                    }
                }
                .frame(height: min(CGFloat(results.count) * 70, 500))
            }

            // Show path completions if available
            if !pathCompletions.isEmpty && (query.hasPrefix("~") || query.hasPrefix("/") || query.hasPrefix(".")) {
                Divider()
                Text("Press Tab to cycle: \(pathCompletions.count) matches")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .frame(width: 700)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showErrorPopup) {
            ErrorPopup(message: errorMessage, onClose: {
                showErrorPopup = false
            })
        }
    }

    @MainActor
    private func updateResults() async {
        let inputType = classifier.classify(query)

        print("DEBUG: Query changed to: '\(query)'")
        print("DEBUG: Input type: \(inputType)")

        switch inputType {
        case .appSearch:
            let apps = await appCache.search(query)
            results = apps.map { .app($0) }
            selectedIndex = 0
            print("DEBUG: Found \(apps.count) apps, results array has \(results.count)")
            if apps.count > 0 {
                print("DEBUG: Apps found: \(apps.map { $0.name }.joined(separator: ", "))")
            }

        case .path:
            results = generateDirectoryActions(path: query)
            selectedIndex = 0
            print("DEBUG: Path detected, \(results.count) actions")

        case .command:
            results = [.command(query)]
            selectedIndex = 0
            print("DEBUG: Command detected")
        }
    }

    private func generateDirectoryActions(path: String) -> [SearchResult] {
        var actions: [SearchResult] = []

        // Finder action
        let finderAction = DirectoryAction(
            id: "finder",
            name: "Open in Finder",
            path: path,
            icon: "folder.fill",
            shortcut: "⌘F"
        ) {
            executor.openDirectoryInFinder(path)
        }
        actions.append(.directoryAction(finderAction))

        // Terminal action
        let terminalAction = DirectoryAction(
            id: "terminal",
            name: "Open in Terminal",
            path: path,
            icon: "terminal.fill",
            shortcut: "⌘T"
        ) {
            executor.openDirectoryInTerminal(path)
        }
        actions.append(.directoryAction(terminalAction))

        // Claude Code action (if enabled)
        let claudeAction = QuickAction(
            id: "claude",
            name: "Open in Claude Code",
            commandTemplate: "tell application \"Terminal\" to do script \"cd {path} && claude\"",
            shortcut: "Cmd+C",
            icon: "bolt.fill",
            enabled: true
        )
        let claudeDirAction = DirectoryAction(
            id: "claude",
            name: "Open in Claude Code",
            path: path,
            icon: "bolt.fill",
            shortcut: "⌘C"
        ) {
            executor.executeQuickAction(claudeAction, path: path)
        }
        actions.append(.directoryAction(claudeDirAction))

        return actions
    }

    private func executeSelected() {
        print("DEBUG: executeSelected() called, selectedIndex=\(selectedIndex), results.count=\(results.count)")

        guard selectedIndex >= 0 && selectedIndex < results.count else {
            print("DEBUG: Index out of range!")
            return
        }

        let result = results[selectedIndex]
        print("DEBUG: Executing result: \(result)")

        Task {
            switch result {
            case .app(let app):
                print("DEBUG: Case is .app, calling launchApp")
                launchApp(app)

            case .directoryAction(let action):
                print("DEBUG: Case is .directoryAction")
                action.action()
                closeWindow()

            case .command(let command):
                print("DEBUG: Case is .command")
                let result = await executor.execute(command)
                if !result.isSuccess {
                    errorMessage = "Command: \(command)\nExit Code: \(result.exitCode)\n\n\(result.combinedOutput)"
                    showErrorPopup = true
                } else {
                    closeWindow()
                }
            }
        }
    }

    private func launchApp(_ app: InstalledApp) {
        print("DEBUG: Launching app: \(app.name) at path: \(app.path)")
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: app.path), configuration: config) { runningApp, error in
            if let error = error {
                print("ERROR: Failed to launch app: \(error)")
            } else {
                print("SUCCESS: Launched \(app.name)")
                Task {
                    await appCache.recordAppLaunch(app)
                }
            }
        }
        closeWindow()
    }

    private func handleTab() {
        if query.hasPrefix("~") || query.hasPrefix("/") || query.hasPrefix(".") {
            // If query ends with /, check if we're cycling or going deeper
            if query.hasSuffix("/") {
                // Remove trailing slash to check current path
                let currentPath = String(query.dropLast())

                // If current path is IN our completion list, we're cycling through siblings
                if !pathCompletions.isEmpty && pathCompletions.contains(currentPath) {
                    // Continue cycling through the same level
                    if let currentIndex = pathCompletions.firstIndex(of: currentPath) {
                        completionIndex = (currentIndex + 1) % pathCompletions.count
                    }
                    query = pathCompletions[completionIndex] + "/"
                } else {
                    // Going deeper - get subdirectories
                    let completions = autocompleter.autocomplete(query)

                    if completions.isEmpty {
                        pathCompletions = []
                        return
                    }

                    pathCompletions = completions
                    completionIndex = 0
                    query = completions[0] + "/"
                }
                return
            }

            // Otherwise, check if we're cycling through existing completions
            let currentPath = query
            let isCycling = !pathCompletions.isEmpty && pathCompletions.contains(currentPath)

            if isCycling {
                // Continue cycling through the same set of completions
                if let currentIndex = pathCompletions.firstIndex(of: currentPath) {
                    completionIndex = (currentIndex + 1) % pathCompletions.count
                }
                query = pathCompletions[completionIndex] + "/"
            } else {
                // Start new autocomplete
                let completions = autocompleter.autocomplete(query)

                if completions.isEmpty {
                    pathCompletions = []
                    return
                }

                pathCompletions = completions
                completionIndex = 0
                query = completions[0] + "/"
            }
        }
    }

    private func handleShiftTab() {
        if query.hasPrefix("~") || query.hasPrefix("/") || query.hasPrefix(".") {
            // If query ends with /, check if we're cycling or going deeper
            if query.hasSuffix("/") {
                // Remove trailing slash to check current path
                let currentPath = String(query.dropLast())

                // If current path is IN our completion list, we're cycling through siblings
                if !pathCompletions.isEmpty && pathCompletions.contains(currentPath) {
                    // Continue cycling BACKWARDS through the same level
                    if let currentIndex = pathCompletions.firstIndex(of: currentPath) {
                        completionIndex = (currentIndex - 1 + pathCompletions.count) % pathCompletions.count
                    }
                    query = pathCompletions[completionIndex] + "/"
                } else {
                    // Going deeper - get subdirectories (start at end for backwards)
                    let completions = autocompleter.autocomplete(query)

                    if completions.isEmpty {
                        pathCompletions = []
                        return
                    }

                    pathCompletions = completions
                    completionIndex = completions.count - 1
                    query = completions[completionIndex] + "/"
                }
                return
            }

            // Otherwise, check if we're cycling through existing completions
            let currentPath = query
            let isCycling = !pathCompletions.isEmpty && pathCompletions.contains(currentPath)

            if isCycling {
                // Continue cycling BACKWARDS through the same set of completions
                if let currentIndex = pathCompletions.firstIndex(of: currentPath) {
                    completionIndex = (currentIndex - 1 + pathCompletions.count) % pathCompletions.count
                }
                query = pathCompletions[completionIndex] + "/"
            } else {
                // Start new autocomplete (go to last item)
                let completions = autocompleter.autocomplete(query)

                if completions.isEmpty {
                    pathCompletions = []
                    return
                }

                pathCompletions = completions
                completionIndex = completions.count - 1
                query = completions[completionIndex] + "/"
            }
        }
    }

    private func selectPrevious() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    private func selectNext() {
        if selectedIndex < results.count - 1 {
            selectedIndex += 1
        }
    }

    private func closeWindow() {
        query = ""
        results = []
        selectedIndex = 0
        NSApp.keyWindow?.close()
    }
}
