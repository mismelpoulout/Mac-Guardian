# Security

## Current posture

- No elevated helper, shell execution, network service, or telemetry exists. Cleanup can move direct children of the current user's cache folder and eligible application bundles to the macOS Trash after explicit confirmation.
- The dashboard reads metadata through public Foundation and ProcessInfo APIs.
- Errors are translated into user-facing messages; logs use OSLog categories.
- Permission failures must remain visible and must never be interpreted as an empty scan.

## Required design constraints

- Least privilege; no SIP, Gatekeeper, or TCC bypass.
- Never execute arbitrary commands as root. Any future helper protocol must expose narrow typed operations, validate the caller and target, fail closed, and log a privacy-minimized audit record.
- Scanners remain read-only and separate from the narrow Trash executor. No move without explicit user approval.
- Trash operations must enforce path boundaries, reject symbolic links, exclude system apps, and report failures. Prefer recoverable moves over permanent deletion.
- Do not log secrets or unnecessary file/user data.

Unit tests cover cache path boundaries, symbolic-link rejection, and application removal policy. Keep these tests in place and add coverage for any new mutating path before exposing it.
