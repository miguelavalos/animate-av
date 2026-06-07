import Foundation

extension AnimateRemoteClient {
    func milliseconds(from date: Date) -> Double {
        date.timeIntervalSince1970 * 1000
    }

    func expirationMilliseconds(from date: Date = Date()) -> Double {
        date.addingTimeInterval(30 * 24 * 60 * 60).timeIntervalSince1970 * 1000
    }
}
