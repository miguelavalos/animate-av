import Foundation

enum AnimateCreditBalanceLoadState: Equatable {
    case signedOut
    case loading
    case loaded
    case offline
    case unavailable

    var isLoading: Bool {
        self == .loading
    }

    var hasLoadedBalance: Bool {
        self == .loaded
    }

    var systemImage: String {
        switch self {
        case .signedOut:
            "person.crop.circle"
        case .loading:
            "creditcard"
        case .loaded:
            "creditcard.fill"
        case .offline:
            "wifi.slash"
        case .unavailable:
            "exclamationmark.triangle.fill"
        }
    }

    static func failureState(for error: Error) -> AnimateCreditBalanceLoadState {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return .unavailable
        }

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorTimedOut,
             NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorDNSLookupFailed:
            return .offline
        default:
            return .unavailable
        }
    }
}
