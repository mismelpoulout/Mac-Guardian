# Permissions

The dashboard requests no special privacy permissions. It reads public volume resource values and ProcessInfo metadata. User-selected folder scans and inventories of common cache and startup folders may encounter locations protected by macOS privacy controls.

Future file scans may encounter locations macOS protects with privacy controls. Explain the specific access needed, provide a route to System Settings where appropriate, and distinguish denied/unavailable access from an empty result. Veltrix Security must not attempt to grant Full Disk Access, bypass TCC, or claim access without evidence.

Camera, microphone, location, automation, screen recording, and accessibility grants are not generally queryable as a complete inventory through a public API. Display “Not available through public macOS APIs” when a permission state cannot be verified.
