import SwiftUI

struct LanguagePicker: View {
    @ObservedObject var languageManager = LanguageManager.shared
    
    var body: some View {
        Menu {
            ForEach(languageManager.availableLanguages, id: \.code) { lang in
                Button(action: {
                    withAnimation {
                        languageManager.currentLanguage = lang.code
                    }
                }) {
                    HStack {
                        Text(lang.name)
                        if languageManager.currentLanguage == lang.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "globe")
                Text(languageManager.getLanguageName(languageManager.currentLanguage))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    LanguagePicker()
}
