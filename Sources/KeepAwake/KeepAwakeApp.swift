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

            let screen = NSBezierPath(roundedRect: NSRect(x: 1.2, y: 6.1, width: 11.8, height: 8.8), xRadius: 1.7, yRadius: 1.7)
            screen.lineWidth = 1.5
            screen.stroke()

            let stand = NSBezierPath()
            stand.lineWidth = 1.4
            stand.lineCapStyle = .round
            stand.move(to: NSPoint(x: 4, y: 4.2))
            stand.line(to: NSPoint(x: 8, y: 4.2))
            stand.move(to: NSPoint(x: 6, y: 4.2))
            stand.line(to: NSPoint(x: 6, y: 6.1))
            stand.stroke()

            let handle = NSBezierPath(ovalIn: NSRect(x: 13.9, y: 3, width: 3.2, height: 4.1))
            handle.lineWidth = 1.3
            handle.stroke()

            let cup = NSBezierPath()
            cup.move(to: NSPoint(x: 9.5, y: 8.2))
            cup.curve(
                to: NSPoint(x: 15.3, y: 8.2),
                controlPoint1: NSPoint(x: 9.5, y: 8.55),
                controlPoint2: NSPoint(x: 15.3, y: 8.55)
            )
            cup.line(to: NSPoint(x: 15, y: 4.3))
            cup.curve(
                to: NSPoint(x: 13.6, y: 2),
                controlPoint1: NSPoint(x: 14.9, y: 2.9),
                controlPoint2: NSPoint(x: 14.4, y: 2)
            )
            cup.line(to: NSPoint(x: 11.2, y: 2))
            cup.curve(
                to: NSPoint(x: 9.8, y: 4.3),
                controlPoint1: NSPoint(x: 10.4, y: 2),
                controlPoint2: NSPoint(x: 9.9, y: 2.9)
            )
            cup.close()
            cup.lineWidth = 1.3
            if isActive { cup.fill() } else { cup.stroke() }

            if isActive {
                let steam = NSBezierPath()
                steam.lineWidth = 1.2
                steam.lineCapStyle = .round
                steam.move(to: NSPoint(x: 11.2, y: 9.5))
                steam.curve(
                    to: NSPoint(x: 11.5, y: 12.2),
                    controlPoint1: NSPoint(x: 10.3, y: 10.3),
                    controlPoint2: NSPoint(x: 12.2, y: 11.2)
                )
                steam.move(to: NSPoint(x: 13.6, y: 9.5))
                steam.curve(
                    to: NSPoint(x: 13.9, y: 12.2),
                    controlPoint1: NSPoint(x: 12.7, y: 10.3),
                    controlPoint2: NSPoint(x: 14.6, y: 11.2)
                )
                steam.stroke()
            }
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
