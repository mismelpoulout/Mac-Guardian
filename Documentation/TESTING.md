# Testing

Run the unit tests with:

```sh
xcodegen generate
xcodebuild -project VeltrixSecurity.xcodeproj -scheme VeltrixSecurity -destination 'platform=macOS' test
```

Current unit tests cover storage fraction calculation, missing/out-of-range capacity inputs, top-level folder aggregation, large-file threshold filtering and result limits, cache path boundaries, symbolic-link rejection, and protected/nested application removal policy. Scanner tests use temporary directories; never move real user data to Trash in tests.
