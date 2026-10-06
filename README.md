# Mac Guardian

Native macOS maintenance and diagnostics software by Cynaxia.

Mac Guardian is local-first and privacy-first. The current app provides a system overview, cancellable folder-size and large-file scans, a developer-cache inventory, installed-app inventory, and a startup-item (`.plist`) audit. The Cleanup section lets the user review direct children of their own cache folder and explicitly move selected items to Trash. The Applications section can move eligible app bundles from `/Applications` or `~/Applications` to Trash; related support files are left untouched. Startup settings are read-only, and protected system apps cannot be moved. Privileged operations and deeper uninstall analysis are still planned work.

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
