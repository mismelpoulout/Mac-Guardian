# Testing

Run the Phase 1 unit tests with:

```sh
xcodegen generate
xcodebuild -project MacGuardian.xcodeproj -scheme MacGuardian -destination 'platform=macOS' test
```

Current unit tests cover storage fraction calculation, missing/out-of-range capacity inputs, top-level folder aggregation, and large-file threshold filtering. Scanner tests use temporary directories; never run destructive operations against real user data in tests. Add security tests for path validation and policy decisions before implementing cleanup.
