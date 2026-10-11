# Development

## Requirements

- macOS 14.0 or newer to run the app.
- Xcode with a macOS SDK compatible with the deployment target.
- XcodeGen to generate the project from `project.yml`.

## Build and run

```sh
xcodegen generate
xcodebuild -project VeltrixSecurity.xcodeproj -scheme VeltrixSecurity -destination 'platform=macOS' build
open VeltrixSecurity.xcodeproj
```

Bundle identifier: `com.cynaxia.veltrixsecurity`. Product: Cynaxia. The generated Xcode project is derived from the checked-in `project.yml`.

## Localization

UI translations live in `VeltrixSecurityApp/Resources/Localizable.xcstrings`. Keep the English source entry and provide translations for `es`, `en`, `pt-BR`, `zh-Hans`, and `ja`. Spanish is the first-run app preference; the selected language is stored in `UserDefaults` and applied to the SwiftUI locale without changing the macOS system language. Use locale-aware formatters for sizes and durations.

## Signing

Local development can use automatic signing or ad hoc signing where suitable. Do not treat the installed Apple Development identity as proof of Developer ID access or paid membership. Distribution signing and notarization are deferred to Phase 8 after team access is verified.
