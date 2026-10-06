# Mac Guardian — Environment Audit

Audit performed 2026-10-06 in the supplied development environment.

## Environment

| Item | Finding |
| --- | --- |
| macOS | 26.4 (build 25E246) |
| Xcode | 26.6 (build 17F113) |
| macOS SDK | 26.5 |
| Swift | Apple Swift 6.3.3; compiler target arm64-apple-macosx26.0 |
| CPU architecture | arm64 (Apple Silicon) |
| Other SDKs | iOS/tvOS/visionOS/watchOS 26.5, simulators 26.5, DriverKit 25.5 |
| Project directory | Empty at audit start; no Xcode project, workspace, package, source, docs, dependencies, or Git repository |
| Xcode project listing | `xcodebuild -list` reports no project/workspace/package |
| Signing identities | One valid Apple Development identity is installed |
| Provisioning profiles | None installed for the current user |
| XcodeGen | Installed at `/opt/homebrew/bin/xcodegen` |

The signing identity proves local signing material exists; it does not show whether the associated Apple team currently has paid-program membership. That account status is not verifiable from the workspace or local command output.

## Capabilities and constraints

| Capability | Local development | Paid program / special approval | User authorization |
| --- | --- | --- | --- |
| SwiftUI app, local build and run | Available | Not required | No |
| Public storage and system metadata | Available; access varies by location | Not generally required | Full Disk Access is needed for some protected user data |
| Full Disk Access | Can be requested/tested locally | Not inherently a paid capability | Yes, granted by the user in System Settings |
| XPC | API and local development available | Signing/distribution setup needs validation for production | Not inherently |
| SMAppService helpers | Public API on macOS 13+ | Distribution and helper signing require later verification | User approval/system settings may apply |
| Developer ID signing | Not established by the installed Apple Development identity | Requires Apple Developer Program account holder access | No |
| Notarization | Not available from current evidence | Developer ID and Apple notary service; membership required | No |
| Endpoint Security | Do not assume available | Apple entitlement request required | System extension approval and applicable OS authorization |
| System Extensions / DriverKit | Do not assume available | Entitlement may be required for the intended use | User/system approval applies |

Apple states free Apple Account holders can develop with Xcode and test locally; Developer ID and notarization are included with paid membership. Apple separately requires a request for the Endpoint Security entitlement. See [membership comparison](https://developer.apple.com/support/compare-memberships/), [Developer ID](https://developer.apple.com/developer-id/), and [Endpoint Security entitlement](https://developer.apple.com/documentation/BundleResources/Entitlements/com.apple.developer.endpoint-security.client).

## Implement now

- SwiftUI application, navigation, domain types, OSLog categories, typed errors, and a non-destructive dashboard.
- Read public volume capacity and system uptime/memory information, with unavailable states when macOS does not return a value.
- Compile and run locally on this Apple Silicon Mac; build settings can later add x86_64 for a universal binary.
- Scanner and cleanup architecture can be developed unprivileged and tested against synthetic inputs before accessing user files.

## Defer until verified

- Developer ID signing and notarization until paid team membership and the relevant certificate/account role are confirmed.
- Any privileged helper until a concrete operation needs it and its supported ServiceManagement model, signing, authorization, and distribution route are validated.
- Endpoint Security or a system extension until a real product requirement exists and Apple grants the entitlement.
- Full Disk Access inspection: offer the user an explanation and Settings navigation; never infer authorization from a failed scan.

## Technical risks and decisions

- A clean workspace means no existing behavior, project settings, or tests could be assessed.
- macOS version 26.4 is newer than the SDK-independent compatibility floor. Use macOS 14.0 as an initial deployment target because the product is new and current API needs can be supported; revise only against a documented feature/compatibility need.
- Swift 6 strict concurrency may surface isolation diagnostics. Keep scanning off the main actor and use value types/actors when scanner work is introduced.
- Storage figures can differ by filesystem/APFS accounting and privacy permissions; present the precise API meaning and unavailable states rather than extrapolated category totals.
- The generated Release app was verified as a universal binary containing arm64 and x86_64 slices. Intel runtime testing still requires Intel hardware or a compatible CI host.
- The name “Mac Guardian” and bundle ID are product inputs, not evidence of trademark availability or legal ownership.

## Recommended architecture and roadmap

Keep a SwiftUI presentation layer, domain models/policies, and infrastructure adapters separate. Begin with least-privilege public APIs; scanners produce findings, analyzers and risk policy explain them, planners produce reviewable plans, and only an explicit cleanup service may mutate user data. Add XPC/helper only for a narrowly defined operation that cannot be performed safely in-process.

1. Phase 1 — app foundation, navigation, models, logging, typed errors, honest dashboard, build/test setup.
2. Phase 2 — incremental, cancellable storage inventory and large-file scan.
3. Phase 3 — risk scoring, cleanup plan and dry-run only; require review before mutation.
4. Phase 4 — application inventory and removal plans.
5. Phase 5 — developer storage inventory.
6. Phase 6 — persistence/security audit and public-API privacy surface.
7. Phase 7 — narrowly scoped privileged design only when justified.
8. Phase 8 — distribution signing, hardened runtime, notarization and installer validation.
