import Foundation
import IOKit.pwr_mgt

public final class AssertionSession {
    private let provider: PowerAssertionProviding
    private var assertionID: IOPMAssertionID?

    public init(provider: PowerAssertionProviding) {
        self.provider = provider
    }

    public var isActive: Bool { assertionID != nil }

    public func start(duration: KeepAwakeDuration) throws {
        stop()
        assertionID = try provider.acquire(timeout: duration.seconds)
    }

    public func stop() {
        guard let assertionID else { return }
        self.assertionID = nil
        provider.release(assertionID)
    }

    deinit {
        stop()
    }
}
