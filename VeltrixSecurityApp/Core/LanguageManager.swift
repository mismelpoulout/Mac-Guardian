import SwiftUI
import Combine

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            updateLocale()
        }
    }
    
    private var localeUpdateSubject = PassthroughSubject<Locale, Never>()
    var localePublisher: AnyPublisher<Locale, Never> {
        localeUpdateSubject.eraseToAnyPublisher()
    }
    
    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "es"
    }
    
    private func updateLocale() {
        let locale = Locale(identifier: currentLanguage)
        localeUpdateSubject.send(locale)
    }
    
    var availableLanguages: [(code: String, name: String)] {
        [
            ("es", "Español"),
            ("en", "English"),
            ("pt-BR", "Português"),
            ("zh-Hans", "中文"),
            ("ja", "日本語")
        ]
    }
    
    func getLanguageName(_ code: String) -> String {
        availableLanguages.first(where: { $0.code == code })?.name ?? code
    }
}

// MARK: - View Modifier para aplicar idioma globalmente
struct LanguageEnvironmentModifier: ViewModifier {
    @ObservedObject var languageManager = LanguageManager.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
            .onChange(of: languageManager.currentLanguage) { oldValue, newValue in
                // Forzar re-renderizado de toda la interfaz
                UserDefaults.standard.set(newValue, forKey: "app_language")
            }
    }
}

extension View {
    func applyLanguageEnvironment() -> some View {
        modifier(LanguageEnvironmentModifier())
    }
}
