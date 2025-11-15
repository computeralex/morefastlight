import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 28))
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)

            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .lineLimit(1)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Shortcut hint
            if let shortcut = shortcutHint {
                Text(shortcut)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
    }

    private var iconName: String {
        switch result {
        case .app:
            return "app.fill"
        case .directoryAction(let action):
            return action.icon
        case .command:
            return "terminal.fill"
        }
    }

    private var title: String {
        switch result {
        case .app(let app):
            return app.name
        case .directoryAction(let action):
            return action.name
        case .command(let cmd):
            return "Run: \(cmd)"
        }
    }

    private var subtitle: String? {
        switch result {
        case .app(let app):
            return app.path
        case .directoryAction(let action):
            return action.path
        case .command:
            return nil
        }
    }

    private var shortcutHint: String? {
        switch result {
        case .app:
            return nil
        case .directoryAction(let action):
            return action.shortcut
        case .command:
            return nil
        }
    }
}
