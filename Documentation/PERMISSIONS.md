# Permissions

The Phase 1 dashboard requests no special privacy permissions. It reads public volume resource values and ProcessInfo metadata.

Future file scans may encounter locations macOS protects with privacy controls. Explain the specific access needed, provide a route to System Settings where appropriate, and distinguish denied/unavailable access from an empty result. Mac Guardian must not attempt to grant Full Disk Access, bypass TCC, or claim access without evidence.

Camera, microphone, location, automation, screen recording, and accessibility grants are not generally queryable as a complete inventory through a public API. Display “Not available through public macOS APIs” when a permission state cannot be verified.
