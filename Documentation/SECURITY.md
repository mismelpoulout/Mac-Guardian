# Security

## Current posture

- No elevated helper, shell execution, network service, telemetry, or file mutation exists.
- The dashboard reads metadata through public Foundation and ProcessInfo APIs.
- Errors are translated into user-facing messages; logs use OSLog categories.
- Permission failures must remain visible and must never be interpreted as an empty scan.

## Required design constraints

- Least privilege; no SIP, Gatekeeper, or TCC bypass.
- Never execute arbitrary commands as root. Any future helper protocol must expose narrow typed operations, validate the caller and target, fail closed, and log a privacy-minimized audit record.
- Scanner, analyzer, risk engine, planner, and cleanup executor remain separate. No deletion without explicit user approval.
- Prefer recoverable moves only when the OS operation and destination semantics have been verified.
- Do not log secrets or unnecessary file/user data.

Security tests for path and policy validation are required before any mutating operation is introduced.
