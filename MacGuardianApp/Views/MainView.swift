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

                HStack(spacing: 10) {
                    Image("MacGuardianLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 42, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mac Guardian").font(.headline)
                        Text("by Cynaxia").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

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
                    DashboardView(onSmartScan: { selection = .cleanup })
                case .storage:
                    FolderAnalysisView(mode: .folderUsage)
                case .largeFiles:
                    FolderAnalysisView(mode: .largeFiles(minimumBytes: 100 * 1024 * 1024))
                case .cleanup:
                    CleanupView()
                case .developerTools:
                    DeveloperStorageView()
                case .applications:
                    InstalledApplicationsView()
                case .security:
                    PersistenceAuditView()
                case .privacy:
                    PrivacyAuditView()
                case .performance:
                    PerformanceView()
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
