import Foundation
import IOKit.pwr_mgt

public protocol PowerAssertionProviding: AnyObject {
    func acquire(timeout: TimeInterval?) throws -> IOPMAssertionID
    func release(_ id: IOPMAssertionID)
}

public enum PowerAssertionError: LocalizedError, Equatable {
    case creationFailed(IOReturn)

    public var errorDescription: String? {
        switch self {
        case .creationFailed(let code):
            return "電源管理 assertion を開始できませんでした (IOKit: \(code))"
        }
    }
}

public final class IOKitPowerAssertionProvider: PowerAssertionProviding {
    public init() {}

    public func acquire(timeout: TimeInterval?) throws -> IOPMAssertionID {
        var assertionID = IOPMAssertionID(kIOPMNullAssertionID)
        let result = IOPMAssertionCreateWithDescription(
            kIOPMAssertPreventUserIdleDisplaySleep as CFString,
            "KeepAwake" as CFString,
            "KeepAwake が選択時間中のアイドル消灯を抑止しています" as CFString,
            "ユーザーが KeepAwake を有効にしました" as CFString,
            nil,
            timeout ?? 0,
            timeout == nil ? nil : kIOPMAssertionTimeoutActionTurnOff as CFString,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            throw PowerAssertionError.creationFailed(result)
        }
        return assertionID
    }

    public func release(_ id: IOPMAssertionID) {
        guard id != IOPMAssertionID(kIOPMNullAssertionID) else { return }
        IOPMAssertionRelease(id)
    }
}
