import Foundation
import KeepAwakeCore

let provider = IOKitPowerAssertionProvider()
let session = AssertionSession(provider: provider)

do {
    try session.start(duration: .untilStopped)
    print("QA_ASSERTION_ACTIVE pid=\(ProcessInfo.processInfo.processIdentifier)")
    fflush(stdout)
    Thread.sleep(forTimeInterval: 5)
    session.stop()
    print("QA_ASSERTION_RELEASED")
} catch {
    fputs("QA_ERROR: \(error.localizedDescription)\n", stderr)
    exit(1)
}
