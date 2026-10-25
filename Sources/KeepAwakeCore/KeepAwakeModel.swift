import Combine
import Foundation

@MainActor
public final class KeepAwakeModel: ObservableObject {
    @Published public private(set) var isActive = false
    @Published public private(set) var remainingSeconds: TimeInterval?
    @Published public private(set) var lastError: String?

    private let session: AssertionSession
    private let now: () -> Date
    private var endDate: Date?
    private var timer: Timer?

    public init(
        provider: PowerAssertionProviding = IOKitPowerAssertionProvider(),
        now: @escaping () -> Date = Date.init
    ) {
        session = AssertionSession(provider: provider)
        self.now = now
    }

    public func start(_ duration: KeepAwakeDuration) {
        stop()
        do {
            try session.start(duration: duration)
            isActive = true
            lastError = nil
            if let seconds = duration.seconds {
                endDate = now().addingTimeInterval(seconds)
                remainingSeconds = seconds
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                    Task { @MainActor in self?.updateCountdown() }
                }
            } else {
                endDate = nil
                remainingSeconds = nil
            }
        } catch {
            stop()
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        remainingSeconds = nil
        session.stop()
        isActive = false
    }

    public func updateCountdown() {
        guard let endDate else { return }
        let remaining = max(0, endDate.timeIntervalSince(now()))
        remainingSeconds = remaining
        if remaining <= 0 { stop() }
    }

    public var remainingText: String? {
        guard let remainingSeconds else { return nil }
        let totalMinutes = Int(ceil(remainingSeconds / 60))
        return String(format: "残り %d:%02d", totalMinutes / 60, totalMinutes % 60)
    }

    deinit {
        timer?.invalidate()
    }
}
