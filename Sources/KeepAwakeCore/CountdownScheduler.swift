import Foundation

public protocol CountdownTimer: AnyObject {
    func invalidate()
}

extension Timer: CountdownTimer {}

@MainActor
public protocol CountdownScheduling {
    func scheduleRepeating(
        every interval: TimeInterval,
        action: @escaping () -> Void
    ) -> CountdownTimer
}

public protocol TimerRegistering {
    func add(_ timer: Timer, forMode mode: RunLoop.Mode)
}

extension RunLoop: TimerRegistering {}

@MainActor
public struct CommonModeCountdownScheduler: CountdownScheduling {
    private let runLoop: TimerRegistering

    public init(runLoop: TimerRegistering = RunLoop.main) {
        self.runLoop = runLoop
    }

    public func scheduleRepeating(
        every interval: TimeInterval,
        action: @escaping () -> Void
    ) -> CountdownTimer {
        let timer = Timer(timeInterval: interval, repeats: true) { _ in action() }
        runLoop.add(timer, forMode: .common)
        return timer
    }
}
