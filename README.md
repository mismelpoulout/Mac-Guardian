# Mac Guardian

Native macOS maintenance and diagnostics software by Cynaxia.

Mac Guardian is local-first and privacy-first. The current app provides a system overview, cancellable folder-size and large-file scans, a developer-cache inventory, installed-app inventory, and a startup-item (`.plist`) audit. The screens open relevant macOS utilities where useful. These features inspect data only: they do not delete files, uninstall apps, or modify startup settings. Cleanup plans, uninstall workflows, and privileged operations are still planned work.

The interface supports Spanish by default, English, Brazilian Portuguese, Simplified Chinese, and Japanese. Its language preference is stored on this Mac. The app uses the supplied `logo.jpg` for its sidebar branding and application icon.

## Build

Requirements: Xcode 26.6 or compatible Xcode with the macOS 14 SDK or newer, and XcodeGen.

```sh
xcodegen generate
xcodebuild -project MacGuardian.xcodeproj -scheme MacGuardian -destination 'platform=macOS' build
```

Bundle identifier: `com.cynaxia.macguardian`. Deployment target: macOS 14.0.

The interface supports Spanish (default), English, Brazilian Portuguese, Simplified Chinese, and Japanese. The language choice is saved on this Mac.

See [DEVELOPMENT.md](Documentation/DEVELOPMENT.md) for setup, [COMPETITIVE_REVIEW.md](Documentation/COMPETITIVE_REVIEW.md) for product research, and [ROADMAP.md](Documentation/ROADMAP.md) for phase boundaries.
