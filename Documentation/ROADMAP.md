# Roadmap

- **Phase 0 — Environment audit:** complete. See `ENVIRONMENT_AUDIT.md`.
- **Phase 1 — Foundation:** SwiftUI app, sidebar navigation, domain/error/logging foundation, honest system overview, and build/test setup.
- **Phase 2 — Storage intelligence:** initial incremental, cancellable folder scanner and large-file listing implemented. Category attribution, deduplicated totals, exclusions, and richer partial-result explanations remain.
- **Phase 3 — Smart cleanup:** explicit, item-by-item movement of direct user-cache children to Trash implemented. Risk explanations, exclusions, stale-plan validation, and broader cleanup categories remain.
- **Phase 4 — Applications:** read-only inventory and explicit movement of eligible app bundles to Trash implemented. Related-file discovery and review remain unimplemented; support files are never removed implicitly.
- **Phase 5 — Developer tools:** initial inventory for known developer-related storage implemented; broader ecosystem coverage remains.
- **Phase 6 — Security:** read-only persistence audit and honest public-API privacy findings implemented; additional security analysis remains.
- **Phase 7 — Privileged architecture:** only for a demonstrated operation that requires elevation.
- **Phase 8 — Distribution:** Developer ID, hardened runtime, notarization and packaging.

Do not start a later phase until the current phase builds, tests, and has a documented security review.
