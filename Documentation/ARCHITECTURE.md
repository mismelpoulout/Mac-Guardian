# Architecture

Mac Guardian is a native SwiftUI app with boundaries between presentation, domain models, core services, and platform infrastructure.

```text
SwiftUI Views → View Models → Core services → Public macOS APIs
                         ↘ Domain models and safety policies
```

`MacGuardianApp/Views` owns presentation; `ViewModels` owns screen state; `Domain` owns platform-independent values and errors; `Core` coordinates system reads; `Infrastructure` contains OS integrations such as OSLog. Future scans must be incremental, cancellable, and detached from the main actor. A scanner must never delete. Cleanup requires an explicit reviewed plan and a separate executor.

The initial dashboard reads root-volume capacity using Foundation resource values and reports physical memory and uptime from ProcessInfo. It does not label installed memory as current memory use, invent health scores, or estimate recoverable bytes.

Initial deployment target: macOS 14.0. This enables a modern baseline and is a project decision, not a claim that every planned capability is available on that OS. API availability and behavior must be checked when each feature is implemented.
