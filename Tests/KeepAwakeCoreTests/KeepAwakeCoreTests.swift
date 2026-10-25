import XCTest
@testable import KeepAwakeCore
import IOKit.pwr_mgt

private final class FakeProvider: PowerAssertionProviding {
    var nextID: IOPMAssertionID = 100
    var acquiredTimeouts: [TimeInterval?] = []
    var released: [IOPMAssertionID] = []
    var error: Error?

    func acquire(timeout: TimeInterval?) throws -> IOPMAssertionID {
        if let error { throw error }
        acquiredTimeouts.append(timeout)
        defer { nextID += 1 }
        return nextID
    }

    func release(_ id: IOPMAssertionID) { released.append(id) }
}

final class KeepAwakeCoreTests: XCTestCase {
    func testDurationSettings() {
        XCTAssertEqual(KeepAwakeDuration.oneHour.seconds, 3_600)
        XCTAssertNil(KeepAwakeDuration.untilStopped.seconds)
    }

    func testRestartReleasesPreviousAssertion() throws {
        let provider = FakeProvider()
        let session = AssertionSession(provider: provider)
        try session.start(duration: .oneHour)
        try session.start(duration: .untilStopped)

        XCTAssertEqual(provider.acquiredTimeouts.count, 2)
        XCTAssertEqual(provider.acquiredTimeouts[0], 3_600)
        XCTAssertNil(provider.acquiredTimeouts[1])
        XCTAssertEqual(provider.released, [100])

        session.stop()
        XCTAssertEqual(provider.released, [100, 101])
        XCTAssertFalse(session.isActive)
    }

    func testSessionDeinitReleasesAssertion() throws {
        let provider = FakeProvider()
        var session: AssertionSession? = AssertionSession(provider: provider)
        try session?.start(duration: .untilStopped)
        session = nil
        XCTAssertEqual(provider.released, [100])
    }

    @MainActor
    func testCountdownExpiryStopsAndReleases() {
        let provider = FakeProvider()
        var date = Date(timeIntervalSince1970: 1_000)
        let model = KeepAwakeModel(provider: provider, now: { date })

        model.start(.oneHour)
        XCTAssertTrue(model.isActive)
        date.addTimeInterval(3_601)
        model.updateCountdown()

        XCTAssertFalse(model.isActive)
        XCTAssertNil(model.remainingSeconds)
        XCTAssertEqual(provider.released, [100])
    }

    @MainActor
    func testFailedCreationLeavesModelOff() {
        let provider = FakeProvider()
        provider.error = PowerAssertionError.creationFailed(kIOReturnError)
        let model = KeepAwakeModel(provider: provider)

        model.start(.untilStopped)

        XCTAssertFalse(model.isActive)
        XCTAssertNotNil(model.lastError)
        XCTAssertTrue(provider.released.isEmpty)
    }
}
