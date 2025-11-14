import SwiftUI

struct SettingsView: View {
    @StateObject private var configManager = ConfigManager()

    var body: some View {
        TabView {
            GeneralSettings(config: $configManager.config, onSave: configManager.save)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            QuickActionsSettings(config: $configManager.config, onSave: configManager.save)
                .tabItem {
                    Label("Quick Actions", systemImage: "bolt.fill")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettings: View {
    @Binding var config: Config
    let onSave: () -> Void

    var body: some View {
        Form {
            Section("Terminal") {
                Picker("Terminal App:", selection: $config.terminalApp) {
                    Text("Terminal").tag("Terminal")
                    Text("iTerm2").tag("iTerm")
                }

                TextField("Shell:", text: $config.shell)
            }

            Section("Search Paths") {
                List {
                    ForEach(config.appSearchPaths, id: \.self) { path in
                        Text(path)
                    }
                }
                .frame(height: 100)
            }

            HStack {
                Spacer()
                Button("Save") {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}

struct QuickActionsSettings: View {
    @Binding var config: Config
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Directory Quick Actions")
                .font(.headline)
                .padding(.bottom, 8)

            List {
                ForEach(config.directoryQuickActions) { action in
                    HStack {
                        Image(systemName: action.icon)
                        Text(action.name)
                        Spacer()
                        Text(action.shortcut)
                            .foregroundColor(.secondary)
                        Toggle("", isOn: .constant(action.enabled))
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Save") {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Morefastlight")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0")
                .foregroundColor(.secondary)

            Text("A minimal, blazing-fast macOS launcher")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}
