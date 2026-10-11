import Foundation

enum MacGuardianError: Error, Equatable {
    case permissionDenied
    case protectedLocation
    case operationNotAllowed
    case helperUnavailable
    case invalidPath
    case scanFailed(String)
    case cleanupFailed(String)

    var userMessageKey: String {
        switch self {
        case .permissionDenied:
            "error.permissionDenied"
        case .protectedLocation:
            "error.protectedLocation"
        case .operationNotAllowed:
            "error.operationNotAllowed"
        case .helperUnavailable:
            "error.helperUnavailable"
        case .invalidPath:
            "error.invalidPath"
        case .scanFailed:
            "error.scanFailed"
        case .cleanupFailed:
            "error.cleanupFailed"
        }
    }
}
