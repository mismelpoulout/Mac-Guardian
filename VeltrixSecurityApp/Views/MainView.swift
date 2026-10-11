import SwiftUI

struct MainView: View {
    @State private var selection: NavigationItem? = .dashboard
    @AppStorage("preferredLanguage") private var preferredLanguage = "es"

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List {
                    Section("Veltrix Security") {
                        ForEach(NavigationItem.allCases) { item in
                            Button {
                                selection = item
                            } label: {
                                HStack(spacing: 8) {
                                    Label(item.title, systemImage: item.symbol)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if item == .appleIntelligence {
                                        Text("AI")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(
                                                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                                in: Capsule()
                                            )
                                            .foregroundStyle(.white)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(
                                selection == item ? Color.accentColor.opacity(0.16) : nil
                            )
                        }
                    }
                }
                .listStyle(.sidebar)

                HStack(spacing: 10) {
                    Image("VeltrixSecurityLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 42, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Veltrix Security").font(.headline)
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
            .navigationSplitViewColumnWidth(min: 200, ideal: 230)
        } detail: {
            Group {
                switch selection ?? .dashboard {
                case .dashboard:
                    DashboardView(
                        onSmartScan: { selection = .cleanup },
                        onNavigateToSecurity: { selection = .threatScan },
                        onNavigateToAI: { selection = .appleIntelligence },
                        onNavigateToPerformance: { selection = .performance },
                        onNavigateToPersistence: { selection = .security }
                    )
                case .appleIntelligence:
                    AppleIntelligenceView(
                        onNavigateToPerformance: { selection = .performance },
                        onNavigateToCleanup: { selection = .cleanup },
                        onNavigateToSecurity: { selection = .threatScan }
                    )
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
                case .threatScan:
                    ThreatScanView()
                case .scheduledCleanup:
                    ScheduledCleanupView()
                case .osUpdater:
                    OSUpdaterView()
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
        .onChange(of: preferredLanguage) { oldValue, newValue in
            // Fuerza re-renderizado global con nuevo idioma
        }
    }

        private var languagePicker: some View {
        Menu {
            Button("Español") { 
                preferredLanguage = "es"
                UserDefaults.standard.set("es", forKey: "preferredLanguage")
                NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: "es")
            }
            Button("English") { 
                preferredLanguage = "en"
                UserDefaults.standard.set("en", forKey: "preferredLanguage")
                NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: "en")
            }
            Button("Português") { 
                preferredLanguage = "pt-BR"
                UserDefaults.standard.set("pt-BR", forKey: "preferredLanguage")
                NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: "pt-BR")
            }
            Button("中文") { 
                preferredLanguage = "zh-Hans"
                UserDefaults.standard.set("zh-Hans", forKey: "preferredLanguage")
                NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: "zh-Hans")
            }
            Button("日本語") { 
                preferredLanguage = "ja"
                UserDefaults.standard.set("ja", forKey: "preferredLanguage")
                NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: "ja")
            }
        } label: {
            HStack {
                Image(systemName: "globe")
                Text("Idioma")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }
}
