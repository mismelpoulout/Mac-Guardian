# Mac Guardian

Native macOS maintenance and diagnostics software by Cynaxia.

Mac Guardian is being built local-first and privacy-first. The initial foundation displays a small set of values read from public macOS APIs. Scanning, recommendations, cleanup, and privileged operations are not yet implemented.

## Build

Requirements: Xcode 26.6 or compatible Xcode with the macOS 14 SDK or newer, and XcodeGen.

```sh
xcodegen generate
xcodebuild -project MacGuardian.xcodeproj -scheme MacGuardian -destination 'platform=macOS' build
```

Bundle identifier: `com.cynaxia.macguardian`. Deployment target: macOS 14.0.

The interface supports Spanish (default), English, Brazilian Portuguese, Simplified Chinese, and Japanese. The language choice is saved on this Mac.

See [DEVELOPMENT.md](Documentation/DEVELOPMENT.md) for setup and [ROADMAP.md](Documentation/ROADMAP.md) for phase boundaries.
