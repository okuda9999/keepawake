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

private final class FakeTimer: CountdownTimer {
    private(set) var isInvalidated = false
    func invalidate() { isInvalidated = true }
}

@MainActor
private final class FakeScheduler: CountdownScheduling {
    let timer = FakeTimer()
    private(set) var interval: TimeInterval?
    private var action: (() -> Void)?

    func scheduleRepeating(every interval: TimeInterval, action: @escaping () -> Void) -> CountdownTimer {
        self.interval = interval
        self.action = action
        return timer
    }

    func fire() { action?() }
}

private final class RunLoopSpy: TimerRegistering {
    private(set) var mode: RunLoop.Mode?
    func add(_ timer: Timer, forMode mode: RunLoop.Mode) {
        self.mode = mode
    }
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

    func testStopIsIdempotent() throws {
        let provider = FakeProvider()
        let session = AssertionSession(provider: provider)
        try session.start(duration: .untilStopped)
        session.stop()
        session.stop()
        XCTAssertEqual(provider.released, [100])
    }

    @MainActor
    func testCountdownExpiryStopsAndReleases() {
        let provider = FakeProvider()
        let scheduler = FakeScheduler()
        var date = Date(timeIntervalSince1970: 1_000)
        let model = KeepAwakeModel(provider: provider, now: { date }, scheduler: scheduler)

        model.start(.oneHour)
        XCTAssertTrue(model.isActive)
        XCTAssertEqual(scheduler.interval, 1)
        date.addTimeInterval(3_601)
        scheduler.fire()

        XCTAssertFalse(model.isActive)
        XCTAssertNil(model.remainingSeconds)
        XCTAssertEqual(provider.released, [100])
        XCTAssertTrue(scheduler.timer.isInvalidated)
    }

    @MainActor
    func testRemainingTextUsesJapaneseUnits() {
        let model = KeepAwakeModel(provider: FakeProvider(), scheduler: FakeScheduler())
        model.start(.oneHour)
        XCTAssertEqual(model.remainingText, "残り 1時間00分")
    }

    @MainActor
    func testProductionTimerRegistersInCommonRunLoopMode() {
        let runLoop = RunLoopSpy()
        let timer = CommonModeCountdownScheduler(runLoop: runLoop).scheduleRepeating(every: 1) {}
        timer.invalidate()
        XCTAssertEqual(runLoop.mode, .common)
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
