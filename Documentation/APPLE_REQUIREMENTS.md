# Apple Requirements

This table separates local development from distribution and special Apple approvals. “Verify” means the exact entitlement, signing, authorization, and deployment behavior must be checked against the selected implementation before it is built.

| Capability | Local development | Paid Developer Program | User permission / approval |
| --- | --- | --- | --- |
| SwiftUI | YES | NO | NO |
| Storage scanner | YES | NO | Depends on location and TCC access |
| Full Disk Access | YES | NO | YES |
| XPC | YES | NO for local development | NO inherently; production signing must be verified |
| Privileged helper | Verify implementation and macOS version | Likely for distribution signing; verify | YES / authorization flow depends on design |
| Developer ID | NO for Apple-issued distribution certificate | YES | NO |
| Notarization | NO for Apple notary submission | YES, Developer ID distribution route | NO |
| Endpoint Security | Do not assume | Apple entitlement approval required | System extension and user/system approval may apply |
| System Extensions | Verify | Entitlement may be required | YES / system approval may apply |

Xcode local development is available with a free Apple Account. Apple lists Developer ID and notarization as paid-program benefits. Endpoint Security requires requesting its entitlement from Apple. Account membership is not confirmed by the local signing identity. Sources: [membership comparison](https://developer.apple.com/support/compare-memberships/), [Developer ID](https://developer.apple.com/developer-id/), [Endpoint Security entitlement](https://developer.apple.com/documentation/BundleResources/Entitlements/com.apple.developer.endpoint-security.client), [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice).
