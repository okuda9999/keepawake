import AppKit
import KeepAwakeCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var onTerminate: (() -> Void)?

    func applicationWillTerminate(_ notification: Notification) {
        onTerminate?()
    }
}

@main
struct KeepAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = KeepAwakeModel()

    var body: some Scene {
        MenuBarExtra {
            KeepAwakeMenu(model: model)
                .onAppear { appDelegate.onTerminate = { model.stop() } }
        } label: {
            Image(nsImage: StatusIcon.image(isActive: model.isActive))
                .accessibilityLabel(model.isActive ? "KeepAwake オン" : "KeepAwake オフ")
        }
        .menuBarExtraStyle(.menu)
    }
}

private enum StatusIcon {
    static func image(isActive: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { bounds in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            let screen = NSBezierPath(roundedRect: NSRect(x: 2, y: 3.5, width: 14, height: 10.5), xRadius: 2, yRadius: 2)
            screen.lineWidth = 1.5
            screen.stroke()

            let sunRect = NSRect(x: 6.5, y: 7, width: 5, height: 5)
            let sun = NSBezierPath(ovalIn: sunRect)
            if isActive { sun.fill() } else { sun.lineWidth = 1.25; sun.stroke() }

            if isActive {
                let rays = NSBezierPath()
                rays.lineWidth = 1.25
                for (start, end) in [
                    (NSPoint(x: 9, y: 12.6), NSPoint(x: 9, y: 13.5)),
                    (NSPoint(x: 6.1, y: 9.5), NSPoint(x: 5.2, y: 9.5)),
                    (NSPoint(x: 11.9, y: 9.5), NSPoint(x: 12.8, y: 9.5))
                ] {
                    rays.move(to: start)
                    rays.line(to: end)
                }
                rays.stroke()
            }

            let stand = NSBezierPath()
            stand.lineWidth = 1.5
            stand.move(to: NSPoint(x: 7, y: 2))
            stand.line(to: NSPoint(x: 11, y: 2))
            stand.move(to: NSPoint(x: 9, y: 2))
            stand.line(to: NSPoint(x: 9, y: 3.5))
            stand.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}

private struct KeepAwakeMenu: View {
    @ObservedObject var model: KeepAwakeModel

    var body: some View {
        if model.isActive {
            Text("状態: オン")
            if let remaining = model.remainingText { Text(remaining) }
            Button("停止") { model.stop() }
        } else {
            Text("状態: オフ")
            Button("1時間開始") { model.start(.oneHour) }
            Button("手動で停止するまで開始") { model.start(.untilStopped) }
        }

        if let error = model.lastError {
            Divider()
            Text(error)
        }

        Divider()
        Text("オン中はバッテリー消費が増える場合があります")
        Divider()
        Button("KeepAwake を終了") {
            model.stop()
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
