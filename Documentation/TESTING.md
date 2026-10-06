# Testing

Run the Phase 1 unit tests with:

```sh
xcodegen generate
xcodebuild -project MacGuardian.xcodeproj -scheme MacGuardian -destination 'platform=macOS' test
```

Current unit tests cover storage fraction calculation and missing/out-of-range capacity inputs. Future scanner tests should use fixtures and temporary directories; never run destructive operations against real user data in tests. Add security tests for path validation and policy decisions before implementing cleanup.
