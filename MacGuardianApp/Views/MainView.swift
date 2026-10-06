import SwiftUI

struct MainView: View {
    @State private var selection: NavigationItem? = .dashboard
    @AppStorage("preferredLanguage") private var preferredLanguage = "es"

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    Section("Mac Guardian") {
                        ForEach(NavigationItem.allCases) { item in
                            Label(item.title, systemImage: item.symbol)
                                .tag(Optional(item))
                        }
                    }
                }
                .listStyle(.sidebar)

                Divider()
                languagePicker
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            Group {
                switch selection ?? .dashboard {
                case .dashboard:
                    DashboardView()
                case let item:
                    ModulePlaceholderView(item: item)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .tint(Color.orange)
        .environment(\.locale, Locale(identifier: preferredLanguage))
    }

    private var languagePicker: some View {
        Picker("Language", selection: $preferredLanguage) {
            Text("Español").tag("es")
            Text("English").tag("en")
            Text("Português").tag("pt-BR")
            Text("中文").tag("zh-Hans")
            Text("日本語").tag("ja")
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ModulePlaceholderView: View {
    let item: NavigationItem

    var body: some View {
        ContentUnavailableView(
            item.title,
            systemImage: item.symbol,
            description: Text("This module is planned for a later development phase.")
        )
    }
}
