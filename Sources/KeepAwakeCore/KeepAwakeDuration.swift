import Foundation

public enum KeepAwakeDuration: Equatable, Sendable {
    case oneHour
    case untilStopped

    public var seconds: TimeInterval? {
        switch self {
        case .oneHour: return 60 * 60
        case .untilStopped: return nil
        }
    }
}
