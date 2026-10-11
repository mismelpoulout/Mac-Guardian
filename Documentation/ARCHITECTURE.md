# Architecture

Veltrix Security is a native SwiftUI app with boundaries between presentation, domain models, core services, and platform infrastructure.

```text
SwiftUI Views → View Models → Core services → Public macOS APIs
                         ↘ Domain models and safety policies
```

`VeltrixSecurityApp/Views` owns presentation; `ViewModels` owns screen state; `Domain` owns platform-independent values and errors; `Core` coordinates system reads and narrow Trash operations; `Infrastructure` contains OS integrations such as OSLog. Folder scans are incremental, cancellable, detached from the main actor, and read-only. The app also inventories known developer storage, application bundles, and launch plist definitions. A scanner must never delete. Cleanup actions are separate, path-scoped operations requiring an explicit confirmation and use the macOS Trash instead of permanent deletion.

The dashboard reads root-volume capacity using Foundation resource values and reports physical memory and uptime from ProcessInfo. It does not label installed memory as current memory use, invent health scores, or estimate recoverable bytes. Folder size reports use allocated size when macOS provides it and disclose skipped items; large-file scans default to a 100 MiB threshold in the UI.

Initial deployment target: macOS 14.0. This enables a modern baseline and is a project decision, not a claim that every planned capability is available on that OS. API availability and behavior must be checked when each feature is implemented.
