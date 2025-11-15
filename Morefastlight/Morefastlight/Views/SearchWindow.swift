import SwiftUI

struct SearchWindow: View {
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var selectedIndex = 0
    @State private var showErrorPopup = false
    @State private var errorMessage = ""

    private let appCache = AppCache.shared
    private let classifier = InputClassifier()
    private let executor = CommandExecutor()
    private let autocompleter = PathAutocompleter()

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            SearchField(query: $query, onSubmit: executeSelected, onEscape: closeWindow, onTab: handleTab, onArrowUp: selectPrevious, onArrowDown: selectNext)
                .onChange(of: query) { _ in
                    Task {
                        await updateResults()
                    }
                }

            if !results.isEmpty {
                Divider()

                // Results list
                ScrollView {
                    LazyVStack(spacing: 0) {
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
                .frame(maxHeight: 400)
            }
        }
        .frame(width: 600)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showErrorPopup) {
            ErrorPopup(message: errorMessage, onClose: {
                showErrorPopup = false
            })
        }
    }

    private func updateResults() async {
        let inputType = classifier.classify(query)

        switch inputType {
        case .appSearch:
            let apps = await appCache.search(query)
            results = apps.map { .app($0) }
            selectedIndex = 0

        case .path:
            results = generateDirectoryActions(path: query)
            selectedIndex = 0

        case .command:
            results = [.command(query)]
            selectedIndex = 0
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
        guard selectedIndex >= 0 && selectedIndex < results.count else { return }

        let result = results[selectedIndex]

        Task {
            switch result {
            case .app(let app):
                launchApp(app)

            case .directoryAction(let action):
                action.action()
                closeWindow()

            case .command(let command):
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
        NSWorkspace.shared.launchApplication(
            at: URL(fileURLWithPath: app.path),
            options: [],
            configuration: [:]
        ) { _, error in
            if let error = error {
                print("Failed to launch app: \(error)")
            } else {
                Task {
                    await appCache.recordAppLaunch(app)
                }
            }
        }
        closeWindow()
    }

    private func handleTab() {
        if classifier.classify(query) == .path {
            let completions = autocompleter.autocomplete(query)
            if let first = completions.first {
                query = first + "/"
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
